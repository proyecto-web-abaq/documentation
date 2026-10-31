# Diseño de Datos: Ciclo de Vida, Respaldos y Recuperación

**Proyecto:** Plataforma Web ABAQ (Servicio Social)
**Versión:** 0.3.0
**Fecha:** 2026-10-14
**Estado:** Propuesta de diseño (con decisiones pendientes marcadas)
**Relacionado:** [Arquitectura](architecture.md) · [Despliegue en la nube (Azure)](cloud-deployment.md) · [Mapa de interfaces](ui-prompts-figma.md)

---

## 1. Propósito y contexto

La infraestructura **no contempla replicación** de la base de datos y el presupuesto de almacenamiento es acotado. El sistema resuelve esto con dos mecanismos **independientes**:

1. **Ciclo de vida de los datos (tiering):** mantiene en la base de datos solo lo que se usa en el presente y mueve el resto a almacenamiento barato del que se puede recuperar para consulta.
2. **Respaldos:** copias completas de la base de datos para recuperarse de pérdidas, errores o rollbacks.

!!! abstract "Principios"
    1. **El ciclo de vida es diseño de arquitectura, no configuración.** La ventana activa, las fases y sus reglas forman parte del diseño del backend y de la nube. Desde el portal **se observan y se accionan, pero no se reconfiguran**.
    2. **Lo relevante es ocupación y costo**, no qué periodos están en cada fase.
    3. El sistema **no guarda archivos** en la base de datos. Todo artefacto (ZIP de datos, backup) vive en un bucket (Azure Blob Storage).
    4. **Los respaldos no forman parte del tiering.** Viven en su propio bucket, con su propia regla de permanencia.
    5. Toda operación de datos relevante para administración tiene **interfaz en el portal**.

```mermaid
flowchart LR
    subgraph T["Dominio 1 — Ciclo de vida (visible en la Consola)"]
        A["ACTIVA<br/>Base de datos<br/>periodo en curso + 1 año atrás"] -->|"automático al salir de la ventana<br/>(ZIP)"| F["FRÍO<br/>Blob tier Archive"]
        F -->|"rehidratar (acción admin)"| R["REHIDRATACIÓN<br/>Blob tier Hot<br/>consumo y descarga de ZIP"]
        R -->|"regresar a frío (acción admin)"| F
    end
    subgraph B["Dominio 2 — Respaldos (bucket propio, fuera del tiering)"]
        P["Programados 2x/semana"] --> BK["Bucket de respaldos<br/>Blob tier Cold<br/>permanencia 6 meses"]
        M["Generados manualmente"] --> BK
    end
    A -.volcado completo.-> P
    A -.volcado completo.-> M
```

---

## 2. Ciclo de vida de los datos (tiering)

### 2.1 Ventana activa (fija por diseño)

- La base de datos trabaja con el **periodo en curso y un año hacia atrás**. Con periodos semestrales, equivale al semestre vigente y los dos anteriores.
- La ventana **no es configurable** desde el portal; cambiarla es un cambio de diseño (backend + infraestructura).
- Cuando un periodo sale de la ventana, el sistema lo **exporta como ZIP** y lo envía a **Frío**. Luego lo **borra de la base de datos**.

!!! danger "Salvaguarda antes de borrar de la base de datos"
    El borrado de un periodo en la base de datos solo procede si:

    1. el ZIP se subió a Frío y su **checksum coincide** con el archivo generado, y
    2. existe al menos un **respaldo vigente** que contiene ese periodo.

    Si alguna condición falla, el periodo permanece en la base de datos y se notifica a las administradoras.

### 2.2 Las tres fases

| Fase | Qué guarda | Servicio Azure | Acceso | Mínimo de permanencia |
|---|---|---|---|---|
| **Activa** | Datos del periodo en curso + 1 año atrás | Azure DocumentDB (Cosmos DB for MongoDB vCore) | En vivo, por la aplicación | — |
| **Frío** | ZIP de cada periodo que salió de la ventana | Blob Storage, tier **Archive** | **Offline:** no se puede leer ni descargar sin rehidratar [1] | 180 días [1] |
| **Rehidratación** | Copias de ZIP traídas de Frío para consumo | Blob Storage, tier **Hot** | Inmediato (descarga del ZIP) | Ninguno [1] |

!!! warning "Regla técnica de Azure: no hay descarga directa desde Archive"
    Un blob en Archive no se puede leer ni descargar. Para consumirlo hay que **rehidratarlo** a un tier en línea, lo que tarda **hasta 15 horas** con prioridad estándar o **menos de 1 hora** con prioridad alta para objetos menores a 10 GB. El límite es de **10 GiB por hora por cuenta** con prioridad alta [2]. La política de lifecycle **no puede rehidratar**; la rehidratación siempre es una acción explícita [1].

    En la interfaz, "descargar de Frío" es por tanto una acción en dos pasos: **rehidratar → descargar desde Rehidratación**.

### 2.3 Rehidratación (consumo desde el bucket, no en la base de datos)

- La rehidratación **no vuelve a cargar datos en la base de datos**. El ZIP queda disponible en el bucket para **descargarse y consultarse fuera del sistema**.
- Se implementa como **copia** del blob archivado hacia Rehidratación (Hot) [2]:
    - el original **permanece en Frío**, por lo que no se paga el cargo por borrado anticipado de Archive (180 días);
    - se evita que una regla de lifecycle vuelva a archivar la copia [2].
- **Regresar a Frío** = eliminar la copia de Rehidratación. El original sigue en Archive, y Hot no tiene mínimo de permanencia, así que la operación es inmediata y sin penalización [1].
- La carga de datos a la base de datos (por ejemplo, tras una pérdida) es otro proceso: el **bulk load** (§5).

```mermaid
sequenceDiagram
    participant AD as Administradora
    participant CO as Consola (portal)
    participant BE as Backend
    participant AR as Frío (Archive)
    participant HO as Rehidratación (Hot)

    AD->>CO: "Rehidratar" ZIP (prioridad estándar o alta)
    CO->>AD: Aviso de tiempo estimado y costo
    AD->>CO: Confirma
    CO->>BE: Solicitud de rehidratación
    BE->>AR: Copy Blob → destino Hot con prioridad
    Note over AR,HO: Hasta 15 h (estándar) / < 1 h (alta)
    HO-->>BE: Copia disponible
    BE-->>CO: Estado "Listo para descargar"
    AD->>CO: Descargar ZIP
    CO->>HO: Descarga
    AD->>CO: "Regresar a frío"
    CO->>BE: Eliminar copia en Hot (original intacto en Archive)
```

---

## 3. Consola de ciclo de vida de datos

Sección de administración para **conocer la información vital** de las tres fases y **accionar** sobre Frío y Rehidratación. No permite modificar el diseño del ciclo de vida.

### 3.1 Indicadores

| Indicador | Activa | Frío | Rehidratación | Total |
|---|---|---|---|---|
| Ocupación (GB) | ✔ | ✔ | ✔ | ✔ |
| % del total almacenado | ✔ | ✔ | ✔ | 100 % |
| % de capacidad | ✔ (vs. 32 GB del Free Tier [3]) | — | — | — |
| Costo mensual | ✔ | ✔ | ✔ | ✔ |
| Elementos (ZIP) | — | ✔ | ✔ | — |
| Rehidrataciones en curso | — | — | ✔ (con prioridad y tiempo transcurrido) | — |

### 3.2 Acciones permitidas y no permitidas

| Acción | ¿Permitida? | Detalle |
|---|---|---|
| Rehidratar ZIP (Frío → Rehidratación) | Sí | Elegir prioridad estándar o alta; la consola muestra tiempo y costo estimados antes de confirmar |
| Regresar a Frío (Rehidratación → Frío) | Sí | Elimina la copia en línea; el original sigue en Archive |
| Descargar ZIP | Sí, solo desde Rehidratación | Desde Frío, el botón inicia la rehidratación |
| Cambiar la ventana activa, las fases o sus reglas | No | Es diseño de arquitectura |
| Borrar datos de Frío | No incluido | Fuera del alcance definido |

### 3.3 Cómo se calcula la ocupación

- **Activa:** estadísticas de la base de datos (`dbStats` / `collStats`).
- **Frío y Rehidratación:** listado de blobs de la cuenta de tiering, sumando el tamaño por tier (cada blob expone su tier y su tamaño). A la escala de ABAQ, este listado es exacto e inmediato.

### 3.4 Cómo se calcula el costo

!!! warning "El costo real facturado puede no estar disponible o no reflejar el crédito"
    Cost Management (la fuente del costo facturado) depende del tipo de cuenta del grant. En el modelo actual, el grant es un **crédito aplicado a un perfil de facturación (MCA)** y Cost Management funciona. En el modelo heredado, la oferta **Microsoft Azure Sponsorship (MS-AZR-0036P)** figura entre las **no soportadas** [4]. En ambos casos, Cost Management **no descuenta créditos ni muestra recursos gratuitos**, y sus datos llegan con retraso (8–24 h en EA/MCA, hasta 72 h en pago por uso) [4]. Hay que confirmar el *Offer ID* real de la suscripción (D-T5).

Por eso el diseño calcula un **costo estimado**:

> costo mensual de la fase = ocupación medida (GB) × precio unitario de lista del tier (Azure Retail Prices API [5], `eastus`)

- Los precios se consultan periódicamente y se guardan en caché; la consola muestra la fecha del precio.
- El costo se etiqueta como **estimado (precio de lista)**, no como facturado.
- **Activa:** $0 mientras se use el Free Tier de DocumentDB; con un tier pagado, el costo es fijo por clúster más almacenamiento.
- Si en el futuro la suscripción soporta Cost Management, se puede añadir el costo facturado como dato complementario.

Precios de referencia (`eastus`, LRS, consulta 2026-10-14):

| Concepto | Precio de lista |
|---|---|
| Archive — almacenamiento | $0.00099 por GB-mes |
| Hot — almacenamiento | $0.0208 por GB-mes |
| Cold — almacenamiento (respaldos) | $0.0036 por GB-mes |
| Rehidratación estándar — recuperación / lectura | $0.02 por GB / $5.00 por 10K operaciones |
| Rehidratación alta — recuperación / lectura | $0.10 por GB / $50.00 por 10K operaciones |

Con el volumen de ABAQ, rehidratar un ZIP de 100 MB cuesta menos de $0.01 (estándar) o ~$0.015 (alta).

---

## 4. Respaldos (dominio independiente)

- **Bucket propio:** una cuenta de almacenamiento separada de la de tiering. **No aparece en la Consola de ciclo de vida.** Separar cuentas permite atribuir el costo por recurso y evita mezclar reglas de lifecycle.
- **Programados:** 2 veces por semana (volcado completo, comprimido).
- **Generables manualmente** desde el portal: base de datos completa o por modelo. Permite descarga directa de archivo comprimido `.zip` (JSONs + `manifest.json`) y libro consolidado de Excel `.xlsx` para auditoría administrativa.
- **Permanencia: 6 meses.** Una regla de lifecycle **elimina cada respaldo a los 180 días** de su creación [6]. Aplica a respaldos programados y manuales.
- **Tier Cold:** en línea, restauración inmediata [1]. Su mínimo de 90 días es menor a los 180 de permanencia, así que no hay cargo por borrado anticipado. Archive no conviene para respaldos: restaurar tomaría horas.
- **Qué pueden hacer las administradoras:** generar, listar (fecha, tamaño, fecha de expiración), descargar y usar como fuente de bulk load / rollback.
- **Qué no pueden hacer:** cambiar la frecuencia ni la permanencia; son parte del diseño.

!!! tip "Implementación en el Portal Web Admin (v2.2.0)"
    El portal de administración incorpora la sección **Respaldos** (`/admin/backups`) que ejecuta la descarga directa local de:
    1. Paquete `.zip` con los volcados JSON de las 14 colecciones más manifiesto de integridad SHA-256 (fuente oficial de rollback).
    2. Libro Excel `.xlsx` multi-hoja formateado para consulta operativa y auditoría de datos.
    3. Restauración en dos fases (*dry-run* y confirmación) para re-inyección de datos (*rollback*).

!!! warning "Alcance de desarrollo (dependiente de infraestructura)"
    La integración real con Azure Blob queda **pendiente de aprovisionar la infraestructura**. En el backend se desarrolla hasta antes de la subida efectiva: volcado, compresión y preparación del artefacto, dejando la subida como integración documentada (stub).

```mermaid
flowchart TD
    subgraph Origen
        S["Programado 2x/semana"]
        H["Manual: BD completa o por modelo"]
    end
    S --> G["mongodump + compresión"]
    H --> G
    G --> U["Subida al bucket de respaldos (Cold)"]
    U --> L["Lifecycle: borrado a los 180 días"]
    U --> D["Descarga / fuente de bulk load"]
```

---

## 5. Recuperación y carga masiva (bulk load)

Sistema para **re-inyectar** información en la base de datos ante pérdidas, errores, rollbacks o escenarios imprevistos. Tiene **interfaz en el portal**.

### 5.1 Fuentes admitidas

- **Respaldos del sistema** (§4).
- **Excel y CSV** con el formato definido.

### 5.2 Validación previa obligatoria (dry-run)

!!! danger "Dry-run obligatorio"
    Antes de inyectar cualquier dato, el sistema ejecuta una **validación en seco** y presenta un **reporte previo** (conteos, conflictos, registros inválidos). La inyección real **solo procede tras revisar y confirmar ese reporte**.

```mermaid
flowchart TD
    F["Fuente: respaldo del sistema<br/>o Excel/CSV con formato"] --> V["Dry-run: validación + reporte previo"]
    V --> R{"¿Reporte conforme?"}
    R -->|No| X["Cancelar / corregir archivo"]
    R -->|Sí, confirmar| I["Inyección real a la BD"]
    I --> OK["Datos recuperados"]
```

---

## 6. Dependencias técnicas a investigar

| Propósito | Candidata | Notas |
|---|---|---|
| Azure Blob (subir, listar, cambiar tier, copiar con rehidratación) | `@azure/storage-blob` | SDK oficial para Node |
| Autenticación a Azure | `@azure/identity` | Identidad administrada, sin credenciales embebidas |
| Empaquetado ZIP | `archiver` / `zlib` (nativo) | ZIP por periodo (Frío); gzip/archivo para respaldos |
| Volcado y restauración | `mongodump` / `mongorestore` | MongoDB Database Tools |
| Parseo de Excel / CSV | `xlsx` / `csv-parse` | Bulk load |
| Precios para la consola | Azure Retail Prices API | Pública, sin credenciales [5] |
| Jobs programados | Según la arquitectura | Ver [Despliegue](cloud-deployment.md) |
| Lifecycle de los buckets | Reglas de Azure Blob lifecycle | Configuración de infraestructura (OpenTofu), no dependencia npm [6] |

---

## 7. Requisitos derivados

- **RF-DAT-01**: La base de datos mantiene el periodo en curso y un año hacia atrás; la ventana no es configurable desde el portal.
- **RF-DAT-02**: Al salir de la ventana, cada periodo se exporta como ZIP a Frío (Archive) y se borra de la base de datos, solo tras verificar el checksum y la existencia de un respaldo vigente.
- **RF-DAT-03**: La Consola muestra, por fase y en total, ocupación, porcentaje y costo mensual estimado.
- **RF-DAT-04**: Las administradoras pueden rehidratar ZIP (Frío → Rehidratación) eligiendo prioridad, regresarlos a Frío y descargarlos desde Rehidratación.
- **RF-DAT-05**: La rehidratación no carga datos en la base de datos; el consumo es desde el bucket.
- **RF-DAT-06**: Respaldos programados 2 veces por semana y generables manualmente (BD completa o por modelo), en un bucket propio fuera del tiering.
- **RF-DAT-07**: Todo respaldo se elimina automáticamente a los 6 meses (180 días).
- **RF-DAT-08**: El bulk load admite respaldos del sistema y Excel/CSV, con dry-run obligatorio.
- **RNF-DAT-01**: El sistema no persiste archivos en la base de datos; los artefactos van al bucket.
- **RNF-DAT-02**: El costo mostrado en la Consola se rotula como estimado (precio de lista) mientras no exista una fuente de costo facturado para la suscripción.

---

## 8. Decisiones pendientes

| ID | Decisión | Opciones |
|---|---|---|
| D-T1 | Tier de Frío | **Archive (aplicado):** costo mínimo, descarga en dos pasos con espera de horas · **Cold:** descarga inmediata sin rehidratación, ~3.6× el costo de Archive; a la escala de ABAQ la diferencia es de centavos al mes |
| D-T2 | Expiración de copias en Rehidratación | Manual (aplicado: solo "Regresar a frío") / automática tras N días |
| D-T3 | Modo de carga del bulk load | Overwrite total / upsert por correo institucional / insertar solo faltantes |
| D-T4 | Fuente del costo en la Consola | Estimado por precio de lista (aplicado) / añadir el facturado si la suscripción lo soporta |
| D-T5 | Tipo de cuenta del grant | Confirmar el *Offer ID*: crédito en perfil MCA (Cost Management disponible, costo bruto) o Sponsorship heredada (no soportada) |

---

## Referencias

1. Microsoft Learn — *Access tiers for blob data* (Hot, Cool, Cold, Archive; permanencias mínimas; Archive offline). <https://learn.microsoft.com/en-us/azure/storage/blobs/access-tiers-overview>
2. Microsoft Learn — *Blob rehydration from the archive tier* (prioridades, tiempos, límite de 10 GiB/h, rehidratación por copia). <https://learn.microsoft.com/en-us/azure/storage/blobs/archive-rehydrate-overview>
3. Microsoft Learn — *Free tier – Azure DocumentDB* (32 GB). <https://learn.microsoft.com/en-us/azure/documentdb/free-tier>
4. Microsoft Learn — *Understand Cost Management data* (ofertas soportadas, retraso, exclusiones). <https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/understand-cost-mgt-data>
5. Microsoft Learn — *Azure Retail Prices REST API*. <https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices>
6. Microsoft Learn — *Azure Blob Storage lifecycle management overview*. <https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview>

*Contenido de las fuentes parafraseado para cumplir restricciones de licencia.*
