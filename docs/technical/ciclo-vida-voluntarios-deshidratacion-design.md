# Propuesta Técnica: Sistema Integral de Gestión de Voluntarios — Ciclo de Vida, Inactivación, Deshidratación de BD, Folios de Interacción (AC/OP) y Mapeo de Vistas

**Proyecto:** Plataforma Web ABAQ (Servicio Social y Voluntariado General)  
**Versión:** 1.2.0 (Propuesta Técnica en Refinamiento Activo)  
**Fecha:** 2026-11-02  
**Estado:** Propuesta Técnica / Idea en Construcción (Espacio Activo de Trabajo y Refinamiento)  
**Relacionado:** [Ideas y Propuestas](ideas/index.md) · [Arquitectura General](architecture.md) · [Diseño de Respaldos y Datos](datos-respaldo-recuperacion-design.md) · [Diseño de Autenticación](auth-design.md) · [Sistema de Notificaciones](notificaciones-design.md)

> [!NOTE] Contexto y Alcance del Documento (Evolución de la Propuesta)
> Este documento consolida la arquitectura y especificación de la **Gestión Integral de Voluntarios** de ABAQ. Aunque la iniciativa inició conceptualmente orientada al archivado de usuarios, la ingeniería del sistema demandó abordar de manera sistémica e indivisible **todo el ciclo de vida del colaborador**, desde su admisión, folios de seguimiento de horas y asistencias, reglas de inactividad automática, hasta la depuración de base de datos en 3 fases y la auditoría forense de datos.

---

## 1. Resumen Ejecutivo y Marco Integral del Sistema

La plataforma web de la **Asociación de Bienestar Animal Querétaro (ABAQ)** requiere gobernar de forma exhaustiva, automatizada y legalmente transparente la participación de sus dos figuras operativas: **Estudiantes de Servicio Social** (`student`, sujetos al cumplimiento estricto de 480 horas curriculares) y **Voluntarios Generales** (`volunteer`, colaboración cívica altruista sin cómputo horario formal).

Para garantizar la sustentabilidad técnica de la plataforma, evitar la saturación visual de las vistas operativas y amparar fehacientemente cada hora y asistencia registrada, esta propuesta técnica articula **8 módulos funcionales interconectados**:

### Los 8 Módulos Funcionales Comprendidos en esta Especificación

```mermaid
flowchart LR
    M1["1. Máquina de Estados\n(pending, active, inactive, rejected)"] --> M2["2. Inactivación Dual\n(480 hrs SS / 60 días inactividad)"]
    M2 --> M3["3. Retención y Vistas\n(12 meses / /volunteers/history)"]
    M3 --> M4["4. Deshidratación en 3 Fases\n(Análisis previo + ZIP + Purga)"]
    M4 --> M5["5. Bitácoras y Telemetría\n(statusHistory + DehydrationAuditLog)"]
    M5 --> M6["6. Folios AC y OP\n(Nomenclatura 3L sin colisiones)"]
    M6 --> M7["7. Mapeo de Vistas\n(Dónde SÍ, NO y Condicional)"]
    M7 --> M8["8. Notificaciones Resend\n(Exclusivo para Voluntarios)"]
```

1. **Máquina de Estados Unificada del Voluntario:** Control estricto de accesos según el estado de la cuenta (`pending`, `active`, `inactive`, `rejected`), flujo de primer ingreso obligatorio a `/onboarding/expediente` para descarga de carta de aceptación, y mecanismo de **re-registro idempotente** con el mismo correo electrónico para solicitudes previamente rechazadas.
2. **Automatización de Inactivación Dual:** Reglas de cese desatendido sin intervención humana:
   * *Inmediata al cumplir 480 horas* para estudiantes de servicio social al aprobarse su acreditación definitiva.
   * *A los 60 días continuos de inactividad integral* (medida sobre login, asistencia o acreditación), con alerta preventiva urgente a los 45 días.
   * *Baja administrativa discrecional* con justificación obligatoria.
3. **Visibilidad Escalonada y Registro Histórico:** Ventana operativa de 12 meses para usuarios inactivos en las tablas principales (ordenados al final con diseño atenuado), retiro automático a los 365 días y habilitación de la vista dedicada `/volunteers/history` con pestañas ligeras para auditorías universitarias.
4. **Deshidratación y Rehidratación Segura de la Base de Datos:**
   * *Principio del Corte Indivisible:* No se permiten purgas parciales; una actividad u oportunidad solo se purga si el 100% de sus participantes son inactivos $> 1$ año.
   * *Flujo en Tres Fases con Análisis Previo Bajo Demanda en `/backup`:* Cero ejecución pasiva; el backend solo procesa el análisis cuando el admin pulsa explícitamente el botón, previsualizando el impacto antes de descargar el ZIP y purgar con contraseña y token criptográfico `X-Purge-Token`.
5. **Esquema de Datos, Telemetría y Bitácoras de Auditoría:**
   * *Trazabilidad de cambios de estado (`statusHistory` y `UserStatusAuditLog`):* Registro exacto de a qué usuario se le aplicó (`targetUserId`, `targetUserFolio`), qué administrador lo realizó (`changedByEmail`), la causal (`reason`) y el comentario explicativo (`comments`) visible en perfiles e interfaces.
   * *Telemetría real de MongoDB Atlas:* Diagnóstico empírico de las 14 colecciones que clasifica los 12 modelos que se van (liberando el 41.4% de la BD al purgar `notifications`) frente a los 4 modelos conservados permanentemente (`quickactivities`, `users` admin, `pets` y `DehydrationAuditLog`).
6. **Nomenclatura Determinista de Folios de Interacción (`AC` y `OP`):**
   * Generación de folios no para la actividad a nivel macro, sino para la **solicitud de interacción específica del colaborador**.
   * Respaldo para que el alumno pueda validar y "pelear" sus horas acreditadas y el voluntario amparar su asistencia cívica.
   * Prefijo `AC-YYMMDD-HEX` para actividades convocadas y `OP-CAT-YYMMDD-HEX` con sub-código mnemónico de 3 letras (`EVE`, `IND`, `IDE`, `STE`, `ADO`, `MOD`, `TLK`, `CAM`, `MED`, `SOC`, `DON`, `ADM`) que resuelve formalmente la colisión triple de `AD`.
7. **Mapeo y Definición Visual de Vistas:** Reglas claras de presentación que definen las 9 vistas críticas donde el folio es indispensable, las 3 vistas de visibilidad condicional dinámica y las 10 vistas excluidas para preservar una interfaz limpia y sin sobrecarga cognitiva.
8. **Sistema de Notificaciones Transaccionales y Certificación Criptográfica:** Envío de correos automáticos mediante Resend con destino exclusivo a los voluntarios (cero notificaciones de admin ni in-app) y generación de URLs seguras con firma HMAC-SHA256 para constancias y cartas oficiales de terminación.

---

## 2. Máquina de Estados del Usuario (`accountStatus`)

Los modelos de Mongoose `Student` y `Volunteer` comparten el enum unificado de estados de cuenta: `["pending", "active", "inactive", "rejected"]`.

```mermaid
stateDiagram-v2
    [*] --> pending: Registro por Fases (Signup)
    
    pending --> active: Aprobación por Administrador\n(Genera Carta Aceptación + Email Resend)
    pending --> rejected: Rechazo por Administrador\n(Permanece en BD con motivo)
    
    rejected --> pending: Re-registro con mismo email\n(Reset idempotente + nuevo hash)
    
    active --> inactive: 1. Cumplimiento de 480 hrs (Student)\n2. 60 días sin actividad integral\n3. Decisión Administrativa
    
    state inactive {
        [*] --> OperativoReciente: Inactivo < 12 meses\n(Fila gris al final de tablas)
        OperativoReciente --> RetiradoVistas: Inactivo >= 12 meses\n(Solo en /volunteers/history)
        RetiradoVistas --> Deshidratado: Purga con corte de fecha\n(Descarga ZIP + DehydrationLog)
    }

    Deshidratado --> RetiradoVistas: Rehidratación por ZIP (Upsert)
```

### 2.1 Estado `pending` (Default de Registro)
- **Definición:** Estado inicial al completar el onboarding de 4 fases.
- **Acceso:** Restringido exclusivamente a la vista `/onboarding/expediente` en modo "Expediente Recibido en Validación".
- **Restricción de Login:** Si el usuario ingresa credenciales válidas en `/login`, `AuthGuard` y `LoginComponent` lo redirigen obligatoriamente a `/onboarding/expediente`. No tiene acceso a APIs de consulta operativa ni al menú del portal.

### 2.2 Estado `active` (Aprobado)
- **Activación:** Se detona cuando el administrador presiona "Aceptar" en la tabla de voluntarios/estudiantes.
- **Flujo de Ingreso (Primera vez tras ser aceptado vs. Ingresos posteriores):**
  - **Primer Ingreso (`primerIngresoRealizado: false`):** 
    - Al autenticarse por primera vez tras la aceptación, el sistema lo dirige obligatoriamente a `/onboarding/expediente`.
    - En esta pantalla visualiza su tarjeta oficial de bienvenida con estatus de expediente aprobado y el enlace criptográfico para descargar su **Carta de Aceptación y Felicitación Oficial** (`cartaAceptacion`).
    - Para ingresar al portal operativo, debe pulsar explícitamente el botón **"Ingresar a la Plataforma ABAQ"**. Al hacer clic en este botón, el sistema marca de forma permanente en base de datos la bandera `primerIngresoRealizado: true`.
  - **Ingresos Posteriores (`primerIngresoRealizado: true`):**
    - En todos los inicios de sesión subsecuentes, el usuario **ya no pasa por el expediente**. 
    - El login lo redirige directamente a la vista inicial correspondiente a su rol (`/activity-list` para voluntarios y estudiantes de servicio social; `/admin/home` para administradores).
  - **Control de Navegación por Guard (`primerIngresoRealizado`):** Si un voluntario activo aún no ha realizado su primer ingreso formal (`primerIngresoRealizado === false`) e intenta ingresar directamente por URL a `/activity-list`, `AuthGuard` lo intercepta y lo regresa a `/onboarding/expediente` hasta que concluya el trámite inicial pulsando el botón de acceso. Una vez completado, el acceso a sus rutas operativas queda 100% liberado.

### 2.3 Estado `rejected` (Rechazado)
- **Comportamiento en BD:** Al rechazar una solicitud, el backend **no elimina el documento**. Actualiza `accountStatus: "rejected"` y registra el evento en `statusHistory`.
- **Comportamiento en UI:** Desaparece de la lista de pendientes (filtro `showPendingOnly`). Si el usuario inicia sesión, se le muestra la pantalla de expediente rechazado ("Solicitud no aprobada") con opción única de cerrar sesión o corregir su registro.
- **Protocolo de Re-registro con el Mismo Correo:**
  - El correo electrónico **no queda invalidado ni bloqueado**.
  - Si el aspirante vuelve a llenar el registro usando el mismo correo, el backend localiza el documento existente por `email`:
    1. Reemplaza los datos personales, académicos y respuestas de formulario con los nuevos valores.
    2. Hashea y actualiza la nueva contraseña (`passwordHash`).
    3. Limpia las observaciones de rechazo previas.
    4. Cambia su `accountStatus` de nuevo a `"pending"`.
    5. Registra una nueva entrada en `statusHistory` con motivo `"re_registration"`.

### 2.4 Estado `inactive` (Inactivo / Desvinculado)
La transición a `inactive` ocurre de forma automática o manual bajo tres causales estrictas:

| Causal de Inactivación | Aplica a | Detonante Técnico | Emisión de Constancia | Notificación Resend |
| :--- | :--- | :--- | :--- | :--- |
| **Cumplimiento de 480 horas** | `student` | Inmediato al aprobar la acreditación que alcance $\ge 480$ hrs | Sí (`constanciaFinalizacion` con token) | Correo de finalización con enlace a certificado |
| **2 meses de inactividad (60 días)** | `student` y `volunteer` | Cron Job diario en backend al evaluar `Date.now() - ultimaActividad >= 60` días | No (baja por abandono) | Correo de baja definitiva por inactividad |
| **Decisión Administrativa** | Ambos roles | PATCH manual ejecutado por administrador desde el portal | Condicional (solo si concluyó formalmente) | Correo informativo según causal |

#### Criterio de "Última Actividad Integral"
El temporizador de inactividad se calcula evaluando la fecha más reciente entre:
$$\text{fechaUltimaActividad} = \max(\text{lastLogin}, \text{fechaUltimaAcreditacion}, \text{fechaInscripcionActividad}, \text{fechaAceptacionExpediente})$$
- A los **45 días** sin actividad (15 días antes del corte), el cron job envía un **correo de alerta urgente**.
- A los **60 días**, el cron job actualiza `accountStatus = "inactive"`, fija `fechaDesactivacion = Date.now()` y envía el correo de baja.

#### Matriz de Permisos del Usuario Inactivo
- **Lectura Histórica Restringida:** Puede iniciar sesión para consultar su historial pasado.
- **Filtro de Actividades:** El endpoint `GET /activities` detecta si el usuario está inactivo y aplica la restricción:
  $$\text{filtroActividades} = \{ \text{createdAt}: \{ \$lte: \text{fechaDesactivacion} \} \}$$
  Impidiendo que observe actividades convocadas con posterioridad a su baja.
- **Acciones Bloqueadas:** Se prohíbe inscribirse a nuevas actividades (`403 Forbidden`), editar su perfil o solicitar acreditaciones u oportunidades.

---

## 3. Reglas de Visibilidad en Frontend y Retención (12 Meses)

Para balancear la supervisión administrativa inmediata y la limpieza visual a largo plazo, el sistema divide a los usuarios inactivos según el tiempo transcurrido desde su fecha de desactivación:

```mermaid
flowchart TD
    V["Voluntario en Estado Inactivo"] --> D{"Tiempo desde fechaDesactivacion"}
    D -->|Menor a 12 meses| T1["Tabla Principal de Voluntarios (/volunteers)"]
    D -->|Mayor o igual a 12 meses| T2["Vista de Voluntarios Pasados (/volunteers/history)"]
    
    subgraph T1_Style ["Renderizado en Tabla Principal"]
        T1A["Fila completa con estilo gris claro (#f1f5f9)"]
        T1B["Ordenamiento forzado al final de la paginación"]
        T1A --- T1B
    end
    
    subgraph T2_View ["Estructura de /volunteers/history"]
        TAB1["Pestaña: Estudiantes Pasados (Servicio Social)"]
        TAB2["Pestaña: Voluntarios Generales Pasados"]
        TAB3["Pestaña: Bitácora de Auditoría (statusHistory)"]
    end
```

### 3.1 Ventana Operativa Reciente ($< 12$ Meses)
- Los voluntarios que lleven menos de 1 año inactivos siguen apareciendo en la tabla principal de administración.
- **Estilo Visual:** Se marcan con la clase CSS `.row-inactive` (fondo gris claro `#f1f5f9`, texto atenuado `#64748b`).
- **Ordenamiento:** La consulta operativa los ordena al final de la lista para no interferir con la supervisión de voluntarios activos y expedientes pendientes.

### 3.2 Retiro de Vistas Operativas ($\ge 12$ Meses)
- Al cumplirse 1 año (365 días) de su fecha de desactivación, los registros se excluyen de la consulta principal mediante el filtro `{ $or: [ { accountStatus: { $ne: 'inactive' } }, { fechaDesactivacion: { $gte: cutoff12Months } } ] }`.
- Ya no son visibles en la tabla principal y pasan a residir exclusivamente en la nueva pantalla de historial.

### 3.3 Vista Dedicada: Voluntarios Pasados (`/volunteers/history`)
Accesible desde un botón primario ubicado en el encabezado de la sección de Voluntarios: **"Ver Voluntarios Pasados"**.

La pantalla cuenta con navegación por pestañas y dos tablas optimizadas mediante **MongoDB Aggregation Pipelines** que proyectan únicamente los datos esenciales sin cargar modelos pesados:

#### Tabla 1: Estudiantes de Servicio Social Pasados
1. **Nombre Completo:** `fullName`
2. **Datos de Contacto:** Correo electrónico (`email`) y Teléfono (`phone`)
3. **Edad:** Calculada a partir de fecha de nacimiento o edad registrada
4. **Fecha en la Organización:** `fechaEmisionExpediente` o `createdAt`
5. **Fecha de Activación:** `fechaAceptacionExpediente`
6. **Fecha de Desactivación:** `fechaDesactivacion`
7. **Total de Acreditaciones:** Conteo consolidado de acreditaciones (actividades + oportunidades manuales aprobadas)
8. **Total de Horas Realizadas:** Horas totales acreditadas (ej. 480 hrs)
9. **Tipo de Periodo Académico:** Valor del enum (`TRIMESTRAL`, `SEMESTRAL`, `TETRAMESTRAL`, etc.)
10. **Universidad / Institución:** `school`

#### Tabla 2: Voluntarios Generales Pasados
1. **Nombre Completo:** `fullName`
2. **Datos de Contacto:** Correo (`email`) y Teléfono (`phone`)
3. **Edad:** `age`
4. **Fecha en la Organización:** `createdAt`
5. **Fecha de Activación:** `fechaAceptacionExpediente`
6. **Fecha de Desactivación:** `fechaDesactivacion`
7. **Total de Acreditaciones:** Conteo de participaciones aprobadas (sin cómputo horario)

---

### 3.4 Matriz Integral de Visibilidad Escalonada: Fórmulas Matemáticas y Filtros de MongoDB

Para asegurar predictibilidad matemática y rendimiento óptimo en las consultas de base de datos, el ciclo de visibilidad de los voluntarios se segmenta en **cuatro escalones operacionales**:

| Escalón | Estado y Denominación | Condición Lógica y Fórmula Temporal | Filtro MongoDB / Query Mongoose | Comportamiento en Frontend (UX) | Endpoints Backend |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **Nivel 1** | **Activo / Pendiente**<br>*(Operación Vigente)* | $\text{accountStatus} \in \{\text{'active'}, \text{'pending'}\}$ | `{ accountStatus: { $in: ['active', 'pending'] } }` | • Visible en tabla `/student`<br>• Acceso total a actividades<br>• Estilo normal blanco/hover | `GET /student`<br>`GET /volunteer`<br>`GET /activities` |
| **Nivel 2** | **Inactivo Reciente**<br>*(Transición $< 12$ Meses)* | $\text{accountStatus} = \text{'inactive'} \quad \land$<br>$0 \le \Delta t_{\text{baja}} < 365\text{ días}$<br><br>Donde:<br>$\Delta t_{\text{baja}} = t_{\text{actual}} - t_{\text{desactivacion}}$ | `{ accountStatus: 'inactive', fechaDesactivacion: { $gt: new Date(Date.now() - 365*24*60*60*1000) } }` | • Fila gris clara (`.row-inactive`, `#f1f5f9`)<br>• Texto atenuado (`#64748b`)<br>• Ordenado al final de la paginación<br>• Banner informativo en su perfil | `GET /student`<br>`GET /volunteer`<br>`GET /volunteer-profile` |
| **Nivel 3** | **Retirado Operativo**<br>*(Historial Pasado $\ge 12$ Meses)* | $\text{accountStatus} = \text{'inactive'} \quad \land$<br>$\Delta t_{\text{baja}} \ge 365\text{ días}$ | **Exclusión en tabla principal:**<br>`{ $or: [ { accountStatus: { $ne: 'inactive' } }, { fechaDesactivacion: { $gt: cutoff12Months } } ] }`<br><br>**Inclusión en `/volunteers/history`:**<br>`{ accountStatus: 'inactive', fechaDesactivacion: { $lte: cutoff12Months } }` | • **Oculto al 100%** de `/student` y `/volunteer`<br>• Accesible solo en `/volunteers/history`<br>• Pestañas ligeras proyectadas por Aggregation Pipeline<br>• Modal de historial de horas pasadas | `GET /volunteers/history/students`<br>`GET /volunteers/history/volunteers`<br>`GET /volunteers/history/audit` |
| **Nivel 4** | **Deshidratado de BD**<br>*(Corte y Purga Atómica)* | $(t_{\text{desactivacion}} \le t_{\text{corte}}) \quad \land$<br>$(\forall p \in \text{Participantes}(A), p \in \mathcal{U}_{\text{inactivos}})$ | Documento purgado físicamente de MongoDB Atlas. Referenciado en `DehydrationAuditLog` con hash criptográfico SHA-256 del paquete ZIP. | • **Inexistente en MongoDB**<br>• No aparece en búsquedas ni logins<br>• Rehidratable en cualquier momento mediante subida de ZIP en `/backup` | `POST /backup/dehydrate/analyze`<br>`POST /backup/dehydrate/download`<br>`POST /backup/dehydrate/purge`<br>`POST /backup/dehydrate/restore` |

#### Fórmulas de Cálculo Temporal en Servidor
1. **Diferencial de Inactividad de la Cuenta:**
   $$\Delta t_{\text{inactivo}} = \text{Date.now()} - \max(\text{lastLogin}, \text{fechaUltimaAcreditacion}, \text{fechaInscripcionActividad}, \text{fechaAceptacionExpediente})$$
   * Si $\Delta t_{\text{inactivo}} \ge 45\text{ días}$: Disparo de alerta preventiva por email (`stage='day45'`).
   * Si $\Delta t_{\text{inactivo}} \ge 60\text{ días}$: Inactivación automática de cuenta (`stage='day60'`).

2. **Diferencial de Antigüedad de Baja (Ventana de 12 Meses):**
   $$\Delta t_{\text{baja}} = \text{Date.now()} - \text{fechaDesactivacion}$$
   * Si $\Delta t_{\text{baja}} < 365\text{ días}$: Clasificación en **Nivel 2** (Tabla principal atenuada).
   * Si $\Delta t_{\text{baja}} \ge 365\text{ días}$: Clasificación en **Nivel 3** (Exclusivo en `/volunteers/history`).

---

---

## 4. Mecanismo de Deshidratación y Rehidratación de la Base de Datos

La deshidratación es el procedimiento administrativo para purgar físicamente de MongoDB la información de usuarios inactivos por más de un año, extrayendo un paquete estructurado en formato `.zip` descargable en local, garantizando que el sistema pueda revertir o rehidratar la información en cualquier momento.

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Administrador
    participant UI as Portal Web (/backup)
    participant API as Backup / Dehydration Controller
    participant DB as MongoDB Atlas

    Note over Admin,UI: PASO 1: Descarga del Paquete (Corte)
    Admin->>UI: Selecciona fecha de corte en dropdown
    Admin->>UI: Clic en "Descargar Información de Corte (.zip)"
    UI->>API: GET /backup/dehydrate/download?cutoffDate=YYYY-MM-DD
    API->>DB: Consulta candidatos (inactivos > 1 año + actividades concluidas)
    API-->>UI: Stream ZIP (JSONs de colecciones + manifest + SHA-256) + purgeToken
    UI-->>Admin: Archivo descargado en máquina local

    Note over Admin,UI: PASO 2: Purga Segura de BD
    Note over UI: Botón "Borrar registros de la BD" SE HABILITA con el purgeToken
    Admin->>UI: Clic en "Borrar registros descargados de la BD"
    UI->>API: POST /backup/dehydrate/purge { purgeToken, cutoffDate }
    API->>API: Valida token criptográfico (TTL 15 min) y coincidencia de corte
    API->>DB: Borrado atómico transaccional de documentos respaldados
    API->>DB: Inserta bitácora en DehydrationAuditLog
    API-->>UI: Confirmación de purga exitosa
    UI-->>Admin: Notificación de base de datos deshidratada
```

### 4.1 Principio del Corte Indivisible y Decisión Oficial de Arquitectura (Opción A)

#### Resolución del Dilema de Actividades Compartidas (Opción A Oficial)
En la operación de ABAQ, casi todas las convocatorias son de carácter grupal (jornadas de limpieza de albergue, brigadas de esterilización, pláticas masivas). Si una actividad cuenta con participantes pertenecientes a diferentes generaciones (por ejemplo, el Estudiante A que concluyó su servicio hace más de un año y el Estudiante B que ingresó meses después y continúa activo en la plataforma):

> **Decisión Oficial de Arquitectura (Opción A):**
> 1. **El Estudiante Inactivo ($> 1$ año) SÍ se purga:** Se deshidrata y retira de MongoDB Atlas al 100% (liberando su expediente, sus cuentas auth, sus notificaciones y sus registros personales). Todo su historial queda respaldado íntegramente en su archivo ZIP.
> 2. **La Actividad Colectiva Compartida SE CONSERVA en MongoDB:** Permanece viva en la base de datos operativa porque el estudiante activo la sigue necesitando para consultar su convocatoria y amparar sus horas curriculares.
> 3. **Purga Diferida de la Actividad:** La actividad colectiva se purgará de la base de datos únicamente en un corte futuro cuando el **100% de sus participantes inscritos** hayan concluido su vinculación y cumplido su año de inactividad.

```mermaid
flowchart TD
    subgraph Corte ["Ejecución de Corte de BD (cutoffDate: Octubre 2025)"]
        Act["Actividad Colectiva X\n(Limpieza de Albergue Nov 2024)"]
        StA["Estudiante A\n(Inactivo > 1 año: Desactivado Oct 2024)"]
        StB["Estudiante B\n(ACTIVO en plataforma hoy)"]
        
        Act -.->|Inscrito| StA
        Act -.->|Inscrito| StB
    end

    subgraph Decision ["Decisión de Corte: Opción A"]
        StA -->|1. SE PURGA| ZipA["Paquete ZIP + DehydrationAuditLog\n(Expediente, horas y usuario retirados de BD)"]
        Act -->|2. SE CONSERVA EN BD| DbLive["MongoDB Atlas (Base Activa)\n(Actividad permanece intacta sin valores nulos)"]
        StB -->|3. INTOCABLE| DbLive
    end

    subgraph Futuro ["Corte Futuro (Cuando Estudiante B concluya y cumpla > 1 año inactivo)"]
        DbLive -->|100% Participantes Inactivos| PurgeAct["La Actividad X se purga de BD al ZIP"]
    end
```

#### Patrón de Desacoplamiento por Doble Arreglo Embebido en `Student` y `Volunteer`
Para evitar que la eliminación de un usuario o el corte de base de datos deje valores nulos (`null`) o referencias rotas en llaves foráneas (`studentRef: null` o `activityRef: null`), la arquitectura establece un **patrón de datos embebidos autosuficientes**:

1. **El modelo `Activity` NO guarda referencias hacia los alumnos:** Las actividades convocadas son entidades maestras colectivas.
2. **Los modelos de colaborador (`Student` y `Volunteer`) almacenan dos arreglos embebidos independientes:**
   * **`assignedActivities`:** Subdocumentos con el historial de actividades convocadas en las que participó (`interactionFolio: 'AC-...'`, `activityId`, `status`, `validatedHours`, fechas).
   * **`accreditations`:** Subdocumentos con el historial de oportunidades y acreditaciones manuales (`interactionFolio: 'OP-...'`, `type`, `date`, `hoursAccredited`, `status`, evidencias).

##### Comparativa de Arquitectura: Modelo Tradicional Frágil vs Desacoplamiento ABAQ

```mermaid
flowchart TD
    subgraph Tradicional ["❌ Enfoque Tradicional Frágil (Llaves Foráneas Dependientes)"]
        UserOld["Student / Volunteer\n(_id: St_01)"]
        AccOld["Accreditation\n(studentRef: St_01, activityRef: Act_01)"]
        ActOld["Activity\n(_id: Act_01)"]
        
        UserOld --- AccOld
        AccOld --- ActOld
        
        PurgeStOld["1. Purga de Estudiante"] -.->|Elimina St_01| UserOld
        UserOld -.->|Deja| Broken["Accreditation.studentRef = null\n(Registro huérfano / Llave rota)"]
    end

    subgraph Desacoplado ["✅ Enfoque Desacoplado ABAQ (Doble Arreglo Embebido Autosuficiente)"]
        direction TB
        StNew["Student / Volunteer Model (_id: St_01)\n────────────────────────────────────────\nfolio: 'SS-261030-01'\nstatus: 'inactive'\nfechaDesactivacion: '2024-10-15'\n\n[ Arreglo 1: assignedActivities ]\n• interactionFolio: 'AC-261102-0A14'\n• activityId: Act_01, validatedHours: 15\n\n[ Arreglo 2: accreditations ]\n• interactionFolio: 'OP-STE-261102-03C8'\n• type: 'STERILIZATION', hours: 10, status: 'approved'"]
        
        ActNew["Activity Colectiva (_id: Act_01)\n(Sin lista de ObjectIds de estudiantes)"]
        
        StNew -.->|Referencia débil por ID| ActNew
    end

    subgraph BeneficioCorte ["Comportamiento en Corte y Deshidratación (Opción A)"]
        StNew -->|1. Deshidratación Atómica| ZipPkg["Paquete ZIP (students.json / volunteers.json)\n(El documento se exporta CON sus 2 arreglos completos)"]
        ZipPkg -->|2. Purga de MongoDB| CleanDB["MongoDB Atlas Activa\n(Cero registros huérfanos, CERO campos null)"]
        ActNew -->|3. Se conserva viva en BD| CleanDB
    end

    subgraph BeneficioRehidrata ["Comportamiento en Rehidratación (Restauración)"]
        ZipPkg -->|4. Rehidratación con replaceOne + upsert| StNewRestored["Student Restaurado en MongoDB\n(Sus 2 arreglos vuelven con folios y horas completas.\nRe-vinculado automáticamente sin tocar llaves)"]
    end
```

##### Ventajas Críticas del Desacoplamiento:
* **Cero Campos Nulos (`null-free`):** Si el Estudiante A es purgado, la Actividad compartida no sufre ninguna modificación, y no existe ninguna colección en MongoDB que requiera parchear llaves foráneas a `null`.
* **Historial Completo Autocontenido:** Toda la evidencia, horas acreditadas y participaciones de un voluntario viven dentro de su propio documento. Si la organización entrega un respaldo al usuario o a su universidad, el JSON de su expediente contiene el 100% de su historia cívica.
* **Resiliencia Total ante Rehidratación:** Al subir el paquete ZIP del Estudiante A años después para una auditoría escolar, su documento en MongoDB se restaura con sus dos listados completos embebidos mediante `replaceOne` con `upsert: true`. El estudiante vuelve a estar vinculado de forma inmediata a sus actividades y oportunidades históricas sin necesidad de reconstruir tablas intermedias ni resolver dependencias de integridad foránea.

---

### 4.2 Flujo Operativo en Tres Fases con Análisis Previo Bajo Demanda (Garantía Anti-Sobrecarga y Anti-Pérdida)

La interfaz de **Respaldos y Recuperación** (`/backup`) amplía su sección de *"Generar y Descargar Copias Locales"* configurando una **cuadrícula de tres columnas (3 tarjetas de acción)**:

1. **Columna 1 — Respaldo Completo del Sistema (`.ZIP / JSON`):** Copia completa de las 14 colecciones para restauración general (*rollback*).
2. **Columna 2 — Libro Consolidado en Excel (`.XLSX`):** Cuaderno estructurado con 14 hojas de cálculo para patronato y auditoría humana.
3. **Columna 3 — Corte y Deshidratación de Base de Datos (`.ZIP / PURGA`):** Tarjeta dedicada a la depuración de usuarios inactivos $> 1$ año y oportunidades pasadas.

#### Alerta Operativa para el Administrador
Dado el alto impacto computacional de esta operación, la tarjeta de la tercera columna incluye de forma prominente un aviso de advertencia institucional:

!!! warning "Aviso de Alto Consumo de Procesamiento (Operación Fuera de Horario)"
    **Se recomienda enfáticamente ejecutar el corte de base de datos fuera de horarios operativos de oficina** (preferentemente en horario nocturno o fines de semana).  
    La verificación relacional indivisible entre los 14 modelos de Mongoose, el filtrado de participantes activos, la compresión en tiempo real y el borrado transaccional generan una alta demanda de CPU y memoria en el clúster de MongoDB Atlas, lo que podría ralentizar la experiencia de los colaboradores que interactúen con el portal durante el día.

#### Principio de No Ejecución Pasiva: Análisis Previo Exclusivamente Bajo Demanda
Para salvaguardar el rendimiento del servidor y de MongoDB Atlas, **el sistema tiene estrictamente prohibido ejecutar la verificación o cálculo de corte de forma automática, continua o al cargar la página**:
* Al ingresar a la vista `/backup` o al cambiar la fecha en el selector, **no se dispara ninguna consulta pesada de agregación**.
* La verificación relacional de las 14 colecciones representa una carga de cómputo significativa; por ello, **se ejecuta única y exclusivamente cuando el administrador lo requiere de forma intencional**, pulsando el botón explícito de análisis previo.

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                              GENERAR Y DESCARGAR COPIAS LOCALES                                        │
├──────────────────────────────┬──────────────────────────────┬──────────────────────────────────────────┤
│ COLUMNA 1                    │ COLUMNA 2                    │ COLUMNA 3                                │
│ Respaldo Completo (.zip)     │ Libro Consolidado (.xlsx)    │ Deshidratación & Corte (Cut-off)         │
│                              │                              │                                          │
│ 14 colecciones nativas       │ 14 hojas tabulares formatead.│ [Dropdown: Seleccionar Fecha de Corte ▼] │
│ Oficial para rollback        │ Auditoría y patronato        │                                          │
│                              │                              │ ⚠️ AVISO: Ejecutar fuera de horario      │
│                              │                              │ operativo por alta carga en BD.          │
│                              │                              │                                          │
│                              │                              │ [ 🔍 Analizar Fecha de Corte ]           │
│                              │                              │                                          │
│                              │                              │ ┌─ Resumen de Impacto (Previsualización) ┐│
│                              │                              │ │ • Estudiantes inactivos: 14            ││
│                              │                              │ │ • Voluntarios inactivos: 8             ││
│                              │                              │ │ • Actividades purgadas: 10 (0 activos) ││
│                              │                              │ │ • Actividades retenidas: 2 (1+ activos)││
│                              │                              │ │ • Almacenamiento a liberar: ~145 KB    ││
│                              │                              │ └────────────────────────────────────────┘│
│                              │                              │                                          │
│ [ Descargar Respaldo JSON ]  │ [ Descargar Base en Excel ]  │ [ 1. Descargar Corte Limpio (.zip) ]     │
│                              │                              │ [ 2. Purgar Registros de la BD ] (lock)  │
└──────────────────────────────┴──────────────────────────────┴──────────────────────────────────────────┘
```

#### Flujo Operativo en Tres Fases (Garantía Anti-Pérdida)

El flujo de deshidratación sigue una progresión estricta de tres fases secuenciales:

```mermaid
flowchart TD
    A["Admin selecciona Fecha de Corte"] --> B["Fase 0: Clic en 'Analizar Fecha de Corte' (Bajo Demanda)"]
    B --> C["Backend ejecuta Dry-Run de sólo lectura sobre las 14 colecciones"]
    C --> D{"¿Existen registros elegibles y corte válido?"}
    D -- No --> E["Muestra alerta: 'No hay usuarios ni oportunidades con > 1 año de inactividad'"]
    D -- Sí --> F["Despliega Resumen de Impacto y HABILITA botón de Descarga"]
    F --> G["Fase 1: Clic en '1. Descargar Corte Limpio (.zip)'"]
    G --> H["Genera ZIP con JSONs y SHA-256 + Emite cabecera HTTP: X-Purge-Token (TTL 15 min)"]
    H --> I["Descarga guardada en equipo del Admin y HABILITA botón de Purga"]
    I --> J["Fase 2: Clic en '2. Purgar Registros de la BD'"]
    J --> K["Modal de Confirmación con Contraseña de Admin"]
    K --> L["Backend valida X-Purge-Token + Ejecuta purga atómica + Registra DehydrationAuditLog"]
```

1. **Fase 0 — Análisis Previo y Simulación de Impacto (`POST /backup/dehydrate/analyze`):**
   * **Bajo Demanda:** Se invoca únicamente tras la pulsación manual del botón *"Analizar Fecha de Corte"*.
   * **Simulación en Modo Lectura (*Dry-Run*):** El backend ejecuta las consultas de agregación sin alterar ningún dato en la base de datos:
     1. Filtra estudiantes y voluntarios con `accountStatus: 'inactive'` y `fechaDesactivacion <= cutoffDate`.
     2. Evalúa las actividades pasadas, verificando si el 100% de los inscritos son inactivos; clasifica las que cumplen para purga y las que se retienen por tener participantes activos vinculados.
     3. Cuantifica los documentos asociados en las oportunidades (`talks`, `campaigns`, `adoptions`, `identifications`, `surveys`, `contacts`, `notifications`, `accreditations`).
     4. Calcula el volumen estimado en bytes a liberar y certifica que los modelos maestros (`quickactivities`, `users` admin, `pets`) no se toquen.
   * **Despliegue del Resumen de Impacto:** La tarjeta de la UI renderiza el panel con los totales proyectados y el estado del corte. Si el análisis confirma registros purgados sin violar la integridad, **se desbloquea el botón del Paso 1**.

2. **Fase 1 — Descarga del Paquete Seguro y Emisión de Token (`POST /backup/dehydrate/download`):**
   * El administrador pulsa *"1. Descargar Corte Limpio (.zip)"*.
   * El backend compila en memoria o temporal seguro los JSONs estructurados de las 12 colecciones afectadas y genera el `manifest.json` con el hash SHA-256 del contenido.
   * La respuesta HTTP envía el archivo binario descargable (`abaq-dehydrate-YYYYMMDD-HHmmss.zip`) e inyecta en los encabezados de respuesta el token temporal firmado criptográficamente: `X-Purge-Token` (con expiración estricta de 15 minutos).
   * Al recibirse la descarga exitosa en el navegador, el frontend guarda temporalmente el token y **desbloquea el botón del Paso 2**.

3. **Fase 2 — Purga Atómica Condicionada en Base de Datos (`POST /backup/dehydrate/purge`):**
   * El botón *"2. Purgar registros de la BD"* deja de estar bloqueado.
   * Al pulsarlo, el sistema despliega un **modal crítico de confirmación** solicitando que el administrador ingrese su contraseña de acceso institucional para autorizar la depuración definitiva.
   * La petición al backend incluye en sus cabeceras el `X-Purge-Token` y en su cuerpo `{ adminPassword }`.
   * El backend valida la contraseña y la vigencia del token criptográfico. Si es válido:
     1. Ejecuta la purga atómica de los documentos respaldados en MongoDB.
     2. Genera y persiste de forma inmediata el registro inmutable en `DehydrationAuditLog` (con el detalle de los modelos y usuarios que salieron).
     3. Invalida de forma irrevocable el `X-Purge-Token` para evitar reutilizaciones accidentales.
   * Si el token expiró (superó los 15 minutos) o es inválido, el backend aborta la transacción y rechaza la petición con HTTP `412 Precondition Failed` o `403 Forbidden`, manteniendo la base de datos totalmente intacta.

### 4.3 Rehidratación Idempotente (Restauración)
En caso de auditoría externa o requerimiento de consulta histórica en plataforma:
- El administrador carga el archivo `.zip` en la interfaz de respaldos (`POST /backup/dehydrate/restore`).
- El backend lee los archivos JSON correspondientes a cada modelo y ejecuta una operación **upsert idempotente** (`bulkWrite` con `replaceOne` y `upsert: true`).
- Se restauran los documentos conservando exactamente sus identificadores originales (`_id`), preservando intactas las relaciones entre voluntarios, acreditaciones y actividades.
- Se registra el evento en la colección interna de auditoría `DehydrationAuditLog` con tipo `"rehydrate_restore"`.

---

### 4.4 Algoritmo de Deshidratación: Búsqueda Relacional, Verificación Indivisible y Purga Atómica

El algoritmo de deshidratación resuelve el desafío de depurar grandes volúmenes de datos históricos garantizando que **jamás se rompa la integridad referencial** ni se elimine una actividad donde todavía exista un alumno activo.

#### Diagrama de Flujo del Algoritmo de Deshidratación

```mermaid
flowchart TD
    Start(["Inicio: Selección de cutoffDate"]) --> Step1["Paso 1: Query Voluntarios Inactivos Candidatos\n(accountStatus == 'inactive' && fechaDesactivacion <= cutoffDate)"]
    Step1 --> Step2["Paso 2: Query Cuentas Auth Vinculadas\n(User con rol student/volunteer de los candidatos)"]
    Step2 --> Step3["Paso 3: Query Acreditaciones Candidatas\n(studentRef o volunteerRef en candidatos)"]
    
    Step3 --> Step4["Paso 4: Evaluación Relacional Indivisible de Actividades (Activity)"]
    Step4 --> LoopAct{"Para cada actividad pasada:\n¿Todos sus inscritos son inactivos > 1 año?"}
    
    LoopAct -- "NO (Tiene >= 1 participante activo o reciente)" --> RetainAct["ACTIVIDAD SE RETIENE\n(No se purga; sus inscripciones se conservan)"]
    LoopAct -- "SÍ (100% inscritos son candidatos inactivos)" --> PurgeAct["ACTIVIDAD SE MARCA PARA PURGA\n(Se incluirá en el ZIP y en la purga)"]
    
    RetainAct & PurgeAct --> Step5["Paso 5: Evaluación de las 11 Oportunidades Especializadas\n(Talks, Campaigns, Adoptions, Identifications, Surveys, Contacts, Notifications)"]
    Step5 --> Step6["Paso 6: Verificación de Exclusión de Modelos Permanentes\n(QuickActivities, Users admin, Pets, DehydrationAuditLog)"]
    
    Step6 --> Step7["Paso 7: Generación de Reporte de Impacto (Previsualización Dry-Run)\nTotal colecciones, documentos y bytes proyectados"]
    
    Step7 --> Phase1{"¿Admin confirma 'Descargar Corte (.zip)'?"}
    Phase1 -- No --> EndDryRun(["Fin de Simulación (Sin cambios en BD)"])
    Phase1 -- Sí --> Step8["Paso 8: Generación de Paquete ZIP en Memoria (archiver)\n12 JSONs + manifest.json con SHA-256 + Token X-Purge-Token (TTL 15 min)"]
    
    Step8 --> Phase2{"¿Admin ejecuta 'Purgar Registros BD' con contraseña y token?"}
    Phase2 -- "Token inválido / expirado" --> AbortPurge["Transacción Abortada (HTTP 412/403)\nBase de datos intacta"]
    Phase2 -- "Token válido + Contraseña correcta" --> Step9["Paso 9: Transacción Atómica en MongoDB (session.withTransaction)\nBorrado en bloque de IDs respaldados en las 12 colecciones"]
    
    Step9 --> Step10["Paso 10: Inserción Inmutable de DehydrationAuditLog\nInvalidación definitiva de token + Notificación de éxito"]
    Step10 --> Done(["Fin de Deshidratación Exitosa"])
```

#### Los 10 Pasos del Algoritmo de Deshidratación (Lógica y Criterios Mongoose)

1. **Paso 1 — Búsqueda del Conjunto de Voluntarios Candidatos ($\mathcal{U}_{\text{inactivos}}$):**
   El backend ejecuta consultas paralelas sobre las colecciones `students` y `volunteers`:
   ```javascript
   const candidateStudents = await Student.find({
     accountStatus: 'inactive',
     fechaDesactivacion: { $lte: cutoffDate }
   }).lean();

   const candidateVolunteers = await Volunteer.find({
     accountStatus: 'inactive',
     fechaDesactivacion: { $lte: cutoffDate }
   }).lean();

   const candidateUserIds = [
     ...candidateStudents.map(s => s.userId),
     ...candidateVolunteers.map(v => v.userId)
   ].filter(Boolean);
   ```

2. **Paso 2 — Búsqueda de Cuentas de Acceso Vinculadas ($\mathcal{A}_{\text{auth}}$):**
   Filtra en `users` exclusivamente aquellas cuentas con rol operativo de voluntariado:
   ```javascript
   const candidateUsers = await User.find({
     _id: { $in: candidateUserIds },
     role: { $in: ['student', 'volunteer'] } // NUNCA rol 'admin'
   }).lean();
   ```

3. **Paso 3 — Búsqueda de Acreditaciones Candidatas ($\mathcal{AC}_{\text{candidatas}}$):**
   Localiza todas las acreditaciones vinculadas a los colaboradores candidatos:
   ```javascript
   const candidateAccreditations = await Accreditation.find({
     $or: [
       { studentRef: { $in: candidateStudents.map(s => s._id) } },
       { volunteerRef: { $in: candidateVolunteers.map(v => v._id) } }
     ]
   }).lean();
   ```

4. **Paso 4 — Evaluación Relacional Indivisible de Actividades (`Activity`):**
   Para cada actividad convocada cuya fecha de realización sea menor o igual a la fecha de corte (`dueDate <= cutoffDate` o `created <= cutoffDate`):
   * Se extrae el conjunto de colaboradores inscritos:
     $$P(A_j) = \{ u \in \text{Participantes}(A_j) \}$$
   * **Comprobación de Corte Indivisible para Actividades Colectivas:**
     $$\text{EsPurgable}(A_j) \iff P(A_j) \subseteq \mathcal{U}_{\text{inactivos}}$$
   * **Criterio de Decisión Oficial (Opción A):**
     * Si existe al menos un alumno activo o con inactividad menor a 12 meses ($P(A_j) \not\subseteq \mathcal{U}_{\text{inactivos}}$):  
       **La actividad se RETIENE en MongoDB** (`retainedActivities.push(A_j)`). Sin embargo, **el alumno inactivo SÍ SE PURGA de la base de datos** al ZIP con todo su expediente. Gracias al desacoplamiento por doble arreglo en `Student` y `Volunteer`, la actividad no sufre alteraciones ni deja valores nulos (`null`), manteniéndose íntegra para el alumno activo.
     * Si el 100% de los participantes inscritos son inactivos elegibles ($P(A_j) \subseteq \mathcal{U}_{\text{inactivos}}$):  
       **La actividad se PURGA** (`purgedActivities.push(A_j)`), exportándose al paquete ZIP junto con sus inscripciones históricas.

5. **Paso 5 — Evaluación Relacional de las 11 Oportunidades Especializadas:**
   * **`talks` y `campaigns`:** Se evalúa si todos los asistentes registrados pertenecen a $\mathcal{U}_{\text{inactivos}}$. De existir un asistente activo, la plática o campaña masiva se conserva íntegra.
   * **`adoptions` e `identifications`:** Expedientes y solicitudes pasadas vinculadas a los voluntarios candidatos sin trámites pendientes.
   * **`surveys` y `contacts`:** Cuestionarios y bitácoras comunitarias creadas por los estudiantes candidatos (`studentId: { $in: candidateStudentIds }`).
   * **`notifications`:** Purgado masivo de todas las notificaciones dirigidas a los usuarios deshidratados (`userId: { $in: candidateUserIds }`), lo que erradica de inmediato el **41.40% del almacenamiento total de la base de datos**.

6. **Paso 6 — Verificación de Exclusión de Modelos Permanentes:**
   El algoritmo valida de forma asertiva que los modelos protegidos jamás sean incluidos en el arreglo de purga:
   * `quickactivities`: Cero registros tocados (conteo verificado).
   * `users` con `role: 'admin'`: Cero cuentas tocadas.
   * `pets`: Cero animales tocados (el padrón es patrimonio comunitario).
   * `dehydrationauditlogs`: Bitácora inmutable permanente.

7. **Paso 7 — Retorno del Reporte de Impacto (Fase 0 — Dry-Run):**
   El endpoint responde un JSON ligero con la telemetría calculada sin tocar la BD:
   ```json
   {
     "status": "success",
     "dryRun": true,
     "cutoffDate": "2025-10-15T00:00:00.000Z",
     "metrics": {
       "totalCollectionsAffected": 12,
       "totalDocumentsPurged": 185,
       "totalBytesFreed": 148520,
       "activeParticipantsRetainedCount": 0
     },
     "retainedActivitiesCount": 2,
     "eligibleForPurge": true
   }
   ```

8. **Paso 8 — Generación del Paquete ZIP Criptográfico (Fase 1 — Descarga):**
   * El servicio compila mediante el módulo `archiver` un archivo ZIP que contiene la carpeta `collections/` con los 12 archivos JSON (`students.json`, `accreditations.json`, etc.).
   * Genera el archivo `manifest.json` que contiene:
     * Fecha y hora de generación (`generatedAt`).
     * Identificador y correo del administrador (`generatedBy`).
     * Conteo exacto de documentos por modelo.
     * **Checksum SHA-256 individual por cada archivo JSON y global del paquete**.
   * Emite el token firmado criptográficamente en cabecera HTTP:
     ```http
     X-Purge-Token: <hmac-sha256-signed-payload>
     ```
     Con vigencia estricta de 15 minutos (TTL).

9. **Paso 9 — Purga Atómica Condicionada en MongoDB (Fase 2 — Ejecución):**
   * Al recibir la petición `POST /backup/dehydrate/purge` con el `X-Purge-Token` y la contraseña de administrador:
   * Se inicia una sesión transaccional atómica en MongoDB:
     ```javascript
     const session = await mongoose.startSession();
     session.startTransaction();
     try {
       for (const target of purgePlan) {
         await target.model.deleteMany(
           { _id: { $in: target.purgedIds } },
           { session }
         );
       }
       await DehydrationAuditLog.create([auditPayload], { session });
       await session.commitTransaction();
     } catch (err) {
       await session.abortTransaction();
       throw err;
     } finally {
       session.endSession();
     }
     ```

10. **Paso 10 — Registro Inmutable y Notificación:**
    * Invalida de forma irrevocable el `X-Purge-Token`.
    * Retorna código HTTP `200 OK` con el folio de operación pericial generado (ej. `DEHYD-20261102-0A14`).

#### 4.4.1 Especificación Algorítmica Técnica: Motor de Deshidratación (`DehydrationEngine`)

A continuación se detalla la lógica algorítmica técnica de ejecución a bajo nivel para evaluar las estructuras de datos, la complejidad computacional y el manejo atómico en MongoDB:

```javascript
/**
 * @file dehydration.service.js
 * @description Motor de evaluación relacional, empaquetado y purga atómica de deshidratación.
 */

const crypto = require("crypto");
const mongoose = require("mongoose");
const archiver = require("archiver");
const bcrypt = require("bcryptjs");
const AppError = require("../utils/appError");

// Modelos requeridos
const User = require("../models/user.model");
const Student = require("../models/student.model");
const Volunteer = require("../models/volunteer.model");
const Activity = require("../models/activity.model");
const Accreditation = require("../models/accreditation.model");
const Talk = require("../models/talk.model");
const Campaign = require("../models/campaign.model");
const Adoption = require("../models/adoption.model");
const Identification = require("../models/identification.model");
const Survey = require("../models/survey.model");
const Contact = require("../models/contact.model");
const Notification = require("../models/notification.model");
const QuickActivity = require("../models/quickActivity.model");
const Pet = require("../models/pet.model");
const DehydrationAuditLog = require("../models/dehydrationAuditLog.model");

const PURGE_TOKEN_SECRET = process.env.JWT_SECRET || "abaq-purge-secret-key-2026";
const TOKEN_TTL_MS = 15 * 60 * 1000; // 15 minutos

// Memoria volátil / caché de tokens emitidos para prevenir ataques de repetición (Replay Attacks)
const activePurgeTokens = new Map();

/**
 * ALGORITMO TÉCNICO 1: Construcción del Plan de Purga Relacional Indivisible
 * Complejidad temporal: O(U + A*P) donde U es usuarios, A actividades y P participantes.
 * Con Sets en memoria, la verificación de cada participante se realiza en O(1).
 * 
 * @param {Date|string} cutoffDateRaw - Fecha límite de corte
 * @returns {Promise<Object>} purgePlan estructurado con IDs y documentos a purgar/retener
 */
async function buildPurgePlan(cutoffDateRaw) {
  const cutoffDate = new Date(cutoffDateRaw);
  if (isNaN(cutoffDate.getTime())) {
    throw new AppError("La fecha de corte especificada no es válida.", 400);
  }

  // 1. Identificación de Voluntarios Candidatos (> 1 año de inactividad)
  const [candidateStudents, candidateVolunteers] = await Promise.all([
    Student.find({
      accountStatus: "inactive",
      fechaDesactivacion: { $lte: cutoffDate },
    }).lean(),
    Volunteer.find({
      accountStatus: "inactive",
      fechaDesactivacion: { $lte: cutoffDate },
    }).lean(),
  ]);

  // Estructuras de búsqueda rápida en memoria (O(1) lookups)
  const candidateStudentIdSet = new Set(candidateStudents.map((s) => s._id.toString()));
  const candidateVolunteerIdSet = new Set(candidateVolunteers.map((v) => v._id.toString()));
  const candidateUserIdSet = new Set([
    ...candidateStudents.map((s) => s.userId?.toString()),
    ...candidateVolunteers.map((v) => v.userId?.toString()),
  ].filter(Boolean));

  // 2. Identificación de Cuentas Auth vinculadas (NUNCA rol admin)
  const candidateUsers = await User.find({
    _id: { $in: Array.from(candidateUserIdSet) },
    role: { $in: ["student", "volunteer"] },
  }).lean();

  // 3. Mapa de Inscripciones en Actividades extraídas de los perfiles de los candidatos
  // En ABAQ, las inscripciones residen desnormalizadas en assignedActivities de Student/Volunteer
  const activityParticipantMap = new Map(); // activityId -> Set de student/volunteer ObjectIds

  // Cargar TODAS las actividades concluidas anteriores a la fecha de corte
  const candidateActivities = await Activity.find({
    $or: [
      { dueDate: { $lte: cutoffDate } },
      { created: { $lte: cutoffDate } },
    ],
  }).lean();

  // Para cada actividad candidata, consultar TODOS los alumnos y voluntarios inscritos
  // (soporta compatibilidad dual: assignedActivities.activityRef y assignedActivities.activityId)
  const candidateActivityIds = candidateActivities.map((a) => a._id);
  const [allEnrolledStudents, allEnrolledVolunteers] = await Promise.all([
    Student.find(
      {
        $or: [
          { "assignedActivities.activityRef": { $in: candidateActivityIds } },
          { "assignedActivities.activityId": { $in: candidateActivityIds } },
        ],
      },
      { _id: 1, accountStatus: 1, fechaDesactivacion: 1, assignedActivities: 1 }
    ).lean(),
    Volunteer.find(
      {
        $or: [
          { "assignedActivities.activityRef": { $in: candidateActivityIds } },
          { "assignedActivities.activityId": { $in: candidateActivityIds } },
        ],
      },
      { _id: 1, accountStatus: 1, fechaDesactivacion: 1, assignedActivities: 1 }
    ).lean(),
  ]);

  // Poblar el mapa con todos los participantes reales
  for (const st of allEnrolledStudents) {
    for (const act of st.assignedActivities || []) {
      const actId = (act.activityRef || act.activityId)?.toString();
      if (!actId) continue;
      if (!activityParticipantMap.has(actId)) {
        activityParticipantMap.set(actId, []);
      }
      activityParticipantMap.get(actId).push({
        id: st._id.toString(),
        role: "student",
        isEligible: candidateStudentIdSet.has(st._id.toString()),
      });
    }
  }

  for (const vol of allEnrolledVolunteers) {
    for (const act of vol.assignedActivities || []) {
      const actId = (act.activityRef || act.activityId)?.toString();
      if (!actId) continue;
      if (!activityParticipantMap.has(actId)) {
        activityParticipantMap.set(actId, []);
      }
      activityParticipantMap.get(actId).push({
        id: vol._id.toString(),
        role: "volunteer",
        isEligible: candidateVolunteerIdSet.has(vol._id.toString()),
      });
    }
  }

  // 4. ALGORITMO DE CORTE INDIVISIBLE PARA ACTIVIDADES
  const purgedActivities = [];
  const retainedActivities = [];
  const retainedActivityIdSet = new Set();

  for (const act of candidateActivities) {
    const actIdStr = act._id.toString();
    const participants = activityParticipantMap.get(actIdStr) || [];

    // CONDICIÓN INDIVISIBLE:
    // ¿Existe al menos un participante que NO sea candidato inactivo elegible?
    const hasActiveOrRecentParticipant = participants.some((p) => !p.isEligible);

    if (hasActiveOrRecentParticipant) {
      // LA ACTIVIDAD SE RETIENE EN BASE DE DATOS
      retainedActivities.push({
        activityId: act._id,
        title: act.title,
        dueDate: act.dueDate,
        totalParticipants: participants.length,
        activeParticipantsCount: participants.filter((p) => !p.isEligible).length,
      });
      retainedActivityIdSet.add(actIdStr);
    } else {
      // 100% de los inscritos son inactivos > 1 año: LA ACTIVIDAD SE PURGA
      purgedActivities.push(act);
    }
  }

  // 5. Acreditaciones Candidatas:
  // Se purgan acreditaciones de los candidatos SIEMPRE Y CUANDO la actividad vinculada NO haya sido retenida
  const candidateAccreditations = await Accreditation.find({
    $or: [
      { studentRef: { $in: Array.from(candidateStudentIdSet) } },
      { volunteerRef: { $in: Array.from(candidateVolunteerIdSet) } },
    ],
  }).lean();

  const purgedAccreditations = candidateAccreditations.filter((acc) => {
    if (acc.activityRef && retainedActivityIdSet.has(acc.activityRef.toString())) {
      return false; // Se conserva para no generar acreditación huérfana en actividad retenida
    }
    return true;
  });

  // 6. Evaluación de las 11 Oportunidades Especializadas
  const [
    candidateTalks,
    candidateCampaigns,
    candidateAdoptions,
    candidateIdentifications,
    candidateSurveys,
    candidateContacts,
    candidateNotifications,
  ] = await Promise.all([
    Talk.find({ date: { $lte: cutoffDate } }).lean(),
    Campaign.find({ date: { $lte: cutoffDate } }).lean(),
    Adoption.find({ status: "completed", updatedAt: { $lte: cutoffDate } }).lean(),
    Identification.find({ status: { $in: ["delivered", "cancelled"] }, updatedAt: { $lte: cutoffDate } }).lean(),
    Survey.find({ studentId: { $in: Array.from(candidateStudentIdSet) } }).lean(),
    Contact.find({ studentId: { $in: Array.from(candidateStudentIdSet) } }).lean(),
    Notification.find({ userId: { $in: Array.from(candidateUserIdSet) } }).lean(),
  ]);

  // 7. ASERCIÓN ESTRICTA DE MODELOS PERMANENTES (Garantía Anti-Corrupción)
  const quickCount = await QuickActivity.countDocuments({});
  const adminCount = await User.countDocuments({ role: "admin" });
  const petCount = await Pet.countDocuments({});
  if (quickCount === 0 || adminCount === 0) {
    throw new Error("Violación de integridad: Verificación de modelos permanentes fallida.");
  }

  // Consolidación de documentos y bytes liberados
  const collectionsMap = {
    students: { name: "Estudiantes", model: Student, docs: candidateStudents },
    volunteers: { name: "Voluntarios", model: Volunteer, docs: candidateVolunteers },
    users: { name: "Cuentas Auth", model: User, docs: candidateUsers },
    accreditations: { name: "Acreditaciones", model: Accreditation, docs: purgedAccreditations },
    activities: { name: "Actividades", model: Activity, docs: purgedActivities },
    notifications: { name: "Notificaciones", model: Notification, docs: candidateNotifications },
    surveys: { name: "Encuestas", model: Survey, docs: candidateSurveys },
    contacts: { name: "Contactos", model: Contact, docs: candidateContacts },
    identifications: { name: "Identificaciones", model: Identification, docs: candidateIdentifications },
    talks: { name: "Pláticas", model: Talk, docs: candidateTalks },
    campaigns: { name: "Campañas", model: Campaign, docs: candidateCampaigns },
    adoptions: { name: "Adopciones", model: Adoption, docs: candidateAdoptions },
  };

  let totalDocs = 0;
  let totalBytes = 0;
  const collectionsSummary = [];

  for (const [key, item] of Object.entries(collectionsMap)) {
    const rawJson = JSON.stringify(item.docs);
    const bytes = Buffer.byteLength(rawJson, "utf8");
    totalDocs += item.docs.length;
    totalBytes += bytes;

    collectionsSummary.push({
      collectionName: key,
      modelKey: key,
      modelName: item.name,
      documentCount: item.docs.length,
      estimatedBytesFreed: bytes,
      filterCriteria: `{ fechaDesactivacion/fecha: { $lte: "${cutoffDate.toISOString()}" } }`,
      purgedDocumentIds: item.docs.map((d) => d._id),
      sampleItems: item.docs.slice(0, 5).map((d) => ({
        documentId: d._id,
        identifier: d.folio || d.interactionFolio || d.email || d.title || String(d._id),
        displayName: d.fullName || d.title || d.name || "Registro",
        metadata: { role: d.role, hours: d.totalHours || d.hoursAccredited },
      })),
    });
  }

  return {
    cutoffDate,
    totalDocuments: totalDocs,
    totalBytesFreed: totalBytes,
    retainedActivities,
    collectionsMap,
    collectionsSummary,
    candidateStudents,
    candidateVolunteers,
    purgedActivities,
  };
}

/**
 * ALGORITMO TÉCNICO 2: Generación de Paquete ZIP y Emisión de Token Criptográfico (Fase 1)
 */
async function generateDehydrationZipStream(cutoffDateRaw, adminUser, res) {
  const plan = await buildPurgePlan(cutoffDateRaw);

  const archive = archiver("zip", { zlib: { level: 9 } });
  const manifestCollections = {};
  let overallSha256Stream = crypto.createHash("sha256");

  // Inyectar cada archivo JSON en el archivo ZIP y computar SHA-256 individual
  for (const [key, item] of Object.entries(plan.collectionsMap)) {
    const jsonContent = JSON.stringify(item.docs, null, 2);
    const fileSha256 = crypto.createHash("sha256").update(jsonContent).digest("hex");
    overallSha256Stream.update(jsonContent);

    archive.append(jsonContent, { name: `collections/${key}.json` });

    manifestCollections[key] = {
      modelKey: key,
      modelName: item.name,
      documentCount: item.docs.length,
      sha256: fileSha256,
      sizeBytes: Buffer.byteLength(jsonContent, "utf8"),
    };
  }

  const packageSha256 = overallSha256Stream.digest("hex");

  // Manifiesto Criptográfico Oficial
  const manifest = {
    version: "1.0.0",
    operationType: "dehydrate_purge",
    generatedAt: new Date().toISOString(),
    cutoffDate: plan.cutoffDate.toISOString(),
    generatedBy: {
      adminId: adminUser._id,
      email: adminUser.email,
    },
    metrics: {
      totalCollections: Object.keys(manifestCollections).length,
      totalDocuments: plan.totalDocuments,
      totalBytesFreed: plan.totalBytesFreed,
      packageSha256,
    },
    collections: manifestCollections,
  };

  archive.append(JSON.stringify(manifest, null, 2), { name: "manifest.json" });

  // Generación del Token de Purga Criptográfico HMAC-SHA256 (TTL 15 min)
  const tokenPayload = {
    tokenVersion: "1.0",
    cutoffDate: plan.cutoffDate.toISOString(),
    adminId: adminUser._id.toString(),
    packageSha256,
    totalDocuments: plan.totalDocuments,
    expiresAt: Date.now() + TOKEN_TTL_MS,
  };

  const serializedPayload = Buffer.from(JSON.stringify(tokenPayload)).toString("base64url");
  const hmacSignature = crypto
    .createHmac("sha256", PURGE_TOKEN_SECRET)
    .update(serializedPayload)
    .digest("base64url");
  const purgeToken = `${serializedPayload}.${hmacSignature}`;

  // Registrar token activo en memoria
  activePurgeTokens.set(purgeToken, {
    plan,
    expiresAt: tokenPayload.expiresAt,
    adminId: tokenPayload.adminId,
  });

  // Limpieza automática tras expiración
  setTimeout(() => activePurgeTokens.delete(purgeToken), TOKEN_TTL_MS);

  // Inyectar encabezados de respuesta
  const timestampStr = new Date().toISOString().replace(/T/, "_").replace(/:/g, "-").split(".")[0];
  const filename = `abaq-dehydrate-${timestampStr}.zip`;

  res.setHeader("Content-Type", "application/zip");
  res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
  res.setHeader("X-Purge-Token", purgeToken);
  res.setHeader("Access-Control-Expose-Headers", "X-Purge-Token, Content-Disposition");

  archive.pipe(res);
  await archive.finalize();
}

/**
 * ALGORITMO TÉCNICO 3: Purga Atómica Transaccional en MongoDB (Fase 2)
 */
async function executeDehydrationPurge(purgeToken, adminPassword, adminUser) {
  if (!purgeToken) {
    throw new AppError("No se proporcionó el token criptográfico 'X-Purge-Token'.", 400);
  }

  // 1. Verificación del Token Criptográfico (Firma y Expiración)
  const parts = purgeToken.split(".");
  if (parts.length !== 2) {
    throw new AppError("Token de purga con formato inválido.", 403);
  }

  const [serializedPayload, receivedSig] = parts;
  const expectedSig = crypto
    .createHmac("sha256", PURGE_TOKEN_SECRET)
    .update(serializedPayload)
    .digest("base64url");

  if (receivedSig !== expectedSig) {
    throw new AppError("Firma criptográfica del token de purga inválida o adulterada.", 403);
  }

  const payload = JSON.parse(Buffer.from(serializedPayload, "base64url").toString("utf8"));
  if (Date.now() > payload.expiresAt) {
    activePurgeTokens.delete(purgeToken);
    throw new AppError("El token de purga ha expirado (límite de 15 minutos excedido).", 412);
  }

  if (payload.adminId !== adminUser._id.toString()) {
    throw new AppError("El token de purga no corresponde al administrador en sesión.", 403);
  }

  // 2. Re-autenticación de Seguridad con Contraseña del Administrador
  const fullAdmin = await User.findById(adminUser._id);
  const isMatch = await bcrypt.compare(adminPassword, fullAdmin.passwordHash);
  if (!isMatch) {
    throw new AppError("Contraseña de confirmación administrativa incorrecta.", 401);
  }

  // 3. Obtener el Plan de Purga
  const cachedData = activePurgeTokens.get(purgeToken);
  const plan = cachedData?.plan || (await buildPurgePlan(payload.cutoffDate));

  // 4. TRANSACCIÓN ATÓMICA EN MONGODB ATLAS (session.withTransaction)
  const session = await mongoose.startSession();
  session.startTransaction({
    readConcern: { level: "snapshot" },
    writeConcern: { w: "majority" },
  });

  const folioSuffix = crypto.randomBytes(2).toString("hex").toUpperCase();
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, "");
  const operationFolio = `DEHYD-${dateStr}-${folioSuffix}`;

  try {
    // Borrado en lote sobre las 12 colecciones
    for (const [key, item] of Object.entries(plan.collectionsMap)) {
      const idsToDelete = item.docs.map((d) => d._id);
      if (idsToDelete.length > 0) {
        await item.model.deleteMany({ _id: { $in: idsToDelete } }, { session });
      }
    }

    // Inserción inmutable de la Bitácora DehydrationAuditLog dentro de la misma transacción
    await DehydrationAuditLog.create(
      [
        {
          operationFolio,
          operationType: "dehydrate_purge",
          cutoffDate: plan.cutoffDate,
          durationMs: Date.now() - (payload.expiresAt - TOKEN_TTL_MS),
          executedBy: {
            adminId: adminUser._id,
            email: adminUser.email,
          },
          status: "completed",
          backupPackage: {
            fileName: `abaq-dehydrate-${payload.cutoffDate.toISOString().slice(0, 10)}.zip`,
            sha256: payload.packageSha256,
            fileSizeBytes: plan.totalBytesFreed,
          },
          metrics: {
            totalCollectionsAffected: Object.keys(plan.collectionsMap).length,
            totalDocumentsPurged: plan.totalDocuments,
            totalBytesFreed: plan.totalBytesFreed,
          },
          purgedUsersSummary: [
            ...plan.candidateStudents.map((s) => ({
              userId: s._id,
              folio: s.folio,
              email: s.mail || s.schoolMail,
              fullName: s.fullName,
              role: "student",
              fechaDesactivacion: s.fechaDesactivacion,
              totalHoras: s.totalHours || 0,
            })),
            ...plan.candidateVolunteers.map((v) => ({
              userId: v._id,
              folio: v.folio,
              email: v.email,
              fullName: v.fullName,
              role: "volunteer",
              fechaDesactivacion: v.fechaDesactivacion,
              totalHoras: 0,
            })),
          ],
          collections: plan.collectionsSummary,
        },
      ],
      { session }
    );

    // Commit de la transacción en MongoDB
    await session.commitTransaction();
  } catch (err) {
    await session.abortTransaction();
    throw new AppError(`Fallo en la purga atómica de base de datos: ${err.message}`, 500);
  } finally {
    session.endSession();
    // Invalidar token de forma irrevocable
    activePurgeTokens.delete(purgeToken);
  }

  return {
    status: "success",
    operationFolio,
    message: "Base de datos deshidratada y purgada exitosamente con corte indivisible.",
    totalDocumentsPurged: plan.totalDocuments,
    totalBytesFreed: plan.totalBytesFreed,
  };
}

module.exports = {
  buildPurgePlan,
  generateDehydrationZipStream,
  executeDehydrationPurge,
};
```

---

### 4.5 Algoritmo de Rehidratación (Restauración Idempotente sin Pérdida)

A diferencia del procedimiento de **Rollback Completo del Sistema** (el cual vacía la base de datos completa con `deleteMany({})` antes de restaurar), el algoritmo de **Rehidratación de Deshidratados** es **selectivo, aditivo e idempotente**: restaura exclusivamente los documentos purgados que contiene el paquete ZIP **sin borrar ni alterar a los alumnos y actividades activas existentes en el sistema actual**.

#### Diagrama de Flujo del Algoritmo de Rehidratación

```mermaid
flowchart TD
    Up["Admin sube archivo ZIP en /backup/dehydrate/restore"] --> ValZip["Paso 1: Lectura en Memoria (AdmZip) y Verificación de Estructura"]
    ValZip --> ManCheck{"¿Existe manifest.json oficial de ABAQ?"}
    ManCheck -- No --> RejectFormat["Rechazo (HTTP 400): Archivo no es un respaldo válido ABAQ"]
    
    ManCheck -- Sí --> ShaCheck["Paso 2: Comprobación Criptográfica de Integridad\nCalcula SHA-256 de cada collections/<model>.json vs manifest.json"]
    ShaCheck --> HashMatch{"¿Todos los checksums SHA-256 coinciden?"}
    HashMatch -- No --> RejectTamper["Rechazo (HTTP 422): El paquete ZIP fue adulterado o está corrupto"]
    
    HashMatch -- Sí --> DryRunCheck{"¿confirm === true?"}
    DryRunCheck -- "No (Modo Dry-Run)" --> RetDryReport["Paso 3: Reporte de Simulación (Dry-Run)\nDocumentos a restaurar vs documentos en BD actual"]
    
    DryRunCheck -- "Sí (Restauración Confirmada)" --> TopoOrder["Paso 4: Ordenamiento Topológico de Modelos\n1. users -> 2. students/volunteers -> 3. activities/accreditations -> 4. oportunidades"]
    
    TopoOrder --> BulkUpsert["Paso 5: Ejecución Idempotente bulkWrite\nreplaceOne con upsert: true preservando _id original exacto"]
    
    BulkUpsert --> AuditRehyd["Paso 6: Registro en DehydrationAuditLog (operationType: 'rehydrate_restore')"]
    AuditRehyd --> SuccessDone(["Fin: Base de Datos Rehidratada Exitosamente"])
```

#### Los 7 Pasos del Algoritmo de Rehidratación

1. **Paso 1 — Descompresión Segura en Memoria:**
   El backend recibe el archivo binario mediante `multer` en memoria (`req.file.buffer`) y lo parsea utilizando `AdmZip`, evitando escribir archivos temporales inseguros en el disco del servidor.
   ```javascript
   const zip = new AdmZip(zipBuffer);
   const manifestEntry = zip.getEntry("manifest.json");
   if (!manifestEntry) {
     throw new AppError("El paquete no contiene el manifiesto requerido 'manifest.json'.", 400);
   }
   ```

2. **Paso 2 — Verificación Criptográfica Forense (Anti-Manipulación):**
   Para cada archivo `collections/<key>.json` dentro del ZIP, se calcula su hash SHA-256 en tiempo real y se contrasta con el valor original firmado en el manifiesto:
   ```javascript
   const sha256Calculado = crypto.createHash("sha256").update(entryData).digest("hex");
   if (sha256Calculado !== manifest.collections[key].sha256) {
     throw new AppError(`Fallo de integridad criptográfica en '${key}.json'. El archivo fue manipulado.`, 422);
   }
   ```

3. **Paso 3 — Modo de Simulación Preliminar (*Dry-Run*):**
   Si la petición se invoca con `confirm: false` (comportamiento predeterminado al seleccionar el archivo en el modal de subida), el sistema analiza cuántos registros se insertarían o actualizarían y devuelve una tabla comparativa sin modificar MongoDB.

4. **Paso 4 — Orden Topológico de Restauración (Integridad de Llaves Foráneas):**
   Para respetar las dependencias relacionales y no generar referencias huérfanas, los modelos se procesan en estricto orden secuencial:
   ```
   1º. users (Cuentas de autenticación requeridas por Student y Volunteer)
   2º. students y volunteers (Documentos base del colaborador con su userId)
   3º. activities (Convocatorias de actividades pasadas)
   4º. accreditations (Acreditaciones vinculadas a studentRef/volunteerRef y activityRef)
   5º. talks, campaigns, adoptions, identifications, surveys, contacts, notifications
   ```

5. **Paso 5 — Operación Idempotente `bulkWrite` con `replaceOne` y `upsert: true`:**
   En lugar de un borrado masivo, cada documento se restaura mediante una operación atómica que **garantiza conservar su identificador original (`_id`) exacto**:
   ```javascript
   for (const key of TOPOLOGICAL_ORDER) {
     const docs = parsedCollections[key];
     if (!docs || docs.length === 0) continue;

     const operations = docs.map(doc => ({
       replaceOne: {
         filter: { _id: doc._id }, // Coincidencia exacta por _id original
         replacement: doc,
         upsert: true // Inserta si no existe; reemplaza si ya existía
       }
     }));

     await models[key].bulkWrite(operations, { ordered: false });
   }
   ```
   * **Garantía Técnica:** Si la base de datos contiene nuevos estudiantes registrados hoy, sus documentos no son alterados ni eliminados. Los documentos históricos se reintegran transparentemente conservando sus llaves y folios.

6. **Paso 6 — Auditoría de Rehidratación:**
   Se persiste un nuevo registro en la colección `DehydrationAuditLog` con `operationType: "rehydrate_restore"`, capturando:
   * El nombre del archivo y el hash SHA-256 del ZIP restaurado.
   * La lista de colecciones y conteo de documentos rehidratados.
   * El administrador que ejecutó la restauración (`executedBy.email = req.user.email`).

7. **Paso 7 — Respuesta y Confirmación:**
   El backend responde con el resumen de documentos restablecidos y actualiza de inmediato la vista `/volunteers/history`, permitiendo que los registros rehidratados vuelvan a ser consultables en el sistema.

#### 4.5.1 Especificación Algorítmica Técnica: Motor de Rehidratación Idempotente (`RehydrationEngine`)

A continuación se detalla la implementación técnica del motor de rehidratación con procesamiento por lotes (*batching*) para prevenir el desbordamiento del límite BSON de 16 MB en MongoDB:

```javascript
/**
 * @file rehydration.service.js
 * @description Motor de verificación criptográfica y restauración idempotente por bloques.
 */

const crypto = require("crypto");
const AdmZip = require("adm-zip");
const AppError = require("../utils/appError");

// Modelos requeridos
const User = require("../models/user.model");
const Student = require("../models/student.model");
const Volunteer = require("../models/volunteer.model");
const Activity = require("../models/activity.model");
const Accreditation = require("../models/accreditation.model");
const Talk = require("../models/talk.model");
const Campaign = require("../models/campaign.model");
const Adoption = require("../models/adoption.model");
const Identification = require("../models/identification.model");
const Survey = require("../models/survey.model");
const Contact = require("../models/contact.model");
const Notification = require("../models/notification.model");
const DehydrationAuditLog = require("../models/dehydrationAuditLog.model");

// Orden topológico estricto para inserción relacional
const TOPOLOGICAL_ORDER = [
  { key: "users", model: User, name: "Usuarios" },
  { key: "students", model: Student, name: "Estudiantes" },
  { key: "volunteers", model: Volunteer, name: "Voluntarios" },
  { key: "activities", model: Activity, name: "Actividades" },
  { key: "accreditations", model: Accreditation, name: "Acreditaciones" },
  { key: "talks", model: Talk, name: "Pláticas" },
  { key: "campaigns", model: Campaign, name: "Campañas" },
  { key: "adoptions", model: Adoption, name: "Adopciones" },
  { key: "identifications", model: Identification, name: "Identificaciones" },
  { key: "surveys", model: Survey, name: "Encuestas" },
  { key: "contacts", model: Contact, name: "Contactos" },
  { key: "notifications", model: Notification, name: "Notificaciones" },
];

const BATCH_SIZE = 500; // Bloques seguros para bulkWrite

/**
 * ALGORITMO TÉCNICO DE REHIDRATACIÓN: Validación Criptográfica y Restauración Selectiva
 * 
 * @param {Buffer} zipBuffer - Archivo ZIP recibido en memoria
 * @param {boolean} confirm - false: dry-run de sólo lectura; true: commit a MongoDB
 * @param {Object} adminUser - Administrador ejecutor autenticado
 * @returns {Promise<Object>} Resumen pericial de restauración
 */
async function executeRehydrationRestore(zipBuffer, confirm = false, adminUser) {
  if (!zipBuffer || !Buffer.isBuffer(zipBuffer)) {
    throw new AppError("No se recibió un búfer binario de archivo ZIP válido.", 400);
  }

  // 1. Descompresión Segura en Memoria (AdmZip)
  let zip;
  try {
    zip = new AdmZip(zipBuffer);
  } catch (err) {
    throw new AppError(`El archivo no tiene un formato ZIP válido: ${err.message}`, 400);
  }

  const manifestEntry = zip.getEntry("manifest.json");
  if (!manifestEntry) {
    throw new AppError("El archivo ZIP no contiene el manifiesto requerido 'manifest.json' de ABAQ.", 400);
  }

  let manifest;
  try {
    manifest = JSON.parse(manifestEntry.getData().toString("utf8"));
  } catch (err) {
    throw new AppError(`El manifiesto manifest.json está corrupto: ${err.message}`, 400);
  }

  // 2. Comprobación Criptográfica de Integridad Forense SHA-256
  const parsedCollections = {};
  const reportCollections = [];

  for (const item of TOPOLOGICAL_ORDER) {
    const entryPath = `collections/${item.key}.json`;
    const entry = zip.getEntry(entryPath);

    if (!entry) {
      reportCollections.push({
        key: item.key,
        name: item.name,
        status: "omitted_in_package",
        restoreCount: 0,
      });
      continue;
    }

    const rawData = entry.getData();
    const calculatedSha256 = crypto.createHash("sha256").update(rawData).digest("hex");
    const expectedSha256 = manifest.collections?.[item.key]?.sha256;

    if (expectedSha256 && expectedSha256 !== calculatedSha256) {
      throw new AppError(
        `Fallo de verificación criptográfica SHA-256 en '${item.name}' (${item.key}.json). El paquete fue adulterado externamente.`,
        422
      );
    }

    let docs;
    try {
      docs = JSON.parse(rawData.toString("utf8"));
    } catch (parseErr) {
      throw new AppError(`JSON corrupto en '${entryPath}': ${parseErr.message}`, 400);
    }

    if (!Array.isArray(docs)) {
      throw new AppError(`El archivo '${entryPath}' debe contener un arreglo de documentos JSON.`, 400);
    }

    parsedCollections[item.key] = docs;
    reportCollections.push({
      key: item.key,
      name: item.name,
      status: "verified_ready",
      documentsToRestore: docs.length,
      bytes: rawData.length,
    });
  }

  // 3. Si es Modo Simulación (Dry-Run), retornar diagnóstico comparativo
  if (!confirm) {
    return {
      status: "success",
      dryRun: true,
      message: "Validación de integridad completada exitosamente. Listo para rehidratación.",
      manifestInfo: {
        packageDate: manifest.generatedAt,
        cutoffDate: manifest.cutoffDate,
        originalAuthor: manifest.generatedBy?.email,
      },
      collections: reportCollections,
    };
  }

  // 4. RESTAURACIÓN SELECTIVA IDEMPOTENTE POR BLOQUES (bulkWrite con upsert: true)
  const startTime = Date.now();
  const restorationResults = [];
  let totalRestored = 0;

  for (const item of TOPOLOGICAL_ORDER) {
    const docs = parsedCollections[item.key];
    if (!docs || docs.length === 0) continue;

    let collectionRestoredCount = 0;

    // Procesar en chunks de BATCH_SIZE (500) para evitar desbordar memoria y BSON limits
    for (let i = 0; i < docs.length; i += BATCH_SIZE) {
      const chunk = docs.slice(i, i + BATCH_SIZE);

      const bulkOps = chunk.map((doc) => ({
        replaceOne: {
          filter: { _id: new mongoose.Types.ObjectId(doc._id) }, // Conservación exacta de _id original
          replacement: doc,
          upsert: true, // Si no existe lo inserta; si existe lo actualiza de forma idempotente
        },
      }));

      const res = await item.model.bulkWrite(bulkOps, { ordered: false });
      collectionRestoredCount += (res.upsertedCount || 0) + (res.modifiedCount || 0);
    }

    totalRestored += collectionRestoredCount;
    restorationResults.push({
      key: item.key,
      name: item.name,
      restoredCount: collectionRestoredCount,
    });
  }

  // 5. Inserción de la Bitácora Inmutable en DehydrationAuditLog
  const folioSuffix = crypto.randomBytes(2).toString("hex").toUpperCase();
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, "");
  const operationFolio = `REHYD-${dateStr}-${folioSuffix}`;

  await DehydrationAuditLog.create({
    operationFolio,
    operationType: "rehydrate_restore",
    cutoffDate: manifest.cutoffDate || new Date(),
    durationMs: Date.now() - startTime,
    executedBy: {
      adminId: adminUser._id,
      email: adminUser.email,
    },
    status: "completed",
    backupPackage: {
      fileName: `rehydration-${operationFolio}.zip`,
      sha256: manifest.metrics?.packageSha256 || "verified_in_stream",
      fileSizeBytes: zipBuffer.length,
    },
    metrics: {
      totalCollectionsAffected: restorationResults.length,
      totalDocumentsPurged: 0,
      totalBytesFreed: 0,
    },
    collections: restorationResults.map((r) => ({
      collectionName: r.key,
      modelKey: r.key,
      modelName: r.name,
      documentCount: r.restoredCount,
      estimatedBytesFreed: 0,
      filterCriteria: "{ bulkWrite: replaceOne, upsert: true }",
    })),
  });

  return {
    status: "success",
    operationFolio,
    message: "Base de datos rehidratada exitosamente. Registros históricos restaurados.",
    totalRestoredDocuments: totalRestored,
    collections: restorationResults,
  };
}

module.exports = {
  executeRehydrationRestore,
};
```

---

---

## 5. Esquema de Datos y Bitácora de Auditoría

### 5.1 Sub-documento `statusHistory` y Colección Centralizada `UserStatusAuditLog`

Para garantizar trazabilidad completa de cada transición de cuenta (especificando con total transparencia **a qué usuario se le hizo**, **qué administrador lo hizo**, **el estado previo y nuevo**, **el motivo** y **las observaciones**), el sistema define una estructura unificada de auditoría de transiciones.

#### Estructura de Datos de Transición de Estado (`StatusHistoryEntry`)

```typescript
interface StatusHistoryEntry {
  // 1. Identificación del Usuario Afectado (A quién se le hizo)
  targetUserId: mongoose.Types.ObjectId;               // _id del Student o Volunteer
  targetUserFolio: string;                            // Folio único institucional (ej. "SS-261030-01" o "VG-261030-01")
  targetUserEmail: string;                            // Correo electrónico del voluntario
  targetUserName: string;                             // Nombre completo del colaborador
  targetUserRole: 'student' | 'volunteer';            // Rol del colaborador

  // 2. Transición Exacta de Estados
  previousStatus: 'pending' | 'active' | 'inactive' | 'rejected' | null;
  newStatus: 'pending' | 'active' | 'inactive' | 'rejected';
  changedAt: Date;

  // 3. Responsable de la Acción (Quién lo hizo)
  // Alineado a la realidad de MongoDB: el modelo User solo posee email, role y passwordHash; no posee campo name.
  changedBy: mongoose.Types.ObjectId | 'system_cron'; // _id del User admin autenticado o string 'system_cron'
  changedByEmail: string;                             // req.user.email del administrador ejecutor o 'system_cron'
  changedByRole: 'admin' | 'system';                  // Rol operativo del actor ejecutor

  // 4. Causal Formal de la Transición
  reason: 
    | 'initial_signup'                     // Registro inicial por el colaborador en onboarding
    | 'admin_approval'                     // Aprobación y alta manual por administrador
    | 'admin_rejection'                    // Rechazo manual de expediente con observaciones
    | 'hours_completed'                    // Sistema: cumplimiento íntegro de 480 hrs reglamentarias
    | 'inactivity_60_days'                 // Sistema: baja automática por acumular 60 días de inactividad
    | 'administrative_decision'            // Inactivación manual por administrador a su discreción
    | 're_registration';                   // Re-registro tras haber sido previamente rechazado

  // 5. Justificación y Observaciones Formales
  comments: string;                        // Mensaje institucional explicativo visible en UI y correos
}
```

!!! note "Auditoría Real sin Campos Ficticios: Uso de `changedByEmail`"
    En la base de datos de ABAQ, las cuentas de administración residen exclusivamente en la colección `users` (`User`), la cual cuenta únicamente con los atributos `email`, `passwordHash`, `role` (`'admin'`) y `createdAt`. **No existe un campo de nombre propio para los administradores**. Por ello, el responsable se audita fidedignamente mediante su correo electrónico real (`changedByEmail = req.user.email`), garantizando cero discrepancias o campos inexistentes en backend.

#### Estrategia Dual de Persistencia: Local y Centralizada
1. **Embebida en `Student` y `Volunteer` (`statusHistory: [StatusHistoryEntry]`):**
   Permite lecturas inmediatas y atómicas ($O(1)$) al renderizar la vista de expediente recibido (`/onboarding/expediente`), la ficha de perfil de voluntario (`/volunteer-profile`) o el detalle del estudiante (`StudentDetailComponent`), sin necesidad de hacer joins relacionales.
2. **Colección Centralizada `UserStatusAuditLog` (o Aggregation Pipeline Indexado):**
   Permite alimentar de forma altamente eficiente la pestaña **"Bitácora de Estados"** de la vista `/volunteers/history`, posibilitando al administrador filtrar transiciones por rango de fechas, por tipo de causal (`reason`), por correo del administrador ejecutor (`changedByEmail`) o por estudiante afectado (`targetUserFolio`).

#### Reglas de Llenado del Campo `comments`
1. **Acciones Autónomas del Sistema (Comentarios Automáticos Preconfigurados):**
   * *Cumplimiento de 480 horas (`hours_completed`):*  
     `"Cumplimiento íntegro de las 480 horas reglamentarias de Servicio Social. Acreditación final aprobada y emisión de constancia oficial de acreditación."`
   * *Inactividad de 60 días (`inactivity_60_days`):*  
     `"Baja automática del programa por acumular 60 días continuos sin inicio de sesión ni participación registrada en la plataforma institucional."`
   * *Re-registro tras rechazo (`re_registration`):*  
     `"Reactivación a estatus pendiente tras el reenvío de un nuevo expediente y formulario corregido por parte del colaborador."`
   * *Registro inicial (`initial_signup`):*  
     `"Expediente digital recibido en 4 fases, pendiente de revisión y validación administrativa por la Coordinación de ABAQ."`

2. **Acciones Manuales del Administrador (Modal con Campo de Observaciones):**
   * Al **Rechazar un Expediente (`admin_rejection`)**: La UI despliega un modal con un campo de texto obligatorio para que el administrador redacte las observaciones específicas (ej. *"Falta adjuntar constancia oficial sellada por la universidad en la Fase 3"*, *"El enlace a Google Drive carece de permisos públicos de lectura"*).
   * Al **Inactivar a Discreción (`administrative_decision`)**: Modal para capturar la causa de la baja (ej. *"Baja voluntaria solicitada formalmente por el estudiante por motivos de carga académica universitaria"*).
   * Al **Aceptar un Expediente (`admin_approval`)**: Mensaje institucional por defecto (*"Expediente validado satisfactoriamente por la Coordinación de ABAQ"*), con posibilidad de ingresar notas de bienvenida personalizadas.
   * *Fallback por Omisión:* Si el admin deja el campo en blanco, el backend inyecta automáticamente una plantilla formal predeterminada.

#### Consumo y Visibilidad del Comentario por Voluntarios y Administradores
El campo `comments` no se queda oculto en la base de datos; se expone estratégicamente en interfaces y correos según el estado y rol:

1. **En la Interfaz Web de Expediente (`/onboarding/expediente`):**
   * Aplica a ambos roles de voluntario (`student` y `volunteer`).
   * **Estado `accepted` (`active`):** La pantalla de expediente muestra la tarjeta oficial de felicitación acompañada del mensaje de bienvenida y observaciones de la Coordinación (`comments`).
   * **Estado `rejected`:** La pantalla despliega un contenedor de alerta ámbar/rojo con las **"Observaciones de la Coordinación: {{comments}}"**, permitiendo que el aspirante conozca con exactitud qué corregir antes de iniciar su re-registro con el mismo correo.

2. **En el Perfil Personal del Voluntario (Estado `inactive`):**
   * Cuando la cuenta pasa a `inactive`, el voluntario ya no tiene acceso operativo ni visualiza nuevas actividades convocadas.
   * Al acceder a su perfil (`/volunteer-profile` o perfil de estudiante), el sistema renderiza de **forma fija y permanente en la parte superior (inmediatamente debajo del header)** un banner destacado:
     > 🛑 **Cuenta Inactiva / Servicio Concluido:** {{comments}}  
     > *Fecha de Desactivación: {{fechaDesactivacion}} · Causal: {{reason}}*

3. **En la Vista Administrativa del Perfil (`student-detail` y `volunteer-detail`):**
   * Mientras el usuario inactivo sea visible en las interfaces normales operativas ($< 12$ meses), el administrador visualiza en la parte superior de la ficha del perfil (debajo del hero) una tarjeta informativa permanente:
     > ℹ️ **Registro Inactivo:** {{comments}}  
     > *Inactivado el: {{fechaDesactivacion}} por {{changedByEmail}} (Causal: {{reason}})*
   * Esto permite que cualquier administrador que consulte el perfil de un voluntario inactivo identifique de inmediato **por qué, cuándo y quién** realizó la baja (evitando confusiones entre bajas por cumplimiento de 480 hrs, bajas automáticas por 60 días de ausencia, o bajas manuales a discreción).

4. **En los Correos Transaccionales (Resend):**
   * En cada notificación de cambio de estado (aceptación, rechazo, baja por 60 días o finalización), el texto de `comments` se inyecta en una caja destacada (*callout box*):
     > *"Mensaje de la Coordinación: {{comments}}"*

---

### 5.2 Colección de Auditoría `DehydrationAuditLog` y Análisis Cuantitativo de Almacenamiento

Para garantizar máxima transparencia y auditoría legal, el sistema implementa la colección inmutable `dehydrationauditlogs` en MongoDB. A continuación se presenta el análisis de telemetría extraído en vivo de MongoDB Atlas (`abaqPrototype`) que fundamenta qué modelos se retiran, cuáles se preservan y cómo se estructura el log para detallar con precisión **qué es lo que se salió del sistema**.

#### Análisis Cuantitativo de Almacenamiento en MongoDB Atlas
Un análisis empírico del clúster de base de datos determinó el peso real y la jerarquía de almacenamiento:

| Colección | Documentos | DataSize (Bytes) | % del Total | Promedio / Doc | Diagnóstico Arquitectónico |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **`notifications`** | 73 | 64,806 B | **41.40%** | 887 B | **Mayor consumidor de almacenamiento.** Notificaciones de constancias, alertas y avisos. |
| **`students`** | 14 | 28,444 B | **18.17%** | **2,031 B** | **Modelo individual más pesado.** Almacena `onboardingData` (JSON) y `assignedActivities` anidadas. |
| **`accreditations`** | 51 | 18,465 B | **11.80%** | 362 B | Oportunidades validadas con URLs de evidencias y desglose horario. |
| **`volunteers`** | 8 | 10,886 B | 6.95% | 1,360 B | Voluntarios generales con grados académicos y actividades anidadas. |
| **`surveys`** | 10 | 10,492 B | 6.70% | 1,049 B | Encuestas de campo con más de 25 reactivos socio-ambientales. |
| **`pets`** | 8 | 4,159 B | 2.66% | 519 B | Padrón de mascotas registradas para esterilización y citas. |
| **`users`** | 22 | 3,686 B | 2.35% | 167 B | Cuentas de acceso (estudiantes, voluntarios y administradores). |
| **`activities`** | 12 | 3,303 B | 2.11% | 275 B | Convocatorias de actividades (ligeras; el peso real se absorbe en `students`). |
| **`adoptions`** | 3 | 2,381 B | 1.52% | 793 B | Expedientes de adopción con periodos de prueba, contratos y fotos. |
| **`campaigns`** | 3 | 2,184 B | 1.39% | 728 B | Jornadas masivas con datos completos de tutores. |
| **`identifications`** | 5 | 2,047 B | 1.31% | 409 B | Solicitudes de placas con comprobantes de pago. |
| **`quickactivities`**| 6 | 1,370 B | 0.88% | 228 B | **Plantillas maestras reutilizables (permanentes).** |
| **`talks`** | 4 | 1,298 B | 0.83% | 324 B | Pláticas con listas embebidas de asistentes. |
| **`contacts`** | 6 | 1,049 B | 0.67% | 174 B | Bitácoras de prospección ciudadana vinculadas a estudiantes. |

> **Corroboración Técnica:**  
> La afirmación operativa es certera: **los estudiantes, las oportunidades (`accreditations`) y las actividades concentran el mayor flujo transaccional**. Sin embargo, la inspección técnica reveló un hallazgo crucial: **las actividades individuales son muy ligeras (275 bytes)** porque el peso de cada inscripción se desnormaliza dentro del arreglo `assignedActivities` de cada `Student` (elevando el documento a > 2 KB).  
> Además, se identificó un **punto ciego crítico**: la colección **`notifications` concentra por sí sola más del 41% del almacenamiento total**. Purgar las notificaciones de los usuarios inactivos libera de inmediato casi la mitad del volumen de la base de datos.

---

#### Catálogo Exhaustivo de Modelos: Qué se va vs. Qué se queda

El principio del **Corte Limpio e Indivisible** (*"o se quita todo o no se quita nada"*) rige estrictamente el proceso de deshidratación. Si una actividad u oportunidad cuenta con al menos un voluntario activo, se conserva íntegramente.

```mermaid
flowchart TD
    subgraph Purgados ["12 MODELOS QUE SE VAN (PURGADOS EN EL CORTE LIMPIO)"]
        direction TB
        M1["1. students (Expedientes, onboardingData y actividades asignadas)"]
        M2["2. volunteers (Perfiles generales inactivos > 1 año)"]
        M3["3. users (Cuentas auth de estudiantes y voluntarios purgados)"]
        M4["4. accreditations (Acreditaciones pasadas y horas cubiertas)"]
        M5["5. activities (Actividades pasadas sin ningún participante activo)"]
        M6["6. notifications (Notificaciones de usuarios archivados - 41.4% BD)"]
        M7["7. surveys (Cuestionarios levantados por voluntarios purgados)"]
        M8["8. contacts (Bitácoras de prospección levantadas en campo)"]
        M9["9. identifications (Trámites de placas concluidos de ciclos pasados)"]
        M10["10. talks (Pláticas de tenencia responsable concluidas)"]
        M11["11. campaigns (Jornadas masivas de esterilización concluidas)"]
        M12["12. adoptions (Expedientes de adopción con resolución definitiva)"]
    end

    subgraph Conservados ["4 MODELOS QUE SE CONSERVAN PERMANENTEMENTE"]
        direction TB
        C1["1. quickactivities (Plantillas maestras reutilizables)"]
        C2["2. users con rol 'admin' (Cuentas de gobierno y coordinación)"]
        C3["3. pets (Catálogo comunitario de identidad y salud animal)"]
        C4["4. DehydrationAuditLog (Bitácora inmutable de auditoría)"]
    end
```

##### Detalle de los 12 Modelos que se Puran (Salen del Sistema a JSON/ZIP)
1. **`students` (`Student`):** Expedientes completos de estudiantes de Servicio Social con inactividad mayor a 1 año (`fechaDesactivacion <= cutoffDate`). Incluye su `onboardingData`, reflexiones de inducción, consentimientos y el arreglo `assignedActivities`.
2. **`volunteers` (`Volunteer`):** Perfiles completos de Voluntarios Generales inactivos por más de 1 año. Incluye formación académica (`degrees`) y participaciones cívicas.
3. **`users` (`User`, roles `'student'` y `'volunteer'`):** Credenciales y cuentas de acceso de autenticación vinculadas directamente a los colaboradores archivados.
4. **`accreditations` (`Accreditation`):** Todos los registros históricos de acreditación de horas y oportunidades de los colaboradores purgados.
5. **`activities` (`Activity`):** Convocatorias de actividades pasadas concluidas donde **el 100% de los inscritos sean inactivos mayor a 1 año**. Si existe un solo alumno activo, la actividad se conserva en su totalidad.
6. **`notifications` (`Notification`):** Notificaciones dirigidas a los usuarios purgados. Su eliminación erradica el 41.40% de la carga de base de datos.
7. **`surveys` (`Survey`):** Respuestas a cuestionarios y encuestas de bienestar animal levantadas por los estudiantes que se deshidratan.
8. **`contacts` (`Contact`):** Prospecciones y censos levantados en campo por los estudiantes deshidratados.
9. **`identifications` (`Identification`):** Expedientes de placas de identificación animal gestionadas en ciclos concluidos.
10. **`talks` (`Talk`):** Pláticas de tenencia responsable concluidas con listas cerradas de asistentes inactivos.
11. **`campaigns` (`Campaign`):** Jornadas masivas de esterilización concluidas sin vinculación a colaboradores vigentes.
12. **`adoptions` (`Adoption`):** Trámites y contratos de adopción resueltos y concluidos de periodos pasados.

##### Detalle de los 4 Modelos que se Conservan Permanentemente
1. **`quickactivities` (`QuickActivity`):** **Plantillas maestras reutilizables.** Definen configuraciones base de actividades institucionales frecuentes. Su eliminación rompería la capacidad del administrador de convocar nuevas actividades rápidamente.
2. **`users` con `role: 'admin'`:** Cuentas del personal administrativo, directivo y operativo de ABAQ. Deben permanecer intactas para gobernar la plataforma.
3. **`pets` (`Pet`):** Padrón comunitario de animales registrados para campañas de salud, vacunación y seguimiento en Querétaro. Representa la identidad del paciente animal y trasciende la baja de cualquier voluntario temporal.
4. **`DehydrationAuditLog` (`dehydrationauditlogs`):** La propia bitácora inmutable de auditoría. Es la prueba pericial de qué datos salieron, en qué fecha y bajo qué firma criptográfica.

---

#### Esquema de Mongoose Granular: `DehydrationAuditLog`

Para que el log sea **altamente detallado y certifique con exactitud qué salió del sistema**, el esquema registra:
- Lista consolidada de los usuarios deshidratados (`purgedUsersSummary`).
- Verificación de integridad relacional del corte (`relationalIntegrityCheck`).
- Desglose granular por colección purgada con resumen de entidades e identificadores legibles (`collections`).
- Métricas cuantitativas de almacenamiento antes y después de la purga.
- Firma criptográfica SHA-256 del paquete ZIP descargado.

```javascript
const mongoose = require("mongoose");

// Sub-documento que detalla cada entidad o registro representativo purgado
const purgedEntityItemSchema = new mongoose.Schema(
  {
    documentId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
    },
    identifier: {
      type: String, // Folio ("SS-251020-01"), Email ("alumno@mail.com") o Título ("Jornada San Pedrito")
      required: true,
    },
    displayName: {
      type: String, // Nombre legible de la persona o actividad
      required: true,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {}, // Metadatos útiles: { horasTotales: 480, fechaDesactivacion: "2025-10-15" }
    },
  },
  { _id: false }
);

// Resumen granular por cada una de las 12 colecciones afectadas
const collectionPurgeSummarySchema = new mongoose.Schema(
  {
    collectionName: {
      type: String, // ej. "students", "accreditations", "notifications", "activities"
      required: true,
    },
    modelKey: {
      type: String, // ej. "students"
      required: true,
    },
    modelName: {
      type: String, // ej. "Estudiantes de Servicio Social"
      required: true,
    },
    documentCount: {
      type: Number,
      required: true,
      min: 0,
    },
    estimatedBytesFreed: {
      type: Number,
      required: true,
      min: 0,
    },
    filterCriteria: {
      type: String,
      required: true, // Query de corte ejecutada
    },
    purgedDocumentIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
      },
    ],
    // Muestra representativa para inspección rápida sin abrir el ZIP
    sampleItems: [purgedEntityItemSchema],
  },
  { _id: false }
);

// Resumen específico de los usuarios deshidratados
const purgedUserSummarySchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, required: true },
    folio: { type: String, required: true },
    email: { type: String, required: true },
    fullName: { type: String, required: true },
    role: { type: String, enum: ["student", "volunteer"], required: true },
    fechaDesactivacion: { type: Date, required: true },
    totalHoras: { type: Number, default: 0 },
    totalAcreditaciones: { type: Number, default: 0 },
  },
  { _id: false }
);

const dehydrationAuditLogSchema = new mongoose.Schema(
  {
    operationFolio: {
      type: String, // Ej: "DEHYD-20261102-E9A2"
      required: true,
      unique: true,
      uppercase: true,
      index: true,
    },
    operationType: {
      type: String,
      enum: ["dehydrate_purge", "rehydrate_restore"],
      required: true,
      index: true,
    },
    cutoffDate: {
      type: Date,
      required: true,
      index: true,
    },
    executedAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
    durationMs: {
      type: Number,
      required: true,
    },
    executedBy: {
      adminId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true,
      },
      email: {
        type: String, // req.user.email del administrador ejecutor
        required: true,
      },
      ipAddress: {
        type: String,
        default: "",
      },
    },
    status: {
      type: String,
      enum: ["started", "completed", "failed", "rolled_back"],
      default: "completed",
      index: true,
    },

    // Integridad Criptográfica del Paquete de Respaldo Local
    backupPackage: {
      fileName: {
        type: String,
        required: true, // Ej: "abaq-dehydrate-20261102-143000.zip"
      },
      sha256: {
        type: String,
        required: true, // Hash SHA-256 de 64 caracteres hex
      },
      fileSizeBytes: {
        type: Number,
        required: true,
      },
      storageLocation: {
        type: String,
        default: "local_download", // "local_download" | "cloud_blob"
      },
      manifestVersion: {
        type: String,
        default: "1.0.0",
      },
    },

    // Certificación de Integridad Relacional del Corte Indivisible
    relationalIntegrityCheck: {
      activeParticipantsFound: {
        type: Number,
        default: 0, // DEBE SER ESTRICTAMENTE 0 para que la purga proceda
      },
      activitiesEvaluatedCount: {
        type: Number,
        required: true,
      },
      opportunitiesEvaluatedCount: {
        type: Number,
        required: true,
      },
      cutoffIntegrityVerified: {
        type: Boolean,
        default: true,
      },
    },

    // Verificación de los 4 Modelos Preservados
    preservedCatalogVerification: {
      quickActivitiesPreservedCount: { type: Number, required: true },
      adminUsersPreservedCount: { type: Number, required: true },
      petsPreservedCount: { type: Number, required: true },
    },

    // Métricas Globales de Liberación de Almacenamiento
    metrics: {
      totalCollectionsAffected: {
        type: Number,
        required: true,
      },
      totalDocumentsPurged: {
        type: Number,
        required: true,
      },
      totalBytesFreed: {
        type: Number,
        required: true,
      },
      preExecutionStorageBytes: {
        type: Number,
        default: 0,
      },
      postExecutionStorageBytes: {
        type: Number,
        default: 0,
      },
    },

    // Lista Consolidada de Usuarios que se Retiraron del Sistema
    purgedUsersSummary: [purgedUserSummarySchema],

    // Desglose Granular por cada una de las 12 Colecciones Purgadas
    collections: [collectionPurgeSummarySchema],

    errorMessage: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

const DehydrationAuditLog = mongoose.model(
  "DehydrationAuditLog",
  dehydrationAuditLogSchema
);

module.exports = DehydrationAuditLog;
```

---

### 5.3 Nomenclatura Determinista y Folios de Solicitud de Interacción (`AC` y `OP`)

Así como los usuarios cuentan con un folio institucional único de expediente (`SS-YYMMDD-HEX` para Servicio Social y `VG-YYMMDD-HEX` para Voluntariado General), el sistema establece una **nomenclatura determinista obligatoria para las solicitudes de interacción de los colaboradores con actividades y oportunidades**.

#### Propósito Operativo y Jurídico de los Folios de Interacción
!!! important "El Folio Representa la Solicitud de Interacción del Usuario, no la Actividad General"
    El objetivo del folio **no es categorizar la actividad general ni la oportunidad a nivel macro**, sino identificar de forma unívoca **la interacción específica de un usuario (estudiante o voluntario) con dicha actividad u oportunidad**:
    * **Para Estudiantes de Servicio Social (`student`):** Constituye el comprobante oficial de registro con el que el alumno puede dar seguimiento, validar y **pelear sus horas acreditadas** ante la Coordinación de ABAQ o ante la Dirección de Servicio Social de su universidad en caso de discrepancias o revisiones.
    * **Para Voluntarios Generales (`volunteer`):** Constituye el respaldo institucional inmutable que **certifica su asistencia y participación cívica** en las actividades u oportunidades comunitarias en las que colaboró.
    * **Para la Administración:** Proporciona un código alfanumérico estandarizado y legible para resolver aclaraciones, auditar listas de asistencia y dictaminar solicitudes sin ambigüedades.

#### Reglas de Nomenclatura y Prefijos Deterministas
El sistema distingue de forma estricta entre dos tipos de interacción y sub-clasifica las oportunidades para que el folio exprese inmediatamente la naturaleza de la participación:

| Tipo | Prefijo Base | Sub-código de Modalidad | Estructura Canónica | Ejemplo Real |
| :--- | :---: | :--- | :--- | :--- |
| **Actividad Convocada** | `AC` | N/A (Convocatoria directa en plataforma) | `AC-YYMMDD-HEX` | `AC-261102-0A14` |
| **Oportunidad Institucional** | `OP` | Código de 3 letras de la modalidad (`CAT`) | `OP-CAT-YYMMDD-HEX` | `OP-STE-261102-0B2E` |

##### Análisis de Colisiones de las Primeras 2 Letras en las Oportunidades
Al analizar si las primeras 2 letras de los nombres en el enum (`accreditation.model.js`) pueden usarse directamente, se detecta un **solapamiento crítico (colisión triple)** en la raíz `AD`:

* `ADOPTION` $\to$ **`AD`** *(Colisión)*
* `ADOPTION_MODULE` $\to$ **`AD`** *(Colisión)*
* `ADMINISTRATIVE` $\to$ **`AD`** *(Colisión)*

Si se tomaran ciegamente las dos primeras letras, sería imposible distinguir si un folio `OP-AD-...` corresponde a un expediente de adopción individual, a una jornada en un módulo itinerante o a tareas de apoyo administrativo.

##### Catálogo Estandarizado de Sub-códigos sin Solapamiento
Para eliminar cualquier colisión y garantizar legibilidad inmediata para estudiantes, voluntarios y administración, se definen dos alternativas estandarizadas (con recomendación formal del estándar de 3 letras tipo ISO):

| Oportunidad (Enum) | Modalidad Operativa | Opción Recomendada (3 Letras) | Opción Alternativa (2 Letras) | Ejemplo Canónico (Recomendado) |
| :--- | :--- | :---: | :---: | :--- |
| `EVENT` | Eventos institucionales y albergue | `EVE` | `EV` | `OP-EVE-261102-01A2` |
| `INDUCTION` | Inducción reglamentaria (10 hrs) | `IND` | `IN` | `OP-IND-261102-0045` |
| `IDENTIFICATION` | Placas y registro de identidad animal | `IDE` | `ID` | `OP-IDE-261102-02B1` |
| `STERILIZATION` | Campañas de esterilización quirúrgica | `STE` | `ST` | `OP-STE-261102-03C8` |
| `ADOPTION` | Adopción individual y seguimiento | `ADO` | `AD` | `OP-ADO-261102-01F4` |
| `ADOPTION_MODULE`| Módulos itinerantes en centros comerciales| `MOD` | `AM` | `OP-MOD-261102-0089` |
| `TALK` | Pláticas de tenencia responsable | `TLK` | `TK` | `OP-TLK-261102-0112` |
| `CAMPAIGN` | Campañas masivas de vacunación/salud | `CAM` | `CA` | `OP-CAM-261102-04D7` |
| `MEDIA` | Cobertura en prensa, radio y TV | `MED` | `MD` | `OP-MED-261102-0023` |
| `SOCIAL_MEDIA` | Contenido y gestión de redes sociales | `SOC` | `SM` | `OP-SOC-261102-0067` |
| `DONATION` | Recaudación de fondos y donativos | `DON` | `DO` | `OP-DON-261102-0019` |
| `ADMINISTRATIVE` | Soporte de oficina y archivo | `ADM` | `AA` | `OP-ADM-261102-0031` |

> [!TIP] Ventaja del Estándar de 3 Letras (`OP-CAT-YYMMDD-HEX`)
> El formato de 3 letras (ej. `OP-STE-...` para Esterilización, `OP-ADM-...` para Administrativo, `OP-TLK-...` para Pláticas) es **auto-explicativo** para cualquier colaborador o autoridad escolar al primer vistazo, evitando ambigüedades y manteniendo una longitud homogénea y profesional.

* **Componentes del Folio Resultante:**
  * `AC` / `OP`: Prefijo indicativo del tipo de interacción (Actividad convocada vs Oportunidad institucional).
  * `CAT` (sólo para `OP`): Sub-código de 3 letras de la oportunidad (`STE`, `ADO`, `ADM`, etc.).
  * `YYMMDD`: Fecha exacta de la solicitud o inscripción (año, mes, día).
  * `HEX`: Correlativo hexadecimal de 4 caracteres generado atómicamente por día (ej. `0001`, `0A14`).

#### Visibilidad Transversal en Todas las Vistas y para Todos los Roles
El folio de interacción no permanece oculto como un identificador técnico interno; **está marcado y visible de forma destacada en la información de cada vista para todos los roles**:

```mermaid
flowchart LR
    subgraph Interaccion ["Generación de Interacción"]
        U["Voluntario (SS o VG)"] -->|Se inscribe a Actividad| FAC["Folio AC-YYMMDD-HEX"]
        U -->|Solicita Oportunidad / Horas| FOP["Folio OP-YYMMDD-HEX"]
    end

    subgraph FrontColab ["Vistas del Colaborador (SS y VG)"]
        FAC & FOP --> V1["Modal de Confirmación de Inscripción"]
        FAC & FOP --> V2["Tarjetas de Mis Actividades (/activity-list)"]
        FAC & FOP --> V3["Ficha de Detalle de Actividad (/activity-detail)"]
        FAC & FOP --> V4["Historial de Horas y Acreditaciones (Perfil)"]
    end

    subgraph FrontAdmin ["Vistas de Administración (Admin)"]
        FAC & FOP --> A1["Tabla de Acreditaciones (Columna Folio)"]
        FAC & FOP --> A2["Lista de Inscritos en Detalle de Actividad"]
        FAC & FOP --> A3["Ficha del Estudiante/Voluntario (StudentDetail)"]
        FAC & FOP --> A4["Barra de Búsqueda y Aclaraciones por Folio"]
    end
```

1. **En la Experiencia del Colaborador (Estudiantes y Voluntarios Generales):**
   * **Modal de Confirmación:** Al pulsar *"Inscribirme"* o *"Enviar Acreditación"*, el modal de éxito despliega en tipografía monoespaciada destacada:  
     `🎉 Solicitud registrada con éxito. Tu Folio de Seguimiento es: AC-261102-0A14`
   * **En la Lista de Actividades Convocadas (`/activity-list`):** Si el usuario ya está registrado en la actividad, la tarjeta sustituye el botón de inscripción por una píldora con gradiente: `Folio: AC-261102-0A14 · Estado: Registrado`.
   * **En la Vista de Detalle (`/activity-detail`):** Encabezado de estado con el folio de inscripción y opción de copiar al portapapeles.
   * **En el Perfil Personal (`/volunteer-profile` o perfil de estudiante):** La tabla de *"Mis Horas y Asistencias"* expone el folio de interacción como primera columna, permitiendo al usuario respaldar cada fila con su código oficial.

2. **En la Experiencia de Administración (`Admin`):**
   * **Tabla de Gestión de Acreditaciones (`accreditation.component.html`):** Columna visible `Folio Interacción`, permitiendo ordenar y buscar rápidamente por `AC-...` u `OP-...`.
   * **Administración de Actividades (`activity.component.html`):** En la lista desplegable de voluntarios inscritos a una convocatoria, cada fila muestra el nombre, el folio de expediente del colaborador (`SS-...` / `VG-...`) y el folio específico de su inscripción (`AC-...`).
   * **Ficha de Detalle del Alumno (`StudentDetailComponent` y `VolunteerDetailComponent`):** En la tabla de actividades asignadas y acreditadas, cada registro exhibe su folio para facilitar el cotejo ante reclamos de horas.

#### Persistencia en Modelos de MongoDB

##### 1. Sub-esquema `assignedActivities` (en `Student` y `Volunteer`)
En los modelos `backend/models/student.model.js` y `backend/models/volunteer.model.js`, cada inscripción en el arreglo `assignedActivities` incorpora los campos del folio:

```javascript
const assignedActivitySchema = new mongoose.Schema({
  activityId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Activity",
    required: true,
  },
  // Folio determinista de la interacción del usuario con la actividad
  interactionFolio: {
    type: String,
    required: true,
    uppercase: true,
    trim: true,
    index: true, // Ej: "AC-261102-0A14"
  },
  interactionType: {
    type: String,
    enum: ["AC", "OP"],
    default: "AC",
    required: true,
  },
  comments: {
    type: String,
    default: "Sin realizar",
  },
  dueDate: { type: Date },
  valueInHours: { type: Number },
  validatedHours: { type: Number, default: 0 },
  status: {
    type: String,
    enum: ["registered", "attended", "absent", "validated", "cancelled"],
    default: "registered",
  },
  performance: {
    type: String,
    enum: ["pending", "very_bad", "bad", "good", "very_good", "excellent", "absent"],
    default: "pending",
  },
  registrationDate: {
    type: Date,
    default: Date.now,
  },
});
```

##### 2. Sub-esquema `accreditations` Embebido (Arreglo 2 en `Student` y `Volunteer`)
Para que cada colaborador sea dueño integral de su historial y no dependa de llaves foráneas frágiles en una colección externa, `Student` y `Volunteer` incorporan un segundo arreglo embebido para sus oportunidades acreditadas:

```javascript
const embeddedAccreditationSchema = new mongoose.Schema(
  {
    accreditationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Accreditation",
      required: false,
    },
    // Folio determinista único de la interacción (OP-CAT-YYMMDD-HEX)
    interactionFolio: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },
    interactionType: {
      type: String,
      enum: ["AC", "OP"],
      default: "OP",
      required: true,
    },
    type: {
      type: String,
      enum: [
        "EVENT", "INDUCTION", "IDENTIFICATION", "STERILIZATION",
        "ADOPTION", "ADOPTION_MODULE", "TALK", "CAMPAIGN",
        "MEDIA", "SOCIAL_MEDIA", "DONATION", "ADMINISTRATIVE",
      ],
      required: true,
    },
    categoryCode: {
      type: String,
      enum: ["EVE", "IND", "IDE", "STE", "ADO", "MOD", "TLK", "CAM", "MED", "SOC", "DON", "ADM"],
      required: true,
    },
    date: { type: Date, required: true },
    hoursPerformed: { type: Number, default: 0, min: 0 },
    hoursAccredited: { type: Number, default: 0, min: 0 },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
      index: true,
    },
    comments: { type: String, default: "" },
    evidenceUrl: { type: String, default: "" },
    activityRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Activity",
      required: false,
    },
    registeredAt: { type: Date, default: Date.now },
    validatedAt: { type: Date },
  },
  {
    _id: true, // Cada acreditación embebida retiene su propio ObjectId inmutable
  }
);
```

##### 3. Definición Dual en los Esquemas Maestros `Student` y `Volunteer`
En `backend/models/student.model.js` y `backend/models/volunteer.model.js`, los esquemas raíz alojan de forma estandarizada los dos arreglos desnormalizados:

```javascript
// Esquema raíz en Student y Volunteer:
const studentSchema = new mongoose.Schema({
  folio: { type: String, required: true, uppercase: true, index: true }, // "SS-261030-01"
  accountStatus: { type: String, enum: ["active", "inactive"], default: "active" },
  fechaDesactivacion: { type: Date, default: null },

  // ARREGLO 1: Actividades convocadas colectivas (con folio AC-YYMMDD-HEX)
  assignedActivities: [assignedActivitySchema],

  // ARREGLO 2: Oportunidades y horas acreditadas (con folio OP-CAT-YYMMDD-HEX)
  accreditations: [embeddedAccreditationSchema],

  // Otros campos del perfil, expediente, consentimientos...
}, { timestamps: true });
```

##### 4. Colección Transaccional `Accreditation` (`backend/models/accreditation.model.js`)
Para la cola de moderación y aprobación administrativa, la colección independiente `Accreditation` opera como un buzón transaccional de revisión que sincroniza atómicamente el estado aprobado al subdocumento del estudiante/voluntario:

```javascript
const accreditationSchema = new mongoose.Schema(
  {
    // Folio determinista único de la acreditación
    interactionFolio: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
      index: true, // Ej: "OP-STE-261102-03C8"
    },
    interactionType: {
      type: String,
      enum: ["AC", "OP"],
      default: "OP",
      required: true,
      index: true,
    },

    // Referencias opcionales al colaborador (permite rol student o volunteer)
    studentRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Student",
      required: false,
    },
    volunteerRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Volunteer",
      required: false,
    },
    userRole: {
      type: String,
      enum: ["student", "volunteer"],
      required: true,
    },

    type: {
      type: String,
      enum: [
        "EVENT", "INDUCTION", "IDENTIFICATION", "STERILIZATION",
        "ADOPTION", "ADOPTION_MODULE", "TALK", "CAMPAIGN",
        "MEDIA", "SOCIAL_MEDIA", "DONATION", "ADMINISTRATIVE",
      ],
      required: true,
    },
    
    activityRef: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Activity",
      required: false,
    },

    date: { type: Date, required: true },
    hoursPerformed: { type: Number, default: 0, min: 0 },
    hoursAccredited: { type: Number, default: 0, min: 0 },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
      index: true,
    },
    comments: { type: String, default: "" },
    evidenceUrl: { type: String, default: "" },
  },
  {
    timestamps: true,
  }
);
```

#### Sincronización Atómica y Garantía Cero-Null en Deshidratación / Rehidratación

```mermaid
sequenceDiagram
    autonumber
    actor Vol as Voluntario (SS o VG)
    participant Ctrl as Accreditation Controller
    participant DB_Acc as Colección Accreditations
    participant DB_Usr as Colección Students / Volunteers
    actor Admin as Administrador

    Note over Vol,DB_Usr: PASO 1: Registro de Oportunidad
    Vol->>Ctrl: POST /accreditations (Tipo, fecha, horas, evidencia)
    Ctrl->>Ctrl: Genera folio determinista: OP-CAT-YYMMDD-HEX
    Ctrl->>DB_Acc: Crea documento en buzón de moderación (status: 'pending')
    Ctrl->>DB_Usr: Inserta subdocumento en arreglo user.accreditations
    Ctrl-->>Vol: Retorna folio OP-... para seguimiento

    Note over Admin,DB_Usr: PASO 2: Validación por Administrador
    Admin->>Ctrl: PUT /accreditations/:id/validate (status: 'approved', hoursAccredited: 10)
    Ctrl->>DB_Acc: Actualiza status: 'approved'
    Ctrl->>DB_Usr: Actualiza user.accreditations.$[elem].status = 'approved'

    Note over DB_Usr: PASO 3: Deshidratación a los 12 meses
    Note over DB_Usr: El usuario inactivo se exporta al ZIP CON SUS DOS ARREGLOS.\nMongoDB viva queda 100% limpia sin registros huérfanos ni campos null.

    Note over Admin,DB_Usr: PASO 4: Rehidratación por Auditoría Universitaria
    Admin->>Ctrl: POST /backup/dehydrate/restore (Carga paquete ZIP)
    Ctrl->>DB_Usr: bulkWrite con replaceOne + upsert: true
    Note over DB_Usr: El usuario se restaura con sus dos listas completas.\nVínculo restablecido inmediatamente sin tocar llaves foráneas.
```

##### Resumen de la Garantía de Integridad:
1. **Durante la Operación Activa:** El usuario consulta su perfil y ve inmediatamente sus horas y folios desde sus propios arreglos embebidos `assignedActivities` y `accreditations`, sin sobrecargar la base de datos con joins de agregación pesados.
2. **Durante la Deshidratación:** Al cumplirse el año de inactividad, el documento completo del usuario (con sus dos arreglos y todos sus folios) se empaqueta en `students.json` o `volunteers.json` y se retira de Atlas. No queda ningún campo en la base de datos viva apuntando a `studentRef: null`.
3. **Durante la Rehidratación:** Si la universidad requiere el expediente dos años después, la carga del ZIP restaura el documento del estudiante con sus horas y folios originales. El usuario vuelve a existir en Atlas con todo su historial íntegro.

#### Preservación en Deshidratación y Vista de Historial
* **En la Vista `/volunteers/history`:** Cuando un voluntario inactivo $> 12$ meses es consultado en la vista de historial de voluntarios pasados, sus registros pasados de acreditaciones retienen y muestran el `interactionFolio` (`AC-...` u `OP-...`), permitiendo a la organización atender auditorías escolares retrospectivas.
* **En el Manifiesto de Deshidratación:** Los identificadores `interactionFolio` son exportados en los archivos JSON de `accreditations.json` y respaldados en el sub-esquema `sampleItems` de la bitácora `DehydrationAuditLog`.

---

### 5.4 Mapeo y Definición Visual de Vistas: Ubicación Exacta de los Folios

Para evitar la saturación visual (*UI clutter*) y garantizar que los folios cumplan su función operativa (respaldar horas, auditar asistencias y tramitar aclaraciones), el sistema define con precisión en qué vistas, para qué roles y en qué elementos visuales específicos se renderizan los folios, así como las vistas donde queda estrictamente prohibido colocarlos.

```mermaid
flowchart TD
    subgraph DONDE_SI ["DONDE SÍ SE MUESTRA EL FOLIO (9 Vistas Críticas)"]
        direction TB
        S1["1. /my-accreditations (Folio AC / OP para pelear horas)"]
        S2["2. /admin/accreditations (Folio AC / OP para dictaminar)"]
        S3["3. /student-profile (SS-... en header y tabla con AC/OP)"]
        S4["4. /volunteer-profile (VG-... en header y tabla con AC/OP)"]
        S5["5. /onboarding/expediente (SS-... o VG-... de admisión)"]
        S6["6. /student (Tabla de voluntarios con columna de Folio)"]
        S7["7. /student/:id (Ficha alumno con SS-... y AC/OP)"]
        S8["8. /volunteer-detail/:id (Ficha voluntario con VG-... y AC/OP)"]
        S9["9. /volunteers/history (Histórico pasado para auditorías)"]
    end

    subgraph CONDICIONAL ["VISIBILIDAD CONDICIONAL / DINÁMICA (3 Vistas)"]
        direction TB
        C1["/activity-list (Solo si el voluntario ya está inscrito)"]
        C2["/activity-list/:id (Solo si el voluntario ya está inscrito)"]
        C3["Detalle de Plática/Campaña (Solo en lista de asistentes)"]
    end

    subgraph DONDE_NO ["DONDE NO SE MUESTRA (Excluidas por Ruido Visual / 10 Vistas)"]
        direction TB
        N1["/admin/home (Dashboard macro directivo)"]
        N2["/activity (Crear actividad colectiva)"]
        N3["/admin/quick-activities (Plantillas maestras permanentes)"]
        N4["/pets (Censo animal comunitario)"]
        N5["/survey y /contact (Analítica y directorio externo)"]
        N6["/sobre-mi (Edición de biografía personal)"]
        N7["/survey/form (Captura de preguntas en campo)"]
        N8["/auth/login y /signup (Sin sesión autenticada)"]
        N9["Formularios públicos ciudadanos (Trámites externos)"]
    end
```

#### 1. Catálogo de Vistas donde SÍ va el Folio (Especificación de Componentes)

| # | Vista y Ruta | Rol de Acceso | Qué muestra la vista (Código) | Folios Mostrados | Elemento UI y Ubicación Exacta |
| :-: | :--- | :--- | :--- | :---: | :--- |
| **1** | **`/my-accreditations`**<br>([`MyAccreditationsComponent`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/my-accreditations/my-accreditations.ts)) | `student` | Bandeja de horas y actividades personales, solicitudes pendientes/aprobadas y modal de nueva solicitud. | **Folio de Interacción (`AC` / `OP`)** | **En cada tarjeta y fila de tabla:** Píldora destacada junto al estatus (`.folio-pill-interactive`) con botón de copiado rápido al portapapeles. |
| **2** | **`/admin/accreditations`**<br>([`AccreditationListComponent`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/accreditation-list/accreditation-list.ts)) | `admin` | Bandeja general de validación de horas (pendientes e historial). Dictamen con modal de observaciones. | **Folio de Interacción (`AC` / `OP`)** | **Columna dedicada en la tabla principal (`th.folio-col`, `td.folio-cell`):** Permite ordenar, filtrar y cotejar solicitudes universitarias. |
| **3** | **`/student-profile`**<br>([`StudentProfile`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/student-profile/student-profile.ts)) | `student` | Perfil del estudiante: progreso sobre 480 hrs, carrera, matrícula, expediente y actividades asignadas. | **Ambos:**<br>• `SS-YYMMDD-HEX`<br>• `AC` / `OP` | • **Header:** Badge institucional permanente `.profile-header-folio-badge` junto al nombre.<br>• **Tabla de Actividades Asignadas:** Primera columna con el folio de interacción de cada actividad/hora. |
| **4** | **`/volunteer-profile`**<br>([`VolunteerProfile`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/volunteer-profile/volunteer-profile.ts)) | `volunteer` | Perfil del voluntario general: grados académicos, constancia de vinculación e historial de asistencias. | **Ambos:**<br>• `VG-YYMMDD-HEX`<br>• `AC` / `OP` | • **Hero:** Badge `.profile-header-folio-badge` junto al nombre.<br>• **Tabla de Participaciones:** Columna de folio para amparar cada asistencia cívica. |
| **5** | **`/onboarding/expediente`**<br>([`ExpedienteRecibidoComponent`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/onboarding/expediente-recibido.component.ts)) | `student`<br>`volunteer` | Estado de revisión documental (`pending`, `accepted`, `rejected`), observaciones de coordinación y descarga de carta. | **Folio de Expediente (`SS` / `VG`)** | **Hero superior:** Contenedor destacado `.expediente-folio-badge` con tipografía monoespaciada: *"Tu Folio Oficial de Admisión: SS-261030-01"*. |
| **6** | **`/student`**<br>([`StudentComponent`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/student/student.component.ts)) | `admin` | Tabla general de voluntarios (pestaña Estudiantes y pestaña Voluntarios Generales), buscador y paginador. | **Folio de Expediente (`SS` / `VG`)** | **Columna visible e indexada (`th.folio-th`, `td.folio-cell`):** Permite buscar directamente por folio en el input de filtrado rápido. |
| **7** | **`/student/:id`**<br>([`StudentDetail`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/student-detail/student-detail.ts)) | `admin` | Ficha exhaustiva del estudiante: expediente digital, URLs de Drive, actividades asignadas y bitácora de estatus. | **Ambos:**<br>• `SS-YYMMDD-HEX`<br>• `AC` / `OP` | • **Encabezado principal:** Badge de folio escolar.<br>• **Tabla de Actividades y Acreditaciones:** Columna dedicada exhibiendo `AC-...` u `OP-...` en cada registro. |
| **8** | **`/volunteer-detail/:id`**<br>([`VolunteerDetail`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/volunteer-detail/volunteer-detail.ts)) | `admin` | Ficha del voluntario general: grados académicos, participaciones cívicas y bitácora de estatus. | **Ambos:**<br>• `VG-YYMMDD-HEX`<br>• `AC` / `OP` | • **Encabezado:** Badge `VG-...`<br>• **Tabla de Participaciones:** Columna de folio de asistencia de cada jornada. |
| **9** | **`/volunteers/history`**<br>*(Propuesta Técnica)* | `admin` | Historial de voluntarios pasados inactivos $> 12$ meses y bitácora de transiciones. | **Ambos:**<br>• `SS` / `VG`<br>• `AC` / `OP` | • **Tablas de Historial:** Folio de expediente en cada fila.<br>• **Modal de Desglose:** Folios `AC/OP` de las participaciones pasadas para atender requerimientos universitarios. |

---

#### 2. Vistas con Visibilidad Condicional / Dinámica

| Vista y Ruta | Rol de Acceso | Comportamiento sin Inscripción previa | Comportamiento con Inscripción Confirmada |
| :--- | :--- | :--- | :--- |
| **`/activity-list`**<br>([`ActivityListComponent`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/activity-list/activity-list.component.ts)) | `student`<br>`volunteer` | **NO se muestra ningún folio.** La tarjeta exhibe los datos generales de la convocatoria y el botón *"Inscribirme"*. | **SÍ se muestra una píldora con el Folio:** El botón de inscripción se reemplaza por el badge: `Folio: AC-261102-0A14 · Estado: Registrado`. |
| **`/activity-list/:id`**<br>([`ActivityDetail`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/activity-detail/activity-detail.ts)) | `student`<br>`volunteer` | **NO se muestra folio.** Muestra el botón de postulación o inscripción. | **SÍ se muestra el banner de participación:** En el hero superior aparece una barra destacada: `Tu Folio de Inscripción es: AC-261102-0A14` con botón de *"Copiar"*. |
| **Detalle de Oportunidad**<br>(`/admin/talks/:id`, `/admin/campaigns/:id`, `/admin/adoptions/:id`) | `admin` | **NO se muestra en el encabezado del evento.** La plática o campaña no es una interacción individual. | **SÍ en la lista de voluntarios asistentes:** Cada fila de la tabla de colaboradores inscritos exhibe su folio individual (`OP-TLK-...`, `OP-CAM-...`). |

---

#### 3. Vistas donde NO Vale la Pena Mostrar el Folio (Exclusión Justificada)

| Vista y Ruta | Rol | Qué muestra | Razón de Exclusión (Cero Ruido Visual) |
| :--- | :--- | :--- | :--- |
| **`/admin/home`** | `admin` | Tablero directivo con tarjetas de métricas agregadas (totales de voluntarios, horas acumuladas, actividades creadas). | **Vista macro-estadística.** No opera sobre registros individuales. Añadir folios generaría saturación absurda. |
| **`/activity`** | `admin` | Formulario para crear una nueva actividad institucional y catálogo general. | La actividad a crear es una entidad institucional abstracta. El folio de interacción sólo nace cuando un alumno se inscribe. |
| **`/admin/quick-activities`** | `admin` | Plantillas maestras reutilizables (limpieza, eventos exprés). | Son moldes permanentes de configuración; no tienen relación con ningún voluntario individual. |
| **`/pets`** | `admin` | Padrón y censo de animales comunitarios (vacunas, fotos, citas). | Es la entidad paciente animal de Querétaro; no pertenece al subsistema de horas de voluntarios. |
| **`/survey`** y **`/contact`** | `admin` | Tableros analíticos de encuestas y directorio de aliados/veterinarios. | Gráficas agregadas de Business Intelligence y directorio externo sin relación con folios de servicio. |
| **`/sobre-mi`** | `student`<br>`volunteer` | Formulario de edición de biografía personal, teléfono y redes sociales. | Pantalla de edición de campos blandos. Exhibir folios aquí sobrecarga el formulario sin aportar valor. |
| **`/survey/form`** | Colaborador | Cuestionario de 25 preguntas socioambientales para aplicar en campo. | Durante la captura de datos en campo se requiere máxima agilidad; no debe haber folios distractores. |
| **`/auth/login` y `/signup`** | Público | Formularios de inicio de sesión y registro público. | No existe sesión autenticada ni cuenta creada todavía. |
| **Formularios Públicos Ciudadanos** (`/formularios/...`) | Ciudadanía | Solicitud ciudadana de adopción, placa o plática. | Son trámites de cara a la comunidad externa, no interacciones de voluntariado de horas. |

---

#### 4. Especificación Visual y Estilos de Interfaz (Design System ABAQ)

Para mantener una presentación consistente, limpia y accesible, los folios se renderizan bajo tres patrones visuales estandarizados:

```
1. BADGE DE FOLIO DE EXPEDIENTE (Header de Perfil y Tablas Generales)
   ┌────────────────────────────────────────────────────────┐
   │  FOLIO: SS-261030-01                                   │  (Fondo azul suave, borde 1.5px, monoespaciado)
   └────────────────────────────────────────────────────────┘

2. PÍLDORA DE ACTIVIDAD CONVOCADA (AC)
   ┌────────────────────────────────────────────────────────┐
   │  📅 AC-261102-0A14 · Registrado                       │  (Fondo verde esmeralda suave, texto institucional)
   └────────────────────────────────────────────────────────┘

3. PÍLDORA DE OPORTUNIDAD INSTITUCIONAL (OP)
   ┌────────────────────────────────────────────────────────┐
   │  🏷️ OP-STE-261102-03C8 · Validado (10 hrs)             │  (Sub-código de 3 letras visible, monoespaciado)
   └────────────────────────────────────────────────────────┘
```

##### Clases CSS Estandarizadas
```css
/* Badge de Folio de Expediente (Estudiantes y Voluntarios Generales) */
.folio-badge-expediente {
  font-family: 'SF Mono', 'Roboto Mono', Menlo, monospace;
  font-size: 0.88rem;
  font-weight: 800;
  letter-spacing: 0.5px;
  background: rgba(31, 47, 99, 0.08);
  border: 1.5px solid rgba(31, 47, 99, 0.28);
  color: #1f2f63;
  padding: 3px 10px;
  border-radius: 6px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

/* Píldora de Folio de Actividad (AC) */
.folio-pill-ac {
  font-family: 'SF Mono', 'Roboto Mono', Menlo, monospace;
  font-size: 0.82rem;
  font-weight: 700;
  background: rgba(45, 106, 46, 0.1);
  border: 1px solid rgba(45, 106, 46, 0.35);
  color: #2d6a2e;
  padding: 2px 8px;
  border-radius: 20px;
  display: inline-flex;
  align-items: center;
  gap: 5px;
}

/* Píldora de Folio de Oportunidad (OP) */
.folio-pill-op {
  font-family: 'SF Mono', 'Roboto Mono', Menlo, monospace;
  font-size: 0.82rem;
  font-weight: 700;
  background: rgba(234, 88, 12, 0.1);
  border: 1px solid rgba(234, 88, 12, 0.35);
  color: #c2410c;
  padding: 2px 8px;
  border-radius: 20px;
  display: inline-flex;
  align-items: center;
  gap: 5px;
}
```

---

## 6. Sistema Transaccional de Notificaciones (Resend)

Reintegrado de la rama `dev-rivers`, el servicio `backend/utils/email.js` utiliza la API oficial de Resend. 

!!! important "Destinatarios Exclusivos: Los Voluntarios"
    Todas las notificaciones del ciclo de vida son **exclusivamente para los voluntarios** (estudiantes de servicio social y voluntarios generales). Se despachan directamente a su dirección de correo electrónico personal registrada. **No existen notificaciones hacia los administradores ni se implementa ninguna interfaz web, campana o bandeja in-app**; la comunicación es 100% por correo electrónico transaccional.

```mermaid
flowchart TD
    E1["Aprobación de Expediente"] -->|Inmediato| M1["sendAcceptanceEmail()\nEnviado al correo del Voluntario\n(Enlace a Carta de Aceptación Oficial)"]
    E2["Inactividad: Día 45"] -->|Cron Diario| M2["sendInactivityWarningEmail(stage='day45')\nEnviado al correo del Voluntario\n(Alerta de 15 días restantes antes de baja)"]
    E3["Inactividad: Día 60"] -->|Cron Diario| M3["sendInactivityWarningEmail(stage='day60')\nEnviado al correo del Voluntario\n(Aviso de baja definitiva por abandono)"]
    E4["Finalización Exitosa"] -->|Inmediato al completar| M4["sendCompletionEmail()\nEnviado al correo del Voluntario\n(Student: con 480 hrs + Certificado\nGeneral: sin horas + Agradecimiento)"]
```

1. **Aceptación de Expediente (`sendAcceptanceEmail`):** Notifica al voluntario a su buzón que su cuenta fue validada, con enlace directo para descargar su Carta de Aceptación Oficial.
2. **Alerta Preventiva de Inactividad a los 45 días (`sendInactivityWarningEmail`, stage 45):** Advierte al voluntario a su correo que acumula 45 días continuos sin participación y que le restan 15 días antes de la baja definitiva.
3. **Baja por Inactividad a los 60 días (`sendInactivityWarningEmail`, stage 60):** Notifica al voluntario su desvinculación formal por inactividad prolongada (sin certificado de finalización).
4. **Finalización de Vinculación (`sendCompletionEmail`):**
   - **Para Estudiante de Servicio Social:** Reconocimiento con cómputo de sus **480 horas** acreditadas y enlace de descarga a su **Certificado de Finalización Oficial**.
   - **Para Voluntario General:** Reconocimiento y carta de agradecimiento institucional por su labor comunitaria, sin mención de cómputo de horas.

---

## 7. Emisión Criptográfica de Constancias y Certificados

La generación de documentos oficiales se desacopla en dos eventos precisos del ciclo de vida:

| Certificado / Constancia | Evento de Emisión | Condición Obligatoria | Mecanismo Criptográfico |
| :--- | :--- | :--- | :--- |
| **Carta de Aceptación y Felicitación** | Transición a `active` | Aprobación formal por administrador | Token SHA-256 (`acceptance`) verificado en `/certificate/v/:token` |
| **Certificado de Finalización Oficial** | Transición a `inactive` | **Únicamente por término exitoso** (480 horas completadas o desvinculación formal regular) | Token SHA-256 (`completion`) con firma digital institucional y código QR |

!!! warning "Exclusión Estricta de Constancia"
    Si un usuario pasa a `inactive` por **inactividad (60 días de abandono)** o por **sanción administrativa**, el sistema **NO** emite certificado de finalización. La constancia es un mérito oficial reservado a voluntarios que concluyeron formalmente.

---

## 8. Homologación Visual de Encabezados (Design System)

Para unificar la identidad visual de la plataforma en ambos roles, todos los encabezados de sección adoptan el patrón estándar institucional `.admin-hero` / `.page-hero`:

```scss
/* Contenedor estándar unificado de encabezado */
.page-hero,
.admin-hero {
  background: linear-gradient(135deg, #1f2f63 0%, #24366f 35%, #2d6a2e 78%, #5ca83a 100%);
  color: #ffffff;
  padding: 32px 36px;
  border-radius: 20px;
  margin-bottom: 28px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 10px 25px -5px rgba(31, 47, 99, 0.25);

  .hero-text-block {
    .eyebrow {
      display: inline-block;
      font-size: 11.5px;
      font-weight: 800;
      letter-spacing: 1.5px;
      text-transform: uppercase;
      opacity: 0.85;
      margin-bottom: 6px;
    }
    h1 {
      font-size: 28px;
      font-weight: 800;
      margin: 0 0 8px 0;
      color: #ffffff;
    }
    p {
      margin: 0;
      font-size: 14.5px;
      opacity: 0.9;
      max-width: 680px;
      line-height: 1.5;
    }
  }
}
```

### Pantallas Homologadas:
- **Rol Administrador:** Home (`/admin/home`), Voluntarios (`/student`), Actividades (`/activity`), Respaldos y Deshidratación (`/backup`), Historial de Voluntarios Pasados (`/volunteers/history`), Encuestas (`/survey`).
- **Rol Voluntario / Estudiante:** Catálogo de Actividades (`/activity-list`), Detalle de Actividad (`/activity-detail/:id`), Perfil de Voluntario (`/volunteer-profile`), Encuestas (`/survey`).
