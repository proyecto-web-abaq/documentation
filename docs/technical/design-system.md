# ABAQ — Design System, Visual Language & Codebase Specification (`DESIGN.md`)

> **Source of Truth**: Extraído directamente del código en producción de la rama `dev` (`frontend/` commit `1d76cbd`, `backend/` commit `43b51f1` y `documentation/`). Cada token de color, ancho de contenedor (`max-width`), regla de encabezado `.admin-hero`, comportamiento responsivo de botones en tableta/móvil (`327px`–`1024px`), sistema de pestañas de tablas y lenguaje de interfaz proviene del código real en Angular v22 Standalone, Node.js v24 / Express v4.19 y MongoDB.

---

## 1. Propósito, Lenguaje de Diseño Humano y Rasgos Dominantes

### 1.1 Propósito de la Plataforma
**ABAQ** (**Amor y Bienestar Animal en Querétaro**) digitaliza y coordina el **Servicio Social universitario (`SS`)**, el **Voluntariado General (`VG`)**, las **actividades grupales y participaciones individuales**, los expedientes digitales con documentos PDF en el bucket institucional S3 de Railway, los formularios públicos de bienestar animal y las constancias oficiales con verificación criptográfica.

- **Nombre del Producto**: `ABAQ`
- **Subtítulo en Marca (`navbar`)**: `Servicio Social`
- **Secciones del Menú por Rol**:
  - **Colaborador (`student` / `volunteer`)**: `Inicio` (`/home` o `/volunteer-home`), `Mi participación` (`/activity-list`), `Mi Perfil` (`/student-profile` o `/volunteer-profile`).
  - **Administrador (`admin`)**: `Inicio` (`/admin/home`), `Participación` (`/activity-list`), menú desplegable **`Base de datos`** (`Voluntarios` `/student`, `Adopciones` `/admin/adoptions`, `Pláticas` `/admin/talks`, `Campañas EST` `/admin/campaigns`, `Placas de Identificación` `/admin/identifications`), y `Respaldos` (`/admin/backups`).

### 1.2 Lenguaje de Diseño Humano y Reglas Semánticas
1. **Lenguaje Simple Centrado en «Participación» (Cero Jerga Críptica)**:
   - La sección unificada se llama **`Mi participación`** (para colaboradores) y **`Participación`** (para administración).
   - Se prohíbe mostrar en etiquetas visibles acrónimos internos (`AC`, `OP`, `STE`, `TLK`, `IDE`, `ADO`), nombres crudos en inglés (`optional`, `mandatory`, `specific`, `Full Name`, `School Mail`, `Status`) o identificadores internos de depuración (`ID`, `Auth ID`, `ID de estudiante`, `_id`).
   - Distinción conceptual clara para el usuario:
     - **`Actividad grupal`** (`AC` — folio `AC-YYMMDD-XXXX`): Jornada o evento convocado por ABAQ con fecha, horario, cupo y pase de lista grupal (representa la opción 1 de *Eventos ABAQ / Limpieza de refugio* dentro de las 11 opciones).
     - **`Participación individual`** (`OP` — folio `OP-YYMMDD-XXXX`): Solicitud granular mediante la cual el colaborador avisa a administración lo que realizó por su cuenta (cualquiera de las **11 opciones del catálogo**) adjuntando su evidencia en PDF para revisión.
2. **Tipos de Actividad Explicativos en Español**:
   - En los formularios administrativos de plantillas (`/admin/quick-activities`) y creación (`/activity`), los valores técnicos del esquema se traducen a frases autoexplicativas:
     - `mandatory` $\rightarrow$ **`Obligatoria · todos los participantes deben asistir`**
     - `optional` $\rightarrow$ **`Voluntaria · se inscribe quien quiera participar`**
     - `specific` $\rightarrow$ **`Por convocatoria · solo personas elegidas por administración`**
3. **Segregación Estricta de Horas (`SS` vs. `VG`)**:
   - **Estudiante de Servicio Social (`SS`)**: Acumula horas hacia su meta (480 h), recibe 10 h por inducción (Fase 2) y visualiza el banner `.accreditation-calc-banner` con multiplicadores en tiempo real (`Limpieza 4×`, `Placas 5×`, `Campaña de esterilización 10× / 100 h`, `Adopción 100 h`, `Redes 5 h + reacciones/5`, `Donaciones 1 h / $50 MXN`).
   - **Voluntario General (`VG`)**: Participa sin cómputo de horas curriculares (`hoursAccredited: 0`, `hoursPerformed: 0` en fallback silencioso). Se suprime toda píldora, columna, campo numérico o leyenda de horas en héroes, agenda, tarjetas, tablas y modales compartidos, conservando íntegramente la evaluación cualitativa de desempeño (`5 niveles` + comentario).
4. **Cero Avatares de Iniciales de Texto**:
   - Se eliminaron todos los círculos con iniciales de letras (`.avatar`, `.student-avatar`, `.context-avatar`) en encabezados, tablas, modales y perfiles de todos los roles para mantener una estética institucional limpia.

---

## 2. Anchos de Contenedor en Escritorio (`max-width`) y Discrepancias por Vista

El estándar canónico de lienzo para vistas principales de escritorio (`> 1024px`) es **`max-width: 1500px`** centrado (`margin: 0 auto`) con **`padding: 32px 24px 80px`** y `box-sizing: border-box`. No obstante, algunas vistas de formulario o detalle mantienen anchos específicos más acotados para optimizar la línea de lectura:

| Vista / Componente | Ruta | Selector Raíz | `max-width` en Escritorio | `padding` en Escritorio | Notas / Discrepancia Consciente |
|---|---|---|---|---|---|
| **Mi participación / Participación** | `/activity-list` | `.activities-page` | **`1500px`** | `32px 24px 80px` | Lienzo canónico de 1 columna (sin `div.activities-content` ni `aside`). |
| **Detalle de Actividad Grupal** | `/activity-list/:id` | `.activity-detail-page` | **`1500px`** | `32px 24px 80px` | Lienzo canónico homologado. |
| **Inicio Estudiante (`SS`)** | `/home` | `.home-page` | **`1500px`** | `32px 24px 80px` | Lienzo canónico homologado. |
| **Inicio Voluntario (`VG`)** | `/volunteer-home` | `.home-page` | **`1500px`** | `32px 24px 80px` | Lienzo canónico homologado. |
| **Mi Perfil (`SS` y `VG`)** | `/student-profile`, `/volunteer-profile` | `.profile-page` | **`1500px`** | `32px 24px 80px` | Lienzo canónico homologado. |
| **Padrón Base de Datos (Voluntarios)** | `/student` | `.students-page` | **`1500px`** | `32px 24px 80px` | Lienzo canónico homologado. |
| **Historial de Voluntarios y Bitácora** | `/volunteers/history` | `.history-page` | **`1500px`** | `32px 24px 80px` | Lienzo canónico homologado. |
| **Expediente Estudiante (Admin)** | `/student/:id` | `.student-detail-page` | **`1500px`** | `32px 24px 80px` | Lienzo canónico homologado. |
| **Expediente Voluntario (Admin)** | `/volunteer-detail/:id` | `.volunteer-detail-page` | **`1500px`** | `32px 24px 80px` | Lienzo canónico homologado. |
| **Listados de Base de Datos** | `/admin/adoptions`, `/talks`, `/campaigns`, `/identifications` | `.adoption-page`, `.talk-list-page`, `.campaign-list-page`, `.identification-page` | **`1500px`** | `32px 24px 80px` | Lienzo canónico homologado en los 4 módulos. |
| **Centro de Respaldos y Cortes** | `/admin/backups` | `.backup-container` | **`1500px`** | `32px 24px 80px` | Lienzo canónico homologado. |
| **Inicio Administrador** | `/admin/home` | `.admin-dashboard` | **`1440px`** | `34px 24px 80px` | Discrepancia leve (`60px` menor al estándar de `1500px`). |
| **Gestión de Plantillas** | `/admin/quick-activities` | `.quick-activities-page` | **`1400px`** | `32px` | Discrepancia leve (`100px` menor al estándar de `1500px`). |
| **Navbar Superior** | Global | `.navbar-shell` | **`min(1400px, 100vw)`** | `0 20px` | Barra fija superior de `72px` de altura. |
| **Detalle de Adopción** | `/admin/adoptions/:id` | `.adoption-detail-page` | **`1200px`** | `32px 24px` | Contenedor de lectura media para expediente de adopción. |
| **Detalles de Plática, Campaña y Placa** | `/admin/talks/:id`, `/campaigns/:id`, `/identifications/:id` | `.talk-detail-page`, `.campaign-detail-page`, `.identification-detail-page` | **`1100px`** | `30px 24px` | Contenedor enfocado en fichas de detalle e inspección. |
| **Crear Actividad Manual** | `/activity` | `.activity-page` | **`1050px`** | `32px 24px 80px` | Contenedor de formulario de una sola tarjeta. |
| **Formularios Públicos Externos** | `/formularios/*` | `.form-container` | **`850px` – `900px`** | `40px 24px` | Ancho acotado de lectura para ciudadanos externos. |

> **Overrides Globales en Tableta y Móvil (`frontend/src/styles.scss`)**:
> - **Tableta (`<= 1024px`)**: Todos los contenedores de página fuerzan `padding-left: 16px !important; padding-right: 16px !important; max-width: 100% !important;`.
> - **Móvil (`<= 768px`)**: Todos los contenedores fuerzan `padding: 24px 10px 50px !important; width: 100% !important;` (`.profile-page` conserva `padding-top: 72px !important`).
> - **Móvil Ultra-Angosto (`<= 480px`)**: `padding-left: 8px !important; padding-right: 8px !important;`.

---

## 3. Homologación de Encabezados Hero (`.admin-hero`, `.student-hero`, `.volunteer-hero`) y `a.back-link`

Todas las vistas operativas de la plataforma abren con el encabezado institucional homologado:

### 3.1 Enlace Superior Externo de Retorno (`a.back-link`)
- En todas las vistas de detalle y sub-vistas (`/admin/quick-activities`, `/activity`, `/volunteers/history`, `/activity-list/:id`, `/student/:id`, `/volunteer-detail/:id`, `/admin/talks/:id`, `/admin/campaigns/:id`, `/admin/adoptions/:id`, `/admin/identifications/:id`), el botón de retorno se coloca **fuera y arriba a la izquierda del hero**:
  ```html
  <a class="back-link" routerLink="/admin/quick-activities" role="button" tabindex="0">
    ← Volver a plantillas
  </a>
  ```
- **Estilo**: `display: inline-flex; align-items: center; gap: 6px; margin-bottom: 18px; color: #36508f; font-size: 13px; font-weight: 700; text-decoration: none;` con `transform: translateX(-2px)` en `:hover`.

### 3.2 Anatomía del `.admin-hero`
- **Superficie y Gradiente**:
  - `background: linear-gradient(135deg, #24366f 0%, #334c91 58%, #5ca83a 135%);`
  - `border-radius: 22px; padding: 30px 34px; color: #ffffff; box-shadow: 0 18px 40px rgba(27, 43, 94, 0.16);`
- **Fila Superior (`.hero-header-row` / `.hero-top-row`)**:
  - `display: flex; align-items: flex-start; justify-content: space-between; gap: 20px; flex-wrap: wrap;`
  - **Bloque de Texto Izquierdo (`.hero-text-block`)**:
    - `.hero-eyebrow`: `font-size: 11px; font-weight: 800; letter-spacing: 0.08em; text-transform: uppercase; opacity: 0.85;`
    - `h1` / `.hero-title`: `font-size: 30px; font-weight: 800; line-height: 1.15; color: #ffffff;`
    - `.hero-subtitle`: `font-size: 14px; line-height: 1.6; opacity: 0.92; max-width: 640px;`
    - `<app-folio-pill>`: Cuando el hero representa un expediente o actividad con folio (`SS-YYMMDD-XX`, `VG-YYMMDD-XX`, `AC-YYMMDD-XXXX`), se inserta el componente `<app-folio-pill [folio]="..." variant="hero">` con copiado al portapapeles en un clic.
  - **Fila de Botones de Acción Derecha (`.hero-actions-row` / `.hero-actions`)**:
    - `display: flex; align-items: center; justify-content: flex-end; flex-wrap: wrap; gap: 12px;`
- **Fila Inferior de Estadísticas Integradas (`.hero-stats-row`)**:
  - `display: flex; flex-wrap: wrap; gap: 10px; padding-top: 12px; border-top: 1px solid rgba(255, 255, 255, 0.16);`
  - **Regla de Orden Canónico**: La **primera píldora de izquierda a derecha** (`.hero-stat-pill.stat-total-first`) muestra siempre el **conteo total general** de registros de la vista (ej. `25 participaciones en total`, `42 colaboradores registrados`), seguida de los desgloses por estado.
  - **Estructura de `.hero-stat-pill`**:
    - `background: rgba(255, 255, 255, 0.14); border: 1px solid rgba(255, 255, 255, 0.24); border-radius: 12px; padding: 8px 16px; backdrop-filter: blur(6px);`
    - `.stat-number`: `font-size: 18px; font-weight: 800; color: #ffffff; white-space: nowrap; flex-shrink: 0;` (garantiza que unidades como `200 h` jamás se partan en dos renglones).
    - `.stat-label`: `font-size: 12.5px; font-weight: 600; color: rgba(255, 255, 255, 0.9);`

---

## 4. Sistema de Botones en Encabezados y Tarjetas (y Reglas Responsivas en Tableta y Móvil)

### 4.1 Variantes de Botones en el Hero (`.hero-actions-row`)
1. **CTA Primario Blanco (`.btn-create-item`, `.btn-new-accreditation`, `.btn-invite-volunteers`)**:
   - `background: #ffffff; color: #24366f; border-radius: 12px; padding: 10px 18px; font-size: 13.5px; font-weight: 700; box-shadow: 0 6px 18px rgba(0, 0, 0, 0.12);`
2. **CTA Secundario Glassmórfico (`.btn-hero-action.btn-hero-glass`, `.btn-copy-form`, `.btn-view-history`)**:
   - `background: rgba(255, 255, 255, 0.15); color: #ffffff; border: 1px solid rgba(255, 255, 255, 0.32); border-radius: 12px; padding: 10px 18px; backdrop-filter: blur(8px);`
3. **Interacción Dual en Botones `.btn-copy-form` (`[appLongPressOpen]`)**:
   - Presente en Campañas (`/formularios/campanas`), Pláticas (`/formularios/platicas`), Adopciones (`/formularios/adopciones`) y Placas (`/formularios/placas`).
   - **Clic / Tap corto**: Copia la URL pública al portapapeles.
   - **Mantener presionado (`600 ms` con mouse, touch o pen vía `LongPressOpenDirective`)**: Abre el formulario público en una pestaña nueva (`window.open(url, '_blank', 'noopener')`), cancelando el `(click)` posterior y suprimiendo el menú contextual móvil.
4. **CTA Destructivo en Detalle (`.btn-hero-delete`, `.btn-inactivate-hero`)**:
   - Alineado arriba a la derecha del hero; abre `<app-delete-confirm-modal>` (que exige escribir `"borrar"` para habilitar la confirmación).

### 4.2 Reglas de Responsividad de Botones (Escritorio $\rightarrow$ Tableta $\rightarrow$ Móvil `327px`)
- **Escritorio (`> 1024px`)**:
  - Los botones de `.hero-actions-row` se alinean a la derecha en su tamaño intrínseco.
- **Tableta (`<= 1024px` y `<= 900px`, ej. `680px`)**:
  - `.hero-header-row` pasa a `flex-direction: column; align-items: stretch; gap: 14px;`.
  - `.hero-actions-row` y `.hero-actions` ocupan `width: 100%; display: flex; flex-wrap: wrap; gap: 10px;`.
  - Cada botón aplica `flex: 1 1 220px; max-width: 100%; white-space: normal; text-align: center; justify-content: center; box-sizing: border-box;` para acomodarse limpia y simétricamente de dos en dos (`50% / 50%`) sin desbordar el contenedor.
- **Móvil (`<= 768px`, `<= 540px` y resoluciones ultra-angostas como `376px` y `327 × 2751 px`)**:
  - `.hero-actions-row`, `.hero-actions` y `.edit-btn-group` colapsan a columna (`flex-direction: column !important; align-items: stretch !important; width: 100% !important; gap: 10px !important;`).
  - Todos los botones de hero y sección aplican `width: 100% !important; max-width: 100% !important; flex: none !important; white-space: normal !important; justify-content: center !important; text-align: center !important; box-sizing: border-box !important;`.
  - **Regla Anti-Estiramiento Vertical en Contenedores Columna (`.activity-actions`, `.prep-actions-row`)**:
    - En tarjetas cuyas botoneras cambian de fila (en tableta) a `flex-direction: column` (en móvil), queda **prohibido** dejar un `flex-basis` en píxeles (como `flex: 1 1 160px`), ya que en dirección columna `flex-basis` se convierte en altura mínima e infla los botones a `160px` de alto. En móvil deben declarar explícitamente `flex: 0 0 auto; height: auto; width: 100%; min-height: 42px–44px;`.

---

## 5. Sistema de Pestañas de Tablas (`.vol-tabs`, `.sd-tabs`, `.history-tabs`) y Transformación Móvil

### 5.1 Variantes de Pestañas en la Plataforma
Aunque cumplen la misma función de segmentar vistas de tablas y listados, coexisten dos estilos visuales principales en el código:

1. **Pestañas con Borde Inferior Activo (`.vol-tabs` / `.vol-tab` y `.history-tabs` / `.history-tab`)**:
   - Usadas en: **Participación** (`/activity-list`: `Para inscribirme y recientes` | `Mi historial`), **Base de datos de Voluntarios** (`/student`: `Todos` | `Servicio Social` | `Voluntariado General`) e **Historial** (`/volunteers/history`: `Estudiantes pasados` | `Voluntarios pasados` | `Bitácora`).
   - **Estilo en Escritorio**: Barra horizontal con `border-bottom: 2px solid #e2e8f0; gap: 8px;`. Cada `.vol-tab` tiene fondo transparente (o blanco/gris tenue), texto `#64748b`, `font-weight: 700`, indicador inferior activo en azul/verde institucional (`#24366f` / `#5ca83a`) y badge numérico `.vol-tab-count` (`border-radius: 999px; flex-shrink: 0`).
2. **Pestañas Tipo Píldora Redondeada (`.sd-tabs` / `.sd-tab` y `.filter-chip`)**:
   - Usadas en: **Expediente de Estudiante y Voluntario** (`/student/:id`, `/volunteer-detail/:id`, `/student-profile`, `/volunteer-profile`: `Todas` | `Actividades` | `Acreditaciones`) y en la barra superior de filtro de `Estatus:` en `/student`.
   - **Estilo**: `border-radius: 999px; padding: 8px 16px; border: 1.5px solid #dce2e8; background: #ffffff; color: #4b5563; font-size: 13px; font-weight: 700;`. En estado `.active`: `background: #24366f; border-color: #24366f; color: #ffffff; box-shadow: 0 4px 12px rgba(36, 54, 111, 0.2);` con contador `.sd-tab-count`.

### 5.2 Ergonomía Táctil de Pestañas y Tablas en Tableta y Móvil
- **Carrusel Horizontal sin Apilamiento Vertical (`<= 1024px` / `<= 768px`)**:
  - `.vol-tabs`, `.sd-tabs` y `.history-tabs` aplican `display: flex; flex-wrap: nowrap !important; overflow-x: auto; -webkit-overflow-scrolling: touch; scroll-snap-type: x mandatory; scrollbar-width: none;`.
  - Cada pestaña mantiene `white-space: nowrap; flex: 0 0 auto; min-height: 42px–44px; scroll-snap-align: start;`.
- **Transformación de Tablas a Tarjetas Etiquetadas (`<= 900px`)**:
  - Las tablas operativas (`.students-table`, `.volunteer-table`, `.sd-combined-table`, `.ranked-activities-table`) ocultan su `thead` (`display: none`) y transforman cada `tbody tr` en una tarjeta blanca (`display: flex; flex-direction: column; padding: 16px; border: 1px solid #e2e8f0; border-radius: 14px; gap: 8px;`).
  - Cada celda `td` se muestra como fila llave-valor (`display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; border-bottom: 1px dashed #f1f5f9;`) inyectando el título de columna en español mediante `td::before { content: attr(data-label); font-weight: 700; color: #64748b; font-size: 11.5px; text-transform: uppercase; }`.

### 5.3 Sistema de Paginación Institucional (`<app-pagination>` — `PaginationComponent`)
- **Ubicación**: `frontend/src/app/components/ui/pagination/pagination.component.{ts,html,scss}` (`ChangeDetectionStrategy.OnPush`).
- **Visibilidad Condicional**: Solo se renderiza cuando `computedTotalPages > 1`.
- **Anatomía y Controles (`.pagination-wrapper` / `.pagination-controls`)**:
  - **Flechas de Salto Rápido al Inicio y Final (`«` y `»`)**: Se activan automáticamente cuando `computedTotalPages >= 10` (o mediante `[showFirstLastNav]="true"`).
  - **Flechas Anterior y Siguiente (`‹` y `›`)**: Siempre visibles a los extremos del riel numérico (`.pagination-nav-button`: `background: #f8fafc; color: #334155; border-color: #cbd5e1;`).
  - **Riel Horizontal Deslizable (`.pagination-track`)**:
    - `max-width: min(100%, 540px); overflow-x: auto; scroll-behavior: smooth; scroll-snap-type: x proximity; scrollbar-width: thin;`.
    - En escritorio permite desplazar horizontalmente los números usando la rueda vertical del ratón (`(wheel)="onTrackWheel($event)"`).
    - Al cambiar de página (`goToPage`), centra automáticamente el botón `.pagination-button.active` dentro del riel (`scrollToActivePage()`).
  - **Botones Numéricos (`.pagination-button`)**:
    - Reposo: `min-width: 38px; height: 38px; border-radius: 10px; border: 1px solid #e2e8f0; background: #ffffff; color: #475569; font-size: 14px; font-weight: 600;`.
    - Activo (`.active`): `background: var(--pagination-active-bg, #2563eb); border-color: var(--pagination-active-bg, #2563eb); color: #ffffff; font-weight: 700; box-shadow: 0 2px 6px rgba(37, 99, 235, 0.3);`.
  - **Indicador de Posición (`.pagination-indicator`)**:
    - Cuando hay más de 12 páginas (`computedTotalPages > 12`), muestra debajo del riel una píldora `Página X de Y` (`background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 999px; font-size: 12.5px;`).
- **Modos de Scroll Vertical al Paginar (`[scrollBehavior]`)**:
  - `'preserve'` (por defecto): Conserva exactamente la posición vertical `window.scrollY` para no provocar saltos de pantalla al cambiar de página en tablas intermedias.
  - `'top'`: Desplaza suavemente al inicio de la ventana.
  - `'anchor'`: Desplaza suavemente hacia el selector o elemento indicado en `[scrollTarget]`.
  - `'none'`: Sin acción de scroll.
- **Responsividad del Paginador**:
  - **Tableta / Móvil (`<= 768px`)**: `.pagination-track` ajusta su ancho a `max-width: calc(100vw - 190px); gap: 5px;`.
  - **Móvil Compacto (`<= 480px`)**: `.pagination-track` pasa a `max-width: calc(100vw - 160px); gap: 4px;` y los botones reducen su geometría a `min-width: 34px; height: 34px; font-size: 13px; border-radius: 8px;`.
  - **Móvil Ultra-Angosto (`<= 360px` / `327px`)**: `.pagination-track` aplica `max-width: calc(100vw - 140px);` y botones de `min-width: 30px; height: 32px; font-size: 12px;` para que las flechas `« ‹` y `› »` nunca desborden el ancho de la pantalla.

---

## 6. Arquitectura Visual de «Mi participación» (`/activity-list`) y Formularios de Plantillas

### 6.1 Estructura Unificada de «Mi participación»
1. **Hero Superior (`header.activities-header.admin-hero`)**:
   - **Colaborador**: Botón blanco `Ver actividades para inscribirme` + botón glass `Registrar participación individual`.
   - **Administrador**: Botón blanco `Nueva actividad grupal` (que navega a `/admin/quick-activities`) + botón glass `Registrar participación a colaborador`.
   - **Estadísticas**: 1ª píldora `participaciones en total`, seguida de `próximas en mi agenda`, `en revisión`, `validadas` y (solo para `SS`) `h acumuladas de 480 h`.
2. **Agenda Abierta de 2 Semanas (`div.agenda-open-wrapper`)**:
   - Sin contenedor blanco envolvente para aprovechar los `1500px` de ancho.
   - Dividida en **Esta semana** y **Próxima semana** con paginación `<app-pagination>`.
   - Cada tarjeta `section.next-activity-spotlight` integra:
     - `div.ticket-stub-left`: Bloque azul marino con fecha, mes y horario (en móvil `<= 768px` se convierte en barra horizontal a todo lo ancho).
     - `div.ticket-center`: Píldoras de identificación (`<app-folio-pill>`, origen `Actividad grupal` / `Participación individual`, categoría), título, descripción, metadatos y nota contextual diferenciando **`Indicaciones:`** (de admin en `AC`) vs. **`Comentario de solicitud:`** (del colaborador en `OP`).
     - `div.split-prep-box`: Contiene la barra de progreso de 3 fases `.step-pipeline` y los botones de acción (`.prep-actions-row`).
3. **Barra de Progreso de 3 Fases (`.step-pipeline`) Sin Píldoras de Estado Redundantes**:
   - **Actividad grupal (`AC`)**: `1. Inscrito` $\rightarrow$ `2. Asistencia` (o `.failed` `2. No asistió`) $\rightarrow$ `3. Validada` (`.done-green`).
   - **Participación individual (`OP`)**: `1. Enviada` $\rightarrow$ `2. En revisión` (`.active` ámbar) $\rightarrow$ `3. Validada` (`.done-green`, o `.failed` `3. Rechazada`).
   - Donde aparece `.step-pipeline`, no se renderiza ninguna píldora de estado adicional.
4. **Dos Pestañas Inferiores con Corte de 7 Días y Ordenamiento Canónico (`compareRecentFirstThenStatus`)**:
   - **Pestaña 1 (`Para inscribirme y recientes`)**: Actividades abiertas para inscripción + registros de hasta 7 días de antigüedad en tarjetas `article.activity-card`.
   - **Pestaña 2 (`Mi historial`)**: Registros con más de 7 días de antigüedad en `table.sd-combined-table`.
   - **Ordenamiento**: Ambas pestañas ordenan del registro **más reciente al más antiguo** (`b.date.getTime() - a.date.getTime()`) y, a igual fecha, por jerarquía de estado (`statusRank`: abierta para inscribirse $\rightarrow$ pendiente $\rightarrow$ inscrito $\rightarrow$ asistió $\rightarrow$ validada).
5. **Cajón Desplegable `Ver detalles` (`.record-details-drawer`) y Descarga de Evidencia PDF con Cooldown**:
   - Despliega todos los campos granulares de la participación (`quantity`, `participantsCount`, `animalsEnrolled`, `infrastructureAvailable`, `reactionsCount`, `donationAmount`, `trialStartDate`, `trialEndDate`, `performance`, `performanceComment`) y el botón **`Descargar documento (.PDF)`** con caché de `Blob` en memoria (2.º y 3.er intento sin red) y enfriamiento (*cooldown*) al superar 3 intentos.
6. **Comportamiento para Colaboradores Inactivos (`isUserInactive`) y Tabla `Historial` en Perfiles**:
   - Cuando `accountStatus === 'inactive'`, el usuario en `/activity-list` solo ve las actividades y participaciones individuales que él mismo realizó o envió (`isEnrolledOrSubmitted`, incluyendo las que siguen pendientes de validación por el administrador), nunca las nuevas actividades abiertas (`isOpenForEnrollment`). Sus controles de mutación (`Ver actividades para inscribirme`, `Registrar participación individual`, `Inscribirme`, `Cancelar asistencia`, `Cancelar envío`) se deshabilitan u ocultan, dejando la vista en modo consulta mientras administración aún puede validar o rechazar sus pendientes.
   - En `/student-profile` y `/volunteer-profile` (`Mi perfil`), se elimina el bloque redundante de pestañas `Todas / Acreditaciones / Actividades` y permanece únicamente la tabla inferior de trazabilidad titulada **`Historial`**.

### 6.2 Formulario de Plantillas (`/admin/quick-activities`) y Captura Escrita `DD/MM/AAAA` + `24h`
- **Valor en horas (`valueInHours`)**: Inicia limpio (`null`), con `placeholder="Ej. 4"` y `min="0.5"`.
- **Publicación rápida con fechas y horas escritas**:
  - `Fecha de inicio` y `Fecha de finalización`: Inputs de texto numérico (`inputmode="numeric" maxlength="10"`) que autoformatean `DD/MM/AAAA` al teclear corrido (`ej. 25122026 = 25/12/2026`) y autorrellenan la fecha final al completar los 10 caracteres de la fecha de inicio.
  - `Hora de inicio` y `Hora de finalización`: Inputs de texto numérico en formato **24h** (`maxlength="5"`, badge `24h`) que autoformatean `HH:MM` al teclear corrido (`ej. 1430 = 14:30`).
- **Garantía Universal Anti-Zoom en Safari iOS**: Todos los `input`, `select` y `textarea` mantienen `font-size: 16px !important` en resoluciones móviles para evitar acercamientos automáticos del viewport.

---

## 7. Regla de Oro: Arnés de Reutilización Estricta de Componentes (Prohibición de Reescribir Código)

Toda evolución visual o funcional de la plataforma opera bajo un **Arnés de Reutilización de Componentes (*Component Reuse Harness*)**: **no se deben crear nuevos componentes Angular ni reescribir bloques de HTML/SCSS cuando ya existe un componente, directiva o patrón estructural homologado en el repositorio**; en su lugar, se reutiliza y parametriza lo existente.

### 7.1 Catálogo de Componentes y Directivas Canónicas que Deben Reutilizarse
| Necesidad Funcional / Visual | Componente / Directiva Canónica | Ubicación en el Repositorio | Regla de Reutilización |
|---|---|---|---|
| **Píldora de Folio Institucional (`SS`, `VG`, `AC`, `OP`, `PET`)** | `<app-folio-pill>` (`FolioPillComponent`) | `frontend/src/app/components/ui/folio-pill/` | Prohibido maquetar spans manuales para folios; usar siempre `[folio]` y `[variant]="'default' \| 'hero' \| 'ac' \| 'op' \| 'pet'"` con copiado integrado. |
| **Paginación de Tablas y Listados** | `<app-pagination>` (`PaginationComponent`) | `frontend/src/app/components/ui/pagination/` | Único paginador permitido en todas las vistas (`[(page)]`, `[totalItems]`, `[pageSize]`, `[scrollBehavior]`). |
| **Selector / Combobox con Búsqueda** | `<app-custom-select>` (`CustomSelectComponent`) | `frontend/src/app/components/ui/custom-select/` | Reutilizar para selección asistida de escuelas, carreras y colaboradores (`[Folio] Nombre completo`). |
| **Selector de Fecha Institucional** | `<app-custom-datepicker>` (`CustomDatepickerComponent`) | `frontend/src/app/components/ui/custom-datepicker/` | Reutilizar en onboarding y expedientes con máscara `DD/MM/AAAA`. |
| **Carga de Documentos PDF al Bucket S3** | `<app-file-upload-modal>` (`FileUploadModalComponent`) | `frontend/src/app/components/ui/file-upload-modal/` | Único modal para subir INE, CV, reglamento firmado, formato de adopción y evidencias `.PDF`. |
| **Zona de Carga con Arrastrar y Soltar (Drag & Drop)** | `<app-file-dropzone>` (`FileDropzoneComponent`) | `frontend/src/app/components/ui/file-dropzone/` | Componente standalone para carga directa, validación .PDF <= 15MB, estados de arrastre (.is-dragover), vista previa y sustitución/eliminación. Reutilizado en `public-adoption-form`. |
| **Registro de Participación Individual / Acreditación** | `<app-new-accreditation-modal>` (`NewAccreditationModalComponent`) | `frontend/src/app/components/shared/new-accreditation-modal/` | Reutilizado en `Mi participación`, `Participación`, `student-detail`, `volunteer-detail` y en los 4 módulos de Base de Datos (`adopciones`, `campañas`, `placas`, `pláticas`) con `[initialAccreditationType]`. |
| **Confirmación Segura de Eliminación (`"borrar"`)** | `<app-delete-confirm-modal>` (`DeleteConfirmModalComponent`) | `frontend/src/app/components/shared/delete-confirm-modal/` | Reutilizado tanto en expedientes de detalle como directamente en las tarjetas de los 4 módulos de Base de Datos (`adoptions`, `campaigns`, `identifications`, `talks`). |
| **Tarjeta Super Brief Base de Datos** | `<app-db-record-brief-card>` (`DbRecordBriefCardComponent`) | `frontend/src/app/components/shared/db-record-brief-card/` | Base reutilizable para los 4 módulos de Base de Datos (`talks`, `adoptions`, `campaigns`, `identifications`), con métricas clave, folios y botonera de acciones dentro/fuera. |
| **Confirmación Escrita de Actualización (`"yes"`)** | `<app-update-confirm-modal>` (`UpdateConfirmModalComponent`) | `frontend/src/app/components/shared/update-confirm-modal/` | Modal reutilizable para autorizar la actualización de registros institucionales mediante el tipeo obligatorio de la palabra `"yes"`. |
| **Carta Oficial y Reporte de Impacto Social (Pláticas)** | Endpoints binario DOCX y visor PDF | `backend/utils/talkLetterDocx.js`, `backend/utils/talkLetterPdf.js` | Carta formal para rendición de cuentas ante gobierno en Word (.docx) y visor PDF con barra flotante de herramientas. |
| **Constancia Individual de Pláticas** | Endpoint `/certificate/talk/:hashToken` | `backend/utils/certificates.js` | Constancia digital única por asistente con folio (`CP-AAMMDD-XXXX-NN`), token AES-256-GCM y botones de PDF/PNG. |
| **Aprobación / Rechazo de Aspirantes** | `<app-decision-volunteer-modal>` (`DecisionVolunteerModalComponent`) | `frontend/src/app/components/shared/decision-volunteer-modal/` | Reutilizado en `/student`, `/student/:id` y `/volunteer-detail/:id`. |
| **Baja / Inactivación de Colaboradores** | `<app-inactivate-volunteer-modal>` (`InactivateVolunteerModalComponent`) | `frontend/src/app/components/shared/inactivate-volunteer-modal/` | Reutilizado para registrar motivo y comentarios en bitácora de estatus. |
| **Verificación Anti-Bot en Formularios Públicos** | `<app-turnstile-widget>` (`TurnstileWidgetComponent`) | `frontend/src/app/components/shared/turnstile-widget/` | Reutilizado en las 7 superficies públicas (`login`, `signup`, `adoptions`, `campaigns`, `identifications`, `talks`). |
| **Abrir en Nueva Pestaña al Mantener Presionado** | `[appLongPressOpen]` (`LongPressOpenDirective`) | `frontend/src/app/directives/long-press-open.directive.ts` | Directiva standalone reutilizada en todos los botones `.btn-copy-form` (600 ms con clic o *tap*). |
| **Retroalimentación en Foco de Botón (Cero CLS)** | `[appActionFeedback]` (`ActionFeedbackDirective`) | `frontend/src/app/directives/action-feedback.directive.ts` | Directiva standalone para transformar botones en retroalimentación temporal (`loading`, `success`, `error`, `self-healing`) erradicando banners estáticos. |

### 7.2 Patrones Estructurales CSS/HTML Reutilizados (Sin Crear Componentes Redundantes)
1. **Encabezado `.admin-hero` + `a.back-link`**: Misma estructura DOM (`.hero-header-row` + `.hero-text-block` + `.hero-actions-row` + `.hero-stats-row`) en todas las vistas, gobernada en tableta y móvil por las reglas globales de `frontend/src/styles.scss`.
2. **Barra de Progreso `.step-pipeline` (3 fases)**: Reutilizada idénticamente dentro de la Agenda (`section.next-activity-spotlight`), en las tarjetas de `Para inscribirme y recientes` (`article.activity-card`) y en las filas de `Mi historial` (`table.sd-combined-table`).
3. **Tabla Histórica `table.sd-combined-table`**: Reutilizada en `student-detail`, `volunteer-detail`, `student-profile`, `volunteer-profile` y `activity-list` (`Mi historial`), compartiendo la misma transformación responsiva a tarjetas (`@media (max-width: 900px)`) con `td[data-label]`.
4. **Archivo en Lugar de Eliminación Destructiva (`frontend/src/app/archive/`)**: Cuando una vista completa es absorbida por otra unificada (como `accreditation-list` y `my-accreditations` absorbidas por `activity-list`), los componentes se archivan en `src/app/archive/` para preservar el código compilable como referencia sin duplicar rutas activas.

---

## 8. Tokens de Color, Insignias de Redes Sociales, Lienzo de Constancias y Regla Zero-Null Folio

### 8.1 Paleta Institucional Azul Marino y Verde ABAQ
| Token | Hex | Uso Principal |
|---|---|---|
| **Navy 950** | `#1f2f63` | Inicio de gradiente de navbar, superficies de alta elevación |
| **Navy 900** | `#24366f` | Azul marino primario ABAQ, encabezados `H1`–`H3`, inicio de `.admin-hero`, pestañas activas |
| **Navy 800** | `#2f4787` | Fin de gradiente de navbar, bordes secundarios |
| **Navy 700** | `#334c91` | Punto medio (58%) de gradiente en `.admin-hero`, enlaces de acción primarios |
| **Green 600** | `#5ca83a` / `#609d54` | Fin (135%) de gradiente en `.admin-hero`, insignias numeradas (`01`, `02`...) |
| **Green 500** | `#7bbf4f` / `#78bc4b` | Verde hoja primario, anillos de foco e indicadores activos |
| **Blue 600** | `#2563eb` | Botón activo de `<app-pagination>`, acciones primarias de constancias |

### 8.2 Insignias de Redes Sociales y Tokens del Lienzo de Constancias (`1122 × 793 px` PNG `2x`)
- **Redes Sociales**: Facebook (`#1877F2`), Instagram (`#E1306C`), TikTok (`#000000`), X / Twitter (`#000000`), YouTube (`#FF0000`), LinkedIn (`#0A66C2`).
- **Lienzo de Constancias Oficiales (`#certificateRoot`)**:
  - Fondo pergamino `#F4F3EC` / `#fdfbf7`, marco doble `3px double #24366f`, borde interior dorado `1px solid #b3832b`, tipografías `Cinzel`, `Crimson Text` y `Great Vibes`, exportado directamente como imagen **PNG a resolución `2x`** con escalador 2D responsivo en móvil (`<= 768px`) y sin leyendas técnicas de sello HMAC en las tarjetas web.

### 8.3 Layout Adaptativo de Onboarding en 4 Fases y Política Zero-Null Folio
- **Onboarding en 4 Fases (`/onboarding/phase-1` a `phase-4`)**:
  - **Escritorio (`> 1024px`)**: 2 columnas con outline izquierdo fijo (`260px`, `position: sticky; top: 96px`) y tarjeta derecha (`max-width: 840px`) con indicador reactivo `cloud_done Guardado` (`debounceTime(400)`).
  - **Tableta y Móvil (`<= 1024px`)**: El outline lateral se oculta por completo (`display: none !important`) y el formulario se expande al `100%` del ancho.
- **Invariante Zero-Null Folio (`SS-YYMMDD-XX`, `VG-YYMMDD-XX`, `AC-YYMMDD-XXXX`, `OP-YYMMDD-XXXX`)**:
  - Ningún expediente de estudiante, voluntario, actividad grupal o participación individual puede existir sin folio institucional canónico e inmutable en MongoDB, garantizado por restricción `required: true`, hook `pre('validate')` y migración de arranque `ensureFolioIntegrity()`.

---

## 9. Sistema de Retroalimentación en Foco de Botón (`[appActionFeedback]`) y Erradicación de Layout Shifts

### 9.1 Principio de Diseño: Enfoque Visual en el Punto de Acción (*Action-Focused Feedback*)
Tradicionalmente, las confirmaciones de guardado o actualización en la plataforma insertaban banners estáticos tipo `<div class="status-feedback-alert alert-success">`. Esta práctica introducía dos fallas críticas de UX:
1. **Ruptura del foco visual**: El usuario hace clic en el botón de acción (ej. *"Modificar datos del voluntario"* al pie del formulario) y debe desviar la vista hacia arriba o hacia otra región remota de la pantalla para buscar si apareció un mensaje.
2. **Desplazamiento Acumulativo de Diseño (*Cumulative Layout Shift - CLS*)**: La aparición y desaparición repentina del banner empuja físicamente los elementos interactivos 40px–60px, provocando clics erróneos y desorientación en dispositivos móviles.

La directiva `[appActionFeedback]` muta temporalmente el propio botón en el que el usuario hizo clic, manteniendo su atención exactamente donde ocurrió la interacción, con **CLS = 0**.

### 9.2 Tokens de Color y Tipografía para Retroalimentación
| Estado | Fondo (Background) | Texto / Ícono | Contraste WCAG | Duración Activa |
|---|---|---|---|---|
| **`idle` (Reposo)** | Color natural del botón (ej. `#24366f`, `#1f2937`) | Color natural | AA / AAA | Permanente |
| **`loading` (Procesando)** | Tono base opacado (85%) con cursor `wait` | `#ffffff` | AA ($\ge 4.5:1$) | Hasta resolución asíncrona |
| **`success` (Éxito)** | `#16a34a` (Verde esmeralda institucional) | `#ffffff` + Ícono `✓` | 7.3:1 (AAA) | **3000 ms** (3 segundos) |
| **`error` (Fallo)** | `#dc2626` (Rojo advertencia institucional) | `#ffffff` + Ícono `✕` | 7.1:1 (AAA) | **4000 ms** (4 segundos) |
| **`self-healing`** | Transición suave `background-color 250ms ease, opacity 200ms ease` | Retorno fiel al original | — | 200 ms |

### 9.3 Microanimaciones CSS
```scss
// Rotación suave del mini spinner (16px)
@keyframes abaqFeedbackSpin {
  to { transform: rotate(360deg); }
}

// Micro-pulso sutil de éxito (confirmación táctil)
@keyframes abaqFeedbackPulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.03); }
  100% { transform: scale(1); }
}

// Sacudida lateral suave ante errores (300ms)
@keyframes abaqFeedbackShake {
  0%, 100% { transform: translateX(0); }
  20%, 60% { transform: translateX(-4px); }
  40%, 80% { transform: translateX(4px); }
}
```

### 9.4 Progresión Visual del Botón e Inteligencia Espacial (Cero Mutación de Ancho y Alto)
Para garantizar estabilidad absoluta y evitar deformaciones geométricas:
- **El botón default describe la acción**: Su etiqueta inicial comunica con total claridad la tarea a realizar (ej. `✎ Modificar datos del voluntario`, `✕ Rechazar`, `Guardar cambios`).
- **El ícono describe qué pasó**: La retroalimentación es guiada visualmente por el glifo (`✓` éxito, `✕` error, `⟳` en progreso).
- **Micro-copy compacto sin textos largos**: Quedan prohibidos los textos largos de efecto (como *"Información del expediente actualizada exitosamente en la base de datos"*). Se utiliza micro-copy de una sola palabra (`"¡Listo!"`, `"¡Guardado!"`, `"Error"`).
- **Invariante Geométrica Estricta**: La directiva bloquea y preserva el ancho (`inline-size`) y alto (`block-size`) exactos calculados en reposo (`offsetWidth` / `offsetHeight`), garantizando que el botón **no cambie de ancho ni de altura** durante ninguna fase.

```text
1. Estado Normal (idle):
   ┌────────────────────────────────────────────────────────┐
   │         ✎  Modificar datos del voluntario              │
   └────────────────────────────────────────────────────────┘
   (Ancho W, Alto H)

2. Al presionar (loading):
   ┌────────────────────────────────────────────────────────┐
   │                  ⟳  Guardando...                       │
   └────────────────────────────────────────────────────────┘
   (Exactamente Ancho W, Alto H · Bloqueado contra doble clic)

3. Resolución Exitosa (success) - 3000 ms:
   ┌────────────────────────────────────────────────────────┐
   │                     ✓  ¡Listo!                         │
   └────────────────────────────────────────────────────────┘
   (Exactamente Ancho W, Alto H · Fondo #16a34a · Ícono protagonista)

4. Auto-Restauración (self-healing):
   ┌────────────────────────────────────────────────────────┐
   │         ✎  Modificar datos del voluntario              │
   └────────────────────────────────────────────────────────┘
   (Transición suave 200ms de retorno fiel al estado normal)
```

### 9.5 Regla de Integración en Plantillas Angular
```html
<!-- Ejemplo en formulario de expediente -->
<button 
  type="submit" 
  class="btn-primary"
  [appActionFeedback]="saveState"
  [successText]="'¡Listo!'"
  [errorText]="'Error al guardar'">
  <i class="material-icons">edit</i>
  Modificar datos del voluntario
</button>
```
*En el componente TypeScript:*
```typescript
// Señal o propiedad de estado
saveState: 'idle' | 'loading' | 'success' | 'error' = 'idle';

onSubmit() {
  this.saveState = 'loading';
  this.volunteerService.update(...).subscribe({
    next: () => { this.saveState = 'success'; },
    error: () => { this.saveState = 'error'; }
  });
}
```
*Los banners estáticos `<div class="status-feedback-alert">` se eliminan por completo del HTML.*

### 9.6 Catálogo Exhaustivo de Interfaces, Banners Removidos y Micro-Copy por Botón (Todo el Sistema)

| Vista / Componente | Elementos Legados a Remover | Botones Mapeados (`idle`) | `loadingText` | `successText` | `errorText` |
|---|---|---|---|---|---|
| **`volunteer-detail`** | `.status-feedback-alert` (`statusFeedback`) | `Modificar datos` / `Guardar cambios`<br>`Aceptar Voluntario y Activar`<br>`Rechazar`<br>`Descargar PDF ↓` / `Ver constancia` | `Guardando`<br>`Aceptando`<br>`Rechazando`<br>`Abriendo` | `¡Listo!`<br>`Activado`<br>`Rechazado`<br>`¡Listo!` | `Error`<br>`Error`<br>`Error`<br>`Error` |
| **`student-detail`** | `.status-feedback-alert`, `.profile-message`, `.document-success-alert`, `.document-error` | `Editar información` / `Guardar cambios`<br>`Aceptar Estudiante y Activar` / `Rechazar`<br>`Guardar enlace`<br>`Aprobar` / `Rechazar` (acreditación)<br>`Descargar PDF ↓` / `Ver constancia` | `Guardando`<br>`Procesando`<br>`Guardando`<br>`Procesando`<br>`Abriendo` | `¡Listo!`<br>`¡Listo!`<br>`¡Listo!`<br>`¡Listo!`<br>`¡Listo!` | `Error`<br>`Error`<br>`Error`<br>`Error`<br>`Error` |
| **`volunteer-profile`**<br>**`student-profile`** | `.feedback-toast.toast-success`, `.feedback-toast.toast-error` (`feedbackMessage`, `feedbackError`) | `✓ Guardar cambios` (Contacto)<br>`✓ Guardar cambios` (Semblanza)<br>`✓ Guardar cambios` (Redes sociales)<br>`Descargar PDF ↓` / `Ver constancia` | `Guardando`<br>`Guardando`<br>`Guardando`<br>`Abriendo` | `¡Listo!`<br>`¡Listo!`<br>`¡Listo!`<br>`¡Listo!` | `Error`<br>`Error`<br>`Error`<br>`Error` |
| **`student`** (Directorio) | `.table-action-feedback`, `copiedKey` | `.dropdown-item-btn` (4 links invitación)<br>`Aceptar` / `Rechazar` / `Inactivar` (tabla) | *(Síncrono)*<br>`...` | `¡Copiado!`<br>`¡Listo!` | `Error`<br>`Error` |
| **`activity-list`** | `.participation-feedback-banner`, `.doc-fallback-alert` (`feedbackBannerMessage`) | `Inscribirme` / `Volver a inscribirme`<br>`Cancelar asistencia` / `Sí, cancelar envío`<br>`Validar participación` / `Confirmar rechazo`<br>`Eliminar actividad`<br>`.btn-doc-download` (Comprobante PDF) | `Inscribiendo`<br>`Cancelando`<br>`Procesando`<br>`Eliminando`<br>`Abriendo` | `Inscrito`<br>`Cancelado`<br>`¡Listo!`<br>`Eliminada`<br>`¡Listo!` | `Error`<br>`Error`<br>`Error`<br>`Error`<br>`Error` |
| **`activity-detail`** | Mensajes de error sueltos | `✓ Asistió` / `✕ No asistió`<br>`Validar X h` / `Validar desempeño` | `...`<br>`Validando` | `Asistió` / `No asistió`<br>`Validado` | `Error`<br>`Error` |
| **`quick-activities`**<br>**`activity`** | `.success-toast`, `.success-message`, `.form-error` | `Crear/Actualizar plantilla`<br>`Publicar actividad`<br>`Eliminar` (plantilla)<br>`Crear actividad` | `Guardando`<br>`Publicando`<br>`Eliminando`<br>`Creando` | `¡Listo!`<br>`Publicada`<br>`Eliminada`<br>`Creada` | `Error`<br>`Error`<br>`Error`<br>`Error` |
| **4 Módulos Operativos**<br>(`adoption-*`, `campaign-*`, `identification-*`, `talk-*`) | Todos los `window.alert(...)` de copiado, borrado y descarga | `Copiar formulario/enlace` (`.btn-copy-form`)<br>`Actualizar datos` (`.btn-refresh-data`)<br>`Guardar campaña/placa/plática`<br>`Confirmar adopción` / `Marcar completada`<br>`Descargar PDF` (Adopción) | *(Síncrono)*<br>`Cargando`<br>`Guardando`<br>`Guardando`<br>`Abriendo` | `¡Copiado!`<br>`¡Listo!`<br>`Guardado`<br>`Completada`<br>`¡Listo!` | `Error`<br>`Error`<br>`Error`<br>`Error`<br>`Error` |
| **4 Formularios Públicos**<br>(`public-*-form`) | Alertas de fallo de envío | `Enviar formulario` / `Enviar solicitud` | `Enviando` | `Enviado` | `Error` |
| **5 Modales Compartidos**<br>(`decision`, `inactivate`, `delete`, `new-accreditation`, `file-upload`) | `.alert-error-box`, `.alert-error-banner`, `.upload-alert-danger` y `alert()` en padres | `Aceptar y Activar` / `Confirmar Rechazo`<br>`Inactivar Cuenta Definitivamente`<br>`Eliminar definitivamente`<br>`Enviar a revisión`<br>`Guardar en expediente` | `Procesando`<br>`Inactivando`<br>`Borrando`<br>`Enviando`<br>`Subiendo` | `¡Listo!` (700ms)<br>`Inactivada` (700ms)<br>`Eliminado` (700ms)<br>`Enviado` (700ms)<br>`Guardado` (700ms) | `Error`<br>`Error`<br>`Error`<br>`Error`<br>`Error` |
| **`login` / `signup` / `onboarding` / `backup`** | `.auth-alert-error`, `.validation-alert-banner`, `.enter-error`, `.unified-success-banner`, `.alert-danger`, `.alert-success` | `Iniciar sesión` / `Continuar a Fase 1`<br>`Guardar y continuar` / `Ingresar`<br>`Descargar Respaldo (.ZIP / .XLSX)`<br>`Analizar / Descargar / Purgar corte`<br>`Revisar / Restaurar / Rehidratar` | `Validando`<br>`Guardando`<br>`Generando`<br>`Procesando`<br>`Restaurando` | `¡Listo!`<br>`¡Listo!`<br>`Descargado`<br>`¡Listo!`<br>`Restaurado` | `Credenciales inválidas`<br>`Faltan datos`<br>`Error`<br>`Error`<br>`Error` |

---

## 10. Sistema de Carga de Archivos Drag & Drop (`<app-file-dropzone>`), Acciones Estandarizadas en Formularios y Viewport Multidispositivo

### 10.1 Anatomía y Tokens Visuales de `<app-file-dropzone>`
El componente desacoplado `<app-file-dropzone>` (`frontend/src/app/components/ui/file-dropzone/`) estandariza la interacción de carga de expedientes PDF en formularios:

1. **Estado en Reposo (`idle`)**:
   - Contenedor con borde discontinuo `2px dashed #cbd5e1`, esquinas redondeadas `border-radius: 16px`, fondo `#f8fafc` y cursor puntero.
   - Ícono central `cloud_upload` (42px) en azul marino `#24366f` sobre fondo `#eff6ff`.
   - Micro-copy claro: *"Arrastra y suelta tu archivo aquí"* + *"o si lo prefieres, selecciónalo desde tu dispositivo"*.
   - Botón primario de explorador `.btn-browse-file` con fondo `#24366f`, texto blanco y sombra institucional.
2. **Estado de Arrastre Activo (`.is-dragover`)**:
   - Borde punteado reactivo en verde institucional `2px dashed #5ca83a`.
   - Fondo verde suave `#f0fdf4`, elevación `box-shadow: 0 8px 24px rgba(92, 168, 58, 0.16)` y micro-escala `scale(1.01)`.
   - Ícono muta a color verde `#5ca83a` sobre fondo circular `#dcfce7`.
3. **Estado con Archivo Adjunto (`.has-file`)**:
   - Borde continuo `2px solid #a7f3d0` y fondo `#f0fdf4`.
   - Distintivo con ícono `picture_as_pdf` en rojo `#dc2626` sobre caja `#fee2e2` (44px × 44px).
   - Metadatos del archivo: micro-etiqueta verde con viñeta (`status-dot`) *"Documento listo para envío seguro"*, nombre de archivo en negrita `#1e293b` con elipsis segura, y peso en KB/MB formateado por `formatBytes()`.
   - Botón secundario `.btn-replace-file` (*"Cambiar"*, ícono `refresh`, `#eff6ff`) y botón destructivo `.btn-remove-file` (*"Quitar"*, ícono `delete`, `#fef2f2` con texto `#b91c1c`).
4. **Estado de Error (`.has-error`)**:
   - Borde rojo claro `#fca5a5`, fondo `#fff5f5` y alerta `.dropzone-alert-error` con ícono `error` y texto explicativo.

### 10.2 Botones Estandarizados en Encabezados `.admin-hero`
En los 4 módulos de Base de Datos / Formularios de Servicio Social (`/admin/adoptions`, `/admin/campaigns`, `/admin/identifications`, `/admin/talks`), la fila `.hero-actions-row` contiene:

| Botón | Clase CSS | Visual / Tokens | Acción Operativa |
|---|---|---|---|
| **Copiar formulario / enlace** | `.btn-copy-form` | Fondo blanco `#ffffff`, texto azul `#24366f`, ícono `link` | Copia la URL pública en el portapapeles. Admite pulsación prolongada (`[appLongPressOpen]`) para abrirla en nueva pestaña. |
| **Actualizar datos** | `.btn-refresh-data` | Fondo traslúcido `rgba(255,255,255,0.16)`, borde blanco `rgba(255,255,255,0.28)`, ícono `sync` | Dispara la recarga de datos (`loadAdoptions()`, `loadCampaigns()`, etc.). El ícono gira con `@keyframes abaqSpin` mientras `isLoading` esté activo. |
| **Nueva acreditación** | `.btn-new-accreditation` | Gradiente verde `linear-gradient(135deg, #5ca83a 0%, #468c27 100%)`, texto blanco, ícono `assignment_turned_in` | Abre `<app-new-accreditation-modal>` con `[initialAccreditationType]` preseleccionado según el contexto (`ADOPTION`, `CAMPAIGN`, `IDENTIFICATION`, `TALK`). |
| **Nuevo registro específico** | `.btn-create-item` | Fondo blanco `#ffffff` (o verde según vista), ícono `add_circle` | Abre el formulario in-situ de alta (ej. *"Nueva campaña"*, *"Nueva plática"*, *"Nueva placa"*). |

### 10.3 Botones Estandarizados en Tarjetas Operativas (`Cards`)
Cada tarjeta de registro incorpora una botonera agrupada (`.card-action-buttons`, `.adoption-card-actions`, etc.):

1. **Acción Principal ("Ver detalles" / "Ver detalle")**:
   - Botón oscuro institucional (`#111827` / `#2f4b9a`), texto blanco, esquinas redondeadas (8px–10px).
   - Conduce a la ruta de expediente detallado (`/admin/.../:id`).
2. **Acción Secundaria Destructiva ("Borrar")**:
   - Botón `.btn-delete-card`: Fondo rojo suave `#fee2e2`, borde `#fecaca`, texto `#b91c1c`, ícono `delete` (16px–18px).
   - En `:hover`: Fondo rojo intenso `#ef4444`, texto blanco y sombra sutil `0 4px 12px rgba(239, 68, 68, 0.25)`.
   - Abre el modal institucional `<app-delete-confirm-modal>`, exigiendo teclear `"borrar"` para ejecutar la eliminación.

### 10.4 Reglas de Adaptabilidad y Viewports (Móvil, Tableta y Escritorio)

```
┌────────────────────────────────────────────────────────────────────────┐
│ ESCRITORIO (> 1024px)                                                  │
│ max-width: 1500px; padding: 32px 24px 80px;                            │
│ .hero-actions-row: [ Copiar ] [ Actualizar datos ] [ Nueva acreditación ]
│ Card: [ Foto / Info ] ───────────────────────── [ Ver detalles ] [ Borrar ]
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│ TABLETA (641px - 1024px)                                               │
│ .hero-actions-row: flex-wrap: wrap; gap: 10px; (botones en 2 filas)    │
│ Card: Grid adaptativa de 1 o 2 columnas; acciones alineadas al final   │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│ MÓVIL (320px - 640px)                                                  │
│ .hero-actions-row: flex-direction: column; width: 100%;                │
│ [ ────── Botón 1: Copiar formulario (100% W, min-h: 44px) ────── ]     │
│ [ ────── Botón 2: Actualizar datos (100% W, min-h: 44px) ─────── ]     │
│ [ ────── Botón 3: Nueva acreditación (100% W, min-h: 44px) ───── ]     │
│ Card: flex-direction: column; foto ancho completo                      │
│ Botonera tarjeta: flex-direction: column;                              │
│ [ ────── Ver detalles (100% W) ────── ]                                │
│ [ ────── Borrar (100% W) ──────────── ]                                │
│ Dropzone preview: apilada en vertical; [Cambiar (50%)] [Quitar (50%)]  │
└────────────────────────────────────────────────────────────────────────┘
```




---

## 11. Patrones de UI para Pláticas: Carta Oficial de Impacto Social, Padrón de Constancias y Métricas

### 11.1 Tarjeta Institucional de Carta Oficial (`.official-letter-card`)
En la vista de éxito del formulario público (`public-talk-form`) y en el detalle administrativo (`talk-detail`), la Carta Oficial se presenta en una tarjeta destacada con gradiente tenue y acento izquierdo en azul marino institucional (`#1d3d69`):
- **Encabezado con Badges:**
  - Badge institucional: `.letter-badge` (`background: #1d3d69; color: #fff; font-size: 11.5px; border-radius: 9999px;`).
  - Folio institucional: `.letter-folio-tag` (`background: #fef3c7; color: #92400e; border: 1px solid #fde68a; font-family: monospace;`).
- **Cuerpo Descriptivo:** Ícono temático `📜`, título `H3` y párrafo explicativo del valor probatorio ante gobierno y autoridades educativas.
- **Botonera de Acciones Duales:**
  - Botón primario PDF: `.btn-letter.btn-letter-pdf` (`background: #0284c7; color: #fff;`) con ícono de visor/impresión.
  - Botón secundario DOCX: `.btn-letter.btn-letter-docx` (`background: #1d3d69; color: #fff;`) con atributo `download`.
  - Botón de enlace: `.btn-letter.btn-letter-copy` con retroalimentación in-situ (`✓ ¡Enlace copiado!`).

### 11.2 Padrón de Constancias y Filas de Participantes
- Cada fila (`.cert-participant-row`) organiza:
  - Número progresivo en avatar circular (`.cert-num` con fondo `#e0e7ff` y color `#3730a3`).
  - Nombre completo del asistente con elipsis en móviles.
  - Fila de micro-etiquetas (`.cert-tags-row`): Folio de constancia (`.cert-folio-tag`), insignia de correo (`.cert-email-badge.sent` en verde `#dcfce7` o `.cert-email-badge.none` en rojo `#fef2f2`), y metadatos (sexo y edad).
  - Zona de acciones (`.cert-actions-cell`): Botón para abrir la constancia (`.cert-download-btn` en azul `#4662ad`) y botón para copiar enlace individual (`.cert-copy-btn`).

### 11.3 Métricas de Impacto Social (`.impact-metrics-bar`)
- Barra superior de métricas con 4 píldoras compactas (`.metric-pill`): Total de asistentes, participantes mujeres, hombres y total notificados por correo (destacada en azul celeste `#eff6ff`).
- En móviles (`<= 640px`), las píldoras se distribuyen en una cuadrícula de 2 columnas o se apilan verticalmente garantizando legibilidad inmediata.

---

## 12. Sistema de Vistas de Detalle: Hero Header Canónico, Super Brief Card y Modal con Tipeo "yes"

### 12.1 Hero Header Canónico en Detalle (`.admin-hero.detail-hero`)
Estructura unificada que gobierna todas las vistas de detalle de Base de Datos:
1. **Fila Superior (`.hero-header-row`)**:
   - Bloque de texto con fila de insignias (`.hero-eyebrow-row`), título institucional (`.hero-title`) y subtítulo (`.hero-subtitle`).
   - Botón interactivo de folio (`.hero-folio-btn`): fondo ámbar `#fef3c7`, borde `#fde68a`, texto `#92400e`, que al presionarse copia el código al portapapeles y activa el micro-toast `¡Copiado!`.
2. **Layout Estandarizado de Botones de Acción (`.hero-actions-row`)**:
   - En los 4 módulos de Base de Datos (`talks`, `campaigns`, `adoptions`, `identifications`) el detalle solo expone acciones básicas del registro: `btn-hero-delete` (Borrar registro, `background: #dc2626; color: #fff;`) alineado arriba a la derecha.
   - **Retirados (15/11/2026)**: `btn-hero-update` (Actualizar datos con confirmación `"yes"`, solo recargaba el registro), `btn-hero-accreditation` (Registrar participación, pertenece a `/activity-list`) y `btn-hero-pdf` / `btn-hero-docx` (Carta Oficial, se reubicará en otra sección).
   - Los cambios de estado propios de cada módulo se conservan en el cuerpo de la vista (`Completar adopción`, `Marcar placa como completada`), así como las acciones de documentos de Adopciones y las constancias por participante de Pláticas.
3. **Fila de Métricas Integradas en el Gradiente (`.hero-stats-row`)**:
   - Tarjetas translúcidas con desenfoque (`backdrop-filter: blur(8px)`) que resumen fecha, participantes, género y estatus en una sola composición visual armónica.

### 12.2 Componente Base `DbRecordBriefCardComponent` (`<app-db-record-brief-card>`)
- Ubicado en `src/app/components/shared/db-record-brief-card/`.
- Provee un resumen ejecutivo de alta densidad (*Super Brief*) estructurado en:
  - Fila de insignias con categoría, estatus y botón de folio copiable.
  - Título y subtítulo descriptivo del registro.
  - Sin botonera propia: las acciones del registro viven únicamente en el `.admin-hero` para no duplicarlas.
  - Cuadrícula de métricas clave (`.brief-metrics-panel`).
  - Etiquetas temáticas (`.brief-tags-row`) y caja de notas oficiales (`.brief-notes-box`).

### 12.3 Modal Validador con Confirmación Escrita `"yes"` (`<app-update-confirm-modal>`) `[RETIRADO DE LAS VISTAS — 15/11/2026]`
- Ya no se usa en ninguna vista: acompañaba al botón "Actualizar datos", que solo recargaba el registro. El componente se conserva porque lo cubre una prueba unitaria.
- Ubicado en `src/app/components/shared/update-confirm-modal/`.
- Mecanismo de seguridad deliberado para autorizar actualizaciones de expedientes:
  - Muestra la tarjeta Super Brief del registro dentro del cuerpo del modal.
  - Exige al usuario escribir de forma manual la palabra **`yes`** para habilitar el botón primario de confirmación.
  - Muestra indicador de carga `isUpdating` y previene clics concurrentes.

---

## 13. Gobernanza de Narrativa, Roles y Micro-copy Pedagógico (Actividades vs. Participación Individual)

### 13.1 Vocabulario Oficial y Micro-copy de Botones de Acción
- **Prohibición de "Nueva acreditación"**: Se prohíbe el uso de la etiqueta "Nueva acreditación" en botones porque sugiere falsamente una resolución inmediata sin auditoría.
- **Prohibición de Jerga Técnica en UI (p. ej. "1:1")**: Las relaciones arquitectónicas o ratios técnicos (como "1:1") no deben exponerse al usuario final. La interfaz debe usar terminología humana y transparente: *"Registrar participación individual"* o *"Registrar participación"*.
- **Botón Canónico para Voluntarios**: `Registrar participación` (ícono `assignment_turned_in` o `add_circle`).
- **Botón Canónico para Coordinación**: `Registrar participación a voluntario` o `Registrar participación` (ícono `assignment_turned_in` o `verified`).
- **Términos institucionales (15/11/2026)**: "voluntario(s)" en lugar de "colaborador(es)"; "animal(es) de compañía" en lugar de "mascota(s)" o "animal(es)" cuando se refiere a los animales ("Bienestar Animal" no cambia).
- **Navegación Canónica**: La pestaña `/activity-list` se titula en el Navbar como `Actividades y Participación`, englobando ambos componentes de forma transparente.

### 13.2 Banner Informativo de Verificación Institucional (`.accreditation-audit-banner`)
Componente pedagógico insertado en el cuerpo de `<app-new-accreditation-modal>`:
- **Estructura Visual**:
  - `background: #f8fafc; border: 1px solid #e2e8f0; border-left: 4px solid #0284c7; border-radius: 12px; padding: 12px 16px;`.
  - Ícono frontal: `.audit-icon` (`info` en `#0284c7`, `font-size: 22px`).
  - Bloque tipográfico: `strong` en `#0f172a` ("Proceso de verificación institucional:") y descripción clara en `#475569` explicando que la solicitud está respaldada por un comprobante `.PDF` y sujeta a revisión formal.

### 13.3 Badges Diferenciadores de Rol y Píldora de Folio Universal
- **Píldora de Folio Canónica (`<app-folio-pill>`)**: Reutilización estricta del componente en perfiles de colaboradores, cabeceras hero administrativas (`student-detail`, `volunteer-detail`) y tablas maestras (`student.component.html`). Fondo `#E0F2FE`, borde `#BAE6FD`, tipografía monoespaciada en `#0369A1` con botón de copiado reactivo.
- **Estudiante de Servicio Social**: Badge con ícono `school`, fondo azul tenue `#eff6ff`, borde `#bfdbfe`, texto `#1e40af`. Mensaje: *"La participación aprobada sumará horas a tu avance oficial (meta de 480 h)"*.
- **Voluntario General**: Badge con ícono `favorite`, fondo verde tenue `#f0fdf4`, borde `#bbf7d0`, texto `#166534`. Mensaje: *"Registro de labor social comunitaria (no requiere horas curriculares obligatorias)"*.
- **Coordinación**: Eyebrow `Coordinación de Voluntariado` (`#1d3d69`).

### 13.4 Cuadrícula de Métricas de Progreso Desduplicada (`.hero-stats-grid`)
- En el panel de control del estudiante (`home`), el layout se reconfigura de 6 a 5 tarjetas compactas adaptables (`repeat(5, minmax(0, 1fr))` en pantallas grandes, `repeat(3, ...)` en tabletas y `repeat(1, ...)` en móviles):
  1. `Participaciones validadas`
  2. `Participaciones en revisión`
  3. `Horas acreditadas` (con subtexto descriptivo de la meta de 480 h)
  4. `Horas pendientes`
  5. `Progreso` (%)
- Se erradica la tarjeta redundante de *"Horas requeridas"* que provocaba la duplicación del valor `480` en alumnos de nuevo ingreso.

---

## 14. Patrones Visuales de Estadísticas Duales en Respaldos (BD + Bucket S3), Selector de 3 Opciones en Lenguaje Ciudadano, Modal Reutilizado de Vista Previa y Estado Bloqueado de Descarga por 8 Horas

### 14.1 Contenedores Gemelos en `.admin-hero` (Reutilización de `.hero-stats-grid` y `.hero-stat-card`)

Para presentar de forma equilibrada y sin duplicar código visual las métricas de infraestructura en `/admin/backups`, el encabezado `.admin-hero` aloja dos bloques hermanos construidos íntegramente con las clases existentes `.hero-stats-grid` y `.hero-stat-card` definidas en `backup.component.scss`:

```text
+---------------------------------------------------------------------------------------------------+
| CONTENEDOR 1: BASE DE DATOS (Información del sistema)                                             |
| [Estado Conexión / Latencia] [Módulos Activos] [Documentos + Peso] [Costo Mensual + Badge Δ]      |
+---------------------------------------------------------------------------------------------------+
| CONTENEDOR 2: ALMACENAMIENTO DE ARCHIVOS (Documentos guardados — Bucket S3)                       |
| [Estado del Almacén]         [Carpetas: 4 / 4] [Archivos + Peso]   [Costo Mensual + Badge Δ]      |
+---------------------------------------------------------------------------------------------------+
  Última actualización: 15/11/2026
```

- **Reglas de Contenido en Tarjeta de Costo**:
  - Muestra exclusivamente el peso consumido (MB/GB), la cifra estimada mensual en USD (ej. `$X.XX USD / mes`) y una píldora compacta de diferencial y aceleración de crecimiento ($\Delta$, indicando si el consumo sube, baja o se acelera frente al corte previo).
  - **Prohibición estricta en UI**: Nunca renderizar fórmulas matemáticas, precios unitarios por GB/vCPU ni parámetros técnicos internos dentro del widget.
- **Hint Minimalista de Actualización**:
  - Se ubica inmediatamente debajo del segundo contenedor con tipografía sutil secundaria y contiene **únicamente la fecha**: `Última actualización: DD/MM/AAAA`. No debe existir cronómetro ni refresco automático continuo.

### 14.2 Selector Ciudadano de 3 Opciones de Respaldo (Prohibido mencionar "PDF") y Validación Pre-Descarga

En la tarjeta principal de generación y descarga `.zip` de `backup.component.html`, el administrador selecciona entre tres opciones de lenguaje claro orientadas a usuario final. **Regla editorial obligatoria**: queda prohibido utilizar la palabra `"PDF"` en etiquetas, descripciones o ayudas de esta vista; siempre debe decirse **"archivos"** o **"documentos guardados"**:

1. **`Respaldo completo (Base de datos y archivos)`** (`scope: 'full'`) — *Guarda todos los registros del sistema junto con los archivos respaldados en una sola descarga.*
2. **`Solo base de datos (Registros del sistema)`** (`scope: 'db_only'`) — *Incluye únicamente expedientes, actividades, bitácoras y catálogos.*
3. **`Solo archivos (Documentos guardados)`** (`scope: 'bucket_only'`) — *Descarga únicamente los documentos guardados en las carpetas de respaldo.*

- **Feedback de Validación Pre-Descarga (`validateBackupReadiness`)**:
  - Antes de iniciar la descarga del `.zip`, un indicador de estado verifica salud en registros, integridad de archivos y referencias cruzadas sanas. Si detecta algún documento o referencia dañada, bloquea el botón de descarga con un banner informativo claro explicando la causa sin exponer trazas de servidor.

### 14.3 Modal Reutilizado de Vista Previa en Rollback (`.review-table-wrap` / `.review-mobile-card-list`) con Bucket S3 y Zero-Overwrite

Los modales existentes `showRollbackReviewModal` y `showPackageReviewModal` se reutilizan para presentar tanto las colecciones de base de datos como las 4 carpetas del Bucket S3 (`reglamentos`, `adopciones`, `evidencias`, `documentos`):
- **Escritorio (`d-none d-md-block`)**: Tabla `.review-table-wrap` dividida en sección *Registros del sistema* y sección *Archivos guardados (Bucket S3)* con columnas: Carpeta, En paquete, Ya guardados (Omitidos sin sobrescribir), Nuevos a restaurar y Estado.
- **Móvil (`d-md-none`)**: Tarjetas apiladas `.review-mobile-card` dentro de `.review-mobile-card-list` conservando `.card-metrics-grid` y `.contrast-badge` verde (`+N nuevos`) o gris (`Omitido — Protegido contra sobrescritura`).
- **Distintivo Zero-Overwrite**: Aviso fijo en la cabecera del modal aclarando explícitamente al usuario que ningún registro ni archivo existente en el sistema será sobrescrito ni reemplazado.

### 14.4 Estado Bloqueado por 8 Horas en Acciones de Descarga (`.btn-download-locked-8h`)

Cuando el guardián anti-abuso (`downloadGuard.js` + sincronización en `localStorage`) activa el bloqueo de **8 horas** tras alcanzar 3 descargas de un documento o disparar el *Circuit Breaker* global por comportamiento anormal:
- El botón de descarga adopta el estado deshabilitado `.btn-download-locked-8h` (tono neutro `#e2e8f0`, texto `#475569`, cursor `not-allowed`, ícono `lock_clock`).
- Muestra un mensaje sereno orientado a usuario final: *"Límite de descargas alcanzado. Por seguridad de la plataforma, espera 8 horas o solicita el documento directamente con la Coordinación."* (en modo *Circuit Breaker* aplica el mismo aviso bloqueando todas las descargas de documentos de la cuenta).

---

## 15. Hub de Navegación Móvil a Pantalla Completa (`.mobile-fullscreen-hub`)

### 15.1 Filosofía de Experiencia Inmersiva y Eliminación de Duplicidades

Para pantallas móviles (`< 992px`), se abandona el menú desplegable tipo acordeón tradicional en favor de un **Hub de Navegación a Pantalla Completa (`100dvh` / `calc(100dvh - 64px)`)** que aprovecha la totalidad del viewport vertical:

```text
+-------------------------------------------------------------------+
|  [Logo ABAQ]                                              [ ✕ ]   | <- Barra Navbar Fija (64px)
+-------------------------------------------------------------------+
| ⚡ ACCIONES MÁS REQUERIDAS (Grid Táctil 2x2)                       |
| +-------------------------------+ +-----------------------------+ |
| | [+] Nueva Actividad           | | [✓] Nueva Acreditación      | |
| |     Elegir plantilla          | |     Registrar participación | |
| +-------------------------------+ +-----------------------------+ |
| | [🔍] Buscar Voluntario        | | [💾] Respaldar Sistema      | |
| |      Por nombre o folio       | |      Descargar copia        | |
| +-------------------------------+ +-----------------------------+ |
|                                                                   |
| 🔗 VISTAS MÁS UTILIZADAS (Chips Horizontales con Scroll 1-Tap)    |
| ( Estudiantes ) ( Voluntarios ) ( Actividades ) ( Catálogos ) ... |
|                                                                   |
| 📂 SECCIONES DEL SISTEMA (Módulos Agrupados con Iconos SVG)       |
| > GESTIÓN DE VOLUNTARIOS                                          |
|   • Expedientes de Servicio Social                                |
|   • Voluntarios Generales                                         |
| > OPERACIÓN EN CAMPO                                              |
|   • Actividades y Participación                                   |
| > BASE DE DATOS                                                   |
|   • Pláticas, Campañas EST, Adopciones, Placas                    |
| > ADMINISTRACIÓN DEL SISTEMA                                      |
|   • Respaldos y Recuperación                                      |
|                                                                   |
| [ 🚪 Cerrar Sesión ]                                              |
+-------------------------------------------------------------------+
```

- **Supresión de Redundancias**: Se elimina deliberadamente la fila secundaria superior con logotipo repetido y la tarjeta redundante de identidad del usuario. La cabecera nativa del navbar (de `64px`) se mantiene anclada con el botón de hamburguesa/cierre (`[ ✕ ]`), permitiendo que el contenido del hub comience **directamente con la operación útil**.
- **Bloqueo Inteligente de Scroll (`body.mobile-nav-lock`)**: Al desplegarse el hub, el `body` adopta `overflow: hidden !important; touch-action: none;` para evitar desplazamiento en segundo plano, mientras que el scroll interno del hub cuenta con `-webkit-overflow-scrolling: touch;`.

### 15.2 Arquitectura y Componentes por Rol

1. **Bloque 1: Acciones Más Requeridas (`.hub-action-grid`)**:
   - Cuadrícula táctil 2x2 de botones tipo tarjeta (`.hub-action-card`) con tamaño mínimo de toque de `48px`, elevación sutil, ícono con contenedor contrastado, título legible en negrita y bajada descriptiva de contexto.
   - Cada tarjeta **ejecuta la acción** en la vista destino (`?accion=` + `onMenuAction()`), no solo navega a la sección.
   - **Administrador**: *Nueva Actividad* (elegir plantilla), *Nueva Acreditación* (registrar participación), *Buscar Voluntario* (enfoca el buscador), *Respaldar Sistema*.
   - **Servicio Social y Voluntariado General** (misma narrativa, sin "Jornadas"): *Inscribirme a Actividades*, *Registrar Participación*.
   - **Público / Sin Sesión**: *Iniciar Sesión*, *Registrarse*.
   - Constancias y acreditaciones no son acciones rápidas.
2. **Bloque 2: Vistas Más Utilizadas (`.hub-chips-scroll`)**:
   - Píldoras horizontales (`.hub-chip-pill`) con scroll fluido de 1-tap que llevan de inmediato a las vistas de consulta más frecuentes sin necesidad de abrir submenús.
3. **Bloque 3: Secciones del Sistema (`.hub-modules-stack`)**:
   - Tarjetas agrupadas (`.hub-module-card`) con título de sección en versalitas/mayúsculas y enlaces con íconos Material Symbols correspondientes a cada área funcional.
4. **Bloque 4: Barra de Sesión Inferior (`.hub-session-action`)**:
   - Botón ancho al fondo para cierre de sesión o acceso rápido, con confirmación no obstructiva.

---

## 16. Estandarización de Contraste y Accesibilidad en Tarjetas de Estado de Perfil (`.hero-stat-card-status`)

### 16.1 Diagnóstico de Contraste y Corrección de Fuga de Estilos

En los perfiles y expedientes de colaboradores (`student-detail`, `volunteer-detail`, `student-profile`, `volunteer-profile`), se detectó un problema crítico de contraste en el widget de **ESTATUS** del encabezado hero:
- **Causa Raíz**: Las clases `.status-pending` y `.status-rejected` de las tarjetas de acreditación contenían fondos sólidos de tono pastel claro (`#fff4d6` y `#fde9e9`) con reglas globales que se heredaban en el elemento `<strong>` del hero. Al aplicarse estilos de texto en línea como `#fca5a5` o `#fde047`, el elemento presentaba un texto claro sobre un fondo claro casi idéntico, resultando en un ratio de contraste de apenas **1.62:1** (violación flagrante de WCAG AA que exige un mínimo de 4.5:1).
- **Corrección Canónica**:
  1. Se encapsularon las clases `.status-pending`, `.status-approved` y `.status-rejected` dentro de su contenedor semántico legítimo `.accreditation-status`, eliminando cualquier fuga global de estilos.
  2. En el encabezado hero se aplicó la regla terminante:
     ```scss
     .hero-stat-card-status .hero-stat-value {
       strong,
       .hero-status-tag {
         background: transparent !important;
         padding: 0 !important;
         border: none !important;
         box-shadow: none !important;
         font-size: 16px;
         font-weight: 800;
         display: inline-flex;
         align-items: center;
         gap: 6px;
       }
     }
     ```

### 16.2 Matriz Canónica de Estados con Viñeta Circular (`●`)

Todos los estados del widget de perfil reutilizan de forma estricta el patrón canónico de viñeta circular `●` (idéntico al de *● Activo* y *● Inactivo*), erradicando cajas con bordes o fondos opacos sobre el degradado azul oscuro institucional:

| Estado | Token / Color | Clase CSS | Ratio de Contraste sobre Hero Oscuro | Cumplimiento WCAG |
| :--- | :--- | :--- | :--- | :--- |
| **● Activo** | `#86efac` (Verde menta brillante) | `.status-active` | **10.4:1** | WCAG AAA |
| **● Inactivo** | `#fca5a5` (Rojo/coral pastel) | `.status-inactive` | **7.8:1** | WCAG AAA |
| **● Rechazado** | `#fca5a5` (Rojo/coral pastel) | `.status-rejected` | **7.8:1** | WCAG AAA |
| **● Pendiente** | `#fde047` (Amarillo cálido de alta luminosidad) | `.status-pending` | **12.1:1** | WCAG AAA |
| **● Concluido** | `#67e8f9` (Cian brillante) | `.status-completed` | **11.2:1** | WCAG AAA |

---

## 17. Retroalimentación Transitoria In-Situ en Botones (`ActionFeedbackDirective`) y Selectores Nativos del Sistema Operativo

### 17.1 Erradicación Total de Banners Estáticos y `alert()` en Favor de Estados Transitorios del Botón (`CLS = 0`)

Todas las acciones disparadas por botones en la plataforma (guardar, actualizar, copiar enlace/folio, descargar constancia/PDF, inscribirse, aprobar/rechazar/inactivar cuentas, crear registros y restaurar respaldos) notifican su progreso y resultado **exclusivamente dentro del propio botón** mediante `ActionFeedbackDirective` (`button[appActionFeedback]`):
- **Estados Transitorios**: `idle` → `loading` (spinner + texto contextual, ej. *"Actualizando..."*) → `success` (`✓ ¡Actualizado!` / `✓ ¡Listo!` durante `2.5s`) o `error` (`✕ Error` durante `3.5s`) → retorno automático a `idle`.
- **Cero Desplazamiento de Layout (`CLS = 0`)**: Antes de entrar en estado transitorio, la directiva congela `width` y `height` exactos en píxeles (`getBoundingClientRect()`) y oculta temporalmente los nodos hijos originales sin destruir las anclas DOM de Angular (`@if` / `@for`), restaurándolos íntegramente al volver a `idle`.
- **Cero Banners Estáticos ni `window.alert()`**: Se erradicaron todos los banners estáticos residuales (`.status-feedback-alert`, `.participation-feedback-banner`, `.doc-fallback-alert`, `.document-success-alert`, `.document-error`, `.table-action-feedback`, `.alert-error-box`, `.alert-error-banner`, `.upload-alert-danger`, `.unified-success-banner`, `.feedback-toast`, `.success-toast`, `.auth-alert-error`, `.profile-message`) y las 19 llamadas bloqueantes a `alert()` / `window.alert()`.

### 17.2 Selectores Nativos del Sistema Operativo con Escritura Manual (Excepto Registro y Expediente)

Para maximizar la velocidad de captura por teclado y aprovechar los selectores nativos de fecha, hora y listas desplegables de cada sistema operativo (iOS, Android, macOS, Windows):
- **Excepción Protegida**: Únicamente el flujo de **Registro / Onboarding** (`onboarding-phase`) y la vista de **Expediente** (`student-detail`) conservan los componentes personalizados `CustomDatepickerComponent` (`<app-custom-datepicker>`) y `CustomSelectComponent` (`<app-custom-select>`).
- **Estándar Nativo en el Resto del Sistema**: Todas las demás vistas y modales (`NewAccreditationModalComponent`, `activity`, `activity-list`, `quick-activities`, `campaign-list`, `talk-list`, `adoption-detail`, `identification-list`, `backup`) utilizan controles nativos `<input type="date">`, `<input type="time">` y `<select>` estilizados con `.custom-form-control`, permitiendo tanto la escritura manual directa con teclado como la apertura del selector nativo del sistema operativo.

---

## 18. Patrones del 15/11/2026: Esqueleto de Carga, Evaluación de Participantes, Agenda Exportable y Selectores de Hora

### 18.1 Esqueleto de Carga Reutilizable (`.abaq-skeleton`, `styles.scss`)
- Sustituye áreas vacías y textos "Cargando…" en la primera carga de Inicio (Servicio Social y Voluntariado General) y Participación.
- Piezas: `.abaq-skeleton-stack` (columna con `gap: 14px`), `.abaq-skeleton-card` (tarjeta blanca con borde `#e2e8f0`) y `.abaq-skeleton` con variantes `is-title`, `is-line`, `is-short` e `is-block`.
- Brillo con gradiente `#eef2f7 → #f8fafc` animado solo con CSS (`abaqSkeletonShimmer`, 1.4 s); sin animación con `prefers-reduced-motion: reduce`. Lleva `aria-busy="true"` y una etiqueta descriptiva.

### 18.2 Tabla de Evaluación de Participantes (`/activity-list/:id`)
- Reutiliza `.table-wrapper` + `.students-table` (y su transformación a tarjetas en `≤ 900px`) con columna de acciones fija a la derecha (`.actions-th` / `.actions-cell`, `232px`).
- Columnas: Participante (nombre, correo, folio), Programa (`.program-badge` SS/VG), Escuela / Carrera, Estado (`.badge-status`: Por validar, Asistió, No asistió, Validada), Horas, Desempeño (calificación y comentario) y Acciones.
- Acciones `.btn-arrow-action` **Validar** (verde) y **No asistió** (rojo); una evaluación validada muestra "Evaluación cerrada". Filas con inasistencia y validadas llevan un tinte de fondo; en móvil el tinte se aplica a la tarjeta completa.
- Un solo modal (`.confirmation-modal.evaluation-modal`) con los 5 niveles de desempeño; en Servicio Social agrega "Horas a acreditar" con valor sugerido y tope. El botón de confirmación usa estados transitorios (`appActionFeedback`) y, mientras falte algo, indica en su propio texto qué falta.
- El texto de los botones se fija en `.action-btn-text` porque la regla global anti-zoom de iOS fuerza `font-size: 16px !important` en `<button>`.

### 18.3 Agenda Exportable a Calendario
- Las tarjetas `section.next-activity-spotlight.is-calendar-link` son interactivas (cursor de mano, foco visible `3px #7bbf4f`) y muestran la pista `.stub-calendar-hint` ("Agregar al calendario") en el recuadro de fecha.
- `.split-prep-box` y `.record-details-drawer` conservan su propia interacción.

### 18.4 Selectores Nativos de Hora y Valor en Horas Calculado
- Cada campo de hora de las plantillas lleva un botón `.btn-native-picker` con ícono `schedule` que abre el selector nativo (`input type="time"` + `showPicker()`), igual que el botón de calendario de las fechas.
- "Valor en horas" se calcula del rango de horario, queda de solo lectura y muestra la pista "Calculado del horario: 09:00–13:00 = 4 h". Se retiró la pista "Escribe corrido (ej. 25122026…)" de las fechas.

### 18.5 Retroalimentación en Botones: Casos Especiales
- **Botones `type="submit"` con `feedbackOnClick`**: el estado de éxito se aplica después del clic; aplicarlo durante el clic deshabilitaba el botón y cancelaba el envío del formulario.
- **Login**: todo fallo se muestra en el propio botón con texto corto ("Espera la verificación anti-bot", "Correo o contraseña incorrectos", "Sin conexión con el servidor"); un error repetido vuelve a animarse pasando por `idle`.
- **Límite de descargas**: el contador anti-abuso es interno; los botones dicen "✓ Comprobante descargado" o "✓ Documento descargado", sin "(n/3)".

---

## 19. Convocatorias OP con Acreditación Anidada `[VALIDADO 15/11/2026]`

Diseño completo en [Convocatorias OP con Acreditación Anidada](ideas/2026-11-15-convocatorias-op-con-acreditacion-anidada.md). Lineamientos visuales, reutilizando componentes existentes:

- **Plantillas:** el selector "Tipo de actividad" se reemplaza por "Categoría de evento" (cada opción muestra su multiplicador, p. ej. "Apoyo a refugio · Limpieza · 4× por hora"); bajo el valor en horas, `.field-hint` "Acredita N h de Servicio Social por persona · Voluntariado General no acumula horas". La insignia de la tarjeta muestra la categoría y su multiplicador.
- **Narrativa:** "Convocatoria" (lo principal: asistir y ayudar) y "Vinculación" (lo excepcional: "si consigues para ABAQ…"). Menú móvil: "Registrar Vinculación" (voluntarios) y "Nueva Vinculación" (admin).
- **Evaluación:** el campo de horas usa `appAutoSelectOnClick` (clic selecciona para sobrescribir) y el texto "Sugerido: N h (duración × multiplicador, categoría) · tope X h".
- **Participación (voluntario):** una sola lista de oportunidades `OP`; se retiran las insignias "Actividad grupal" / "Participación individual" y la categoría ("Evento · Campaña de esterilización", "Vinculación · Placas…") identifica cada registro. La barra `.step-pipeline` usa las fases `1. Inscrito → 2. Asistencia → 3. Validada` para convocatorias y `1. Enviada → 2. En revisión → 3. Validada` para vinculaciones.
- **Detalle de convocatoria (admin):** la tabla de evaluación de §18.2 se conserva; opera sobre la acreditación anidada.
- **Folios:** `app-folio-pill` toma el color del prefijo del folio (`OP-` naranja, `AC-` azul); tras la migración todas las convocatorias e inscripciones son `OP-EVE`.

---

## 20. Centro de Notificaciones `[IMPLEMENTADO 15/11/2026]`

- **Campana:** `.hnav-bell-btn` (44 px en móvil, junto al botón hamburguesa; 40 px en escritorio, antes de "Cerrar sesión") con `.hnav-badge` rojo (máx. "99+"). `aria-label` con el número de no leídas.
- **Drawer:** `<app-notifications-center [isDrawer]="true">` montado en el shell; estilos en `abaq-design.css` (`.notifications-drawer`, `.notification-card`, píldoras `.filter-pill`). Escape cierra; botón de expandir a pantalla completa.
- **Colores de etiqueta:** `green` (aceptado, concluido), `navy` (nuevo registro, resumen semanal), `amber` (correcciones, inactividad, reglamento), `red` (baja, nuevo `.notif-tag-red` / `.notif-icon-red`), `slate` (informativo).
- **Correo del resumen semanal:** cabecera navy "Tu semana en ABAQ".
    - "Lo que viene esta semana": primero "Tus inscripciones" (en verde) y luego "Convocatorias disponibles". Cada tarjeta lleva la categoría en verde, el título, "📅 día, fecha · 🕒 hora", "Acredita N h" (solo SS) y el cupo o "✓ Ya estás inscrito(a)".
    - Botón verde "Ver convocatorias e inscribirme".
    - Tras un separador, "Lo que hiciste la semana pasada": título y tipo, fecha y hora de la actividad, estado en color (verde "Validada", rojo "No validada", ámbar "Pendiente de validar"), horas asignadas (SS) y "el <fecha de validación>".

---

## 21. Avisos del Ciclo de Participación y Folio Visible `[IMPLEMENTADO 17/11/2026]`

- **Avisos nuevos (campana, sin correo):** usan las categorías y colores de §20.

| Aviso (`archetype`) | Categoría | Etiqueta | Color | Icono |
|---|---|---|---|---|
| `convocatoria_publicada` | Actividades | Nueva convocatoria | `navy` | `event_available` |
| `participacion_validada` | Actividades | Validada | `green` | `task_alt` |
| `participacion_inasistencia` | Actividades | Inasistencia | `red` | `event_busy` |
| `vinculacion_solicitada` (admins) | Acreditaciones | En revisión | `amber` | `pending_actions` |
| `vinculacion_registrada` (titular, la registró la Coordinación) | Acreditaciones | En revisión | `amber` | `pending_actions` |
| `vinculacion_aprobada` | Acreditaciones | Aprobada | `green` | `verified` |
| `vinculacion_rechazada` | Acreditaciones | Rechazada | `red` | `cancel` |
| `convocatoria_por_validar` (admins) | Actividades | Por validar | `amber` | `fact_check` |

- **Regla:** nadie recibe aviso de una acción que acaba de hacer. La Coordinación solo ve solicitudes ("Nueva solicitud de vinculación") y convocatorias terminadas por validar ("Es momento de validar: …").
- **Redacción:** título en segunda persona para el colaborador ("Tu vinculación fue aprobada"); para la Coordinación, el nombre de la persona va en la descripción. La descripción incluye categoría o modalidad, folio y, si aplica, horas ("Se acreditaron 2 h") o motivo. Textos de más de 140 caracteres se recortan con "…".
- **Acción:** todos llevan a `/activity-list` (ruta interna).
- **Chip de participantes (admin):** `.participant-chip` muestra "evaluados/inscritos participantes" (título accesible "Evaluados / inscritos"); `.eval-pending` en ámbar `#b45309` mientras falten evaluaciones, `.eval-complete` en verde `#15803d` al completar; `.full` (rojo) se conserva para cupo lleno.
- **Folio visible:** en tarjetas, agenda y buscador de *Mis participaciones*, `app-folio-pill` muestra el folio de la convocatoria (`OP-EVE-…`) para toda inscripción. En el detalle de la convocatoria (Coordinación) el folio va en el encabezado, junto al título; las filas de inscritos no muestran folio.
- **Filtros de la campana por rol:** píldoras "Todas", "No leídas" y tres por categoría con la narrativa de participaciones (ver SRS RF-NOT-17), generadas desde una sola lista (`filtersFor(role)`) para el drawer y la pantalla completa.
- **Nombre de la sección:** "Mis participaciones" (estudiantes y voluntarios) y "Participaciones" (Coordinación) en la barra, el menú móvil y el título de la vista.

---

## 22. Campo de Horas al Validar (`app-hours-override-field`) `[IMPLEMENTADO 17/11/2026]`

Componente compartido (`components/ui/hours-override-field`) que se usa en los tres puntos donde la Coordinación valida horas: evaluación en el detalle de la convocatoria, modal "Validar participación" de *Mi participación* y modal de aprobación del detalle del estudiante.

- **Entradas:** `[(value)]` horas finales, `[proposed]` propuesta del sistema, `[max]` tope (horas pendientes) o `null`, `[detail]` cálculo ("1 h × 2, Apoyo a refugio · Paseo"), `[earnsHours]`, `inputId`, `label`.
- **Campo:** etiqueta en versalitas de 9 px, caja de 150 px (100 % en móvil) con unidad "h"; texto del número a 16 px para evitar el zoom de iOS. Un clic selecciona el valor (`appAutoSelectOnClick`) para sobrescribirlo.
- **Pista:** "Propuesto por el sistema: N h (cálculo) · tope M h. Da clic en el campo para sobrescribirlo."
- **Ajuste:** si el valor difiere de la propuesta, aparece en ámbar "Ajuste manual: se registrará N h → M h en la bitácora de auditoría."
- **Sobre el tope:** borde y texto rojizos (`input-over-limit`).
- **Voluntariado General:** en lugar del campo, una nota gris "el reglamento no acredita horas. Solo se registra su desempeño".

