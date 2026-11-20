---
title: "Integración de la Auditoría de Seguridad en dev-rivers2 (2026-11-19)"
date: 2026-11-19
icon: lucide/circle-x
author: Equipo de Arquitectura e Ingeniería ABAQ
status: Integración Lista para Revisión
---

# 🔀 Integración de `security/audit-h11` en `dev-rivers2` (Backend)

**Fecha:** 19–20 de noviembre de 2026  
**Repositorio:** `backend`  
**Rama de integración:** `security/audit-h11-integracion` (commit `a6dd1e8`, solo local)  
**Origen:** `security/audit-h11` (commit `36d5867`, «security: complete audit H-01 through H-11», JADAG)  
**Destino:** `dev-rivers2`  
**Revisión:** JADAG y Brandon.

!!! success "Estado"
    La rama de integración contiene **todo** `security/audit-h11` (`git merge-base --is-ancestor` lo confirma). Las 38 suites de pruebas pasan con `mongodb-memory-server`, sin pruebas omitidas, y `eslint` no reporta errores. Falta subir la rama, abrir el PR hacia `dev-rivers2` y configurar las variables nuevas en Railway (sección 5).

!!! info "Cómo leer este documento"
    Para cada tema se muestra el código que **viene** (`security/audit-h11`), el que **tenemos** (`dev-rivers2`) y el que **queda** en la rama de integración, junto con la **evidencia** que justifica la decisión: archivo y línea del frontend o del modelo, prueba automatizada o resultado de ejecución. La regla fue traer todo; solo se ajustó el código entrante donde la evidencia muestra que rompía una función existente.

---

## 1. Punto de partida

| | `dev-rivers2` | `security/audit-h11` |
|---|---|---|
| Base común | `0f1057e` (15 nov) | `0f1057e` (15 nov) |
| Commits desde la base | 31 (incluye notificaciones, folio de convocatoria, re-registro silencioso, OP-EVE, endurecimiento de acciones) | 1 (52 archivos) |
| Conflictos al fusionar | 20 archivos | |

### 1.1 Correcciones a la versión anterior de este documento

Al revisar el código línea por línea, tres afirmaciones de la primera versión resultaron **incorrectas**:

| Afirmación anterior | Realidad en `dev-rivers2` | Evidencia |
|---|---|---|
| «CORS acepta cualquier origen» | Ya tenía lista configurable, pero **abría todo fuera de producción** | `app.js`, bloque `cors()` (commit `10b5fca`) |
| «El middleware enlaza expedientes por correo» | Ya solo **reclamaba expedientes sin dueño**, de forma atómica; nunca reasignaba uno ajeno | `utils/linked-profile.js` (commit `cf3db24`) |
| «Hay que quitar el token en la URL de respaldos» | Ya estaba quitado; la prueba E2E 6 ya exigía 401 | `tests/e2e_backup_api.test.js` |

---

## 2. Cambios adoptados tal cual

Estos temas no chocaban con nada de `dev-rivers2`; se adoptaron sin modificaciones.

| Tema | Qué cambia | Evidencia de que funciona |
|---|---|---|
| Secreto JWT (H-09 parcial) | `JWT_SECRET` ≥ 32 bytes; `JWT_EXPIRES_IN` con formato `Nm/Nh/Nd` y máximo 30 días | `tests/jwt-security.test.js` en verde |
| Secretos independientes | `CERTIFICATE_SECRET`, `RULES_TOKEN_SECRET`, `PURGE_TOKEN_SECRET` (≥ 32 bytes) con `_PREVIOUS` para rotar | `tests/certificate-key-rotation.test.js` en verde |
| Logs sin datos personales | Correos, cuerpos de respuesta y `err.message` fuera de los logs (Resend, bucket, notificaciones) | Revisión de diff |
| Scripts | `db-connection` verifica que la BD conectada sea la solicitada; el resumen de sembrado ya no imprime correo, contraseña ni `_id` | `tests/db-connection-helper.test.js`, `tests/publish-data-endpoints.test.js` (antes fallaba; ahora pasa) |
| Modelos | `Student.fechaFinPeriodoAcademico` (opcional); estado `PENDING`/`COMPLETED` en identificaciones | Campos opcionales, sin migración |
| Regularización de consentimientos al arrancar | Se **elimina** | Ver 2.1 |

### 2.1 Por qué quitar la regularización de consentimientos

Código que **teníamos** en `app.js` (`ensureDataIntegrity`):

```js
// Auto-regularizar consentimientos de usuarios registrados y activos
await Student.updateMany(
  { $or: [{ "consents.privacidad": { $ne: true } }, { consents: { $exists: false } }] },
  { $set: { "consents.privacidad": true, "consents.reglamento": true,
            "consents.etica": true, "consents.consentimiento": true } }
);
```

**Fundamento:** aunque el comentario dice «activos», el filtro no revisa `accountStatus`. En cada arranque marca como aceptados el aviso de privacidad, el reglamento y el código de ética de **todos** los expedientes que no los tengan, incluidos pendientes y rechazados. Eso registra un consentimiento que la persona nunca dio. La rama de seguridad lo elimina y se adopta.

---

## 3. Cambios adoptados con ajuste (y por qué)

### 3.1 CORS (H-10)

=== "Viene"

    ```js
    const allowedOrigins = [
      "http://localhost:8080",
      "https://miabaq.hypercoreqro.lat",
    ];
    // ...
    if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
    const error = new Error("Origin not allowed by CORS");
    error.statusCode = 403;
    return callback(error);
    ```

=== "Teníamos"

    ```js
    const allowedOrigins = [process.env.FRONTEND_URL,
      ...(process.env.ALLOWED_ORIGINS?.split(",") ?? []),
      "http://localhost:4200", /* ... */].filter(Boolean);
    // ...
    if (isConfigured || isLocalhost) return callback(null, true);
    if (process.env.NODE_ENV === "production") return callback(new Error("Not allowed by CORS"));
    callback(null, true); // ← cualquier origen fuera de producción
    ```

=== "Queda"

    ```js
    const allowedOrigins = [
      process.env.FRONTEND_URL,
      ...(process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(",").map((o) => o.trim()) : []),
      "https://miabaq.hypercoreqro.lat",
      "http://localhost:4200",
      "http://localhost:8080",
      "http://127.0.0.1:4200",
    ].filter(Boolean);
    // ...
    if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
    const error = new Error("Origin not allowed by CORS");
    error.statusCode = 403;
    return callback(error);
    ```

**Fundamento:**

- Se adopta la regla de la rama: **rechazar** cualquier origen fuera de la lista en todos los entornos. Lo que teníamos dependía de `NODE_ENV=production`; si esa variable falta en Railway, el backend acepta cualquier origen.
- La lista fija de la rama dejaría sin acceso al frontend de **desarrollo** (proyecto `miabaq-abaq`, otro dominio) y al servidor local de Angular: `frontend/angular.json` no define puerto, así que `ng serve` usa **4200**, no 8080. Por eso se conserva la lista configurable por variables.

### 3.2 Vinculación de expedientes solo por `authId` (H-11)

=== "Viene"

    ```js
    if (user.role === "student") {
      linked = await Student.findOne({ authId: user._id.toString() });
    } else if (user.role === "volunteer") {
      linked = await Volunteer.findOne({ authId: user._id.toString() });
    }
    ```

=== "Teníamos"

    ```js
    const byAuthId = await Model.findOne({ authId });
    if (byAuthId || !user.email) return byAuthId;
    // Reclamo atómico de un expediente SIN dueño cuyo correo coincide
    return Model.findOneAndUpdate({ authId: { $in: [null, ""] }, ...emailMatch },
                                  { $set: { authId } }, { new: true });
    ```

=== "Queda"

    ```js
    // utils/linked-profile.js — usado por protect, /auth/me y /student/auth/:authId
    async function resolveLinkedProfile(user) {
      const Model = user.role === "student" ? Student : user.role === "volunteer" ? Volunteer : null;
      if (!Model) return null;
      return Model.findOne({ authId: user._id.toString() });
    }
    ```

**Fundamento:**

- Se adopta la regla de la rama: el correo **nunca** vincula un expediente. Aunque lo que teníamos ya impedía tomar uno ajeno, quien registrara primero una cuenta con el correo de un expediente creado por la Coordinación se quedaba con ese expediente.
- La regla se aplica en `utils/linked-profile.js`, la única función que ya usaban `protect`, `buildUserData` y `getStudentByAuthId`. Así no queda ninguna otra ruta que vincule por correo; la rama original dejaba esa lógica repetida en tres lugares.

!!! warning "Impacto"
    Un expediente creado por la Coordinación sin cuenta ya **no** se vincula solo cuando su dueño inicia sesión: hay que asignarle `authId`. Antes de desplegar, contar en la BD los expedientes con `authId` vacío.

### 3.3 Listas de campos permitidos (H-02, asignación masiva)

La rama reemplaza la lista de campos prohibidos por **listas de campos permitidos** en el manejador genérico, en actividades, plantillas, estudiantes, voluntarios y registro. Se adoptan todas, y se agregan los campos que la rama omitía y que el sistema sí usa:

| Lista | Campo que faltaba | Evidencia de que se usa |
|---|---|---|
| Actividades (crear y editar) | `eventType` | `models/activity.model.js:65` (`Activity.allowedUpdateFields`); requerido por la acreditación OP-EVE (ADR-36) y la migración `92c3480` |
| Plantillas (`quickActivity`) | `eventType` | `TEMPLATE_FIELDS` en `dev-rivers2` |
| Edición de estudiante | `fechaConclusion`, `curp`, `bioPersonal`, `reporteFinal` | `frontend/src/app/mappers/student.mapper.ts` (`mapFrontendStudentToBackend` envía `fechaConclusion`); `studentProfileRules` valida `curp` |
| Registro (SS y VG) | `signedRulesDocument` | `buildStudentFields` y `buildVolunteerFields` lo usan para marcar `consents.reglamento` |
| Registro (SS y VG) | `fechaInicioFormularioExpediente`, `fechaFinFormularioExpediente`, `fechaEmisionExpediente`, `tiempoLlenadoMinutosExpediente`, `folio` | `onboarding-state.service.ts` los envía; alimentan la analítica de tiempos (Big Data, fase 1); el folio se valida contra `SIGNUP_FOLIO` |
| Registro SS | `horasCubrir`, `fechaConclusion`, `studentId` | `buildStudentFields` y `validateStudentSignupData` (tope de 480 h) |
| Registro VG | `fechaInicioVoluntariado` | `buildVolunteerFields` |

En sentido contrario, se adopta que el registro **ya no acepta** `fechaAceptacionExpediente` ni `fechaExpedicionExpediente`. Antes, quien se registraba podía enviar su propia fecha de aceptación.

El manejador genérico (`controllers/handler.controller.js`) queda así:

```js
// Lista explícita del llamador o Model.allowedUpdateFields. Sin lista se
// rechaza (falla cerrada, H-02); nunca se deriva del esquema completo.
function resolveAllowedFields(Model, allowedFields) {
  const fields = Array.isArray(allowedFields) && allowedFields.length > 0
    ? allowedFields
    : Model?.allowedUpdateFields;
  if (!Array.isArray(fields) || fields.length === 0) return null;
  return fields.filter((f) => !FORBIDDEN_FIELDS.has(f));
}
```

**Fundamento:**

- Lo que teníamos, sin lista, permitía **todos los campos del esquema** (`Model.schema.paths`). La rama falla cerrada (500), y eso se adopta.
- Se conserva `Model.allowedUpdateFields` como fuente, para no repetir en cada controlador la lista que ya vive en el modelo.
- `createActivity` en `dev-rivers2` hacía `Activity.create(body)` con el cuerpo completo; ahora toma solo los campos de `Activity.allowedUpdateFields`.

### 3.4 Acreditaciones

=== "Viene"

    ```js
    if (activityRef) {
      const activity = await Activity.findById(activityRef);
      if (!activity) return next(new AppError("No se encontró la actividad indicada.", 404));
    }
    // ...
    if (req.user.role !== "admin") {   // fuera del bloque donde existe `identification`
      const identificationStudentId = identification.studentRef?.toString();
      // ...
    }
    ```

=== "Queda"

    ```js
    if (identificationRef) {
      const identification = await Identification.findById(identificationRef);
      if (!identification) { /* 404 */ }
      // Un colaborador solo usa identificaciones de su propio expediente
      if (!admin) {
        const identificationStudentId = identification.studentRef?.toString();
        const targetStudentId = targetStudent?._id?.toString();
        if (!targetStudentId || identificationStudentId !== targetStudentId) {
          return next(new AppError("No tienes permiso para utilizar esta identificación.", 403));
        }
      }
    }
    ```

| Pieza de la rama | Decisión | Fundamento |
|---|---|---|
| Propiedad de la identificación | **Adoptada** | `dev-rivers2` no comprobaba que la identificación fuera del propio expediente |
| Horas administrativas solo por la Coordinación (403) | **Adoptada** | Antes se guardaban con 0 h; ahora se rechaza de forma explícita |
| Validación de `activityRef` | **Quitada** | En `dev-rivers2`, `activityRef` no se lee del cuerpo, de forma intencional: las acreditaciones de convocatoria solo nacen de la inscripción (ADR-36). Tras la fusión automática la variable no existía: toda acreditación habría fallado con `ReferenceError` |
| Segunda copia del chequeo de identificación | **Quitada** | La fusión automática la dejó fuera del bloque donde existe `identification`; `eslint` (`no-undef`) lo detectó. Toda acreditación de un colaborador habría fallado |
| Chequeo de dueño en `deletePendingAccreditation` | **Quitado por duplicado** | `ownsAccreditation` ya lo hace consultando la BD; el de la rama dependía de `req.user.linkedDoc` y fallaba en `tests/convocatoria-op.test.js` (prueba 15) |

### 3.5 Rutas

| Ruta | Viene | Teníamos | Queda | Fundamento |
|---|---|---|---|---|
| `GET /student/:id` | Solo admin | Admin o dueño | **Solo admin** | El único llamador en el frontend es la vista de administración (`student-detail.ts:902`); el alumno usa `/student/auth/:authId` |
| `GET /identification`, `GET /identification/:id` | Abiertas a cualquier cuenta activa | Solo admin | **Solo admin** | Se conserva lo más estricto |
| Contactos, mascotas, actividades | `restrictToAdmin` por ruta | `restrictToAdmin` global en el router | Ambas | Equivalentes; no estorban |
| `GET /auth/expediente-status` | **Eliminada** | Activa, con límite de 30 consultas / 15 min | **Eliminada** | Ver 3.6 |

### 3.6 `GET /auth/expediente-status` (eliminada)

Se adopta la eliminación. La ruta permitía consultar, sin sesión, el estatus de un expediente con folio y correo.

!!! warning "Impacto en el frontend (pendiente)"
    `frontend/src/app/components/onboarding/expediente-recibido.component.ts:1515` y `:1525` la siguen llamando.
    
    - **Con sesión:** sin cambio. El componente usa primero `loadMe()`.
    - **Sin sesión:** la llamada responde 404, el `catchError` devuelve `null` y la pantalla no muestra el estatus actualizado. No se rompe, pero esa consulta deja de funcionar.
    
    Hace falta un cambio en el frontend: pedir iniciar sesión para ver el estatus, o quitar la consulta.

---

## 4. Pruebas modificadas

Las cinco pruebas que cambian lo hacen porque el comportamiento cambia **a propósito**, no para ocultar una falla:

| Prueba | Antes esperaba | Ahora espera | Motivo |
|---|---|---|---|
| `security-h01-h08` (prueba 3) | `updateOne(Model)` sin lista acepta campos | Sin lista → 500; con lista, los prohibidos se descartan igual | Falla cerrada (3.3) |
| `lifecycle-cleaner` | El resumen imprime correo y contraseña | No los imprime | Logs sin credenciales (2) |
| `convocatoria-op` (prueba 14) | Horas administrativas de un colaborador → 0 h | → 403 | 3.4 |
| `inactive-readonly-security` R1 | El expediente sin dueño se reclama por correo | No se reclama | H-11 (3.2) |
| `inactive-readonly-security` R2 | El alumno lee su expediente por `/student/:id` | Lo lee por `/student/auth/:authId` | 3.5 |

Además se corrigió el código, no la prueba, en `student-update-authorization`. Un alumno que envía un campo privilegiado (`horasPendientes`) vuelve a recibir **403**. Con la lista de la rama, ese campo se ignoraba en silencio y la respuesta era 200.

**Resultado:** 38/38 suites en verde, ninguna omitida; `eslint .` sin errores.

---

## 5. Pendiente para cerrar

| # | Acción | Responsable |
|---|---|---|
| 1 | Subir `security/audit-h11-integracion` y abrir PR hacia `dev-rivers2` | riosisraelg |
| 2 | Revisión del PR | JADAG y Brandon |
| 3 | Railway (`miabaq-abaq` y después `abaq-dev-app`): `JWT_SECRET` de ≥ 32 bytes, `CERTIFICATE_SECRET`, `RULES_TOKEN_SECRET`, `PURGE_TOKEN_SECRET`, `FRONTEND_URL` / `ALLOWED_ORIGINS`. **Antes** del despliegue: sin ellas fallan el inicio de sesión, las constancias, las reglas firmadas y la purga | riosisraelg |
| 4 | Conservar el `JWT_SECRET` actual durante la transición, para que sigan validando las constancias y los tokens ya emitidos | riosisraelg |
| 5 | Contar expedientes con `authId` vacío y vincularlos (3.2) | Coordinación |
| 6 | Frontend: retirar o reemplazar la consulta pública de estatus (3.6) | Frontend |
| 7 | Cerrar `security/audit-h11` | JADAG |
| 8 | H-09 (sesiones revocables) sigue abierto: ver [Sesiones Seguras y Revocación de JWT](./2026-11-19-sesiones-jwt-revocacion-h09.md) | — |
