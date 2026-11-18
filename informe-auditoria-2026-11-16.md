# Informe de auditoría de seguridad — ABAQ (cuentas inactivas y sistema)

| Campo | Valor |
|---|---|
| Fecha | 16 nov 2026 |
| Metodología | OWASP WSTG + OWASP Top 10 (2021), según *Metodología de Auditoría de Seguridad Web — Ejecución y Reporte* |
| Enfoque | Caja blanca (código y arquitectura) con explotación controlada **local** (MongoDB en memoria) |
| Alcance | Backend Express (`backend`), frontend Angular (`frontend`); énfasis en el dominio de cuentas inactivas |
| Fuera de alcance | Pruebas contra los entornos desplegados (dev y producción): no se atacó ninguno |
| Distribución | Solo el propietario. No publicar mientras producción no tenga las correcciones |

## Resumen ejecutivo

Se mapeó la superficie de ataque de 16 módulos de rutas y se recorrió el checklist del Top 10. Los hallazgos de la Fase 2 se confirmaron en la Fase 3 con una prueba de concepto local, sin tocar datos reales.

| Severidad | Hallazgos | Corregidos en `dev-rivers2` | Pendientes |
|---|---|---|---|
| Crítico | 1 | 1 | 0 |
| Alto | 3 | 3 (uno parcial) | nodemailer |
| Medio | 3 | 1 | 2 |
| Bajo | 4 | 1 | 3 |

**Regla de negocio auditada (cuentas inactivas):** una cuenta inactiva solo consulta lo que ya tenía vinculado y recibe los cambios de estado que haga la Coordinación. No ve convocatorias nuevas, no recibe vinculaciones nuevas y no ejecuta acciones.

- **Antes:** las acciones estaban bloqueadas, pero también la consulta (403 en todo), y la Coordinación sí podía crearle vinculaciones nuevas.
- **Ahora:** se cumple la regla completa, con 15 aserciones automatizadas.

**Importante:** producción (rama `dev`, proyecto `abaq-dev-app`) **sigue expuesta a H-01, H-02 y H-03** hasta que se promuevan los commits `cf3db24` y `16e5011`.

## Fase 1 — Mapa de la superficie (dominio auditado)

| Endpoint | Método | Rol | Inactivo (antes → ahora) |
|---|---|---|---|
| `/activity` | GET | autenticado | 403 → 200, solo convocatorias vinculadas |
| `/activity/:id` | GET | autenticado | 403 → 200 si está vinculada, 404 si no |
| `/activity/changes` | GET | autenticado | 403 → 200, huella acotada a lo vinculado |
| `/activity/:id/assign` | POST | estudiante/voluntario | 403 → 403 |
| `/activity/:id/cancel-registration` | PATCH | estudiante/voluntario | 403 → 403 |
| `/activity/:id/participants/:pid` | PATCH | admin | evalúa lo ya vinculado (se mantiene) |
| `/accreditation` | POST | todos | 403 → 403; admin → inactivo: 500 accidental → 403 explícito |
| `/accreditation/student/:id` | GET | dueño/admin | 403 → 200 (solo el dueño) |
| `/accreditation/:id` | DELETE | dueño | 403 → 403 |
| `/accreditation/:id/approve` | PATCH | admin | aprueba lo existente (se mantiene) |
| `/volunteer/me`, `/student/auth/:authId` | GET | dueño | 200 → 200 |
| `/volunteer/me`, `/student/me` | PATCH | dueño | 403 → 403 |
| `/notifications/*` | GET/PATCH | dueño | 200 → 200 (solo sus avisos) |

Cuentas `pending` y `rejected`: sin acceso a ninguna de estas rutas (se verificó que siguen en 403).

## Fichas de hallazgos

### H-01 — Toma de expediente registrándose con el correo secundario de otra persona

- **Severidad:** Crítico. Sin estar autenticado, cualquiera obtiene el expediente completo de otra persona (CURP, domicilio, teléfono) y actúa en su nombre. Solo requiere conocer su segundo correo; los institucionales son predecibles. Afecta a todo estudiante que tenga dos correos.
- **Ubicación:**
  - `middlewares/auth.middleware.js` (`protect`).
  - `controllers/auth.controller.js` (`buildUserData`).
  - `controllers/student.controller.js` (`getStudentByAuthId`, `getMyProfile`).
  - `POST /auth/register`.
- **Descripción:** el expediente se buscaba con `authId` **o** cualquiera de los correos. Si lo encontraba por correo y su `authId` era de otra cuenta, lo **sobrescribía** con la cuenta actual. `/auth/register` crea cuentas sin verificar el correo.
- **Evidencia:** la víctima entra con `victima@gmail.com`; su expediente tiene además `victima@alumnos.uaq.mx`.
  - `POST /auth/register {email: "victima@alumnos.uaq.mx"}` → 201.
  - `GET /student/:idVictima` con ese token → 200, CURP expuesta, `authId` reasignado.
  - Después de la corrección: 403, `authId` intacto y la víctima conserva el acceso (pruebas H-takeover y R2).
- **Impacto:** fuga de datos personales y suplantación (envío de vinculaciones, edición del perfil, descarga de constancias).
- **Remediación (aplicada):**
  - `utils/linked-profile.js` resuelve el expediente por `authId`.
  - El correo solo **reclama expedientes sin dueño**, con una actualización atómica.
  - Se eliminaron las tres copias inseguras de esa lógica.
- **Referencias:** OWASP A01:2021 y A07:2021; CWE-639, CWE-287.

### H-02 — Asignación masiva en el registro (horas acreditadas)

- **Severidad:** Alto. Compromete la integridad del activo principal (las horas de Servicio Social) y es trivial desde el navegador.
- **Ubicación:** `POST /auth/signup-student` y `POST /auth/signup-volunteer` (`...studentData` / `...volunteerData`).
- **Descripción:** el cuerpo completo se copiaba al expediente. `horasAcreditadas` y `horasPendientes` se tomaban del cliente; `assignedActivities`, `accreditations` y `authId` también pasaban.
- **Evidencia:** registro con `horasAcreditadas: 470` → expediente con 470 h. Después de la corrección: 10 h, el valor del servidor (prueba H-mass).
- **Impacto:** un aspirante llega a la activación con sus horas casi completas.
- **Remediación (aplicada):**
  - Lista `PROTECTED_SIGNUP_FIELDS` que se descarta del cuerpo.
  - Horas fijadas por el servidor.
  - El folio solo se acepta con formato válido (`SS|VG-AAMMDD-XX`).
- **Referencias:** OWASP A04:2021 y A08:2021; CWE-915.

### H-03 — Datos personales de terceros en `/pet` y `/contact` para cualquier cuenta activa

- **Severidad:** Alto. Expone y permite modificar o borrar datos personales (dueños de animales: nombre, dirección y teléfono; contactos). Basta con ser estudiante o voluntario activo.
- **Ubicación:** `routes/pet.route.js` y `routes/contact.route.js` (CRUD completo sin restricción de rol).
- **Evidencia:** voluntario activo `GET /pet` → 200 con los datos de los dueños. Después de la corrección: 403 (pruebas H-pet y H-contact).
- **Impacto:** fuga y alteración de datos personales de personas ajenas a la plataforma.
- **Remediación (aplicada):** `restrictToAdmin` en ambos routers. Las pantallas solo existen en el panel de admin.
- **Referencias:** OWASP A01:2021; CWE-285.

### H-04 — Dependencias con vulnerabilidades públicas

- **Severidad:**
  - Alto (antes Crítico): `mongoose` 8.4.4 tenía avisos críticos de inyección NoSQL (`sanitizeFilter` no aplicado) y `proxy-addr` (vía express) tenía suplantación de IP.
  - Medio pendiente: `nodemailer` (alta, requiere versión mayor).
  - Frontend: `@angular/router`, `browserslist` y `zod`, con severidad alta.
- **Remediación:**
  - Aplicado `npm audit fix` sin cambios mayores (mongoose 8.24.9): backend de 2 críticas y 6 altas a 0 críticas y 1 alta.
  - Pendiente: subir `nodemailer` a 10.x y actualizar las dependencias del frontend, cada una en su propia rama con pruebas.
- **Referencias:** OWASP A06:2021.

### H-05 — La Coordinación podía crear vinculaciones nuevas para expedientes inactivos

- **Severidad:** Medio. Rompe la regla de negocio (el inactivo «recibía actividad nueva»). Requiere una cuenta admin.
- **Ubicación:** `POST /accreditation` (rama admin con `studentRef`/`volunteerRef`).
- **Evidencia:** antes respondía 500 solo por casualidad (falla de validación), no por una regla. Ahora responde 403 explícito. La validación de lo ya vinculado sigue permitida (pruebas A1–A3).
- **Remediación (aplicada):** se exige `accountStatus === "active"` en el destinatario de una vinculación nueva.
- **Referencias:** OWASP A04:2021.

### H-06 — Reclamo de expedientes sin dueño con un correo no verificado (riesgo residual de H-01)

- **Severidad:** Medio. Un expediente creado por la Coordinación que todavía no tiene cuenta puede reclamarlo quien se registre primero con ese correo.
- **Ubicación:** `POST /auth/register` y `utils/linked-profile.js`.
- **Remediación (pendiente):**
  - Verificar el correo (enlace o código de un solo uso) antes del primer reclamo.
  - Retirar `/auth/register`: el onboarding usa `/auth/signup-*`.
- **Referencias:** OWASP A07:2021; CWE-287.

### H-07 — Login sin límite de intentos por cuenta o IP

- **Severidad:** Medio. Turnstile frena bots, pero no a una persona con un captcha resuelto ni ataques distribuidos.
- **Ubicación:** `POST /auth/login`.
- **Remediación (pendiente):** limitador por IP y por correo (por ejemplo, 10 intentos en 15 min) con respuesta genérica; registrar los intentos fallidos (A09).
- **Referencias:** OWASP A07:2021; CWE-307.

### H-08 — Las cuentas inactivas no podían consultar lo que tenían vinculado

- **Severidad:** Bajo (disponibilidad y regla de negocio, no confidencialidad).
- **Ubicación:** `requireActiveAccount` en `/activity` y `/accreditation`.
- **Remediación (aplicada):** `requireActiveOrReadOnly` (solo GET para `inactive`) y acotamiento por `req.readOnlyScope` en lista, detalle y huella de cambios. La huella acotada impide que un inactivo se entere de que se publicó algo nuevo.

### H-09 — JWT de 7 días en `localStorage`, sin revocación

- **Severidad:** Bajo. Un XSS podría robarlo. Lo mitigan la CSP con nonce por petición y que el estado del expediente se revisa en cada petición (desactivar corta el acceso).
- **Remediación (pendiente):** acortar la vigencia (por ejemplo, 24 h con renovación) o migrar a cookie `HttpOnly; Secure; SameSite=Strict`.
- **Referencias:** OWASP A07:2021.

### H-10 — CORS refleja cualquier origen fuera de `NODE_ENV=production`

- **Severidad:** Bajo. La autenticación usa encabezado Bearer, no cookies, así que no se puede explotar directamente.
- **Remediación (pendiente):** confirmar `NODE_ENV=production` en los servicios desplegados y no reflejar orígenes desconocidos en ningún entorno.
- **Referencias:** OWASP A05:2021.

### H-11 — Generación automática de acreditación por placa para estudiantes no activos

- **Severidad:** Bajo. La dispara solo el admin y deriva de un trámite ya vinculado; se documenta para decidir la regla.
- **Ubicación:** `PATCH /identification/:id/status` → `Accreditation.create`.
- **Remediación (pendiente, decisión de negocio):** omitirla si el estudiante no está activo, o mantenerla por ser un trámite previo.

## Categorías sin hallazgos

- **A03 Inyección:** `express-mongo-sanitize` está activo y las expresiones regulares con datos del usuario están escapadas. No hay `$where`.
- **A10 SSRF:** el único `fetch` saliente (bucket) toma el host de la configuración y codifica la clave.
- **A02:** contraseñas con hash, HTTPS en Railway y certificados con HMAC.

## Fase 6 — Reprueba

- Prueba permanente: `backend/tests/inactive-readonly-security.test.js` (24 aserciones: inactivos, admin, pruebas de concepto y regresiones).
- Suites existentes que siguen pasando:
  - `convocatoria-op` (17).
  - `notifications-digest` (4).
  - `e2e_security_guard` (191).
  - `security-h01-h08`, `security-concurrency-tokens`, `status-history`, `talk-certificates`, `publish-data-endpoints`, `dehydration-rehydration`, `lifecycle-seeder`, `backup-dynamic-registry`.

Pendiente para cerrar el encargo: promover a producción con autorización, y volver a probar H-01 a H-03 contra producción solo con cuentas de prueba autorizadas.
