# ABAQ — Design System & Codebase Specification (`DESIGN.md`)

> **Source of Truth**: Extracted directly from the real production codebase (`frontend/` commit `4437780`, `backend/` commit `b669c60`, and `documentation/`). Every product name, tagline, label, field name, status state, validation rule, color token, layout structure, and interface in this document comes from actual production code in Angular v22 Standalone, Node.js v24 Express, and MongoDB—zero mock data or hypothetical placeholders.

---

## 1. Codebase Purpose, Goals & Dominant Feature

### Purpose
**ABAQ** (**Amor y Bienestar Animal en Querétaro**) is an institutional web platform that digitizes and manages university **Servicio Social** (social service), **Voluntariado General** (community volunteers), animal welfare activities, student digital dossiers (*expedientes*), community pet census surveys, and cryptographically verified official documentation.

- **Primary Product Name**: `ABAQ`
- **Platform Subtitle**: `Servicio Social y Voluntariado General`
- **Brand Tagline / Footer Copy**: `Amor y bienestar animal en Querétaro`
- **Portal Headline**: `ABAQ — Plataforma Institucional de Gestión y Acreditación`

### Core Goals
1. **For Social Service Students (`role: 'student'`, `SS`)**:
   - Complete the structured **4-Phase Guided Onboarding** with academic records, induction training, personal bio, and cloud dossier links.
   - Earn **10 accredited hours** automatically upon completing the Phase 2 induction modules.
   - Track progress toward the fixed **480-hour** institutional requirement (`Horas requeridas`, `Horas acreditadas`, `Horas pendientes`).
   - Register for community activities, participate, and obtain official cryptographically signed documents (**Carta de Aceptación** and **Certificado de Término**).
   - Comply with the **2-Month Inactivity Rule** to avoid administrative dismissal.
2. **For General Volunteers (`role: 'volunteer'`, `VG`)**:
   - Register through the 4-Phase flow without university constraints (entering occupation and academic degrees).
   - Experience the platform without school hour burdens (**no 10-hour induction credits and no hour numbers visible** in activities or induction).
   - Receive official recognition via a dedicated **Carta de Aceptación de Voluntario General**.
3. **For Coordinators & Administrators (`role: 'admin'`)**:
   - Audit postulants in dense operational tables (`Estudiantes` and `Voluntarios Generales`) with comprehensive drawer/modal data inspection.
   - Validate attendance and accredit hours (`✓ Asistió` / `✕ No asistió` / `Validar horas`) with strict remaining-hour ceilings and institutional caps (e.g., Anáhuac/ITESM donation limits).
   - Execute database maintenance via the **Backup Subsystem** (`/admin/backup`): full JSON/Excel exports and dry-run transactional rollback restoration.

### What Dominates the Page (Visual Weight & Native Shape)
The product's native shape is an **Hour-Accreditation Pipeline, 4-Phase Guided Onboarding & Dense Operational Ledger**:
1. **Navy-to-Green Diagonal Gradient Hero**:
   - Every primary dashboard and list view opens with the signature `linear-gradient(135deg, #24366f 0%, #334c91 55%, #5ca83a 135%)` banner paired with high-contrast KPI strips.
2. **The 4-State Participation Pipeline**:
   - `registered` (`Registrado`) → `attended` (`Asistió`) / `absent` (`No asistió`) → `validated` (`Horas validadas`).
3. **Adaptive 4-Phase Onboarding Layout**:
   - Desktop (>1024px): Centered card accompanied by a sticky left outline showing real-time progress.
   - Tablet & Mobile (<=1024px): Outline is **completely hidden (`display: none !important`)**, expanding the form to 100% full width and relying solely on the top phase navbar.
4. **Numbered Section Blocks (`01`, `02`, `03`...)**:
   - Clean horizontal cards led by a `42px × 42px` rounded-square green badge with an inline `cloud_done Guardado` indicator at the far right of section headers.

---

## 2. Critical Files in the Repository

### Frontend (`frontend/src/app/` — Standalone Architecture)
- **Global Styles & Foundation**:
  - `frontend/src/styles.scss` — Bootstrap 5.3 import, global `#f8f9fa` canvas, custom scrollbars, and design system utility classes.
  - `frontend/src/app/app.routes.ts` — Standalone route configuration with `AuthGuard`, `PublicGuard`, and role-based route protection.
  - `frontend/src/app/components/navbar/navbar.component.{html,scss,ts}` — Fixed top navy gradient navbar (`72px`) adapting links by `user.role` (`admin`, `student`, `volunteer`).
- **4-Phase Onboarding & Dossier Generation**:
  - `frontend/src/app/features/onboarding/onboarding-phase.component.{html,scss,ts}` — Unified 4-Phase guided signup (`01 Perfil`, `02 Inducción`, `03 Sobre Mí`, `04 Documentos y Legal`).
  - `frontend/src/app/features/onboarding/expediente-recibido.component.{html,scss,ts}` — End-state screen with institutional folio (`SS-YYMMDD-XX` / `VG-YYMMDD-XX`), confetti animation, and pending account state.
  - `frontend/src/app/services/onboarding-state.service.ts` — Client-side reactive persistence with `localStorage` debounced at 400ms and `beforeunload` hook.
- **Custom UI Controls**:
  - `frontend/src/app/components/shared/custom-select/custom-select.component.{html,scss,ts}` — Accessible combobox with keyboard navigation and focus-first behavior.
  - `frontend/src/app/components/shared/custom-datepicker/custom-datepicker.component.{html,scss,ts}` — Auto-slashing masked datepicker (`DD/MM/AAAA`).
- **Dashboards & Workstations**:
  - `frontend/src/app/components/home/home.component.{html,scss,ts}` — Student dashboard with 5 KPI cards, progress doughnut chart, and activity queue.
  - `frontend/src/app/components/admin-home/admin-home.{html,scss,ts}` — Admin dashboard with 4 metric cards, triage panel, and upcoming activities.
  - `frontend/src/app/components/student/student.component.{html,scss,ts}` — Admin dense operational table for social service students with search, filters, and comprehensive data drawer.
  - `frontend/src/app/features/volunteers/components/volunteer-list.component.{html,scss,ts}` — Admin dense operational table for general volunteers.
  - `frontend/src/app/components/student-detail/student-detail.{html,scss,ts}` — Student dossier workstation, document verification links, and hour logs.
  - `frontend/src/app/features/volunteers/components/volunteer-detail.component.{html,scss,ts}` — General volunteer dossier and status management.
  - `frontend/src/app/features/backup/backup.component.{html,scss,ts}` — Database backup center: JSON/Excel downloads and rollback restoration.
- **Activities & Hours**:
  - `frontend/src/app/components/activity-list/activity-list.component.{html,scss,ts}` — Dual-role activity catalog with capacity badges.
  - `frontend/src/app/components/activity-detail/activity-detail.{html,scss,ts}` — Admin attendance and step-0.5h validation workstation.

### Backend (`backend/` — Express v4.19 + Node.js v24 + MongoDB)
- `backend/app.js` — Express application mounting all API routes, CORS configuration, error handlers, and startup `ensureFolioIntegrity()` backfill.
- `backend/models/student.model.js` — Mongoose schema for students with strictly required `folio` (`SS-YYMMDD-XX`, zero-null rule), `cloudUrls`, `consents`, `onboardingData`, and `assignedActivities`.
- `backend/models/volunteer.model.js` — Mongoose schema for general volunteers with strictly required `folio` (`VG-YYMMDD-XX`, zero-null rule), `degrees`, `occupation`, `cloudUrls`, and `consents`.
- `backend/utils/certificates.js` — Cryptographic certificate rendering engine with HMAC-SHA256 signature verification and printable A4 landscape template.
- `backend/controllers/backup.controller.js` — Database backup, Excel generation, and transactional restore.

---

## 3. Visual Identity & Design Tokens

### 3.1 Color Palette

#### Brand Navy & Green Palette
| Token Name | Hex Value | Primary Usage |
|---|---|---|
| **Navy 950** | `#1f2f63` | Navbar gradient start, high-elevation surfaces |
| **Navy 900** | `#24366f` | Primary brand navy, H1-H3 headings, hero gradient start, table headers |
| **Navy 800** | `#2f4787` | Navbar gradient end, secondary borders |
| **Navy 700** | `#334c91` | Hero gradient midpoint (55%), primary action links, validated status |
| **Green 500** | `#7bbf4f` / `#78bc4b` | Primary leaf green, CTA gradient start, focus ring, active nav indicators |
| **Green 600** | `#5ca83a` / `#609d54` | Primary forest green, CTA gradient end, section badges (`01`, `02`...) |
| **Green 700** | `#5b9d36` / `#5c9d38` | Section kicker text, attended status badge, positive highlights |
| **Green 400** | `#85d55d` | Glowing live dot (`Sistema activo`), auto-save checkmark |

#### Social Media Brand Identity Badges
| Platform | Badge Glyph | Brand Hex Color | Background Tint |
|---|---|---|---|
| **Facebook** | `f` | `#1877F2` | `rgba(24, 119, 242, 0.10)` |
| **Instagram** | `◎` | `#E1306C` | `linear-gradient(45deg, #f09433, #e6683c, #dc2743, #cc2366, #bc1888)` |
| **TikTok** | `♪` | `#000000` | `rgba(0, 0, 0, 0.08)` |
| **X / Twitter** | `𝕏` | `#000000` | `rgba(0, 0, 0, 0.08)` |
| **YouTube** | `▶` | `#FF0000` | `rgba(255, 0, 0, 0.10)` |
| **LinkedIn** | `in` | `#0A66C2` | `rgba(10, 102, 194, 0.10)` |

#### Official Certificate Canvas Tokens
| Token | Value | Purpose |
|---|---|---|
| **Canvas Background** | `#F4F3EC` / `#fdfbf7` | Archival parchment simulation for printable certificates |
| **Outer Border Double** | `3px double #24366f` | Formal frame perimeter |
| **Inner Accent Border** | `1px solid #b3832b` | Institutional gold accent line |
| **Watermark Logo** | `opacity: 0.04` | Centered ABAQ crest behind certificate body copy |
| **Typography Display** | `Cinzel`, `Crimson Text`, serif | Formal institutional headers |
| **Signature Script** | `Great Vibes`, cursive | Digital signature title simulation |
| **Verification Seal** | `#b3832b` + `#24366f` | Golden rosette badge with HMAC verification link |

---

## 4. Reusable Component Patterns

### 4.1 4-Phase Adaptive Onboarding Layout
- **Desktop (>1024px)**:
  - 2-column flex container:
    - Left column (`260px`, `position: sticky; top: 96px`): Outline list showing the 4 phases and sub-sections, checked states (`✓`), and current step highlight.
    - Right column (`max-width: 840px; width: 100%`): Active phase card with generous spacing (`padding: 36px 40px`).
- **Tablet & Mobile (<=1024px)**:
  - Outline is **completely hidden (`display: none !important`)**.
  - Form container expands to `100%` width with reduced padding (`padding: 20px 16px`).
  - Progress is communicated exclusively by the sticky top phase navbar.

### 4.2 Composite Period Academic Selector (100% Full Width)
- Encapsulated within a full-width card row in Phase 1:
  - Left column: Custom period number dropdown (`1` to `12`).
  - Right column: Read-only grey block displaying the grammatical ordinal and period type (`1.er Semestre`, `2.º Cuatrimestre`, `3.er Bimestre`, etc.).
  - Period Type dropdown: Free selection between `Semestre`, `Cuatrimestre`, `Bimestre`, `Trimestre`, `Módulo`, `Año`.
  - Service Dates: Strict explanatory text distinguishing social service duration from university graduation.

### 4.3 Reactive Auto-Save Indicator
- Located at the far right of every section heading (`.section-heading`):
  ```html
  <div class="save-status-indicator">
    <span class="material-icons save-icon">cloud_done</span>
    <span class="save-text">Guardado</span>
  </div>
  ```
- Subtly animates upon RxJS `debounceTime(400)` emission and provides reassuring feedback without interrupting data entry.

### 4.4 Zero-File Cloud Storage Input Row
- Standard form field designed for URL entry rather than file uploads.
- Accompanied by helper links for Google Drive and OneDrive, including an amber alert banner:
  > *"Verifica que el enlace sea público abriéndolo previamente en una ventana de incógnito."*

---

## 5. Screen-by-Screen Inventory & Real Copy

### 5.1 Login (`/auth/login` — `LoginComponent`)
- **Card**: Centered glassmorphic container (`430px` width) over radial gradient canvas.
- **Copy**:
  - `h2`: `Bienvenido`
  - `p`: `Ingresa a la plataforma de ABAQ`
  - Input: `Correo electrónico` (placeholder `correo@ejemplo.com`)
  - Input: `Contraseña` (placeholder `••••••••••••`)
  - Checkboxes: `Mostrar contraseña`, `Recordarme`
  - Primary button: `Iniciar sesión`
  - Secondary button: `Crear una cuenta` (`/auth/signup`)

### 5.2 4-Phase Guided Onboarding (`/auth/signup` — `OnboardingPhaseComponent`)
- **Hero / Header**:
  - Title: `Registro de Colaborador`
  - Subtitle: `Completa tu expediente institucional en el proceso de onboarding y registro guiado.`
  - Auto-save indicator: `cloud_done Guardado`
- **Fase 1 — Perfil y Redes**:
  - Section `01`: `Datos de la cuenta` (Correo institucional/personal, contraseña de 12+ caracteres).
  - Section `02`: `Datos personales` (Nombre, apellidos, CURP, fecha de nacimiento, teléfono, WhatsApp).
  - Section `03` (SS): `Información académica` (Institución, carrera, control compuesto de periodo, fechas de servicio).
  - Section `03` (VG): `Perfil profesional` (Ocupación actual, grados académicos modulares).
  - Section `04`: `Redes sociales` (Campos con badges SVG para Facebook, Instagram, TikTok, X, YouTube, LinkedIn).
- **Fase 2 — Módulos de Inducción**:
  - Banner de Horas: *"NOTA: En caso de Servicio Social, esta presentación será válida por 10 horas, además de que te permitirá continuar"* (**exclusivo para SS; completamente oculto para VG**).
  - 6 Módulos con enlaces oficiales a Canva, YouTube y sitio web.
  - 3 Preguntas de reflexión por módulo (vacías por defecto, con placeholders de ejemplo).
  - Declaración bajo protesta de no uso de IA generativa.
- **Fase 3 — Sobre Mí y Priorización de Actividades**:
  - Reseña biográfica, talentos y experiencia previa con animales.
  - Lista de 11 actividades reglamentarias reordenables (con valores de horas visibles solo para SS).
- **Fase 4 — Documentos y Consentimientos Legales**:
  - Enlaces públicos en la nube a INE, CV y Comprobante.
  - 5 Casillas de consentimiento informado legal con modales de lectura íntegra.

### 5.3 Expediente Recibido (`/expediente-recibido` — `ExpedienteRecibidoComponent`)
- **Layout**: Centered confirmation card with zero navbar layout shift.
- **Folio Badge**: `SS-YYMMDD-XX` or `VG-YYMMDD-XX`.
- **Feedback**: Active confetti animation (`canvas-confetti`).
- **Instructions**: Notifies user of account state `pending` and administrative validation within 24–48 hours.

### 5.4 Admin Dense Operational Tables (`/student` and `/volunteer`)
- **Header**: Search toolbar, quick filters by status (`Todos`, `Activos`, `Pendientes`, `Inactivos`), counter badge.
- **Columns**: Nombre, Institución/Carrera (o Ocupación), Correo, Teléfono, Horas (requeridas / validadas / pendientes), Estatus, Acciones.
- **Row Inspector**: Side drawer / modal displaying CURP, period details, dates, social links, cloud URLs, induction reflections, and action buttons (Validar cuenta, Generar constancia, Auditar).

### 5.5 Backup Subsystem Workstation (`/admin/backup` — `BackupComponent`)
- **Header**: `Centro de Respaldo y Recuperación` (`MongoDB Cluster Engine`).
- **Cards**:
  1. `Exportación Completa`: Botones para descargar archivo comprimido `JSON` o libro de cálculo `Excel (.xlsx)`.
  2. `Restauración y Rollback`: Carga de archivo de respaldo con análisis preliminar (*dry-run*) y restauración atómica en caso de error.

---

## 6. Core Data Schemas (TypeScript Interfaces)

```typescript
export interface CloudUrls {
  ine: string;
  cv: string;
  comprobante: string;
}

export interface Consents {
  reglamento: boolean;
  privacidad: boolean;
  etica: boolean;
  incognito: boolean;
  consentimiento: boolean;
}

export interface Degree {
  level: 'preparatoria' | 'tecnico' | 'licenciatura' | 'especialidad' | 'maestria' | 'doctorado' | 'posdoctorado';
  institution: string;
  title: string;
  status: 'completado' | 'en_curso' | 'trunco';
}

export interface AssignedActivity {
  activityRef: string;
  title: string;
  type: string;
  comments: string;
  dueDate: Date;
  valueInHours: number;
  validatedHours: number;
  status: 'registered' | 'attended' | 'absent' | 'validated' | 'cancelled';
  performance?: 'pending' | 'very_bad' | 'bad' | 'good' | 'very_good' | 'excellent' | 'absent';
  performanceComment?: string;
}

export interface Student {
  id: string;
  _id?: string;
  authId?: string;
  folio: string; // Strictly required institutional folio (SS-YYMMDD-XX)
  nombreCompleto: string;
  names?: string;
  apellidoPaterno?: string;
  apellidoMaterno?: string;
  curp?: string;
  matricula: string;
  correoPersonal?: string;
  correoInstitucional: string;
  escuela: string;
  carrera: string;
  academicLevel?: string;
  periodType: string;
  periodNumber: number;
  semestre: string;
  fechaArranque: Date;
  fechaConclusion?: Date;
  telefono: string;
  hasWhatsapp: boolean;
  whatsappNumber?: string;
  fechaNacimiento: Date;
  horasCubrir: number;
  horasAcreditadas: number;
  horasPendientes: number;
  accountStatus: 'pending' | 'active' | 'rejected';
  cloudUrls: CloudUrls;
  consents: Consents;
  onboardingData?: Record<string, any>;
  assignedActivities: AssignedActivity[];
  facebookUsuario?: string;
  instagramUsuario?: string;
  tiktokUsuario?: string;
  xUsuario?: string;
  youtubeUsuario?: string;
  linkedinUsuario?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface Volunteer {
  id: string;
  _id?: string;
  authId?: string;
  folio: string; // Strictly required institutional folio (VG-YYMMDD-XX)
  volunteerType: 'GENERAL' | 'SERVICE_SOCIAL';
  volunteerStatus: 'pending' | 'active' | 'rejected';
  accountStatus: 'pending' | 'active' | 'rejected';
  nombreCompleto: string;
  correoPersonal?: string;
  telefono: string;
  hasWhatsapp: boolean;
  whatsappNumber?: string;
  fechaNacimiento: Date;
  occupation?: string;
  degrees: Degree[];
  cloudUrls: CloudUrls;
  consents: Consents;
  onboardingData?: Record<string, any>;
  assignedActivities: AssignedActivity[];
  createdAt?: Date;
  updatedAt?: Date;
}

export interface BackupStatus {
  totalCollections: number;
  totalDocuments: number;
  databaseSizeBytes: number;
  lastBackupDate?: Date;
  clusterStatus: 'healthy' | 'degraded' | 'syncing';
}
```

---

## 5. Architectural Invariants & Data Integrity Rules

### 5.1 Zero-Null Folio Policy (Regla Estricta de Folio Obligatorio)
- **Mandatory Institutional Folio**: Under NO circumstances can any `Student` or `Volunteer` document exist with `folio: null`, empty, or undefined in the database.
- **Folio Format**: `SS-YYMMDD-XX` for Social Service Students, `VG-YYMMDD-XX` for General Volunteers (where `YYMMDD` is creation date and `XX` is a 2-character hexadecimal suffix).
- **Enforcement Layers**:
  1. **Mongoose Schema Constraint**: `folio: { type: String, required: [true, 'El folio institucional de expediente es obligatorio'], trim: true, uppercase: true, index: true }`.
  2. **Lifecycle Pre-Validate Hook**: `pre('validate')` automatically constructs deterministic folios on any document lacking one prior to validation.
  3. **Startup Backfill Migration**: `ensureFolioIntegrity()` scans and repairs any legacy records without a folio upon MongoDB connection.
  4. **Immutability**: Once created, folios cannot be updated or edited by users or administrators.

