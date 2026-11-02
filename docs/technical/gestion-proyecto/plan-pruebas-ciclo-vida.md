# Plan de Pruebas: Ciclo de Vida, Inactivación y Deshidratación de Usuarios

**Proyecto:** Plataforma Web ABAQ (Servicio Social y Voluntariado General)  
**Versión:** 1.0.0  
**Fecha:** 2026-11-01  
**Estado:** Documento de Especificación de Pruebas (Listo para ejecución por agente de desarrollo)  
**Relacionado:** [SRS Requisitos](../srs.md) · [Arquitectura](../architecture.md) · [Tareas](../tasks.md) · [Diseño Integral de Ciclo de Vida y Deshidratación](../ciclo-vida-voluntarios-deshidratacion-design.md)

---

## 1. Visión General del Plan de Pruebas

El presente documento define la estrategia, matriz de casos de prueba y procedimientos de verificación automatizados para la implementación del **Módulo de Ciclo de Vida, Inactivación Automática y Deshidratación de Base de Datos** de la plataforma ABAQ.

El plan cubre pruebas unitarias de esquemas y lógica de negocio, pruebas de integración de endpoints HTTP Express y MongoDB, y pruebas end-to-end de navegación en el cliente Angular.

---

## 2. Matriz de Pruebas de Backend (Integración y Dominio)

| ID de Caso | Requerimiento SRS | Componente Bajo Prueba | Precondiciones | Estímulo / Acción | Resultado Esperado | Criterio de Éxito |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-BACK-01** | `RF-STATE-04` | `auth.controller.js` | Existe usuario con email `aspirante@test.com` y `accountStatus: 'rejected'`. | Petición `POST /auth/signup` con el mismo email, nuevos datos y nueva clave. | Reutiliza el `_id` original, actualiza `passwordHash`, cambia `accountStatus` a `'pending'`, añade entrada en `statusHistory` con motivo `'re_registration'`. | Documento único en Mongo con `accountStatus: 'pending'`. Código HTTP 201/200. |
| **TC-BACK-02** | `RF-STATE-03` | `auth.controller.js`, `student.controller.js` | Usuario con `accountStatus: 'active'` y `primerIngresoRealizado: false`. | Petición `PATCH /auth/primer-ingreso` tras pulsar el botón en expediente. | Actualiza en BD `primerIngresoRealizado = true`. | Respuesta 200 `{ status: 'success', primerIngresoRealizado: true }`. |
| **TC-BACK-03** | `RF-AUTO-01` | `accreditation.controller.js` | Estudiante activo con 460 hrs acumuladas. | Admin aprueba acreditación de 20 hrs (`PATCH /accreditations/:id/approve`). | Total horas = 480. Transición inmediata: `accountStatus = 'inactive'`, asigna `fechaDesactivacion`, genera URL de certificado y despacha email Resend. | `accountStatus === 'inactive'`, constancia emitida, `hours_completed` en bitácora. |
| **TC-BACK-04** | `RF-AUTO-02` | `scheduler.service.js` (Cron Diario) | Usuario activo con `Date.now() - ultimaActividad == 45` días. | Se dispara el cron diario de escaneo de inactividad. | Detecta umbral de 45 días y ejecuta `sendInactivityWarningEmail(stage='day45')`. `accountStatus` se mantiene en `'active'`. | Correo transaccional enviado con alerta de 15 días restantes. |
| **TC-BACK-05** | `RF-AUTO-02` | `scheduler.service.js` (Cron Diario) | Usuario activo con `Date.now() - ultimaActividad >= 60` días. | Se dispara el cron diario de escaneo de inactividad. | Detecta umbral de 60 días. Actualiza `accountStatus = 'inactive'`, asigna `fechaDesactivacion`, registra en `statusHistory` (`'inactivity_60_days'`) y envía email de baja. | `accountStatus === 'inactive'`. No se genera certificado de finalización. |
| **TC-BACK-06** | `RF-INACT-01`, `RF-INACT-02` | `activity.controller.js` | Usuario con `accountStatus: 'inactive'` y token JWT válido. | 1. Petición `GET /activities`.<br>2. Petición `POST /activities/:id/enroll`. | 1. Sólo recibe actividades con `createdAt <= fechaDesactivacion`.<br>2. Petición de inscripción rechazada con `403 Forbidden`. | Código HTTP 200 con lista filtrada en consulta; código 403 en mutación. |
| **TC-BACK-07** | `RF-DEHYD-01` | `backup.service.js` | Actividad pasada con 2 inscritos: 1 inactivo $> 1$ año y 1 alumno **activo**. | Solicitud de descarga de corte para deshidratación. | La actividad y sus acreditaciones **NO** se incluyen en el corte ni se eliminan. Se conserva íntegra en la base de datos operativa. | Bloque conservado en BD; cero exclusión parcial ("o se quita todo o no se quita nada"). |
| **TC-BACK-08** | `RF-DEHYD-01`, `RF-DEHYD-02` | `backup.service.js` | Oportunidad pasada donde **todos** los participantes son inactivos $> 1$ año. | Solicitud de descarga de corte para deshidratación (`GET /backup/dehydrate/download`). | El paquete ZIP incluye todos los modelos asociados (usuarios, acreditaciones, actividades, oportunidades hijas) y entrega `X-Purge-Token`. | Stream ZIP recibido; cabecera `X-Purge-Token` presente con TTL 15 min. |
| **TC-BACK-09** | `RF-PURGE-02` | `backup.controller.js` | Paquete descargado en TC-BACK-08. Token emitido. | 1. `POST /backup/dehydrate/purge` sin token.<br>2. `POST /backup/dehydrate/purge` con token válido. | 1. Falla con `400 Bad Request`.<br>2. Ejecuta borrado atómico de los documentos en MongoDB y registra evento en `DehydrationAuditLog`. | 1. Error 400.<br>2. Documentos eliminados de Mongo; documento creado en `DehydrationAuditLog`. |
| **TC-BACK-10** | `RF-REHYD-01` | `backup.service.js` | Base de datos deshidratada tras TC-BACK-09. | Admin sube el archivo ZIP en `POST /backup/dehydrate/restore`. | Ejecuta `bulkWrite` con `replaceOne` y `upsert: true`. Restaura todos los documentos con sus `_id`s y relaciones originales exactas. | Todos los documentos reinsertados con sus IDs intactos; registro en bitácora de auditoría. |

---

## 3. Matriz de Pruebas de Frontend (Experiencia de Usuario y Guards)

| ID de Caso | Requerimiento SRS | Componente Bajo Prueba | Precondiciones | Estímulo / Acción | Resultado Esperado | Criterio de Éxito |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-FRONT-01** | `RF-STATE-02`, `RF-STATE-03` | `LoginComponent`, `AuthGuard` | Colaborador aceptado por el admin (`primerIngresoRealizado: false`). | Inicia sesión con sus credenciales en `/login`. | Es redirigido automáticamente a `/onboarding/expediente`. Visualiza la tarjeta de aprobación y el botón *"Ingresar a la Plataforma ABAQ"*. | Ruta actual `/onboarding/expediente`. Tarjeta de felicitación visible. |
| **TC-FRONT-02** | `RF-STATE-03` | `AuthGuard` | Colaborador autenticado con `primerIngresoRealizado: false`. | Intenta ingresar directamente escribiendo `http://localhost:4200/activity-list` en la barra del navegador. | `AuthGuard` intercepta la navegación y lo redirige a `/onboarding/expediente`. | Acceso a actividades bloqueado mientras no pulse el botón de primer ingreso. |
| **TC-FRONT-03** | `RF-STATE-03` | `ExpedienteRecibidoComponent` | Pantalla de expediente con cuenta aprobada. | Pulsa el botón *"Ingresar a la Plataforma ABAQ"*. | Emite petición al backend, actualiza `primerIngresoRealizado: true` y navega a `/activity-list`. En logins subsecuentes entra directo a actividades. | Navegación exitosa a `/activity-list`. Login posterior no pasa por expediente. |
| **TC-FRONT-04** | `RF-VIS-01`, `RF-VIS-02` | `StudentComponent` | Existen colaboradores: 2 activos, 1 inactivo $< 12$ meses y 1 inactivo $\ge 12$ meses. | Admin ingresa a la tabla de voluntarios (`/student`). | El inactivo $< 12$ meses aparece al final con fila gris (`.row-inactive`). El inactivo $\ge 12$ meses no aparece en esta tabla. | Fila gris `#f1f5f9` renderizada; conteo de tabla excluye al inactivo $> 1$ año. |
| **TC-FRONT-05** | `RF-VIS-03` | `PastVolunteersComponent` | Existen inactivos $\ge 12$ meses en la BD. | Admin hace clic en el botón *"Ver Voluntarios Pasados"* en el header de voluntarios. | Navega a `/volunteers/history`. Muestra 2 pestañas (Estudiantes y Generales) con las columnas resumidas consolidadas. | Ambas tablas renderizan datos correctos (acreditaciones, horas, universidad, contacto). |
| **TC-FRONT-06** | `RF-PURGE-01`, `RF-PURGE-02`, `RF-PURGE-03` | `BackupComponent` | Admin en `/backup`. | 1. Valida la cuadrícula de descargas locales.<br>2. Revisa la tercera tarjeta (Deshidratación & Corte) y su alerta.<br>3. Observa el botón *"2. Purgar registros de la BD"*.<br>4. Selecciona fecha y pulsa *"1. Descargar Corte Limpio (.zip)"*.<br>5. Al terminar la descarga, revisa el botón de purga. | 1. Cuadrícula de 3 columnas renderizada.<br>2. Alerta visual preventiva visible indicando ejecutar fuera de horario por alto consumo de procesamiento/BD.<br>3. El botón de purga está **deshabilitado**.<br>4. Se descarga el archivo ZIP y se recibe `purgeToken`.<br>5. El botón de purga pasa a **habilitado**. | Cuadrícula de 3 tarjetas, aviso de advertencia y bloqueo preventivo verificados; activación de purga solo tras descarga exitosa. |
| **TC-FRONT-07** | `RF-UI-01` | Estilos Globales | Navegar por todas las pantallas clave de admin y voluntario. | Cargar `/admin/home`, `/student`, `/activity`, `/backup`, `/volunteers/history`, `/activity-list`, `/activity-detail`, `/volunteer-profile`. | Cada pantalla presenta el encabezado `.page-hero` / `.admin-hero` con gradiente `#1f2f63` -> `#5ca83a` y tipografía estandarizada. | Cero discrepancia visual en encabezados entre vistas. |
| **TC-FRONT-08** | `RF-STATE-05` | `ExpedienteRecibidoComponent` | Cuentas en estado `accepted` y `rejected` (roles SS y VG). | Cargar vista de expediente para ambos estados. | En `accepted`: Se muestra el mensaje de bienvenida y felicitación de la Coordinación (`comments`). En `rejected`: Se muestra la caja de alerta con las *"Observaciones de la Coordinación: {{comments}}"*. | Comentarios renderizados visiblemente en ambas modalidades y estados. |
| **TC-FRONT-09** | `RF-INACT-03` | `VolunteerProfileComponent`, `StudentDetailComponent`, `VolunteerDetailComponent` | Colaborador con `accountStatus: 'inactive'` y antigüedad $< 12$ meses. | 1. Voluntario entra a su perfil.<br>2. Admin entra al detalle del voluntario. | 1. Voluntario visualiza banner fijo superior permanente debajo del header con estado inactivo, fecha y causal/comentarios.<br>2. Admin visualiza tarjeta superior informativa con el comentario del cese, responsable (`changedByEmail`), fecha y causal. | Banner visible permanentemente cerca del header en vista voluntario y vista admin. |

---

## 4. Procedimiento de Ejecución Automatizada para el Agente de Desarrollo

El agente de código debe crear y ejecutar la suite de pruebas unitarias y de integración en:
`backend/tests/user_lifecycle_dehydration.test.js`

### Comando de Ejecución Backend:
```bash
node backend/tests/user_lifecycle_dehydration.test.js
```

### Comando de Verificación de Compilación Frontend:
```bash
cd frontend && npx ng build --configuration development
```

### Criterio de Aceptación Global:
- **100% de casos de prueba pasando (Exit code 0).**
- **Cero regresiones en `node --check` del backend.**
- **Cero errores de tipado o compilación en Angular (`ng build`).**
