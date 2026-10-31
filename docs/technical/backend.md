# Backend — API y Especificación de Servicios

**Proyecto:** Plataforma Web Institucional ABAQ (Servicio Social y Voluntariado General)  
**Versión:** 2.2.0  
**Fecha:** 2026-10-30  
**Estado:** Sistema Real en Producción (Node.js v24 LTS + Express v4.19 + MongoDB Atlas Mongoose)

---

## 1. Visión General de la API

El backend de ABAQ es una API RESTful construida con **Express** sobre **Node.js v24 LTS**, que gestiona la persistencia y reglas de negocio institucionales en **MongoDB Atlas** mediante modelos de **Mongoose**:
- **Base URL local:** `http://localhost:3000`
- **Autenticación:** JSON Web Tokens (JWT) mediante cabecera `Authorization: Bearer <token>` emitida por `/auth/login`. También admite token por query parameter (`?token=...`) en descargas de archivos del navegador.
- **Segregación de Identidades:** La colección `User` administra credenciales, hash bcrypt y roles (`admin`, `student`, `volunteer`), enlazada mediante `authId` a los perfiles de dominio correspondientes (`Student` o `Volunteer`).
- **Arquitectura Zero-File:** El servidor no almacena archivos binarios locales ni en GridFS. Los documentos externos residen en enlaces cloud verificados (`cloudUrls`) y las constancias oficiales se renderizan al vuelo con firmas criptográficas HMAC-SHA256.

---

## 2. Inventario Completo de Endpoints

### 2.1 Autenticación y Cuentas (`/auth`)
| Método + Ruta | Acceso | Descripción |
|---|---|---|
| `POST /auth/login` | Pública | Autentica credenciales (correo y contraseña), emite JWT firmado por 7 días con datos de usuario y rol. |
| `POST /auth/signup` | Pública | Registro completo de estudiante de Servicio Social (`User` con rol `student` + documento `Student`). Asigna y persiste el folio institucional `folio: SS-YYMMDD-XX` e inicializa 10 horas de inducción. |
| `POST /auth/signup-volunteer` | Pública | Registro completo de Voluntario General (`User` con rol `volunteer` + documento `Volunteer` en estado `pending`). Asigna y persiste el folio institucional `folio: VG-YYMMDD-XX`. No inicializa horas. |
| `POST /auth/register` | Pública | Registro base de usuario (default rol `student`). |
| `POST /auth/activate-volunteer` | Pública | Activa cuenta de voluntario general mediante token de activación. |
| `GET /auth/me` | Bearer | Retorna la identidad del usuario en sesión actual. |

---

### 2.2 Estudiantes de Servicio Social (`/student`)
| Método + Ruta | Acceso | Descripción |
|---|---|---|
| `GET /student/v/:hashToken` | Pública | Verificación criptográfica HMAC-SHA256 y renderizado HTML imprimible de constancia oficial. |
| `GET /student/certificate/v/:hashToken` | Pública | Alias directo de verificación criptográfica de constancias. |
| `GET /student/:id/certificate/acceptance` | Pública | Generación bajo demanda de la Carta de Aceptación Oficial de Servicio Social. |
| `GET /student/:id/certificate/completion` | Pública | Generación bajo demanda del Certificado de Término Oficial (480 horas acreditadas). |
| `POST /student/check-inactivity` | Bearer | Ejecuta la auditoría de la regla de inactividad de 2 meses: identifica y actualiza alumnos sin actividad en 60 días. |
| `POST /student/new` | Bearer | Creación de registro de estudiante validado mediante `studentChecks`. |
| `GET /student` | Bearer | Listado completo de estudiantes registrados para la tabla operativa administrativa. |
| `GET /student/:id` | Bearer | Detalle exhaustivo del expediente del estudiante por su identificador `_id`. |
| `GET /student/auth/:authId` | Bearer | Consulta expediente de estudiante por el identificador de cuenta `authId`. |
| `PATCH /student/:id` | Bearer | Actualización integral de expediente por parte de la coordinación administrativa. |
| `PATCH /student/me` | Bearer | Actualización de perfil por el propio estudiante en sesión (teléfono, correo personal, redes). |
| `DELETE /student/:id` | Bearer + admin | Eliminación lógica/física de registro de estudiante. |

---

### 2.3 Voluntarios Generales (`/volunteer`)
| Método + Ruta | Acceso | Descripción |
|---|---|---|
| `GET /volunteer/:id/certificate/acceptance` | Pública | Generación bajo demanda de la Carta de Aceptación de Voluntario General. |
| `GET /volunteer` | Bearer | Listado completo de voluntarios generales para la tabla administrativa. |
| `GET /volunteer/:id` | Bearer | Detalle exhaustivo del perfil de voluntario por su identificador `_id`. |
| `POST /volunteer` | Pública | Registro de voluntario general sin creación inmediata de cuenta de usuario. |
| `PATCH /volunteer/:id/status` | Bearer + admin | Actualización del estado operativo del voluntario (`pending`, `active`, `rejected`). |
| `PATCH /volunteer/:id` | Bearer + admin | Actualización integral de datos personales, ocupación, grados y enlaces cloud por la administración. |
| `PATCH /volunteer/me` | Bearer | Actualización de teléfono y redes sociales por el propio voluntario en sesión. |

---

### 2.4 Respaldo, Exportación y Restauración Transaccional (`/backup`)
*Todas las rutas del router `/backup` están restringidas a rol `admin` y admiten autenticación vía Bearer header o parámetro `?token=` para descargas directas del navegador.*

| Método + Ruta | Acceso | Descripción |
|---|---|---|
| `GET /backup/status` | Bearer / admin | Retorna métricas del clúster: conteo de documentos por colección, peso total y estado de salud. |
| `GET /backup/download/json` | Bearer / admin | Exportación integral de la base de datos en archivo comprimido JSON descargable con timestamp. |
| `GET /backup/download/excel` | Bearer / admin | Generación dinámica de libro de cálculo Excel (`.xlsx`) estructurado con pestañas por colección operativa. |
| `POST /backup/restore` | Bearer / admin | Restauración transaccional desde archivo de respaldo (multipart `file` o `backup`), con análisis preliminar (*dry-run*) y reversión atómica ante fallos. |

---

### 2.5 Actividades y Participación (`/activity` y `/quick-activities`)
| Método + Ruta | Acceso | Descripción |
|---|---|---|
| `GET /activity` | Bearer | Catálogo general de actividades disponibles para inscripción y consulta. |
| `POST /activity` | Bearer + admin | Creación de nueva actividad comunitaria con horario, valor en horas y límite de cupo. |
| `GET /activity/:id` | Bearer | Detalle de actividad con fechas, tipo y cupo disponible. |
| `PATCH /activity/:id` | Bearer + admin | Edición de parámetros de la actividad. |
| `DELETE /activity/:id` | Bearer + admin | Eliminación de actividad del catálogo. |
| `POST /activity/:id/assign` | Bearer | Inscripción de voluntario o estudiante a la actividad. |
| `GET /activity/:id/participants` | Bearer | Lista de participantes inscritos con su estado de asistencia. |
| `PATCH /activity/:id/cancel-registration` | Bearer | Cancelación de inscripción por parte del participante. |
| `PATCH /activity/:id/participants/:studentId` | Bearer + admin | Actualización de asistencia (`attended` / `absent`) y acreditación de horas. |
| `GET/POST /quick-activities` | Bearer + admin | Gestión rápida de actividades exprés convocadas por WhatsApp. |
| `POST /quick-activities/:id/publish` | Bearer + admin | Publicación y activación de actividad rápida. |

---

### 2.6 Acreditaciones y Horas (`/accreditation`)
| Método + Ruta | Acceso | Descripción |
|---|---|---|
| `POST /accreditation` | Bearer | Solicitud de acreditación de horas por actividad completada. |
| `GET /accreditation` | Bearer | Listado general de acreditaciones para auditoría administrativa. |
| `GET /accreditation/student/:studentId` | Bearer | Historial de acreditaciones de un estudiante específico. |
| `PATCH /accreditation/:id/approve` | Bearer + admin | Aprobación de horas con incremento atómico en `horasAcreditadas` del estudiante. |
| `PATCH /accreditation/:id/reject` | Bearer + admin | Rechazo de acreditación con registro de observaciones. |
| `PATCH /accreditation/:id/manual-hours` | Bearer + admin | Ajuste manual excepcional de horas con tope estricto de horas requeridas. |

---

### 2.7 Módulos de Bienestar y Comunidad
| Recurso | Rutas Principales | Descripción |
|---|---|---|
| **Mascotas (`/pet`)** | `GET`, `POST`, `GET/PATCH/DELETE /:id` | Censo y registro de animales atendidos por la fundación. |
| **Campañas (`/campaign`)** | `GET`, `POST`, `GET /:id` | Campañas masivas de esterilización y salud comunitaria. |
| **Pláticas (`/talk`)** | `GET`, `POST`, `GET /:id` | Pláticas de tenencia responsable en escuelas y empresas. |
| **Adopciones (`/adoption`)** | `GET`, `POST`, `GET /:id`, `PATCH /:id/complete` | Registro y seguimiento a protocolos de adopción responsable. |
| **Identificaciones (`/identification`)** | `GET`, `POST`, `GET /:id`, `PATCH /:id/status` | Emisión de placas QR con proveedor oficial ABAQ. |
| **Encuestas (`/survey`)** | `GET`, `POST /form/submit`, `GET /form` | Encuestas vecinales de bienestar animal. |
| **Contacto (`/contact`)** | `POST`, `GET`, `GET/PATCH/DELETE /:id` | Mensajes y solicitudes de apoyo comunitario. |

---

## 3. Subsistema Criptográfico de Certificados (`backend/utils/certificates.js`)

El motor de certificación genera documentos oficiales sin almacenar PDFs ni saturar la memoria del servidor (consumo ~2.2 MB RAM por renderizado):
1. **Generación del Token:**
   ```
   st_[id]_[certType]_[hmac32]
   ```
   Firmado con algoritmo HMAC-SHA256 usando la clave secreta institucional.
2. **Prevención de Ataques de Canal Lateral:**
   La verificación compara el HMAC recibido con el computado mediante `crypto.timingSafeEqual`:
   ```javascript
   const isValid = crypto.timingSafeEqual(
     Buffer.from(tokenHmac, 'hex'),
     Buffer.from(expectedHmac, 'hex')
   );
   ```
3. **Descarga en Cliente:**
   El frontend recibe el documento HTML estructurado y ejecuta `html2pdf.js` en el navegador del cliente para exportar a PDF en formato A4 horizontal (`1122px` × `793px`), liberando de cómputo gráfico a la API.

---

## 4. Reglas de Negocio en Backend

1. **Tope Institucional de Horas:**
   Ningún estudiante de servicio social puede acumular más de **480 horas** (`horasCubrir: 480`). Todo intento de acreditar horas adicionales queda acotado a `Math.min(nuevasHoras, horasPendientes)`.
2. **Segregación Estricta de 10 Horas de Inducción:**
   - Estudiantes de Servicio Social (`SS`) inician con `horasAcreditadas: 10` y `horasPendientes: 470` al completar la inducción de la Fase 2.
   - Voluntarios Generales (`VG`) no acumulan horas escolares y sus registros no computan saldos de horas.
3. **Regla de Inactividad de 2 Meses:**
   El endpoint `/student/check-inactivity` audita la fecha de la última participación activa. Estudiantes sin actividad por más de 60 días naturales son clasificados como inactivos, notificando a coordinación para baja administrativa.
4. **Respaldo Atómico y Rollback:**
   Toda restauración de respaldo ejecutada mediante `POST /backup/restore` corre en modo transaccional cuando la réplica de base de datos lo soporta, o realiza un respaldo preventivo temporal previo antes de reemplazar colecciones para garantizar recuperación inmediata ante fallos.
5. **Persistencia Obligatoria del Folio de Expediente:**
   La decisión preliminar de no definir el folio en la raíz del esquema para no invalidar registros históricos fue formalmente corregida en producción. Todo registro nuevo de estudiante o voluntario genera y persiste de forma estricta su `folio` al crearse (`folio: { type: String, trim: true, uppercase: true, index: true }`), manteniéndose a la vez retrocompatibilidad con fallbacks dinámicos en los controladores y mappers para registros antiguos.
