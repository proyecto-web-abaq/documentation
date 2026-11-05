# Arquitectura de Seguridad Perimetral: Cloudflare Turnstile y WAF

**Documento Técnico:** SEC-2026-CF01
**Sistema:** Plataforma Integral ABAQ Querétaro
**Módulo:** Seguridad Perimetral, Mitigación de Bots y Protección de Autenticación
**Estado:** Propuesta Técnica y Guía de Despliegue — actualizado 2026-11-03
**Dominio objetivo:** `hypercoreqro.lat`

---

## 1. Contexto y Justificación

El inicio de sesión (`/auth/login`) y el alta de aspirantes (`/auth/signup`,
servicio social y voluntariado) son los puntos públicos más expuestos de ABAQ:
ahí un bot puede crear cuentas falsas, probar contraseñas y saturar MongoDB.

Se adoptan **dos capas** de defensa, en **dos etapas**:

1. **Turnstile (ahora, en desarrollo):** verificación humana en el navegador
   antes de que el backend procese login/signup. Bajo esfuerzo, no requiere
   tocar DNS.
2. **WAF + Proxy Cloudflare (al final, antes de producción):** oculta la IP de
   origen, aplica rate-limiting y mitiga DDoS. Requiere delegar DNS a Cloudflare.

> **Las dos capas no son redundantes.** El login identifica *quién* entra;
> Turnstile frena *bots*; el WAF filtra *tráfico malo* en el borde. Son planos
> distintos.

---

## 2. Etapa 1 — Cloudflare Turnstile (implementación actual)

Turnstile verifica autenticidad humana con desafíos criptográficos no
invasivos y entrega un token efímero que el backend valida con `siteverify`.

### 2.1. Datos del widget
- **Site key (pública, frontend):** `0x4AAAAAAFyFdIMaykCWh0xG`
- **Secret key (privada, backend):** vive en `backend/.env` como
  `TURNSTILE_SECRET` (nunca en el repo; `.env` está en `.gitignore`).
- **Dominios registrados en el widget:** `localhost`, `127.0.0.1` y
  `hypercoreqro.lat`.

### 2.2. Superficies protegidas
Contrato **"gate, don't replace"**: el widget se añade a la pantalla y el
backend valida el token ANTES de su lógica actual, que no se modifica.

| Superficie | Ruta frontend | Acción | Handler backend |
| --- | --- | --- | --- |
| Inicio de sesión | `/auth/login` | `login` | `POST /auth/login` |
| Registro | `/auth/signup` | `signup` | `POST /auth/signup` (y `signup-student`/`signup-volunteer`) |

### 2.3. Flujo operativo
1. El usuario abre `/auth/login` o `/auth/signup`; el widget de Turnstile evalúa
   heurísticas y entrega un token `cf-turnstile-response`.
2. El frontend Angular adjunta el token en el cuerpo del `POST`.
3. El backend Node/Express valida el token contra
   `https://challenges.cloudflare.com/turnstile/v0/siteverify` con
   `TURNSTILE_SECRET`, exigiendo `success === true`, la acción esperada y un
   hostname aprobado (`TURNSTILE_HOSTNAMES`).
4. Si el token es inválido o de bot, responde `403` sin consultar MongoDB.
5. Si es válido, corre el handler de login/signup sin cambios.

> El `siteverify` SIEMPRE es servidor-a-servidor: navegador → backend ABAQ →
> Cloudflare. El navegador nunca llama a `siteverify`.

### 2.4. Variables de entorno (backend)
| Variable | Uso |
| --- | --- |
| `TURNSTILE_SECRET` | Secret key del widget; valida el token en `siteverify`. |
| `TURNSTILE_HOSTNAMES` | Hostnames de frontend permitidos. En dev: `localhost,127.0.0.1`. En producción: `hypercoreqro.lat` (sin localhost). |

La site key es pública y puede ir en el `environment` del frontend.

### 2.5. Entorno de pruebas (desarrollo)
El widget acepta `localhost`/`127.0.0.1`, por lo que se prueba end-to-end en
`http://localhost:4200` (frontend) contra `http://localhost:3000` (backend). La
validación real exige: un token real exitoso aceptado una vez y su reintento
(replay) rechazado.

---

## 3. Etapa 2 — WAF y Proxy Cloudflare (diferido a producción)

Se implementa **al final**, cuando `hypercoreqro.lat` apunte a un servidor de
producción. No se hace en desarrollo porque requiere delegar DNS.

### 3.1. Proxy inverso y ocultamiento de origen
- Todo el tráfico a `hypercoreqro.lat` pasa por el Edge de Cloudflare (nube
  naranja) antes de tocar el origen.
- El origen solo acepta rangos IP de Cloudflare.
- TLS Full (Strict) con certificado de origen de Cloudflare.

### 3.2. DNS
1. Delegar nameservers del registrador a los de Cloudflare.
2. Registros `A` (`@`, `api`) y `CNAME` (`www`) en modo **Proxied**.

### 3.3. Rate limiting (WAF)
- **Login:** máx. 5 `POST /auth/login` por IP cada 2 min.
- **Signup:** máx. 3 `POST /auth/signup*` por IP cada 5 min.
- **Bot Fight Mode** activo.

### 3.4. Express tras el proxy
```javascript
app.set('trust proxy', true); // leer IP real vía cf-connecting-ip
```

---

## 4. Orden de implementación

1. **[en curso]** Turnstile en `/auth/login` y `/auth/signup` (dev).
2. Pruebas end-to-end en localhost (token válido aceptado, replay rechazado).
3. Despliegue a producción con dominio `hypercoreqro.lat`.
4. **[al final]** WAF + proxy + rate limiting en Cloudflare.
