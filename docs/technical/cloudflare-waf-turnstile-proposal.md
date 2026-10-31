# Arquitectura de Seguridad Perimetral: Cloudflare Proxy, WAF y Turnstile

**Documento Técnico:** SEC-2026-CF01  
**Sistema:** Plataforma Integral ABAQ Querétaro  
**Módulo:** Seguridad Perimetral, Mitigación de Bots y Protección de Autenticación / Expedientes  
**Estado:** Propuesta Técnica y Guía de Despliegue  

---

## 1. Contexto y Justificación

El registro de aspirantes (onboarding de servicio social y voluntariado) y el acceso a la plataforma institucional ABAQ representan puntos críticos de exposición pública. En una arquitectura estándar sin proxy perimetral, la dirección IP del servidor de producción queda visible en los registros DNS públicos, permitiendo ataques de denegación de servicio (DDoS), escaneo de puertos, ataques de fuerza bruta de credenciales y saturación de la base de datos MongoDB mediante bots automatizados.

Para mitigar estos riesgos de forma transparente y sin fricción de usuario, se diseña una arquitectura basada en **Cloudflare Reverse Proxy**, **WAF con Rate Limiting** y **Cloudflare Turnstile**.

---

## 2. Arquitectura Perimetral

1. **Proxy Inverso Edge (Nube Naranja):** Toda solicitud HTTP/HTTPS dirigida a `abaq.org.mx` o sus subdominios es interceptada por los servidores Edge de Cloudflare antes de tocar la infraestructura de ABAQ.
2. **Ocultamiento de Origen:** La IP del servidor de producción solo acepta tráfico entrante de los rangos de IP autorizados de Cloudflare, neutralizando cualquier intento de conexión directa.
3. **Cifrado Full (Strict):** Cifrado TLS 1.3 de extremo a extremo, utilizando certificados de origen de 15 años de Cloudflare en Nginx/Express.

---

## 3. Integración de Cloudflare Turnstile

Cloudflare Turnstile es una alternativa moderna y ética a CAPTCHA que verifica la autenticidad humana en milisegundos mediante desafíos criptográficos invisibles en el navegador.

### Flujo Operativo:
1. El usuario interactúa con la pantalla de inicio de sesión (`/auth/login`) o con la fase final de registro de expediente (`/onboarding/phase-4`).
2. El widget de Turnstile evalúa heurísticas no invasivas y entrega un token efímero `turnstileToken`.
3. El frontend de Angular adjunta este token en la carga útil de la petición (`POST /auth/login` o `POST /auth/signup-student`).
4. El backend de Node.js/Express valida el token directamente contra el endpoint perimetral `https://challenges.cloudflare.com/turnstile/v0/siteverify` utilizando el `CLOUDFLARE_TURNSTILE_SECRET_KEY`.
5. Si el token no es válido o proviene de un script de bot, el backend responde `403 Forbidden` inmediatamente sin consultar MongoDB.

---

## 4. Guía de Configuración de Dominio y DNS

### 4.1. Delegación de Nameservers
1. Acceder al panel de administración del registrador donde se compró el dominio (ej. GoDaddy, Neubox, Akky, Namecheap).
2. Localizar la sección de **DNS / Servidores de Nombres** y cambiar de los DNS por defecto a los Nameservers provistos por Cloudflare:
   - `ns1.cloudflare.com`
   - `ns2.cloudflare.com`
3. Guardar cambios y aguardar la propagación DNS (5 min a 2 hrs).

### 4.2. Creación de Registros DNS Proxied
En Cloudflare > DNS > Records:
- Registro `A` | Nombre: `@` | Destino: `<IP_ORIGEN_ABAQ>` | Proxy: **Proxied (Naranja)**
- Registro `A` | Nombre: `api` | Destino: `<IP_ORIGEN_ABAQ>` | Proxy: **Proxied (Naranja)**
- Registro `CNAME` | Nombre: `www` | Destino: `abaq.org.mx` | Proxy: **Proxied (Naranja)**

### 4.3. Reglas de Rate Limiting en WAF
- **Login Defense:** Máximo 5 peticiones POST a `/auth/login` por IP en ventana de 2 minutos.
- **Signup Defense:** Máximo 3 peticiones POST a `/auth/signup*` por IP en ventana de 5 minutos.
- **Bot Fight Mode:** Activo para mitigar scrapers y herramientas automáticas de escaneo.

### 4.4. Configuración en Express (`app.js`)
Configurar `trust proxy` para que los controladores y middlewares lean correctamente la IP real mediante `cf-connecting-ip`:
```javascript
app.set('trust proxy', true);
```
