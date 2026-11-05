# Registro de implementación — Módulos de ciclo de vida, folios, deshidratación y notificaciones (M5)

Este documento registra **lo que quedó implementado en código** para el spec
`orden-de-trabajo-tcnica-frontend` (los 8 módulos del ciclo de vida de
colaboradores). Es un registro de estado técnico, no de diseño; el diseño vive
en `ciclo-vida-voluntarios-deshidratacion-design.md`, `srs.md`,
`auth-design.md` y `notificaciones-design.md`.

Fecha: 2026-11-03. Ramas: `dev` en los repos `backend` y `frontend`.

## Backend (`backend/`, rama `dev`, commit `c81955f`)

### Modelos (`models/student.model.js`, `volunteer.model.js`)
Campos nuevos en ambos esquemas: `primerIngresoRealizado` (Boolean),
`fechaDesactivacion`, `lastLogin`, `fechaUltimaAcreditacion`,
`fechaInscripcionActividad` (Date), `inactivityStage`
(enum `null|'day45'|'day60'`) y `statusHistory[]`
(`fromStatus, toStatus, reason, comments, changedByEmail, date`).
Los hooks de folio institucional (`SS-`/`VG-`) y el enum `accountStatus`
quedaron intactos.

### Ciclo de vida y estado
- `utils/status-history.js` → `applyStatusChange(user, {toStatus, reason, comments, changedBy})`:
  único punto que escribe en `statusHistory`; valida `toStatus`.
- `services/inactivity.service.js` → `computeLastActivity(user)` y
  `sweepInactiveUsers(...)`: barrido que a los ≥45 días alerta (`day45`) y a
  los ≥60 días inactiva (`day60`, fija `fechaDesactivacion`).
- `app.js`: cron diario (`node-cron`, `0 3 * * *`) que ejecuta el barrido.
- `controllers/accreditation.controller.js`: al aprobar y alcanzar ≥480 h el
  estudiante se inactiva y se envía `sendCompletionEmail`.
- `middlewares/inactive.middleware.js`: responde `403` a escrituras
  (POST/PUT/PATCH/DELETE) de cuentas `inactive`.

### Notificaciones (`utils/email.js` + `utils/notifications.js`) — Resend

> **Actualización 2026-11-03:** el envío migró de **nodemailer/Gmail** a la
> **API de Resend** (se portó el `utils/email.js` de la rama `dev-rivers`).

- `utils/email.js`: envía por HTTPS a `https://api.resend.com/emails` leyendo la
  API key de `process.env.resend` (o `RESEND_API_KEY`). Remitente por defecto
  `ABAQ Querétaro <notificaciones@hypercoreqro.lat>`, derivado de `EMAIL_FROM`.
  Incluye fallbacks: si el dominio no está verificado reintenta desde
  `onboarding@resend.dev`, y si la cuenta está en modo pruebas redirige al
  correo propietario de la cuenta Resend. Trae 5 plantillas **HTML**:
  `sendAcceptanceEmail`, `sendInactivityWarningEmail` (day30/day45/day60),
  `sendCompletionEmail` y `sendNewUserRegistrationAdminEmail`.
- `utils/notifications.js`: capa adaptadora. Los llamadores
  (`accreditation.controller`, `inactivity.service`, `app.js`) siguen invocando
  `(user)` / `(user, stage)`; el adaptador mapea a la firma de objeto de
  `email.js`, resuelve tipo (SS/VG) por folio/rol, arma los **links firmados**
  de certificado (`createCertificateHashToken`) para acceptance/completion, y
  expone `sendNewUserRegistrationAdminEmail` (destino `ADMIN_EMAIL`/`EMAIL_FROM`).
- Reglas: destino = solo el colaborador, salvo el aviso a administración de
  nuevo registro. La baja por inactividad/sanción no emite `completion`.
- **Variables de entorno**: `resend` (API key `re_...`), `EMAIL_FROM`
  (remitente del dominio), opcional `ADMIN_EMAIL`, `BASE_URL` (para los links de
  certificado) y `FRONTEND_URL`.
- **Verificado en vivo (2026-11-03)**: 4 correos enviados por Resend con id de
  confirmación (acceptance, inactividad day60, completion al colaborador; aviso
  de nuevo registro a administración).
- **Pendiente**: `sendNewUserRegistrationAdminEmail` existe pero aún no está
  enganchado al flujo de registro en `auth.controller` (no se dispara solo al
  registrarse un usuario).

### Deshidratación por fases (`services/dehydration.service.js`, módulo 4)
`signPurgeToken`/`verifyPurgeToken` (HMAC-SHA256, TTL 15 min, fallback a
`JWT_SECRET`), `packageDehydration` (ZIP + manifest + SHA-256), `executePurge`
(borrado + `DehydrationAuditLog`) y `rehydrate` (`replaceOne` upsert).
`buildPurgePlan` (corte indivisible, Opción A) se conservó.
Rutas admin (`backup.controller.js` + `backup.route.js`):
`POST /backup/dehydrate/{analyze,download,purge,restore}`.
`analyze` no ejecuta nada (solo previsualiza).

### Visibilidad e historial (módulo 3)
`student.controller.js` / `volunteer.controller.js`: el listado principal
excluye inactivos de ≥365 días y ordena los inactivos recientes al final.
Rutas: `GET /volunteer/history/{students,volunteers,audit}` (Aggregation
Pipeline; estudiantes con horas, voluntarios sin horas, audit = una fila por
transición de `statusHistory`).

> Nota de ruta: el router de voluntarios se monta en `/volunteer` (singular) en
> `app.js`, por lo que las rutas de historial responden en
> `/volunteer/history/...`. El frontend consume esa ruta singular.

### Primer ingreso (módulo 1)
`PATCH /student/:id/primer-ingreso` y `PATCH /volunteer/:id/primer-ingreso`
(`markPrimerIngreso`) fijan `primerIngresoRealizado=true`.
`auth.controller.js` → `buildUserData` ahora hidrata `primerIngresoRealizado`
(admin = true) para que el guard del frontend lo evalúe.

### Scripts de datos
- `scripts/backfill-m5-lifecycle-fields.js`: inicializa los campos nuevos en
  los documentos existentes (idempotente, `--dry`). Ejecutado en la base real
  (14 estudiantes + 8 voluntarios).
- `scripts/seed-history-demo.js`: datos de QA para el historial (`--undo` revierte).

## Frontend (`frontend/`, rama `dev`, commit `26276d5`)

### Base de folios (módulos 6/7)
- Interfaces (`interfaces/student.interfaces.ts`, `volunteer.interfaces.ts`):
  `AssignedActivity` gana `interactionFolio`/`interactionType`; nuevo
  `EmbeddedAccreditation`; `StatusHistoryEntry`.
- Mappers: pueblan `interactionFolio`/`interactionType`/`categoryCode`.
- `styles.scss`: clases de folio (`.folio-pill-ac/op`, `.btn-copy-folio`, etc.).
- `services/folio.service.ts` (`copyFolio`) y
  `components/ui/folio-pill/` (píldora reutilizable con botón copiar).

### Vistas con folio
`my-accreditations`, `student-profile`, `volunteer-profile` (sin horas),
`onboarding/expediente`, `accreditation-list`, `student-detail`,
`volunteer-detail` (sin horas), `activity-list`, `activity-detail`,
`talk-detail`. El voluntario general nunca muestra horas curriculares.

### Vistas y componentes nuevos / modificados
- `components/volunteers-history/`: vista `/volunteers/history` con 3 pestañas.
- `components/backup/`: tarjeta de corte y deshidratación (análisis bajo demanda;
  «Borrar registros» habilitado solo tras recibir `purgeToken`).
- Guard de primer ingreso (`guards/auth.guard.ts`) + botón en
  `onboarding/expediente-recibido` que llama al PATCH antes de navegar.

### Mejoras de UI (sesión de ajustes)
- `/student`: pestañas Servicio Social / Voluntariado General.
- `student-detail`: pestañas Acreditaciones / Actividades / Todas
  (esta última, tabla unificada en un contenedor).
- `activity-detail`: `participant-row` rediseñado (cabecera arriba; asistencia y
  acreditación en fila a ancho completo), responsive móvil/tablet.
- `talk-list` y `campaign-list`: ancho ampliado y grid responsive.
- Fix: `activity-list` en vista admin mostraba vacío por un gate
  (`isVolunteerStatusLoaded`) que no se liberaba para admin.
- Fix: quitado el badge de folio duplicado del header de `student-detail` y
  `volunteer-detail`; retirada la columna de folio de la tabla `/student`.

## Verificación realizada
- Backend: carga del grafo de módulos (`node -e require`) y `npx eslint .` sin
  errores. Endpoints probados por curl con usuarios reales (login hidrata
  `primerIngresoRealizado`; history, dehydrate/analyze y ambos primer-ingreso
  responden 200).
- Frontend: `npx ng build --configuration development` con exit 0, sin errores
  ni warnings de template.
- Visual: revisado por el usuario en navegador (Actividades, pestañas,
  participantes, pláticas/campañas).

## Seguridad perimetral — Cloudflare (2026-11-03)

Detalle completo en `cloudflare-waf-turnstile-proposal.md`. Resumen:

- **Turnstile (en curso, desarrollo):** anti-bot en `/auth/login` y
  `/auth/signup`. Site key pública `0x4AAAAAAFyFdIMaykCWh0xG`; secret en
  `backend/.env` como `TURNSTILE_SECRET` (+ `TURNSTILE_HOSTNAMES`). Contrato
  "gate, don't replace": el backend valida el token con `siteverify`
  (`success`, acción, hostname) antes del handler, sin cambiar su lógica.
  Dominios del widget: `localhost`, `127.0.0.1`, `hypercoreqro.lat`.
- **WAF + proxy Cloudflare (diferido a producción):** oculta IP de origen,
  rate-limiting (login 5/2min, signup 3/5min) y Bot Fight Mode. Requiere delegar
  DNS; se hace al final, no en desarrollo.
- `.env.example` actualizado: sincronizado con `.env` (APP_NAME, resend,
  EMAIL_FROM/ADMIN_EMAIL de Resend) + nuevas `TURNSTILE_SECRET`,
  `TURNSTILE_HOSTNAMES`, `BASE_URL`, `FRONTEND_URL`.

## Pendientes conocidos
- `npm run test:backup` requiere credenciales de Atlas válidas en el entorno.
- Submódulo `subprojects/tool-constancias`: no se incluyó en los commits (sin
  cambios intencionales en este trabajo).
- Turnstile: pegar el `TURNSTILE_SECRET` real en `backend/.env` antes de probar.
