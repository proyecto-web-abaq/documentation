---
title: "Tutorial: Despliegue en Railway (miabaq-abaq / development)"
icon: lucide/cloud-cog
---

# 🚀 Tutorial Paso a Paso: Despliegue en Railway (`miabaq-abaq` / Entorno `development`)

> [!IMPORTANT]
> **Propósito de esta guía:** Este documento es un **tutorial práctico paso a paso** diseñado para que cualquier miembro del equipo pueda reproducir, operar, auditar o recrear desde cero la infraestructura en la nube de **ABAQ Querétaro** en **Railway**, configurar los builders de CI/CD para frontend y backend sobre la rama `dev-rivers2`, sembrar la base de datos con [`seed.sh`](file:///Users/riosisraelg/dev/abaq/seed.sh) y verificar la entrega transaccional de correos con **Resend** en los dominios públicos generados.

---

## 🧭 1. Resumen Ejecutivo de la Infraestructura Creada

Toda la infraestructura está aprovisionada y operativa bajo el proyecto oficial de Railway:

| Componente | Nombre en Railway | Identificador / URL | Configuración Clave |
|---|---|---|---|
| **Proyecto** | `miabaq-abaq` | `c0b511cf-8ba0-4269-8edc-9d080acf9ebc` | Región `sfo` / `sjc` |
| **Entorno** | `development` | `0e00b992-f8b5-41e9-9b42-91c3a6110398` | Aislamiento completo de staging |
| **Base de Datos** | `MongoDB-GZwo` | Privado: `mongodb-gzwo.railway.internal:27017`<br>Público: `trolley.proxy.rlwy.net:58138` | Imagen `ghcr.io/railwayapp-templates/mongo-ha/mongo:8.0`<br>Volumen 5 GB en `/data/db` |
| **Almacén S3** | `miabaq-docs` | `f06bba9e-0165-4386-9507-cdc7e9aa2f03` | S3-compatible, endpoint en `sjc` |
| **Backend API** | `backend` | [`https://backend-development-a4fa8bc3.up.railway.app`](https://backend-development-a4fa8bc3.up.railway.app) | Railpack (Node 22 LTS), Express, Turnstile, Resend |
| **Frontend Web** | `frontend` | [`https://frontend-development-5a6ef4e4.up.railway.app`](https://frontend-development-5a6ef4e4.up.railway.app) | Railpack (Angular 19), Static Web Server puerto 8080 |

```mermaid
flowchart TD
    subgraph Internet ["🌐 Internet Público"]
        User["👤 Usuario / Administrador"]
        EmailUser["📬 Correo Electrónico del Usuario"]
        LocalAdmin["💻 Terminal Local (seed.sh / mongosh)"]
    end

    subgraph Railway ["☁️ Railway Project: miabaq-abaq (Entorno: development)"]
        subgraph Edge ["Railway Edge & Networking"]
            FrontDomain["frontend-development-5a6ef4e4.up.railway.app"]
            BackDomain["backend-development-a4fa8bc3.up.railway.app"]
            TCPProxy["TCP Proxy: trolley.proxy.rlwy.net:58138"]
        end

        subgraph Compute ["Servicios de Cómputo (Railpack)"]
            FrontApp["Frontend Service (Angular 19 / Port 8080)"]
            BackApp["Backend Service (Node 22 LTS / Port 3000)"]
        end

        subgraph Storage ["Almacenamiento Persistente"]
            MongoServ["MongoDB 8.0 (mongodb-volume 5GB en /data/db)"]
            BucketS3["Bucket S3: miabaq-docs (Reglamentos, Evidencias, Fotos)"]
        end
    end

    subgraph External ["Servicios Externos"]
        ResendAPI["✉️ Resend API (notificaciones@hypercoreqro.lat)"]
        TurnstileAPI["🛡️ Cloudflare Turnstile (Anti-Bot)"]
    end

    User -->|HTTPS| FrontDomain --> FrontApp
    FrontApp -->|API REST Calls| BackDomain --> BackApp
    BackApp -->|DNS Privado: mongodb-gzwo.railway.internal:27017| MongoServ
    BackApp -->|AWS SigV4 S3 SDK| BucketS3
    BackApp -->|POST /emails| ResendAPI
    ResendAPI -->|Entrega con Botones al Dominio Frontend| EmailUser
    EmailUser -->|Clic en Botón del Correo| FrontDomain
    BackApp -->|Validación de Tokens| TurnstileAPI
    LocalAdmin -->|Sembrado con seed.sh vía TCP Proxy| TCPProxy --> MongoServ
```

---

## 🛠️ 2. Prerrequisitos y Herramientas

Para administrar y operar este entorno desde tu máquina local necesitas:

1. **Git**: Con acceso al repositorio `proyecto-web-abaq` (`frontend`, `backend`, `documentation`).
2. **Node.js**: Versión `v20.x` o `v22.x` LTS.
3. **Railway CLI**:
   ```bash
   npm i -g @railway/cli
   railway login
   railway whoami
   ```
4. **Permisos de Colaborador:** Acceso al proyecto de Railway `miabaq-abaq` y a la organización en GitHub.

---

## 📦 3. Creación y Configuración del Proyecto en Railway

### 3.1 Creación del Proyecto y Entorno
1. En Railway Dashboard o vía CLI:
   - Crear proyecto: **`miabaq-abaq`**.
   - Crear entorno: **`development`** (Railway crea por defecto `production`; agrega el entorno `development` para aislar las pruebas).
2. Asegurar que la región predeterminada sea **`sfo`** (US West - San Francisco) para mantener latencia ultra-baja entre el backend, la base de datos y el bucket (`sjc`).

---

## 🗄️ 4. Aprovisionamiento de MongoDB y Almacenamiento Persistente

### 4.1 Por qué usar la Imagen de Plantilla de Railway
> [!NOTE]
> Cuando se conecta un volumen ext4 en Railway en `/data/db`, el sistema de archivos crea automáticamente un directorio de rescate `lost+found`. La imagen estándar de Docker Hub (`mongo:8.0`) detecta cualquier archivo existente y cancela la creación del usuario raíz, provocando fallas de autenticación.
> 
> Por esta razón, Railway provee la imagen optimizada **`ghcr.io/railwayapp-templates/mongo-ha/mongo:8.0`**, la cual maneja volúmenes persistentes y credenciales automáticamente.

### 4.2 Despliegue de MongoDB
1. En Railway: desplegar la plantilla oficial **`mongo`** (Template slug: `mongo`).
2. **Volumen:** Se crea un volumen persistente de **5 GB** (`mongodb-volume`) montado en `/data/db`.
3. **Red Interna:** Railway le asigna el nombre privado `mongodb-gzwo.railway.internal` en el puerto `27017`.
4. **Habilitación de TCP Proxy (Acceso Externo):**
   - En el servicio `MongoDB-GZwo` $\rightarrow$ *Settings* $\rightarrow$ *Networking* $\rightarrow$ *TCP Proxy*.
   - Añadir proxy para el puerto `27017`.
   - Railway asigna un endpoint público único (ejemplo: `trolley.proxy.rlwy.net:58138`).

### 4.3 Almacén de Objetos S3 (`miabaq-docs`)
1. En Railway: crear un **Storage Bucket** llamado `miabaq-docs` en la región `sjc`.
2. Tomar nota de las credenciales generadas:
   - `RAILWAY_BUCKET_NAME`
   - `RAILWAY_BUCKET_ENDPOINT`
   - `RAILWAY_BUCKET_ACCESS_KEY_ID`
   - `RAILWAY_BUCKET_SECRET_ACCESS_KEY`
   - `RAILWAY_BUCKET_REGION`

---

## ⚙️ 5. Configuración del Servicio `backend`

### 5.1 Vinculación con GitHub y Rama `dev-rivers2`
- **Repositorio:** `proyecto-web-abaq/backend`.
- **Rama de Despliegue:** **`dev-rivers2`**.
- **Builder:** **`RAILPACK`** (V3). Railpack detecta automáticamente `package.json`, instala dependencias con `npm ci` y ejecuta `npm start` (`node app.js`).

### 5.2 Variables de Entorno del Backend
Configurar las siguientes variables en *Settings $\rightarrow$ Variables*:

| Variable | Valor Configurado | Propósito |
|---|---|---|
| `NODE_ENV` | `development` | Activa logs extendidos y manejo de errores |
| `PORT` | `3000` | Puerto en el que escucha Express |
| `DATABASE` | `mongodb://mongo:<PASSWORD>@mongodb-gzwo.railway.internal:27017/abaqTesting--dev-rivers?authSource=admin` | URI de conexión interna de base de datos |
| `MONGODB_URI` | `mongodb://mongo:<PASSWORD>@mongodb-gzwo.railway.internal:27017/abaqTesting--dev-rivers?authSource=admin` | Alias estándar para Mongoose |
| `MONGO_URL` | `mongodb://mongo:<PASSWORD>@mongodb-gzwo.railway.internal:27017/abaqTesting--dev-rivers?authSource=admin` | Alias de respaldo para scripts internos |
| `JWT_SECRET` | `(Secreto robusto de 64 caracteres)` | Firma de tokens JWT para sesiones |
| `JWT_EXPIRES_IN` | `7d` | Vigencia de tokens |
| `BASE_URL` | `https://backend-development-a4fa8bc3.up.railway.app` | URL pública canónica del Backend API |
| `FRONTEND_URL` | `https://frontend-development-5a6ef4e4.up.railway.app` | **URL canónica para construir enlaces y botones en correos** |
| `EMAIL_FROM` | `notificaciones@hypercoreqro.lat` | Dirección remitente autorizada en Resend |
| `resend` / `RESEND_API_KEY` | `re_DQ1JeLup_...` | Llave API oficial de Resend |
| `ADMIN_EMAIL` | `riosisraelg@icloud.com` | Buzón receptor de alertas y correos ficticios |
| `TURNSTILE_SECRET` | `0x4AAAAAAAZ...` | Clave secreta anti-bot de Cloudflare Turnstile |
| `TURNSTILE_DISABLED` | `false` | Protección anti-bot activa |
| `TURNSTILE_HOSTNAMES` | `frontend-development-5a6ef4e4.up.railway.app,localhost` | Hostnames autorizados para Turnstile |
| `RAILWAY_BUCKET_*` | *(Credenciales del bucket `miabaq-docs`)* | Conexión S3 para PDFs, constancias y fotos |

### 5.3 Dominio Público del Backend
- Generar dominio en *Networking*: `https://backend-development-a4fa8bc3.up.railway.app`.

---

## 🎨 6. Configuración del Servicio `frontend`

### 6.1 Vinculación con GitHub y Rama `dev-rivers2`
- **Repositorio:** `proyecto-web-abaq/frontend`.
- **Rama de Despliegue:** **`dev-rivers2`**.
- **Builder:** **`RAILPACK`** (V3).
  - **Build Command:** `npm run build:prod`
  - Genera el paquete compilado en `dist/browser`.
  - Railpack monta automáticamente un servidor estático optimizado con Caddy escuchando en el puerto `8080`.

### 6.2 Variables de Entorno del Frontend
| Variable | Valor | Propósito |
|---|---|---|
| `PORT` | `8080` | Puerto HTTP para el servidor estático |
| `NODE_ENV` | `production` | Optimización de assets estáticos |
| `BASE_URL` | `https://backend-development-a4fa8bc3.up.railway.app` | Endpoint del backend al que apunta Angular |
| `FRONTEND_URL` | `https://frontend-development-5a6ef4e4.up.railway.app` | URL pública del frontend |

### 6.3 Dominio Público del Frontend
- Generar dominio en *Networking*: `https://frontend-development-5a6ef4e4.up.railway.app`.

---

## 🔄 7. Pipeline CI/CD y Flujo de Trabajo

El flujo continuo de integración y despliegue opera automáticamente ante cada cambio en git:

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Desarrollador
    participant Git as GitHub (dev-rivers2)
    participant Rail as Railway CI/CD Engine
    participant Back as Backend Deployment
    participant Front as Frontend Deployment

    Dev->>Git: git push origin dev-rivers2
    Git->>Rail: Webhook Push Event (Commit SHA)
    par Build Paralelo
        Rail->>Back: Clonar backend & Railpack Build
        Rail->>Front: Clonar frontend & npm run build:prod
    end
    Back->>Back: Healthcheck & Draining del contenedor anterior
    Front->>Front: Healthcheck & Activación en Edge
    Rail-->>Dev: Notificación de Despliegue Exitoso [SUCCESS]
```

1. **Despliegues con Cero Caídas (Rolling Deploys):** Railway inicia el nuevo contenedor, verifica que responda HTTP saludable y solo entonces conmuta el tráfico y envía `SIGTERM` al contenedor saliente.
2. **Reversión Instantánea:** Desde el historial de despliegues (*Deployments*) de Railway, cualquier versión previa puede restaurarse en 3 segundos con un solo clic.

---

## 🌱 8. Cómo Usar el Script `seed.sh` para Sembrar la Base de Datos

El archivo [`seed.sh`](file:///Users/riosisraelg/dev/abaq/seed.sh) ubicado en la raíz del proyecto es el orquestador unificado de sembrado.

### 8.1 Sintaxis y Modos de Uso
```bash
# Ayuda interactiva
./seed.sh --help

# Sembrado completo (Ciclo de vida + Modelos operativos)
./seed.sh --all

# Sembrado exclusivo de cuentas de ciclo de vida (estudiantes y voluntarios)
./seed.sh --lifecycle

# Sembrado exclusivo de modelos complementarios (mascotas, pláticas, campañas, adopciones)
./seed.sh --models

# Limpieza segura de datos de prueba (@abaq.local y [TEST-*])
./seed.sh --clean

# Resumen visual de credenciales
./seed.sh --summary
```

### 8.2 Ejecución contra el Entorno Railway Development
Para sembrar la base de datos en la nube desde tu máquina, obtén la URI externa vía TCP Proxy e inyéctala en la variable `MONGODB_URI`:

```bash
# 1. Consultar credenciales y puerto del TCP Proxy (vía Railway CLI)
railway variables --project c0b511cf-8ba0-4269-8edc-9d080acf9ebc \
  --environment 0e00b992-f8b5-41e9-9b42-91c3a6110398 \
  --service 6e3e30e0-dd53-4a03-9a5d-db4e38e5fa25 --json

# 2. Ejecutar el sembrador integral apuntando a la nube:
MONGODB_URI="mongodb://mongo:MSdHEcFmFlchPrsmxXGMFqMXNeOzMmtl@trolley.proxy.rlwy.net:58138/abaqTesting--dev-rivers?authSource=admin" \
  ./seed.sh --all
```

### 8.3 Resultado de la Ejecución de Sembrado Realizada

La ejecución inicial arrojó el siguiente balance exitoso:

```
===============================================================================
          ABAQ - GESTOR Y SEMBRADOR INTEGRAL DE DATOS DE PRUEBA                
===============================================================================
🎯 Base de datos seleccionada: abaqTesting--dev-rivers
🔌 Conectado exitosamente a MongoDB: 'abaqTesting--dev-rivers'

🌱 Sembrando datos del ciclo de vida en 'abaqTesting--dev-rivers'...
   🔑 Contraseña universal: 123456789.a
   ✅ Cuentas de Auth (users) procesadas: 15
   ✅ Estudiantes SS sembrados: 8
   ✅ Voluntarios VG sembrados: 6
   ✅ Acreditaciones sincronizadas creadas: 17
   ✅ Actividades para deshidratación: 2
   📄 Archivo JSON sincronizado en raíz: cuentas-ciclo-vida.json
🐾 Sembrando catálogo de modelos operativos en 'abaqTesting--dev-rivers'...
   ✅ QuickActivities creadas: 4
   ✅ Pets registrados: 3
   ✅ Talks generadas: 2
   ✅ Campaigns registradas: 2
   ✅ Adoptions procesadas: 2
   ✅ Identifications generadas: 2
   ✅ Contacts vinculados: 2
🎉 Proceso finalizado correctamente.
```

### 8.4 Cuentas de Prueba Disponibles para Iniciar Sesión
Todas las cuentas comparten la **contraseña universal: `123456789.a`**:

| Rol | Caso de Uso | Correo Electrónico | Folio Expediente |
|---|---|---|---|
| **Administrador** | Acceso total al panel | `admin@abaq.local` | `ADM-001` |
| **Servicio Social** | Pendiente de aprobación | `test.ciclo.ss.pending@abaq.local` | `SS-261103-P1` |
| **Servicio Social** | Primer Ingreso (Constancia) | `test.ciclo.ss.primer.ingreso@abaq.local` | `SS-261103-PI` |
| **Servicio Social** | Activo con acreditaciones | `test.ciclo.ss.activo@abaq.local` | `SS-261103-AC` |
| **Servicio Social** | Alerta 45 días inactividad | `test.ciclo.ss.alerta45@abaq.local` | `SS-261103-A4` |
| **Servicio Social** | Deshidratado histórico | `test.ciclo.ss.historico@abaq.local` | `SS-250815-H1` |
| **Servicio Social** | Rechazado | `test.ciclo.ss.rechazado@abaq.local` | `SS-261103-R1` |
| **Voluntario Gen.** | Pendiente | `test.ciclo.vg.pending@abaq.local` | `VG-261103-P1` |
| **Voluntario Gen.** | Primer Ingreso | `test.ciclo.vg.primer.ingreso@abaq.local` | `VG-261103-PI` |
| **Voluntario Gen.** | Activo | `test.ciclo.vg.activo@abaq.local` | `VG-261103-AC` |
| **Voluntario Gen.** | Rechazado | `test.ciclo.vg.rechazado@abaq.local` | `VG-261103-R1` |

---

## ✉️ 9. Validación de Resend y Parametrización de Botones en Correos

### 9.1 Configuración de Dominio y Remitente
- **Dominio Verificado en Resend:** `hypercoreqro.lat`
- **Remitente Oficial:** `ABAQ Querétaro <notificaciones@hypercoreqro.lat>`
- **Redirección de Pruebas Segura:** En [`backend/utils/email.js`](file:///Users/riosisraelg/dev/abaq/backend/utils/email.js), cualquier correo dirigido a dominios locales (`@abaq.local`, `.test`, `.example`) se redirige automáticamente al `ADMIN_EMAIL` (`riosisraelg@icloud.com`) para evitar rebotes en el proveedor y permitir auditar visualmente los correos reales en bandeja de entrada.

### 9.2 Resolución Dinámica de URLs en Botones de Correo
El componente [`backend/utils/url-helper.js`](file:///Users/riosisraelg/dev/abaq/backend/utils/url-helper.js) resuelve los enlaces de las plantillas de correo respetando jerárquicamente:
1. `req.headers.origin` / `req.headers.referer` de la petición.
2. `process.env.FRONTEND_URL` (`https://frontend-development-5a6ef4e4.up.railway.app`).
3. Reemplazo proactivo de dominios legados hacia el dominio activo.

De esta manera, los botones de los correos:
- **Ver y Descargar Constancia de Inicio** $\rightarrow$ `https://frontend-development-5a6ef4e4.up.railway.app/constancia/aceptacion`
- **Ver y Descargar Constancia de Plática** $\rightarrow$ `https://frontend-development-5a6ef4e4.up.railway.app/constancia/platica/:folio`
- **Descargar Reglamento Oficial** $\rightarrow$ Resuelto a través del endpoint de Bucket Railway.

### 9.3 Evidencia de Validación en Vivo
Se ejecutó una prueba transaccional de extremo a extremo utilizando la API oficial de Resend:

```bash
🟢 [Resend] Correo enviado exitosamente a riosisraelg@icloud.com: {"id":"01a1de50-a251-76c8-917f-6d458ffc3828"}
```

**Resultado verificado:**
```json
{
  "ok": true,
  "provider": "resend",
  "recipient": "riosisraelg@icloud.com",
  "subject": "¡Felicidades! Has sido aceptado(a) oficialmente en ABAQ 🐾",
  "resendId": "01a1de50-a251-76c8-917f-6d458ffc3828",
  "statusCode": 200
}
```
El correo arribó con formato responsivo, tipografía institucional y botón interactivo direccionando correctamente a [`https://frontend-development-5a6ef4e4.up.railway.app/constancia/aceptacion`](https://frontend-development-5a6ef4e4.up.railway.app/constancia/aceptacion).

---

## 🔍 10. Guía de Solución de Problemas (Troubleshooting)

### A. Fallas de Autenticación en MongoDB (`Authentication failed`)
- **Causa:** El volumen ext4 montado contenía un directorio `lost+found` que hizo que el contenedor `mongo:8.0` de Docker Hub omitiera la inicialización del usuario `mongo`.
- **Solución:** Utilizar siempre la imagen de plantilla `ghcr.io/railwayapp-templates/mongo-ha/mongo:8.0` y verificar que las variables `MONGODB_URI` y `DATABASE` en el backend apunten al dominio interno `mongodb-gzwo.railway.internal:27017` con `authSource=admin`.

### B. Error 404 en Rutas Internas de Angular al Recargar Página
- **Causa:** El servidor estático busca un archivo físico en disco para rutas como `/student` o `/admin/voluntarios`.
- **Solución:** El builder Railpack con Caddy en frontend está preconfigurado con directiva `try_files {path} /index.html` para soportar enrutamiento del lado del cliente (SPA HTML5 History API).

### C. Error `Verificación anti-bot requerida` en Endpoints de Auth
- **Causa:** Cloudflare Turnstile está habilitado en `backend` para proteger rutas sensibles contra ataques de fuerza bruta.
- **Solución:** En desarrollo local o pruebas automatizadas con curl, se puede enviar el token emitido por el widget de Turnstile en el frontend o configurar temporalmente `TURNSTILE_DISABLED=true` exclusivamente en entornos de test aislados.

---

## 📚 11. Referencias Cruzadas y Enlaces

- [`seed.sh`](file:///Users/riosisraelg/dev/abaq/seed.sh): Motor unificado de sembrado en raíz.
- [`documentation/docs/scripts/seed-db.md`](file:///Users/riosisraelg/dev/abaq/documentation/docs/scripts/seed-db.md): Manual técnico de colecciones y opciones del sembrador.
- [`backend/utils/email.js`](file:///Users/riosisraelg/dev/abaq/backend/utils/email.js): Proveedor de correo transaccional Resend.
- [`backend/utils/url-helper.js`](file:///Users/riosisraelg/dev/abaq/backend/utils/url-helper.js): Orquestador de URLs canónicas parametrizadas.
- [`documentation/docs/technical/architecture.md`](file:///Users/riosisraelg/dev/abaq/documentation/docs/technical/architecture.md): Arquitectura del sistema y ADR-27 de botones de retroalimentación.
- [`documentation/docs/technical/design-system.md`](file:///Users/riosisraelg/dev/abaq/documentation/docs/technical/design-system.md): Especificación de diseño de tokens y estados transitorios.
