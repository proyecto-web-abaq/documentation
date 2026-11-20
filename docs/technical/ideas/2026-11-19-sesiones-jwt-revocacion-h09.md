---
title: "Sesiones Seguras y Revocación de JWT, Hallazgo H-09 (2026-11-19)"
date: 2026-11-19
icon: lucide/circle-x
author: Equipo de Arquitectura e Ingeniería ABAQ
status: Propuesta Técnica Pendiente
---

# 🔑 Sesiones Seguras y Revocación de JWT: Cierre del Hallazgo H-09

**Fecha:** 19 de noviembre de 2026  
**Origen:** Hallazgo **H-09** del informe de auditoría de seguridad del 16 de noviembre de 2026 («JWT de 7 días en `localStorage`, sin revocación»).  
**Alcance:** Backend (emisión y verificación de tokens, cierre de sesión, cambio de contraseña, desactivación de cuentas) y frontend (almacenamiento del token, interceptor HTTP, guardas de ruta).

---

## 1. Resumen Ejecutivo y Declaración del Problema

La rama `security/audit-h11` atiende los hallazgos H-01 a H-11, pero H-09 solo queda **parcialmente** resuelto: endurece la configuración del JWT (secreto de al menos 32 bytes y formato validado de `JWT_EXPIRES_IN`), pero el token sigue guardándose en `localStorage`, dura 7 días y **no puede revocarse**. Esta propuesta documenta lo que falta para cerrarlo.

### 1.1 Estado actual

| Aspecto | Comportamiento actual | Ubicación |
|---|---|---|
| Emisión | `signToken(userId)` firma `{ id }` con `JWT_SECRET`, vigencia `JWT_EXPIRES_IN` (por omisión `7d`). | `backend/utils/jwt.js` |
| Almacenamiento | El frontend guarda el token en `localStorage`. | `frontend/src/app/services/token.service.ts` |
| Envío | Cabecera `Authorization: Bearer <token>` en cada petición. | `frontend/src/app/interceptors/auth.interceptor.ts` |
| Verificación | El middleware valida la firma y que el usuario exista; **no** revisa cuándo se emitió el token ni una versión de sesión. | `backend/middlewares/auth.middleware.js` |
| Cierre de sesión | Solo borra el token del navegador; el token sigue siendo válido hasta que expira. | `frontend/src/app/services/auth.service.ts` (`logout`) |

### 1.2 Riesgos

- **Robo de token por XSS:** cualquier script que se ejecute en el origen del frontend puede leer `localStorage` y usar el token desde otro equipo durante 7 días.
- **Sin revocación:** cerrar sesión, cambiar la contraseña, desactivar o rechazar una cuenta no invalida los tokens ya emitidos.
- **Ventana amplia:** un token filtrado da acceso completo por toda su vigencia, incluidas las acciones de la Coordinación si pertenece a un administrador.

---

## 2. Objetivos

1. Que el token **no sea legible desde JavaScript**.
2. Que una sesión pueda **revocarse** de inmediato (cierre de sesión, cambio de contraseña, desactivación o decisión de la Coordinación).
3. Reducir la vigencia del token de acceso sin obligar a iniciar sesión con frecuencia.
4. Mantener compatibilidad con el despliegue actual (frontend y backend en dominios distintos de Railway).

---

## 3. Opciones Evaluadas

| Opción | Descripción | Ventajas | Desventajas |
|---|---|---|---|
| **A. Versión de sesión en el usuario** | Campo `tokenVersion` en `User`; el JWT incluye `v`; el middleware rechaza tokens con versión distinta. Cerrar sesión en todos los dispositivos, cambiar contraseña o desactivar incrementa la versión. | Revocación inmediata con una sola lectura que el middleware ya hace (`User.findById`). Sin cambios en el frontend. | El token sigue en `localStorage` (no mitiga XSS). |
| **B. Cookie `httpOnly`** | El backend entrega el token en una cookie `httpOnly; Secure; SameSite`; el frontend deja de manejarlo. | El token no es legible desde JavaScript. | Requiere CORS con credenciales, protección CSRF y que frontend y backend compartan dominio registrable (`miportal.abaq.site` / `api.miportal.abaq.site`) para usar `SameSite=Lax`. |
| **C. Token de acceso corto + token de renovación** | Acceso de 15 min en memoria; renovación de larga duración en cookie `httpOnly`, rotada en cada uso y registrada en BD. | Ventana de exposición mínima; revocación por sesión. | Mayor complejidad: colección de sesiones, rotación y detección de reutilización. |

### 3.1 Recomendación

Implementar en **dos etapas**:

1. **Etapa 1 (inmediata): opción A.** Cierra la parte de revocación de H-09 sin tocar el frontend ni los dominios.
2. **Etapa 2: opción C**, una vez que producción use el dominio final (`miportal.abaq.site` y `api.miportal.abaq.site`, ver la issue de IaC y dominios). Con dominio compartido, la cookie de renovación puede ser `SameSite=Lax` y se elimina el token de `localStorage`.

---

## 4. Diseño de la Etapa 1: Versión de Sesión

### 4.1 Backend

- `User.tokenVersion: { type: Number, default: 0 }`.
- `signToken(user)` firma `{ id, v: user.tokenVersion }`.
- En `auth.middleware.js`, tras `User.findById(decoded.id)`: si `decoded.v !== user.tokenVersion`, responder `401` con el mensaje «Tu sesión expiró. Inicia sesión de nuevo.».
- Incrementar `tokenVersion` (`$inc`) en:
  - `POST /auth/logout-all` (nuevo): cerrar sesión en todos los dispositivos.
  - Cambio y restablecimiento de contraseña.
  - Transiciones de cuenta a `inactive`, `rejected` o eliminación, y cambio de rol.
- Reducir `JWT_EXPIRES_IN` a `1d` en producción.

### 4.2 Frontend

- Ante un `401` con sesión activa, limpiar el token y llevar al inicio de sesión conservando la ruta de retorno.
- Opción «Cerrar sesión en todos los dispositivos» en el perfil.

### 4.3 Migración

Los tokens vigentes no traen `v`. Durante una ventana igual a la vigencia anterior (7 días), tratar la ausencia de `v` como versión `0`; después, rechazarla.

---

## 5. Diseño de la Etapa 2: Renovación con Cookie

- Colección `Session` (`userId`, `hash del token de renovación`, `userAgent`, `ip`, `createdAt`, `expiresAt`, `revokedAt`).
- `POST /auth/refresh`: valida la cookie, **rota** el token de renovación y emite un acceso de 15 minutos. Si se presenta un token ya rotado, revoca todas las sesiones del usuario (detección de reutilización).
- Cookie `abaq_refresh`: `httpOnly; Secure; SameSite=Lax; Path=/auth/refresh`.
- CORS con `credentials: true` y lista de orígenes permitidos (hallazgo H-10, rama `security/audit-h11`).
- Protección CSRF en `/auth/refresh` mediante verificación de `Origin`.
- El frontend guarda el token de acceso solo en memoria y renueva al recargar la página o al recibir `401`.

---

## 6. Pruebas

- Token con versión antigua → `401` en todas las rutas protegidas.
- Cambio de contraseña, desactivación y `logout-all` invalidan los tokens previos.
- Token sin `v` aceptado dentro de la ventana de migración y rechazado después.
- Etapa 2: rotación, detección de reutilización, cookie ausente o vencida, y origen no permitido.

---

## 7. Plan de Implementación

| Paso | Entregable | Depende de |
|---|---|---|
| 1 | Integrar `security/audit-h11` en `dev-rivers2` (endurecimiento del JWT y CORS) | — |
| 2 | Etapa 1: `tokenVersion`, `logout-all`, invalidación por eventos de cuenta | Paso 1 |
| 3 | Reducir `JWT_EXPIRES_IN` a `1d` en producción | Paso 2 |
| 4 | Dominio final de producción | Issue de IaC y dominios |
| 5 | Etapa 2: renovación con cookie y token de acceso en memoria | Pasos 2 y 4 |

---

## 8. Referencias

- Informe de auditoría de seguridad, 16 de noviembre de 2026 (hallazgos H-09 y H-10).
- Rama `security/audit-h11` del backend.
- [Integración de Turnstile en superficies públicas](./2026-11-06-turnstile-antibot-todas-las-superficies-publicas.md)
- OWASP ASVS v4.0, capítulo 3 (gestión de sesiones).
