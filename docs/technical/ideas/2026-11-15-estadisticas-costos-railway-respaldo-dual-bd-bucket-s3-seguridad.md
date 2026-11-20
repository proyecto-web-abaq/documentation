---
title: "Estadísticas Duales, Costos Railway, Respaldo Tri-Modal y Auditoría OWASP (2026-11-15)"
date: 2026-11-15
icon: lucide/circle-check
status: Documentado para Validación (Sin Implementación en Código)
author: Equipo de Arquitectura y Seguridad ABAQ
---

# Estadísticas Duales (Base de Datos + Bucket S3), Costos Oficiales Railway, Respaldo Tri-Modal y Auditoría de Seguridad Web (OWASP WSTG)

> **Estado del Documento:** Propuesta técnica y dictamen de auditoría documental listos para revisión y validación. **No se ha modificado código fuente en `frontend/` ni en `backend/`.**

---

## 1. Resumen Ejecutivo y Objetivos

El módulo de **Respaldos y Recuperación (`/admin/backups`)** debe evolucionar para ofrecer a la Coordinación visibilidad completa tanto de la **base de datos operativa (MongoDB)** como del **almacén de archivos (Railway Storage Bucket S3)**, manteniendo estricto apego a la **reutilización de componentes existentes** (`.hero-stats-grid`, `.hero-stat-card` y modal de vista previa de restauración), lenguaje ciudadano sencillo y controles rigurosos de eficiencia y seguridad.

Las seis metas de esta iniciativa son:

1. **Dividir el encabezado de estadísticas en dos contenedores gemelos**:
   - **Contenedor 1 — Base de datos (Información del sistema):** Conexión/latencia, secciones activas, registros + peso físico y **costo mensual estimado con diferencial de crecimiento ($\Delta$)**.
   - **Contenedor 2 — Almacenamiento de archivos (Documentos guardados — Bucket S3):** Estado del almacén, carpetas activas (`4 / 4`), archivos + peso total y **costo mensual estimado con diferencial de crecimiento ($\Delta$)**.
2. **Calcular costos mensuales reales con la documentación oficial de Railway**: Documentar y explicar aquí las fórmulas exactas para MongoDB y Storage Bucket sin exponer jamás fórmulas matemáticas al usuario final. Mostrar únicamente el peso, el costo mensual estimado, un indicador sencillo de crecimiento/aceleración y un *hint* discreto **con únicamente la fecha** de última actualización (`Última actualización: DD/MM/AAAA`), evitando refrescos automáticos constantes.
3. **Refactorizar el respaldo y manifiesto (`v3.0.0`) con 3 opciones de descarga y lenguaje simple**:
   - **Prohibición explícita en UI:** Nunca mencionar la palabra **"PDF"** en la sección de respaldos; referirse siempre a **"archivos"** o **"documentos guardados"**.
   - Permitir descargar: **(1) Respaldo completo (Base de datos y archivos)**, **(2) Solo base de datos (Registros del sistema)** y **(3) Solo archivos (Documentos guardados)**.
4. **Validación previa a cualquier descarga (`validateBackupReadiness`)**: Antes de entregar el `.zip`, comprobar en servidor que la base de datos no presente corrupción, que los archivos del bucket estén íntegros y que todas las referencias cruzadas BD $\leftrightarrow$ Bucket S3 estén sanas.
5. **Restauración / Rollback con soporte de archivos del Bucket y protección estricta anti-sobrescritura**: Reutilizar el *dropzone* unificado y el modal de vista previa existente (`showRollbackReviewModal` / `showPackageReviewModal`) para inspeccionar colecciones + carpetas de archivos antes de restaurar, conservando intacto todo dato o archivo preexistente (*Zero-Overwrite*).
6. **Blindaje universal contra abuso de descargas (3 intentos / 8 horas + Circuit Breaker)** y **Auditoría de Seguridad Web** de todo el proyecto actual y de esta nueva propuesta conforme al playbook **Metodología de Auditoría de Seguridad Web - Ejecución y Reporte (Prof. Ricardo Monroy)** basado en **OWASP WSTG** y **OWASP Top 10 (2021)**.

---

## 2. Modelo Matemático Oficial de Costos Mensuales en Railway y Diferencial de Crecimiento ($\Delta$)

> **Regla de Presentación UI:** Las ecuaciones matemáticas descritas en esta sección son para **documentación técnica y cálculo en backend exclusivamente**. En la pantalla de `/admin/backups`, la persona usuaria **nunca** verá la fórmula; solo verá el peso acumulado, el costo mensual estimado en USD y una etiqueta clara de variación o tendencia.

### 2.1 Tarifas Oficiales Documentadas por Railway

De acuerdo con la documentación oficial vigente de Railway (`docs.railway.com/pricing/plans` y `docs.railway.com/storage-buckets/billing`), el cobro opera por uso real medido por minuto/GB-mes bajo las siguientes tarifas unitarias:

| Recurso en Railway | Tarifa Oficial Unitaria | Unidad de Facturación | Alcance en Arquitectura ABAQ |
| :--- | :---: | :--- | :--- |
| **Volumen Persistente (Disco MongoDB)** | **$0.15 USD** | por GB-mes | Tamaño físico ocupado en `/data/db` (datos + índices). |
| **Memoria RAM (Servicios / BD)** | **$10.00 USD** | por GB-mes | RAM residente utilizada por el contenedor `MongoDB`. |
| **Cómputo vCPU (Servicios / BD)** | **$20.00 USD** | por vCPU-mes | Promedio de vCPU consumido por `MongoDB`. |
| **Storage Bucket S3 (Almacenamiento)** | **$0.015 USD** | por GB-mes | Total de datos almacenados en el bucket (`storage / (1024^3)`). |
| **Llamadas S3 API y Bucket Egress** | **$0.00 USD** | Ilimitado y gratuito | Peticiones `PutObject`, `GetObject`, `ListObjectsV2` y transferencia del bucket al backend por red interna. |
| **Red Privada Interna (`.railway.internal`)** | **$0.00 USD** | Ilimitado y gratuito | Tráfico Backend $\leftrightarrow$ `mongodb.railway.internal`. |
| **Service Egress (Salida a Internet)** | **$0.05 USD** | por GB transferido | Tráfico saliente del backend Express hacia navegadores (descargas de archivos, ZIP, Excel, constancias). |

*(Nota sobre créditos de plan: En Railway, la suscripción base —Hobby `$5 USD/mes` o Pro `$20 USD/mes`— actúa como crédito mensual aplicable al consumo calculado; cuando el consumo total queda por debajo del crédito del plan, la factura adicional es `$0.00`, pero mostrar el costo bruto calculado permite a la Coordinación anticipar exactamente cuándo se acercan o superan el crédito incluido.)*

### 2.2 Fórmulas de Costo Mensual de Base de Datos (MongoDB)

El cálculo se divide en el costo directo atribuible al peso de los datos (**Costo de Almacenamiento**) y el costo del motor de ejecución (**Costo Operativo de Cómputo y RAM**):

1. **Conversión de almacenamiento físico a Gigabytes binarios ($\text{GiB}$):**
   Mediante el comando interno de MongoDB `db.stats(1)` (`storageSize + indexSize` + margen de journal de WiredTiger medido por el volumen, o `fsUsedSize` cuando el motor lo expone):
   $$S_{\text{DB\_GB}} = \frac{\text{storageSize} + \text{indexSize}}{1024^3}$$
   $$C_{\text{BD\_Disco}} = S_{\text{DB\_GB}} \times 0.15\text{ USD/mes}$$

2. **Componente de Memoria RAM Residente (mediante `serverStatus().mem.resident` en MB):**
   $$R_{\text{DB\_GB}} = \frac{\text{mem.resident\_MB}}{1024}$$
   $$C_{\text{BD\_RAM}} = R_{\text{DB\_GB}} \times 10.00\text{ USD/mes}$$

3. **Componente de vCPU Activo (estimado por métricas del entorno o delta de tiempo CPU de Node/Mongo `process` y tasa base):**
   $$U_{\text{vCPU}} = \text{clamp}\left(\frac{\Delta\text{CPU}_{\text{us}}}{\Delta t_{\text{us}}}, 0, \text{vCPU}_{\text{asignados}}\right)$$
   $$C_{\text{BD\_CPU}} = U_{\text{vCPU}} \times 20.00\text{ USD/mes}$$

4. **Costo Mensual Total Estimado del Servicio de Base de Datos:**
   $$C_{\text{BD\_Total}} = C_{\text{BD\_Disco}} + C_{\text{BD\_RAM}} + C_{\text{BD\_CPU}}$$

   - En el **desglose secundario de la tarjeta** en UI se muestra únicamente en términos simples cuánto corresponde al peso de los registros (`Almacenamiento`) y cuánto al servidor encendido (`Motor de BD`), manteniendo un número principal claro en USD/mes.
   - Si el clúster configurado corresponde a un entorno externo con plan fijo (`MongoDB Atlas`), el sistema detecta `dbHost` y muestra el estimado equivalente bajo las tarifas Railway o la etiqueta del entorno sin confundir al usuario.

### 2.3 Fórmulas de Costo Mensual del Bucket S3 (Almacenamiento de Archivos)

1. **Conversión del peso acumulado de todos los objetos en las 4 carpetas (`reglamentos/`, `adopciones/`, `evidencias/`, `documentos/`):**
   Mediante S3 `ListObjectsV2` (sumando la propiedad `Size` de cada objeto reportado por el bucket, o escaneo de `BUCKET_DIR` cuando el sistema corre en modo `railway_volume` o `local_disk`):
   $$S_{\text{Bucket\_GB}} = \frac{\sum_{i=1}^{N} \text{sizeBytes}_i}{1024^3}$$

2. **Costo mensual de almacenamiento de archivos:**
   - Si `storageMode === 'railway_bucket'`:
     $$C_{\text{Bucket\_Storage}} = S_{\text{Bucket\_GB}} \times 0.015\text{ USD/mes}$$
   - Si `storageMode === 'railway_volume'` (volumen montado directo al backend):
     $$C_{\text{Volume\_Storage}} = S_{\text{Bucket\_GB}} \times 0.15\text{ USD/mes}$$

3. **Costo de Egress por entrega de documentos al navegador (`Service Egress`):**
   Aunque el tráfico **Bucket $\to$ Backend** es gratuito (`$0.00`), cuando Express transmite el archivo hacia el usuario por internet, ese tráfico saliente del contenedor backend se contabiliza a **`$0.05 / GB`**:
   $$C_{\text{Egress\_Mes}} = \left(\frac{\text{bytesDescargadosMes}}{1024^3}\right) \times 0.05\text{ USD}$$
   Por esta razón matemática directa resulta obligatorio bloquear el abuso de descargas repetitivas o ráfagas anormales (§6).

### 2.4 Fórmulas del Diferencial de Crecimiento y Aceleración ($\Delta$)

Para indicar en la tarjeta de costo si el almacenamiento y gasto mensual se está **acelerando**, **desacelerando**, **manteniendo estable** o **reduciendo**, se utilizan las marcas temporales `createdAt` (de documentos en MongoDB) y `LastModified` (de objetos S3 en Bucket) más el historial ligero en caché:

1. **Velocidad de crecimiento de los últimos 30 días ($v_1$) y del periodo previo 30–60 días ($v_0$):**
   $$v_1 = \text{bytes agregados en } [t_{\text{hoy}} - 30\text{d},\ t_{\text{hoy}}]$$
   $$v_0 = \text{bytes agregados en } [t_{\text{hoy}} - 60\text{d},\ t_{\text{hoy}} - 30\text{d})$$

2. **Aceleración neta de crecimiento ($a$) y diferencial de costo proyectado ($\Delta C$):**
   $$a = v_1 - v_0$$
   $$\Delta C_{\text{mensual}} = \left(\frac{v_1}{1024^3}\right) \times r_{\text{GB}} \quad (\text{donde } r_{\text{GB}} = 0.15 \text{ para BD o } 0.015 \text{ para Bucket})$$

3. **Variación porcentual de aceleración (con protección contra división por cero):**
   $$\%_{\text{acel}} = \begin{cases} \frac{v_1 - v_0}{v_0} \times 100 & \text{si } v_0 > 0 \\ +100\% & \text{si } v_0 = 0 \land v_1 > 0 \\ 0\% & \text{si } v_0 = 0 \land v_1 = 0 \end{cases}$$

4. **Diferencial respecto a la última lectura en caché/snapshot ($\Delta_{\text{snapshot}}$):**
   $$\Delta_{\text{bytes}} = S_{\text{actual}} - S_{\text{lectura\_previa}}$$

5. **Clasificación semántica amigable mostrada al usuario final (Badge de Tendencia):**
   - `v_1 === 0 && v_0 === 0` o $|v_1 - v_0| < 1\text{ MB}$ $\rightarrow$ **Sin cambios significativos / Estable** (`neutral`).
   - `a > 0` $\rightarrow$ **Creciendo más rápido** (`+X MB este mes · acelerando`).
   - `a < 0` y `v_1 > 0` $\rightarrow$ **Crecimiento moderándose** (`+X MB este mes · desacelerando`).
   - $\Delta_{\text{bytes}} < 0$ (tras corte/deshidratación) $\rightarrow$ **Espacio liberado** (`-X MB respecto al corte anterior`).

### 2.5 Ejemplo Numérico de Referencia para ABAQ

Supóngase la plataforma operando con:
- **MongoDB**: `120 MB` (`0.117 GiB`) en disco, `180 MB` (`0.176 GiB`) RAM residente promedio, `0.03` vCPU promedio:
  - $C_{\text{BD\_Disco}} = 0.117 \times 0.15 = \$0.018\text{ USD/mes}$
  - $C_{\text{BD\_RAM}} = 0.176 \times 10.00 = \$1.760\text{ USD/mes}$
  - $C_{\text{BD\_CPU}} = 0.03 \times 20.00 = \$0.600\text{ USD/mes}$
  - **$C_{\text{BD\_Total}} \approx \$2.38\text{ USD/mes}$**
- **Bucket S3**: `850 MB` (`0.830 GiB`) en archivos PDF distribuidos en las 4 carpetas:
  - $C_{\text{Bucket\_Storage}} = 0.830 \times 0.015 = \$0.012\text{ USD/mes}$
  - Si se descarga abusivamente 1,000 veces un comprobante de `5 MB` ($5\text{ GB}$ mensuales de Service Egress sin bloqueo): $5 \times 0.05 = \$0.25\text{ USD}$ extra que escalarían linealmente con ataques de ancho de banda; con el bloqueo de 3 descargas / 8 h y Circuit Breaker, el costo de egresión se mantiene marginal.

---

## 3. Diseño de los Dos Contenedores Gemelos en el Encabezado de Respaldos

En `frontend/src/app/components/backup/backup.component.html`, dentro de `<section class="admin-hero">`, se sustituye el bloque único actual de 3 tarjetas por **dos contenedores hermanos** que **reutilizan íntegramente** las clases existentes `.hero-stats-grid` y `.hero-stat-card`, garantizando consistencia de estilos, desenfoque (`backdrop-filter: blur(10px)`), accesibilidad y apilamiento responsivo sin duplicar componentes.

### 3.1 Contenedor 1: Base de datos (Información del sistema)
1. **Tarjeta 1 — Conexión (`stat-db`)**: Conectada / Desconectada y latencia en ms (interacción click existente para probar conexión).
2. **Tarjeta 2 — Secciones activas (`stat-collections`)**: Relación `activeCollections / totalCollections` (*Módulos en funcionamiento*).
3. **Tarjeta 3 — Registros y peso (`stat-documents`)**: Total de documentos almacenados + peso físico formateado (MB / GB).
4. **Tarjeta 4 — Costo mensual estimado (`stat-cost-db`)**: Importe mensual estimado en USD + insignia compacta de crecimiento y diferencial (`+X MB este mes · Acelerando` / `Desacelerando` / `Estable`).

### 3.2 Contenedor 2: Almacenamiento de archivos (Documentos guardados — Bucket S3)
1. **Tarjeta 1 — Estado del almacén (`stat-bucket`)**: Conectado / Desconectado e indicación simple de ubicación (*Almacén en la nube* o *Almacén local*).
2. **Tarjeta 2 — Carpetas activas (`stat-folders`)**: Relación de carpetas activas (`4 / 4`: `reglamentos`, `adopciones`, `evidencias`, `documentos`).
3. **Tarjeta 3 — Archivos y peso (`stat-files`)**: Total de archivos guardados + peso total acumulado formateado (MB / GB).
4. **Tarjeta 4 — Costo mensual estimado (`stat-cost-bucket`)**: Importe mensual estimado en USD + insignia compacta de crecimiento y diferencial (`+X MB este mes · Acelerando` / `Desacelerando` / `Estable`).

### 3.3 Eficiencia de Conexiones y Hint de Fecha Única
- **Cero refresco automático o *polling*:** La consulta de métricas se dispara únicamente al abrir la vista (`/admin/backups`) o cuando la administradora pulsa el botón manual de verificación.
- **Caché en servidor con TTL de 5 minutos:** Evita recorrer repetidamente las 14 colecciones o invocar `ListObjectsV2` contra S3 ante recargas rápidas de página o cambios de pestaña.
- **Cooldown de botón de refresco:** Mínimo `60 segundos` entre consultas forzadas manuales (`?refresh=true`).
- **Hint discreto con únicamente la fecha:** Debajo o en la esquina derecha de los contenedores de métricas, una leyenda sutil de baja prominencia visual muestra **solamente la fecha**:
  - `Última actualización: 15/11/2026` *(sin hora exacta, sin marcas Unix ni texto técnico adicional)*.

---

## 4. Respaldo Tri-Modal, Manifiesto `v3.0.0`, Validación Pre-Descarga y Rollback Dual Zero-Overwrite

### 4.1 Lenguaje Simple en las 3 Opciones de Descarga (Cero Mención a "PDF")

En la tarjeta de descarga `.zip` del componente de respaldos (`Descargar Copias de la Información`), la administradora elige de manera clara entre **3 opciones mutuamente excluyentes**, redactadas en lenguaje simple pensado para usuario final y **omitiendo por completo la palabra "PDF"**:

| Código Interno (`scope`) | Etiqueta en Interfaz (Usuario Final) | Subtítulo Descriptivo en Interfaz | Contenido del Paquete `.zip` |
| :---: | :--- | :--- | :--- |
| `full` *(por defecto)* | **Respaldo completo (Base de datos y archivos)** | Guarda toda la información del sistema junto con los documentos guardados de los participantes. | `manifest.json` + `collections/*.json` + `bucket/*/*` |
| `db_only` | **Solo base de datos (Registros del sistema)** | Guarda únicamente las tablas de registros (cuentas, asistencias, participaciones e historial). | `manifest.json` + `collections/*.json` |
| `bucket_only` | **Solo archivos (Documentos guardados)** | Guarda únicamente los archivos y documentos subidos por los participantes y adopciones. | `manifest.json` + `bucket/reglamentos/*`, `adopciones/*`, `evidencias/*`, `documentos/*` |

*(Los cortes históricos de deshidratación siguen operando como `scope: 'corte'` e integran soporte futuro opcional para adjuntar archivos del bucket vinculados a los expedientes deshidratados).*

### 4.2 Estructura del Nuevo `manifest.json` (`version: "3.0.0"`)

El manifiesto único unifica todos los flujos (respaldo completo, solo base de datos, solo archivos y corte histórico) declarando el alcance exacto y checksums SHA-256 por colección y por archivo del bucket:

```json
{
  "version": "3.0.0",
  "system": "ABAQ Querétaro",
  "operation": "rollback",
  "operationType": "backup_full",
  "backupScope": "full",
  "operationLabel": "Respaldo completo (Base de datos y archivos)",
  "generatedAt": "2026-11-15T12:00:00.000Z",
  "generatedBy": "admin@abaq.org",
  "totalCollections": 13,
  "totalDocuments": 1240,
  "collections": {
    "students": {
      "name": "Estudiantes",
      "collection": "students",
      "documentCount": 145,
      "sizeBytes": 182400,
      "sha256": "...",
      "file": "collections/students.json"
    }
  },
  "bucket": {
    "included": true,
    "storageMode": "railway_bucket",
    "totalFiles": 82,
    "totalBytes": 42918400,
    "folders": {
      "reglamentos": { "fileCount": 30, "totalBytes": 15200000 },
      "adopciones": { "fileCount": 12, "totalBytes": 8400000 },
      "evidencias": { "fileCount": 25, "totalBytes": 12300000 },
      "documentos": { "fileCount": 15, "totalBytes": 7018400 }
    },
    "files": [
      {
        "key": "reglamentos/reglamento_student_abc_17316.pdf",
        "folder": "reglamentos",
        "sizeBytes": 512040,
        "sha256": "e3b0c442...",
        "zipPath": "bucket/reglamentos/reglamento_student_abc_17316.pdf"
      }
    ]
  },
  "integrityReport": {
    "checkedAt": "2026-11-15T12:00:00.000Z",
    "healthy": true,
    "databaseErrors": 0,
    "bucketErrors": 0,
    "brokenReferencesCount": 0
  }
}
```

### 4.3 Validación Previa Obligatoria Antes de Permitir Descargas (`validateBackupReadiness`)

Antes de iniciar el *streaming* del `.zip`, el backend ejecuta una rutina de auditoría en tiempo real (`validateBackupReadiness(scope)`). Si el sistema detecta corrupción o anomalías críticas, **bloquea la descarga antes de emitir un paquete dañado**, devuelve un reporte estructurado (`HTTP 422 Unprocessable Entity`) con lenguaje claro para el administrador e impide distribuir un respaldo inutilizable:

1. **Integridad de Registros en Base de Datos (cuando `scope` incluye BD):**
   - Cada documento de las colecciones descubiertas por `getModelRegistry()` debe tener un `_id` válido, poder serializarse sin ciclos ni bytes inválidos UTF-8 en JSON, y cumplir el invariante Zero-Null Folio (`folio` no nulo ni vacío en `students`, `volunteers` y `activities`).
   - Verificación de ausencia de fallos en `authId` huérfanos críticos respecto a `users`.
2. **Integridad Física de Archivos del Almacén (cuando `scope` incluye archivos):**
   - Cada objeto recuperado del Bucket S3 o volumen debe tener `sizeBytes > 0`, cabecera binaria válida (`%PDF-`) para documentos documentales y coincidencia de hash SHA-256 calculado en streaming durante la lectura.
   - Rechazo preventivo si un objeto referenciado en la BD devuelve fallo de lectura física (`corrupt_stream`) o tamaño `0 bytes`.
3. **Integridad de Referencias Cruzadas (BD $\leftrightarrow$ Archivos del Almacén):**
   - Validación cruzada de que todas las llaves de archivo almacenadas en BD apunten a un objeto existente y legible en el bucket (tolerando únicamente expedientes heredados legados sin archivo adjunto declarado, marcando claramente cualquier referencia rota real):
     - `Student` / `Volunteer`: `signedRulesDocument.storedName` (`reglamentos/...`), `cloudUrls.ine` y `cloudUrls.cv` (`documentos/...`).
     - `Adoption`: `signedFormatDocument.storedName`, `ineDocument.storedName`, `comprobanteDomicilioDocument.storedName` (`adopciones/...`).
     - `Accreditation`: `evidenceUrl` cuando almacena un `storedName` interno (`evidencias/...`).
4. **Regla de Bloqueo vs. Descarga Segura:**
   - Si falla serialización JSON, hay archivos de `0 bytes`/cabecera dañada o existen referencias huérfanas con clave física ausente $\rightarrow$ **Descarga bloqueada** y despliegue de detalle claro de qué registro o archivo debe repararse antes de respaldar.

### 4.4 Restauración / Rollback Dual con Política Estricta de No-Sobrescritura (`Zero-Overwrite`)

Al cargar cualquier `.zip` en la zona de carga unificada (`unifiedRestore` / `processRollback`):

1. **Detección automática del paquete:** Lee `manifest.json` (`v2.2.0` o `v3.0.0`) e identifica `backupScope` (`full`, `db_only`, `bucket_only` o `corte`), manteniendo **100 % retrocompatibilidad** con respaldos anteriores `v2.2.0`.
2. **Reutilización estricta del modal existente de vista previa (`showRollbackReviewModal` / `showPackageReviewModal`):**
   - No se crea un modal nuevo; se amplía el modal actual para mostrar, cuando el paquete contiene archivos, un bloque adicional en la tabla de escritorio y tarjetas móviles con el desglose de las 4 carpetas del almacén (`reglamentos`, `adopciones`, `evidencias`, `documentos`) y sus métricas: **En Respaldo / Ya existen (se respetan) / Nuevos a restaurar**.
3. **Protección estricta anti-sobrescritura (*Zero-Overwrite*):**
   - **En Base de Datos:** Se ejecuta exclusivamente inserción condicional mediante `updateOne({ _id: doc._id }, { $setOnInsert: sanitizedDoc }, { upsert: true })` (y verificación de llaves únicas como `email` o `interactionFolio`). Ningún documento existente en MongoDB es borrado ni sobrescrito.
   - **En Bucket S3 / Almacén de Archivos:** Antes de subir cualquier archivo extraído de `bucket/<folder>/<name>`, el servidor verifica si esa clave ya existe en el bucket actual (consultando el índice en memoria construido con `ListObjectsV2` o `HeadObject`). **Si el archivo ya existe, se omite silenciosamente y jamás se sobrescribe.** Únicamente se restauran archivos faltantes tras validar su SHA-256 contra `manifest.json` y su firma binaria.

### 4.5 Optimización de Almacenamiento, Memoria RAM y Procesador (Compresión Híbrida, Streaming y Disco Temporal `/tmp`)

Para incorporar archivos del Bucket S3 dentro del `.zip` sin disparar los costos de CPU/RAM de Railway ni provocar cierres por falta de memoria (*Out-Of-Memory* / OOM), el diseño separa explícitamente cómo se **guardan diariamente** los archivos en el bucket de cómo se **empaquetan** únicamente al respaldar o restaurar:

1. **Almacenamiento diario en Bucket S3 sin zipeo permanente (`storageMode: railway_bucket`):**
   - Los documentos e imágenes escaneadas ya poseen compresión interna propia (`FlateDecode` / JPEG), por lo que comprimirlos de forma permanente en `.zip` apenas reduce entre **1 % y 3 %** de espacio en disco (`~$0.0003 USD/mes` por cada GB a `$0.015/GB-mes`).
   - En cambio, mantenerlos zipeados obligaría al backend a descargar, descomprimir en RAM/CPU y servir cada consulta diaria, elevando el consumo de **CPU (`$20/vCPU-mes`)** y **RAM (`$10/GB-mes`)**. Por ello, en el Bucket S3 se almacenan intactos listos para entrega directa y en los respaldos se empaquetan bajo demanda.

2. **Compresión Híbrida en `archiver` (`streamJsonZipBackup` en `backend/services/backup.service.js`):**
   Hoy la línea `279` fija `zlib: { level: 9 }` de forma uniforme. Aplicar nivel 9 sobre cientos de archivos binarios ya comprimidos satura el procesador al 90 %–100 % sin reducir peso útil. La **Compresión Híbrida** configura cada tipo de contenido dentro del mismo `.zip` según su naturaleza:
   - **Registros de Base de Datos (`collections/*.json` y `manifest.json`) $\rightarrow$ `zlib: { level: 6 }`:** El texto plano JSON es altamente repetitivo; con nivel 6 se comprime ~**85 %** de su tamaño original usando ~**60 % menos CPU** que el nivel 9 y una fracción mínima de tiempo.
   - **Archivos del Bucket S3 (`bucket/*/*`) $\rightarrow$ `store: true` (`ZIP_STORE`, nivel 0 — guardar sin recomprimir):** Se insertan tal cual dentro del contenedor `.zip` calculando su firma CRC32 al vuelo, sin desperdiciar ciclos de CPU intentando re-exprimir archivos ya comprimidos.

3. **Streaming Secuencial 1 a 1 en descarga (`ReadableStream` en bloques de `64 KB`):**
   - Cada objeto S3 se solicita y canaliza como flujo (`stream`) directamente hacia `archiver` y la respuesta HTTP uno por uno, sin acumular todos los archivos simultáneamente en `Buffer` en memoria.
   - Mantiene un **techo extra constante de RAM de `+15 MB a +25 MB`** durante toda la descarga (`0 MB` persistentes en disco), independientemente de que el paquete final pese `50 MB` o `500 MB`.

4. **Ingesta optimizada en Rollback (`multer.diskStorage` en `os.tmpdir()` + Extracción Selectiva Zero-Overwrite):**
   - Sustituye `multer.memoryStorage()` en `backend/routes/backup.route.js:27` (que hoy retiene hasta `100 MB` íntegros en RAM y los vuelve a duplicar al abrir `new AdmZip(zipBuffer)` en `backup.service.js:487`) por almacenamiento temporal efímero en `os.tmpdir()` (`/tmp`) con eliminación garantizada en bloque `finally { fs.unlink(...) }`.
   - Gracias a la política *Zero-Overwrite*, antes de leer entradas del `.zip` el backend consulta el índice de claves existentes en S3 (`ListObjectsV2`); **todo archivo que ya existe en la nube ni siquiera se descomprime en RAM**, extrayendo únicamente uno por uno los faltantes (máximo 2 cargas paralelas hacia S3).

5. **Impacto estimado en el contenedor Railway (escenario de referencia: `200 MB` de archivos en Bucket S3):**

| Métrica en el Contenedor Backend (Node.js) | Implementación Actual (`level: 9` + `memoryStorage`) | Diseño Optimizado (`level: 6` + `store: true` + Streaming + `/tmp`) |
| :--- | :--- | :--- |
| **Pico de RAM extra al descargar `.zip`** | `+200 MB a +350 MB` *(riesgo alto de OOM)* | **`+15 MB a +25 MB`** *(constante en bloques de `64 KB`)* |
| **Pico de RAM extra al subir Rollback `.zip`** | `+220 MB a +400 MB` *(doble copia en RAM)* | **`+20 MB a +35 MB`** *(solo archivo temporal + máx. 2 en vuelo)* |
| **Uso de CPU al empaquetar `.zip`** | `85 % – 100 %` de vCPU durante `25 – 40 s` | **`3 % – 8 %`** de vCPU durante `4 – 8 s` |
| **Red interna Bucket S3 $\leftrightarrow$ Backend** | `$0.00 USD` *(gratis en Railway)* | **`$0.00 USD`** *(gratis en Railway)* |
| **Impacto en facturación Cómputo Railway** | Eleva picos facturables de RAM y CPU | **Casi `$0.00 USD` adicionales** en operación normal |

---


## 5. Blindaje Universal Contra Abuso de Descargas de Documentos (`downloadGuard.js` + `localStorage` 8h + Circuit Breaker)

### 5.1 Brecha Detectada en el Sistema Actual

En la revisión del código fuente se identificó una protección incompleta y asimétrica:

1. En [`backend/controllers/bucket.controller.js`](file:///Users/riosisraelg/dev/abaq/backend/controllers/bucket.controller.js#L21-L24), el límite de 3 descargas / 8 horas (`documentDownloadRateMap`) y el anti-spam de clics rápidos (`< 2 s`) solo protegen `downloadOfficialDocument` (`GET /api/bucket/documents/:fileName`).
2. Quedan **sin este límite** las rutas `POST /api/bucket/rules-download-token`, `GET /api/bucket/download-signed-rules/:hashToken`, los endpoints de cartas/constancias de pláticas (`talk.controller.js`: `/letter/docx`, `/letter/pdf`, `/certificate/:hashToken`) y las descargas de respaldos en `backup.controller.js`.
3. En [`frontend/src/app/services/bucket.service.ts`](file:///Users/riosisraelg/dev/abaq/frontend/src/app/services/bucket.service.ts#L65-L66), el cooldown de cliente es de solo **45 segundos en memoria RAM** (`COOLDOWN_MS = 45 * 1000`), por lo que recargar la pestaña (`F5`) borra el bloqueo por completo. Además, `downloadSignedRules()` no pasa por el límite ni la caché.

### 5.2 Reglas Unificadas Anti-Egress y Protección ante Comportamiento Anormal

Para evitar que ráfagas automatizadas o usuarios insistentes disparen cargos innecesarios de **Service Egress (`$0.05/GB`)** desde Express hacia internet, se diseña el middleware centralizado **`downloadGuard.js`** acoplado con persistencia en **`localStorage`**:

1. **Capa 1 — Anti-Clicks Rápidos (Debounce de 2 segundos):**
   - Todo doble clic o ráfaga inferior a `2,000 ms` por combinación usuario/IP + archivo es ignorada en backend (`HTTP 204` o `429` según endpoint) y bloqueada en UI deshabilitando el botón mientras la descarga transita.
2. **Capa 2 — Límite de 3 Descargas por Archivo y Bloqueo Estricto de 8 Horas (Backend + `localStorage`):**
   - Al alcanzar **3 descargas** del mismo documento, tanto el backend como el navegador (persistiendo la marca `lockedUntil = now + 8h` en `localStorage` por usuario y archivo) **bloquean ese botón durante 8 horas completas** (incluso si el usuario recarga la página o cambia de vista).
   - **Mensaje claro y amigable en interfaz:** El botón deshabilitado informa al usuario que alcanzó el límite temporal de descargas por 8 horas y que, si necesita el documento con urgencia, **debe solicitarlo directamente a un administrador (Coordinación)** para evitar abusos y cargos de red en la nube.
3. **Capa 3 — Detector de Comportamiento Anormal (Circuit Breaker Global de 8 Horas):**
   - Adicionalmente al conteo por archivo individual, `downloadGuard.js` vigila la **actividad agregada por usuario autenticado e IP** en todas las acciones de descarga de documentos (expedientes, comprobantes, adopciones, reglamentos firmados, cartas de pláticas, constancias y archivos de respaldo):
     - **Umbral de ráfaga anormal:** Intentar descargar **más de 8 documentos distintos en menos de 60 segundos**, o acumular **5 o más rechazos por rate-limit** dentro de un lapso de 10 minutos.
     - **Acción inmediata:** Dispara el *Circuit Breaker* global para ese usuario/IP, **bloqueando TODAS las acciones de descarga de documentos durante 8 horas** (`HTTP 429 Too Many Requests` con `code: "ABNORMAL_DOWNLOAD_BEHAVIOR"`), registrando un evento de auditoría de seguridad (OWASP `A09`) y mostrando en la interfaz que la cuenta quedó temporalmente pausada para descargas por seguridad y debe pedir apoyo a Coordinación.
   - *(Criterio conservador explícito solicitado por el propietario del proyecto: es preferible que ante un falso positivo de comportamiento rápido el usuario espere 8 horas o solicite el documento a Coordinación, antes que exponer a la ONG a cobros por tráfico saliente abusivo).*

---

## 6. Auditoría Integral de Seguridad Web conforme a la Metodología del Prof. Ricardo Monroy (OWASP WSTG & OWASP Top 10:2021)

La auditoría evalúa **tanto el código actual completo del proyecto** (`backend/` y `frontend/`) **como la nueva propuesta de Estadísticas Duales, Respaldo con Bucket S3 y Guard de Descargas**, siguiendo exactamente las **6 fases**, la matriz **OWASP Top 10 (2021)** y la **plantilla oficial de hallazgos** establecidas en el documento del profesor (**`Metodología de Auditoría de Seguridad Web - Ejecución y Reporte.pdf`**).

> **Modalidad de Auditoría Aplicada:** **Caja Blanca** (acceso completo al código fuente, rutas, controladores, modelos Mongoose, servicios S3/Backup, configuración de despliegue e infraestructura).

### 6.1 Fase 1 — Reconocimiento y Mapeo de Superficie de Ataque

#### A. Tecnologías Identificadas en el Código Real
- **Frontend:** Angular v22 (`@angular/core ^22.0.0`, Standalone Components), RxJS `~7.8.0`, TypeScript `~6.0.3`, Bootstrap `^5.3.3`, Chart.js `^4.4.3`, servido por Express 5 en Node 22 Alpine.
- **Backend API:** Node.js `^22.22.3`, Express `^4.19.2`, Mongoose `^8.4.4`, Driver MongoDB `^6.7.0`, JWT (`jsonwebtoken ^9.0.2`), Hashing (`bcryptjs ^2.4.3`, costo 12), `helmet ^7.1.0`, `cors ^2.8.5` (reflexivo con `credentials: true` en `app.js:48-55`), `multer ^1.4.5-lts.1`, `adm-zip ^0.6.1`, `archiver ^8.0.0`, `exceljs ^4.4.0`, `express-rate-limit ^8.7.4`, `express-validator ^7.1.0`.
- **Persistencia y Almacenamiento:** MongoDB 7.0 (`mongodb.railway.internal` + fallback Atlas) y Railway Storage Bucket S3 (AWS Signature V4 en `railwayBucket.service.js`).
- **Perímetro y Despliegue:** AWS Route 53 + OpenTofu + Railway en `NODE_ENV=development` (con `TURNSTILE_DISABLED` configurable para pruebas académicas).

#### B. Flujos de Autenticación y Roles
- **Roles definidos en `user.model.js`:** `student`, `volunteer`, `admin`.
- **Estados de cuenta (`accountStatus`):** `pending`, `active`, `inactive`, `rejected`.
- **Flujo JWT:** Bearer Token en cabecera `Authorization` (y en `?token=` únicamente permitido por `allowQueryToken` dentro de `backup.route.js:35-40`).

#### C. Inventario de Endpoints Críticos (Muestra de Superficie Auditada en Fase 1)

| Endpoint / Prefijo | Métodos | Middleware Actual Observado | Rol Requerido Esperado | Hallazgo / Notas de Auditoría |
| :--- | :--- | :--- | :--- | :--- |
| `/auth/login`, `/auth/signup*` | `POST` | `requireTurnstile(...)` | Anónimo | `auth.controller.js:118` imprime el documento `user` con `+passwordHash` en logs. |
| `/auth/register` | `POST` | **Ninguno** (`auth.route.js:17`) | Deshabilitado / Turnstile | Endpoint legado vivo sin Turnstile ni onboarding ligado. |
| `/auth/activate-volunteer` | `POST` | **Ninguno** (`auth.route.js:30`) | Token válido | Consulta `{ activationToken: token }` directo desde `req.body` (riesgo NoSQL operator). |
| `/auth/expediente-status` | `GET` | **Ninguno** (`auth.route.js:16`) | Limitado / Propietario | Sin auth ni rate-limit; devuelve PII y `cartaAceptacion` por `?folio=`. |
| `/student/` y `/student/:id` | `GET`, `POST`, `PATCH`, `DELETE` | Solo `protect` (`student.route.js:36-50`) | `admin` (o propietario solo lectura) | **CRÍTICO/ALTO (`H-01`)**: Falta `restrictToAdmin` y `requireActiveAccount`! |
| `/volunteer/:id` y `/volunteer/auth/:authId` | `GET` | Solo `protect` (`volunteer.route.js:54,71`) | `admin` o propietario | **ALTO (`H-01`)**: Cualquier autenticado puede leer el expediente ajeno. |
| `/activity/*` | `POST`, `GET`, `PATCH`, `DELETE` | `protect` + `requireActiveAccount` (`activity.route.js`) | `admin` para CRUD y validación | **ALTO (`H-02`)**: Cualquier usuario `active` puede crear/borrar actividades o validar horas. |
| `/adoption`, `/campaign`, `/identification`, `/talk` (rutas autenticadas) | `GET`, `POST`, `PATCH`, `DELETE` | `protect` + `requireActiveAccount` (sin `restrictTo("admin")`) | `admin` para gestión/borrado | **ALTO (`H-02`)**: Cualquier `student`/`volunteer` activo puede borrar expedientes o aprobar placas (`COMPLETED` crea acreditación). |
| `/api/bucket/documents/:fileName` | `GET` | **Ninguno** (`bucket.route.js:23`) | Anónimo solo plantillas; Auth/Owner para expedientes | **ALTO (`H-01/H-06`)**: Sirve archivos privados (`documentos/`, `adopciones/`, `evidencias/`) sin JWT si se conoce/enumera el nombre. |
| `/api/bucket/rules-download-token`, `/download-signed-rules/:hashToken` | `POST`, `GET` | `protect` | Propietario o `admin` | Sin cooldown de 8 h / Circuit Breaker (`H-06`). |
| `/talk/public/:id/letter/*`, `/certificate/talk/:hashToken` | `GET` | `talkCertificateLimiter` (60/15min IP) | Público con tasa controlada | Sin bloqueo de 8 h por abuso ni Circuit Breaker (`H-06`). |
| `/backup/*` (incl. futuros `scope` BD+S3 y métricas) | `GET`, `POST` | `allowQueryToken`, `protect`, `restrictTo("admin")` | Estrictamente `admin` | RBAC sólido (`restrictTo("admin")`), pero requiere hardening ZIP/S3 (`H-07`, `H-08`, `H-09`). |

---

### 6.2 Fase 2 — Pruebas por Categoría OWASP Top 10 (2021) y Checklist WSTG

| Categoría OWASP Top 10 (2021) | Estado en Proyecto Actual | Estado en Nueva Propuesta (BD + S3 + Guard) | Controles / Hallazgos Clave |
| :--- | :---: | :---: | :--- |
| **A01: Broken Access Control** | 🔴 **Crítico / Alto** | 🟢 Mitigado con diseño | En código actual: `student.route.js`, `volunteer.route.js`, `activity.route.js`, `adoption/talk/campaign/identification.route.js` y `bucket/documents/:fileName` presentan fallos de autorización vertical (BFLA) y horizontal (IDOR/BOLA). Propuesta exige RBAC estricto + ownership en BD y S3. |
| **A02: Cryptographic Failures** | 🟡 **Medio** | 🟢 Fuerte | Passwords con `bcryptjs` costo 12 (`user.model.js:33`), tokens de constancias con HMAC-SHA256 + `timingSafeEqual` y AES-256-GCM. Hallazgo: log en texto de documento usuario tras `.select("+passwordHash")` (`H-04`) y corrección obligatoria de `canonicalQuery` en AWS SigV4 (`railwayBucket.service.js:113`) para S3 `ListObjectsV2` (`H-08`). |
| **A03: Injection (NoSQL / Path Traversal)** | 🔴 **Alto** | 🟢 Blindado con sanitización | Ausencia de `express-mongo-sanitize` global y consulta directa de `req.body.token` en `activateVolunteer` (`H-03`). En ZIP/S3 de respaldo: validación obligatoria anti **Zip-Slip** (`CWE-22`) y sanitización de claves S3 antes de subir (`H-07`). |
| **A04: Insecure Design** | 🟠 **Alto** | 🟢 Blindado | Sin límite de egress de 8h ni Circuit Breaker en reglas firmadas, cartas de pláticas ni respaldos (`H-06`); `bucket.service.js` genera PDFs sintéticos ante rutas no encontradas (`createFallbackPdfBuffer`); propuesta añade `downloadGuard.js`, `validateBackupReadiness` (`H-09`) y Zero-Overwrite real en S3. |
| **A05: Security Misconfiguration** | 🟡 **Medio** | 🟢 Controlado | Entorno sandbox deliberado `NODE_ENV=development` y CORS reflexivo (`app.js:48-55`) por RNF-DEP-01/02; además `express.json()` carece de `limit`, `req.query.token` en `backup.route.js` expone JWT en logs HTTP/browser history, y mensajes de error exponen detalles sin filtrar en producción (`H-05`). |
| **A06: Vulnerable & Outdated Components** | 🟢 **Monitoreo** | 🟢 Estándar | Pila moderna (`Node 22`, `Express 4.19.2`, `Mongoose 8.4.4`, `adm-zip 0.6.1`, `archiver 8.0.0`), pero requiere ejecución periódica de `npm audit` en `backend/` y `frontend/` antes de producción (`WSTG-SESS-08`). |
| **A07: Identification & Authentication Failures** | 🟡 **Medio** | 🟢 Controlado | Sin rate-limiter dedicado en `/auth/login` cuando `TURNSTILE_DISABLED=true` en entorno académico, y endpoint público `GET /auth/expediente-status` sin throttling ni prevención de enumeración (`H-04`). |
| **A08: Software & Data Integrity Failures** | 🟡 **Medio** | 🟢 Fuerte | Los paquetes de respaldo validan SHA-256 en `manifest.json` y magic bytes ZIP/PDF, pero el rollback de S3 requiere validar **magic bytes del archivo extraído dentro del ZIP**, límites anti **Zip-Bomb** (`CWE-409`) y protección contra Mass Assignment en campos restaurados (`H-07`). |
| **A09: Security Logging & Monitoring Failures** | 🟡 **Medio** | 🟢 Ampliado | `DehydrationAuditLog` registra cortes/rehidrataciones, pero faltan eventos de auditoría ante intentos bloqueados por el Circuit Breaker anti-abuso de 8h, violaciones de acceso `403`, e inconsistencias detectadas en `validateBackupReadiness`, además de eliminar logs con `passwordHash` (`H-04`). |
| **A10: Server-Side Request Forgery (SSRF)** | 🟢 **Bajo** | 🟢 Bajo | No se procesan URLs externas arbitrarias provistas por usuarios en el backend (Turnstile apunta a dominio fijo `challenges.cloudflare.com`, Resend a `api.resend.com`, Bucket S3 a `endpoint` de `.env`). Solo vigilar `endpoint` en variables de entorno. |

---

### 6.3 Fase 3, 4 y 5 — Clasificación de Riesgo y Fichas Oficiales de Hallazgos (`H-01` a `H-09`)

Siguiendo la fórmula de la metodología ($\text{Riesgo} = \text{Impacto} \times \text{Probabilidad de explotación}$) y la **plantilla exacta de fichas del informe del profesor**:

#### H-01 — Control de Acceso Roto (BFLA e IDOR) en Endpoints de `/student`, `/volunteer` y Descarga de Archivos en `/api/bucket/documents`
- **Severidad:** Crítico (Impacto: confidencialidad e integridad de todo el padrón de datos personales CURP, INE, CV, domicilio y horas acreditadas; Probabilidad: alta, basta cualquier cuenta autenticada en estado `pending` o `active` para estudiantes/voluntarios, o petición directa anónima para documentos guardados).
- **Ubicación:** [`backend/routes/student.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/student.route.js#L36-L50), [`backend/routes/volunteer.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/volunteer.route.js#L54-L71), [`backend/routes/bucket.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/bucket.route.js#L23-L24), [`backend/controllers/bucket.controller.js`](file:///Users/riosisraelg/dev/abaq/backend/controllers/bucket.controller.js#L388-L452).
- **Descripción:** En `student.route.js`, después de `router.use(protect)`, las rutas `GET /student/`, `POST /student/new`, `GET /student/auth/:authId`, `GET /student/:id`, `PATCH /student/:id` y `DELETE /student/:id` carecen de `restrictToAdmin` / `requireActiveAccount` y el controlador `factory.getOne`/`updateStudent`/`deleteStudent` no verifica propiedad del recurso (`_id === req.user.linkedDoc._id`). De forma similar, `GET /volunteer/:id` y `GET /volunteer/auth/:authId` solo aplican `protect`. Adicionalmente, `GET /api/bucket/documents/:fileName` carece de `protect` y busca en todos los prefijos privados del bucket (`evidencias/`, `adopciones/`, `reglamentos/`, `documentos/`).
- **Evidencia / PoC:** Un usuario con sesión JWT recién creada (`role: "student"`, `accountStatus: "pending"`) envía `GET /student/` o `PATCH /student/<otro_id>` con `{"horasAcreditadas": 480, "accountStatus": "active"}` y el servidor procesa la actualización completa. Asimismo, una petición anónima a `GET /api/bucket/documents/<storedName>` descarga comprobantes o documentos almacenados en `BUCKET_DIR`/S3 sin token.
- **Impacto:** Exposición masiva de PII (CURP, teléfonos, correos, identificaciones oficiales, comprobantes de domicilio), manipulación no autorizada de horas de servicio social hacia 480 h y borrado de expedientes de terceros.
- **Remediación:**
  1. Aplicar `restrictToAdmin` en `GET /student/`, `POST /student/new`, `PATCH /student/:id`, `DELETE /student/:id`.
  2. Validar propiedad (`req.user.role === 'admin'` o `doc._id === req.user.linkedDoc._id` / `doc.authId === req.user._id`) en `getStudent`, `getStudentByAuthId`, `getVolunteer` y `getVolunteerByAuthId`.
  3. Separar estrictamente el endpoint público **solo por lista blanca** para plantillas oficiales (`reglamento-voluntarios-abaq.pdf`, `formato-adopcion-abaq.pdf` en `assets/documents/`) del endpoint autenticado y verificado por propiedad para documentos de expedientes en el Bucket S3.
- **Referencias:** OWASP A01:2021, WSTG-ATHZ-02, WSTG-ATHZ-04, CWE-862, CWE-639.

---

#### H-02 — Escalamiento de Funciones Privilegiadas (BFLA) en `/activity`, `/adoption`, `/campaign`, `/identification` y `/talk`
- **Severidad:** Alto (Impacto: modificación de participaciones, borrado de registros comunitarios y auto-acreditación de horas; Probabilidad: alta para cualquier usuario con cuenta `active`).
- **Ubicación:** [`backend/routes/activity.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/activity.route.js#L17-L31), [`backend/routes/adoption.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/adoption.route.js#L25-L32), [`backend/routes/campaign.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/campaign.route.js#L17-L23), [`backend/routes/identification.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/identification.route.js#L18-L25), [`backend/routes/talk.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/talk.route.js#L28-L35).
- **Descripción:** Todas estas rutas montan `protect` + `requireActiveAccount`, pero ninguna aplica `restrictTo("admin")` sobre acciones estrictamente administrativas como `DELETE /:id`, `PATCH /activity/:id/participants/:studentId` (que valida asistencias y suma horas), `PATCH /adoption/:id/complete` o `PATCH /identification/:id/status` (que con `status: "COMPLETED"` crea automáticamente una `Accreditation` de 5 horas en [`identification.controller.js`](file:///Users/riosisraelg/dev/abaq/backend/controllers/identification.controller.js#L151-L175)).
- **Evidencia / PoC:** Un estudiante autenticado (`role: "student"`, `accountStatus: "active"`) invoca `PATCH /activity/<activityId>/participants/<su_studentId>` con `{"status": "validated"}` o `PATCH /identification/<id>/status` con `{"status": "COMPLETED"}` obteniendo la acreditación administrativa sin intervención de Coordinación, o invoca `DELETE /adoption/<id>` eliminando expedientes.
- **Impacto:** Fraude en horas de servicio social universitario y destrucción o alteración de registros de adopciones, campañas y pláticas.
- **Remediación:** Aplicar `restrictTo("admin")` en todas las rutas administrativas (`POST /`, `PATCH /:id`, `DELETE /:id`, `GET /:id/participants`, `PATCH /:id/participants/:studentId`, `PATCH /:id/complete`, `PATCH /:id/status`), dejando exclusivamente las acciones de colaborador (`GET /activity`, `POST /activity/:id/assign`, `PATCH /activity/:id/cancel-registration`, `POST /accreditations`) abiertas al rol `student`/`volunteer` con validación de propiedad sobre su propio `linkedDoc._id`.
- **Referencias:** OWASP A01:2021, WSTG-ATHZ-02, CWE-862.

---

#### H-03 — Superficie Expuesta a Inyección NoSQL y Confusión de Tipos (`Type Confusion`) en Consultas Mongoose
- **Severidad:** Alto (Impacto: bypass lógico en activación de cuentas o consultas filtradas; Probabilidad: media-alta al no existir sanitizador global de llaves `$` y `.`).
- **Ubicación:** [`backend/app.js`](file:///Users/riosisraelg/dev/abaq/backend/app.js#L45-L58), [`backend/controllers/auth.controller.js`](file:///Users/riosisraelg/dev/abaq/backend/controllers/auth.controller.js#L556-L597), [`backend/controllers/handler.controller.js`](file:///Users/riosisraelg/dev/abaq/backend/controllers/handler.controller.js#L30).
- **Descripción:** El paquete `express-mongo-sanitize` no está instalado en [`backend/package.json`](file:///Users/riosisraelg/dev/abaq/backend/package.json) ni configurado en `app.js`. En `activateVolunteer`, el parámetro `req.body.token` se pasa sin verificar `typeof token === "string"` dentro de `Volunteer.findOne({ activationToken: token, ... })`. Asimismo, `factory.updateOne` pasa `req.body` íntegro a `Model.findByIdAndUpdate(req.params.id, req.body, ...)` habilitando *Mass Assignment* sobre campos no filtrados si la ruta falla en RBAC.
- **Evidencia / PoC:** Enviar `POST /auth/activate-volunteer` con JSON `{"token": {"$ne": null}, "password": "...", "confirmPassword": "..."}`. Mientras el backend no valide tipo cadena o sanitice `$`, Mongoose intenta evaluar el operador recibido en la consulta.
- **Impacto:** Manipulación de consultas de base de datos, posible activación o alteración indebida de documentos si existen registros con tokens vigentes, y sobre-escritura masiva de atributos (`Mass Assignment`).
- **Remediación:**
  1. Integrar sanitización global de llaves iniciadas con `$` o conteniendo `.` en `req.body`, `req.query` y `req.params` (middleware tipo `express-mongo-sanitize` o helper recursivo en `app.js`).
  2. Validar explícitamente `typeof field === "string"` y formato hexadecimal/longitud en todo token o identificador recibido (`activateVolunteer`, `login`, `checkExpedienteStatus`).
  3. Usar listas blancas explícitas (*allowlists*) de campos actualizables en lugar de pasar `...req.body` a `findByIdAndUpdate` / `Object.assign`.
- **Referencias:** OWASP A03:2021, A08:2021, WSTG-INPV-05, WSTG-INPV-01, CWE-943, CWE-915.

---

#### H-04 — Exposición de `passwordHash` en Logs y Enumeración de Datos Personales en `/auth/expediente-status`
- **Severidad:** Medio-Alto (Impacto: exposición de hashes de credenciales en registros del servidor y fuga de PII/enlaces firmados a anónimos; Probabilidad: media-alta).
- **Ubicación:** [`backend/controllers/auth.controller.js`](file:///Users/riosisraelg/dev/abaq/backend/controllers/auth.controller.js#L115-L119) y [`backend/controllers/auth.controller.js`](file:///Users/riosisraelg/dev/abaq/backend/controllers/auth.controller.js#L668-L732), [`backend/routes/auth.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/auth.route.js#L16).
- **Descripción:**
  1. En `exports.login`, después de consultar `User.findOne({ email }).select("+passwordHash")`, la línea 118 ejecuta `console.log("USUARIO ENCONTRADO:", user);`, escribiendo el documento completo —incluido `passwordHash` y correo— en la salida estándar de logs de Railway.
  2. El endpoint público `GET /auth/expediente-status` carece de autenticación y de `rateLimit`, acepta `?folio=` o `?email=` con formato predecible (`SS-AAMMDD-XX`) y retorna `fullName`, `email`, `accountStatus`, `comments` y `cartaAceptacion` (URL con token HMAC).
- **Evidencia / PoC:** Cada inicio de sesión escribe el hash bcrypt completo del usuario en la consola del servicio backend. Por otro lado, iterar peticiones anónimas `GET /auth/expediente-status?folio=SS-261115-01`..`FF` permite extraer nombres completos, correos y enlaces de carta de aceptación sin autenticación.
- **Impacto:** Compromiso de confidencialidad de PII de aspirantes y colaboradores y exposición de material sensible en logs operacionales.
- **Remediación:**
  1. Eliminar inmediatamente `console.log("USUARIO ENCONTRADO:", user)` en `auth.controller.js` y auditar los `console.log(req.body)` en `handler.controller.js:25-29` para garantizar CERO PII o hashes en logs.
  2. Exigir coincidencia conjunta de **folio + correo** (o JWT) en `checkExpedienteStatus`, proteger la ruta con `express-rate-limit` estricto y enmascarar campos sensibles si se consulta sin sesión activa.
- **Referencias:** OWASP A09:2021, A01:2021, WSTG-ERRH-01, CWE-532, CWE-200.

---

#### H-05 — Mala Configuración de Seguridad Perimetral, Payload JSON sin Límite, `?token=` en Query y Endpoint Legado Sin Turnstile
- **Severidad:** Medio (Impacto: vulnerabilidad ante payloads JSON gigantes DoS, persistencia de tokens en historial/logs y superficie de registro legado abierta; Probabilidad: media).
- **Ubicación:** [`backend/app.js`](file:///Users/riosisraelg/dev/abaq/backend/app.js#L47-L56), [`backend/routes/auth.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/auth.route.js#L17), [`backend/routes/backup.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/backup.route.js#L35-L40), [`backend/app.js`](file:///Users/riosisraelg/dev/abaq/backend/app.js#L99-L105).
- **Descripción:**
  1. `app.use(express.json())` se configura sin parámetro `{ limit }` (permite parseo innecesariamente amplio en rutas no multipart).
  2. `POST /auth/register` (`auth.route.js:17`) permanece expuesto sin `requireTurnstile`.
  3. `allowQueryToken` (`backup.route.js:35-40`) acepta el JWT administrativo en `?token=` de la URL, exponiéndolo potencialmente en logs de proxies o historial del navegador cuando existen peticiones con `Authorization: Bearer` desde `BackupService`.
  4. CORS (`origin: true`, `credentials: true`) y el manejador global de errores (que siempre imprime `err.message`) están configurados de forma permisiva para el sandbox académico (`RNF-DEP-01/02`).
- **Evidencia / PoC:** Inspección directa de `app.js` líneas 47–56 y `auth.route.js` línea 17.
- **Impacto:** Riesgo de saturación de memoria JSON, bypass del flujo de onboarding vía `/auth/register`, exposición accidental de JWT de administrador en bitácoras de red HTTP y superficie excesiva al pasar de sandbox a producción.
- **Remediación:**
  1. Configurar `express.json({ limit: "1mb" })` y `express.urlencoded({ extended: true, limit: "1mb" })`.
  2. Deshabilitar o proteger `POST /auth/register` con `requireTurnstile("register")` + `rateLimit` estricto.
  3. Deprecar `?token=` en `backup.route.js` en favor exclusivo de `Authorization: Bearer` (ya usado por Angular `HttpClient` en `Blob`).
  4. Documentar perfil de endurecimiento obligatorio previo a producción: `NODE_ENV=production`, lista blanca estricta de `origin` en CORS, `TURNSTILE_DISABLED=false` y ocultamiento de mensajes internos en errores 500.
- **Referencias:** OWASP A05:2021, WSTG-CONF-04, WSTG-ERRH-02, CWE-400, CWE-200, CWE-209.

---

#### H-06 — Exposición a Abuso de Costos de *Service Egress* (`$0.05/GB`) y Cooldown Efímero de 45s en Descarga de Documentos
- **Severidad:** Alto (Impacto: financiero y de disponibilidad / agotamiento de crédito Railway y RAM; Probabilidad: alta ante scripts automatizados o clics repetidos).
- **Ubicación:** [`backend/controllers/bucket.controller.js`](file:///Users/riosisraelg/dev/abaq/backend/controllers/bucket.controller.js#L21-L24) & L388-425, [`frontend/src/app/services/bucket.service.ts`](file:///Users/riosisraelg/dev/abaq/frontend/src/app/services/bucket.service.ts#L65-L66), [`backend/routes/talk.route.js`](file:///Users/riosisraelg/dev/abaq/backend/routes/talk.route.js#L19-L35), [`backend/controllers/backup.controller.js`](file:///Users/riosisraelg/dev/abaq/backend/controllers/backup.controller.js#L74-L120).
- **Descripción:**
  - En backend, la regla de 3 descargas / 8 h y anti-spam de 2 s únicamente cubre `downloadOfficialDocument`. Endpoints pesados como `downloadSignedRules` (archivos hasta 15 MB), `getTalkLetterDocx`, `getTalkLetterPdf`, `getPublicTalkCertificate` (~2.77 MB HTML por petición) y `downloadJsonBackup` / `downloadExcelBackup` no pasan por un controlador unificado anti-abuso de 8 h ni por detección de ráfagas anormales multi-archivo.
  - En frontend, `BucketService` solo guarda el estado 45 segundos en RAM (`this.evidenceDownloadCache` en memoria), perdiéndose al refrescar la pestaña.
- **Evidencia / PoC:** Un usuario recarga la página tras 3 descargas o alterna descargas entre 20 archivos de distintos módulos o constancias de pláticas, eludiendo el cooldown de 45s del frontend y generando tráfico saliente no acotado desde Express (`$0.05/GB` Service Egress).
- **Impacto:** Sobrecargos en la facturación mensual de Railway y degradación de CPU/memoria en el contenedor Node.js.
- **Remediación:** Implementar el middleware unificado **`downloadGuard.js`** con bloqueo de 8 horas tras 3 descargas por documento + **Circuit Breaker global de 8 horas** por comportamiento anormal (`> 8` archivos en `< 60 s` o `>= 5` bloqueos en 10 min) cubriendo Bucket, Pláticas y Respaldos, y persistir los bloqueos por 8 horas en `localStorage` desde el frontend (§5.2).
- **Referencias:** OWASP A04:2021, WSTG-BUSL-01, WSTG-SESN-10, CWE-770, CWE-799.

---

#### H-07 — Riesgos Preventivos de Desempaquetado ZIP en Rollback con Bucket S3: Zip-Slip, Zip-Bomb y Sobrescritura/Suplantación de Binarios *(Nueva Propuesta)*
- **Severidad:** Crítico (Preventivo en diseño antes de implementar) (Impacto: escritura arbitraria fuera de directorio en disco/S3, agotamiento total de RAM / OOM kill en contenedor Railway y adulteración de archivos existentes).
- **Ubicación:** Propuesta de ampliación de `backend/services/backup.service.js` (`processRollback` / `unifiedRestore`) y `backend/services/bucket.service.js` para restaurar carpeta `bucket/*` desde paquetes `.zip`.
- **Descripción:** Al habilitar que el archivo `.zip` subido en Rollback contenga objetos binarios bajo `bucket/<carpeta>/<archivo>` y los suba a Railway Storage Bucket S3 o al volumen local `/data/bucket`, un atacante o un paquete manipulado podrían incluir entradas ZIP con secuencias de *Path Traversal* (`../../app.js`), relaciones de compresión extremas (*Zip-Bomb*: `10 MB` comprimidos que se expanden a `5 GB` en memoria RAM al llamar `entry.getData()`), claves con caracteres de control o archivos ejecutables/HTML disfrazados de `.pdf`.
- **Evidencia / PoC (Escenario de Diseño):** Un administrador malicioso o cuenta comprometida sube un `.zip` modificado con entrada `bucket/../../../../etc/cron` o `bucket/documentos/shell.html` con tamaño descomprimido de 2 GB.
- **Impacto:** Caída inmediata del servidor Node.js (`Out-Of-Memory`), escape de ruta en disco (`Zip-Slip`) o alojamiento de cargas XSS activas en S3 si se relaja el `Content-Type`.
- **Remediación Obligatoria en Diseño:**
  1. **Anti-Zip-Slip estricto (`CWE-22`):** Toda entrada `bucket/...` en el ZIP debe cumplir la regex estricta `^bucket\/(reglamentos|adopciones|evidencias|documentos)\/[A-Za-z0-9._-]+\.pdf$` (prohibido `..`, `\`, enlaces simbólicos, rutas absolutas o extensiones distintas de `.pdf`). Al resolver ruta en disco local validar `path.resolve(target).startsWith(path.resolve(baseDir) + path.sep)`.
  2. **Cuotas Anti-Zip-Bomb (`CWE-409`):** Verificar las cabeceras del ZIP (`entry.header.size` y suma acumulada) **antes** de llamar `entry.getData()`, rechazando si el total descomprimido excede `250 MB`, si un solo archivo excede `20 MB` o si la relación `uncompressed / compressed > 50:1` o cantidad de entradas `> 5,000`.
  3. **Validación de contenido y Hash:** Comprobar `sha256` contra `manifest.json` y `isValidPdfBuffer()` (`%PDF-`) antes de invocar `uploadToRailwayBucket(..., { contentType: 'application/pdf' })`.
  4. **Zero-Overwrite:** Consultar `existingKeysSet` en el bucket antes de subir; si `key` existe, **omitir por diseño**.
- **Referencias:** OWASP A03:2021, A04:2021, A08:2021, WSTG-INPV-04, WSTG-INPV-05, CWE-22, CWE-409, CWE-434, CWE-379.

---

#### H-08 — Firma AWS SigV4 Incompleta para `ListObjectsV2` y Riesgo de Saturación en Endpoints de Estadísticas Duales *(Nueva Propuesta)*
- **Severidad:** Medio (Preventivo en diseño) (Impacto: fallo `403 SignatureDoesNotMatch` al listar el bucket o degradación de latencia en MongoDB/S3 por escaneo repetitivo).
- **Ubicación:** [`backend/services/railwayBucket.service.js`](file:///Users/riosisraelg/dev/abaq/backend/services/railwayBucket.service.js#L112-L122) y futuro servicio de estadísticas y costos (`getBackupStatus`).
- **Descripción:** La función `buildSigV4Headers()` en `railwayBucket.service.js:113` fija `const canonicalQuery = "";`. Aunque funciona para `PutObject` y `GetObject` sobre rutas sin parámetros `?query`, la operación S3 `ListObjectsV2` requiere parámetros de consulta (`?list-type=2&continuation-token=...`). Si `canonicalQuery` no ordena ni codifica RFC-3986 las claves y valores de `url.searchParams`, S3 rechazará la firma con `403`. Adicionalmente, ejecutar `dbStats` + conteo en 13 colecciones + paginación completa S3 en cada carga sin caché permitiría DoS por usuario administrativo o abuso de pestaña.
- **Evidencia / PoC:** Llamada `buildSigV4Headers` actual sobre `https://bucket.endpoint/?list-type=2` produce una firma sobre `""` en lugar de `"list-type=2"`.
- **Impacto:** Inoperatividad de las métricas reales del Bucket S3 y riesgo de consumo excesivo de CPU en el servidor ante recargas continuas.
- **Remediación:**
  1. Actualizar `buildSigV4Headers()` para serializar `url.searchParams` ordenados alfabéticamente y codificados con RFC-3986 (`encodeURIComponent` ajustando `!*'()`).
  2. Paginar `ListObjectsV2` usando únicamente metadatos ligeros (`Key`, `Size`, `LastModified`) sin descargar cuerpos de objetos para calcular estadísticas.
  3. Implementar caché en memoria del servidor con TTL de **5 minutos** y rechazo o reutilización de caché cuando `?refresh=true` se solicite antes de 60 segundos.
- **Referencias:** OWASP A02:2021, A04:2021, WSTG-BUSL-01, CWE-400.

---

#### H-09 — Riesgo de Descarga de Respaldos Corruptos o con Referencias Cruzadas Rotas BD $\leftrightarrow$ Bucket S3 *(Nueva Propuesta)*
- **Severidad:** Medio (Impacto: pérdida de recuperabilidad real ante desastres por respaldos inconsistentes; Probabilidad: media tras migraciones o fallos parciales de red).
- **Ubicación:** Futuro validador `validateBackupReadiness` en `backend/services/backup.service.js` y `backup.controller.js`.
- **Descripción:** Si el servidor empaquetara un respaldo sin validar previamente que las colecciones y los archivos del bucket sean legibles y consistentes entre sí, la Coordinación podría descargar un `.zip` que contenga expedientes apuntando a archivos inexistentes en `bucket/`, archivos truncados de `0 bytes`, o documentos en BD con folio `null` que fallarían la validación al restaurar.
- **Evidencia / PoC (Escenario de Diseño):** Un comprobante falló al subirse parcialmente dejando `evidenceUrl: "comprobante_xyz.pdf"` guardado en MongoDB sin existir el objeto en S3, o un JSON tiene caracteres corruptos.
- **Impacto:** Falsa sensación de seguridad en respaldos y fallos en cascada durante un procedimiento de emergencia (*disaster recovery*).
- **Remediación:** Ejecutar `validateBackupReadiness(scope)` antes de comenzar la compresión del `.zip`, abortando con `HTTP 422` y detalle comprensible si hay archivos ilegibles/corruptos, registros corruptos en BD o referencias BD $\leftrightarrow$ Bucket rotas; además almacenar el resultado en `manifest.json.integrityReport`.
- **Referencias:** OWASP A08:2021, A04:2021, CWE-345, CWE-434.

---

### 6.4 Fase 3 y Fase 6 — Frontera Ética de Prueba de Concepto (PoC) y Cierre del Encargo

En estricto apego a la sección *"Prueba de concepto y cierre"* de la metodología del profesor:
1. Toda comprobación en ambiente de pruebas autorizado (`NODE_ENV=development` en Railway) debe limitarse a **demostrar el hecho sin causar daño**: nunca sobrescribir registros productivos reales, nunca exfiltrar datos personales de estudiantes o adoptantes (ocultando/tapando PII en capturas del informe) ni dejar cuentas, archivos o configuraciones persistentes tras la prueba.
2. **Ciclo de Cierre Propuesto:**
   - **Paso 1:** Validación y firma de prioridad sobre los hallazgos Críticos/Altos (`H-01`, `H-02`, `H-03`, `H-06`, `H-07`) antes de habilitar esta nueva funcionalidad en vivo.
   - **Paso 2:** Programación conjunta de la remediación de seguridad + módulo dual de estadísticas, validación pre-descarga y respaldo/rollback de Bucket S3.
   - **Paso 3 (Reprueba / Regression Security Testing):** Ejecución controlada de casos de prueba verificando `403 Forbidden` en `H-01`/`H-02`, rechazo de `$ne` en `H-03`, ausencia de `passwordHash` en logs (`H-04`), rechazo `422` en ZIP maliciosos Zip-Slip/Zip-Bomb (`H-07`) y activación del bloqueo de 8 horas + Circuit Breaker (`H-06`).
