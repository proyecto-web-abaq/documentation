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
| **Registro de Participación Individual / Acreditación** | `<app-new-accreditation-modal>` (`NewAccreditationModalComponent`) | `frontend/src/app/components/shared/new-accreditation-modal/` | Reutilizado tanto por estudiantes/voluntarios (`Mi participación`) como por administradores (`Participación`, `student-detail`, `volunteer-detail`). |
| **Confirmación Segura de Eliminación (`"borrar"`)** | `<app-delete-confirm-modal>` (`DeleteConfirmModalComponent`) | `frontend/src/app/components/shared/delete-confirm-modal/` | Reutilizado en el borrado de Adopciones, Pláticas, Campañas, Placas y registros administrativos. |
| **Aprobación / Rechazo de Aspirantes** | `<app-decision-volunteer-modal>` (`DecisionVolunteerModalComponent`) | `frontend/src/app/components/shared/decision-volunteer-modal/` | Reutilizado en `/student`, `/student/:id` y `/volunteer-detail/:id`. |
| **Baja / Inactivación de Colaboradores** | `<app-inactivate-volunteer-modal>` (`InactivateVolunteerModalComponent`) | `frontend/src/app/components/shared/inactivate-volunteer-modal/` | Reutilizado para registrar motivo y comentarios en bitácora de estatus. |
| **Verificación Anti-Bot en Formularios Públicos** | `<app-turnstile-widget>` (`TurnstileWidgetComponent`) | `frontend/src/app/components/shared/turnstile-widget/` | Reutilizado en las 7 superficies públicas (`login`, `signup`, `adoptions`, `campaigns`, `identifications`, `talks`). |
| **Abrir en Nueva Pestaña al Mantener Presionado** | `[appLongPressOpen]` (`LongPressOpenDirective`) | `frontend/src/app/directives/long-press-open.directive.ts` | Directiva standalone reutilizada en todos los botones `.btn-copy-form` (600 ms con clic o *tap*). |

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


