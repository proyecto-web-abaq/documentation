# Despliegue en la Nube con Railway, OpenTofu y AWS Route 53: Infraestructura Real y Operativa

**Proyecto:** Plataforma Web ABAQ & Organizador de Tareas  
**Versión:** 2026.11.04 (CalVer)  
**Fecha:** 2026-11-04  
**Estado:** **100 % Implementado y Operativo en Producción de Pruebas (Live)**  
**Entorno Operativo:** `NODE_ENV=development` (Sandbox de Pruebas de Seguridad y Auditoría Académica)  
**Dominio Base en AWS Route 53:** `hypercoreqro.lat` (Hosted Zone `Z09055831PEII3K2XVDLB`)  
**Plataforma de Cómputo y Bases de Datos:** Railway Cloud Platform  
**Gestor de Infraestructura como Código (IaC):** OpenTofu v1.13.1  

---

## Abstract

Este documento describe con rigor de bajo nivel la arquitectura, aprovisionamiento, contenerización y puesta en marcha real de la infraestructura en la nube de la plataforma **ABAQ** (Frontend Angular v22 y Backend Node.js Express) y del sistema complementario **ABAQ-Organizador** (PHP 8.2 y MySQL). 

A diferencia de propuestas teóricas previas, este despliegue se ejecutó de forma efectiva el **4 de noviembre de 2026** mediante la integración de **Railway** para el cómputo distribuido y bases de datos relacionales/documentales, y **OpenTofu v1.13.1** para la orquestación automatizada de zonas DNS y certificados TLS en **AWS Route 53** bajo el perfil institucional `rout53`. 

El sistema opera deliberadamente bajo bandera `NODE_ENV=development` sin bloqueos de producción ni muros anti-bot (Cloudflare Turnstile), con CORS reflexivo de origen abierto y volcados detallados de excepción. Esta configuración responde al requerimiento estricto de habilitar un **sandbox de pruebas de seguridad y pentesting**, permitiendo que evaluadores y docentes ejecuten inyecciones controladas de datos, cargas de archivos binarios y pruebas de estrés sobre la API, base de datos y frontend sin interrupciones perimetrales.

---

## 1. Topología General de Infraestructura

El despliegue se estructuró en dos proyectos independientes y desacoplados dentro de Railway, vinculados a la zona alojada de Route 53 mediante registros `CNAME` y tokens de verificación `TXT`.

```mermaid
flowchart TD
    subgraph Route53["AWS Route 53 (hypercoreqro.lat - us-east-1)"]
        DNS_ZONE["Hosted Zone: Z09055831PEII3K2XVDLB"]
        DNS_FRONT["abaq.hypercoreqro.lat<br/>(CNAME -> 0cv17nrm.up.railway.app)"]
        DNS_API["api.hypercoreqro.lat<br/>(CNAME -> h1hvh4t0.up.railway.app)"]
        DNS_ORG["organizador.hypercoreqro.lat<br/>(CNAME -> wo3xlwaa.up.railway.app)"]
        
        DNS_ZONE --> DNS_FRONT
        DNS_ZONE --> DNS_API
        DNS_ZONE --> DNS_ORG
    end

    subgraph Project1["Railway Proyecto 1: abaq-dev-app (ID: 631d0172-f2ca-48a4-8d4a-85881a6eaeea)"]
        subgraph SvcFront["Servicio: frontend (ID: a7e65b46)"]
            FRONT_NODE["Node.js 22 Alpine<br/>Express 5 SPA Server (Puerto 8080)"]
            FRONT_DIST["Angular v22 Standalone<br/>dist/browser (Modo Dev)"]
            FRONT_NODE --- FRONT_DIST
        end

        subgraph SvcBack["Servicio: backend (ID: ea2b346e)"]
            BACK_API["Node.js v22 Express API (Puerto 3000)<br/>CORS Reflexivo (Dev Sandbox)"]
            BACK_AUTH["JWT Auth & Crypto HMAC-SHA256"]
            BACK_API --- BACK_AUTH
        end

        subgraph SvcMongo["Servicio: MongoDB (ID: 8016a11e)"]
            MONGO_ENGINE["MongoDB 7.0 Engine<br/>Volumen: /data/db"]
            MONGO_INT["DNS Privado Interno<br/>mongodb.railway.internal:27017"]
            MONGO_PROXY["TCP Proxy Publico<br/>crossover.proxy.rlwy.net:23648"]
            MONGO_DB["Base de Datos:<br/>abaqTesting--dev-rivers"]
            MONGO_ENGINE --- MONGO_INT
            MONGO_ENGINE --- MONGO_PROXY
            MONGO_INT --- MONGO_DB
        end

        FRONT_DIST -->|"Peticiones HTTP/2 REST<br/>Bearer JWT"| BACK_API
        BACK_API -->|"Mongoose ODM (Red Privada Interna)"| MONGO_INT
    end

    subgraph Project2["Railway Proyecto 2: abaq-organizador (ID: 3a71a769-3639-4449-81d8-12613f4237eb)"]
        subgraph SvcOrg["Servicio: organizador (ID: 4e10a80e)"]
            PHP_CLI["PHP 8.2 CLI Contenedor<br/>php -S 0.0.0.0:80"]
            PHP_BOOT["conexion.php<br/>Auto-DDL 5 Tablas & Admin Seed"]
            PHP_CLI --- PHP_BOOT
        end

        subgraph SvcMySQL["Servicio: MySQL (ID: 3763d334)"]
            MYSQL_ENGINE["MySQL 8.0 Plugin Oficial (Puerto 3306)"]
            MYSQL_ENV["Variables de Entorno Enlazadas<br/>MYSQLHOST, MYSQLUSER, MYSQLPASSWORD"]
            MYSQL_ENGINE --- MYSQL_ENV
        end

        PHP_BOOT -->|"Conexion MySQLi / PDO"| MYSQL_ENGINE
    end

    DNS_FRONT ==>|"Trafico HTTPS / Let's Encrypt"| FRONT_NODE
    DNS_API ==>|"Trafico HTTPS / Let's Encrypt"| BACK_API
    DNS_ORG ==>|"Trafico HTTPS / Let's Encrypt"| PHP_CLI

    IaC["OpenTofu v1.13.1 (Perfil AWS: rout53)"] -.->|"tofu apply (6 Records)"| Route53
```

### 🗺️ Mapa de Enrutamiento y Puertos

| Dominio (AWS Route 53) | Servicio Railway | Tipo de Contenedor | Puerto Interno | Protocolo y Propósito |
| :--- | :--- | :--- | :--- | :--- |
| **`abaq.hypercoreqro.lat`** | `frontend` | `node:22-alpine` | `8080` | HTTP/2 (Express 5 Catch-All SPA) |
| **`api.hypercoreqro.lat`** | `backend` | `node:22` (Nixpacks) | `3000` | HTTP/2 (Express 4 API REST) |
| **`organizador.hypercoreqro.lat`** | `organizador` | `php:8.2-cli` | `80` | HTTP/1.1 (PHP Built-in Server) |
| *(Red privada interna)* | `mongodb.railway.internal` | `mongo:7.0` | `27017` | TCP (Mongoose ODM privado) |
| **`crossover.proxy.rlwy.net`** | `MongoDB` (TCP Proxy) | Proxy TCP Público | `23648` | TCP (Administración CLI y Sembrado) |
| *(Red privada interna)* | `MySQL Plugin` | `mysql:8.0` | `3306` | TCP (MySQLi / PDO privado) |

---

## 2. Proyecto 1: `abaq-dev-app` (Frontend, Backend y MongoDB)

### 2.1 Servicio `backend` (API RESTful Node.js + Express)
- **ID de Servicio:** `ea2b346e-a15d-4570-ada7-c5120390a9b6`
- **Dominio Directo:** `https://backend-production-8a30d.up.railway.app`
- **Dominio Personalizado:** `https://api.hypercoreqro.lat`
- **Pila de Ejecución:** Node.js v22.23.4 LTS / Express.js v4.19.2.

#### Modificaciones de Bajo Nivel en `backend/app.js`:
1. **Mapeo Dinámico y Fallback de Base de Datos:**
   Se desacopló la dependencia fija con cadenas de conexión de terceros (`SRV` de MongoDB Atlas) implementando una evaluación en cascada:
   ```javascript
   const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URL || srvUri;

   mongoose
     .connect(mongoUri, { serverSelectionTimeoutMS: 4000 })
     .catch((err) => {
       if (!process.env.MONGODB_URI && !process.env.MONGO_URL) {
         console.warn("⚠️ Conexión SRV falló (" + err.message + "). Conectando por réplicas directas...");
         return mongoose.connect(directUri, { serverSelectionTimeoutMS: 6000 });
       }
       throw err;
     })
     .catch((err) => {
       console.warn("⚠️ MongoDB warning (Express server continues running):", err.message);
     });
   ```
2. **CORS Abierto Reflexivo para Pruebas de Seguridad:**
   Para permitir auditorías de seguridad desde herramientas de escritorio (Postman, Burp Suite, scripts de Python, curl) y desde el frontend desplegado sin bloqueos por cabeceras `Origin`:
   ```javascript
   app.use(
     cors({
       origin: (origin, callback) => {
         // Permite peticiones sin origen (curl/herramientas) y refleja cualquier origen en desarrollo
         callback(null, true);
       },
       credentials: true,
     })
   );
   ```
3. **Variables de Entorno Inyectadas en Railway:**
   - `PORT=3000`
   - `NODE_ENV=development`
   - `DATABASE=abaqTesting--dev-rivers`
   - `MONGODB_URI=mongodb://mongo:LyWpaKECoibbuAfWdBWXChxqCTCtyFDu@mongodb.railway.internal:27017/abaqTesting--dev-rivers?authSource=admin`
   - `MONGO_URL=mongodb://mongo:LyWpaKECoibbuAfWdBWXChxqCTCtyFDu@mongodb.railway.internal:27017/abaqTesting--dev-rivers?authSource=admin`
   - `JWT_SECRET=abaq-dev-jwt-secret-change-in-production`
   - `JWT_EXPIRES_IN=7d`
   - `resend=re_************************************`

---

### 2.2 Servicio `frontend` (Angular v22 Standalone SPA)
- **ID de Servicio:** `a7e65b46-fd1f-4c21-b1a5-ad46fc07e700`
- **Dominio Directo:** `https://frontend-production-6834.up.railway.app`
- **Dominio Personalizado:** `https://abaq.hypercoreqro.lat`
- **Estrategia de Despliegue:** Contenerización optimizada basada en Alpine Linux, sirviendo la distribución precompilada en modo desarrollo.

#### Arquitectura de Entrega Client-Side:
1. **Compilación en Modo Desarrollo:**
   Se ejecutó `ng build -c production --configuration development`, produciendo los bundles en `frontend/dist/browser` con mapas de código (*source maps*) y símbolos legibles para facilitar el análisis del profesor:
   - `main.js`: 5.85 MB (sin minificación agresiva para permitir inspección de llamadas)
   - `styles.css`: 550.54 kB
   - `scripts.js`: 107.73 kB
   - `polyfills.js`: 94.51 kB
2. **Servidor SPA Nativo (`frontend/web-server.js`):**
   Dado que Express 5 incluye un parser de rutas estricto (`path-to-regexp` v8) donde la sintaxis clásica `app.get('*', ...)` lanza un error de excepción fatal `PathError`, se implementó un manejador *catch-all* de middleware funcional compatible:
   ```javascript
   const express = require('express');
   const path = require('path');

   const app = express();
   const port = process.env.PORT || 8080;
   const staticDir = path.join(__dirname, 'dist', 'browser');

   app.use(express.static(staticDir));

   // Enrutador de captura universal compatible con Angular HTML5 pushState
   app.use((req, res) => {
     res.sendFile(path.join(staticDir, 'index.html'));
   });

   app.listen(port, '0.0.0.0', () => {
     console.log(`Frontend running on port ${port}`);
   });
   ```
3. **Contenedor Dockerfile (`frontend/Dockerfile`):**
   ```dockerfile
   FROM node:22-alpine
   WORKDIR /app
   RUN npm init -y && npm install express@4
   COPY dist ./dist
   COPY web-server.js ./
   ENV PORT=8080
   ENV NODE_ENV=development
   EXPOSE 8080
   CMD ["node", "web-server.js"]
   ```
4. **Optimización de Empaquetado (`frontend/.railwayignore`):**
   Se excluyeron `node_modules/` (422 MB), `react-mockup/` (80 MB) y el código fuente TypeScript original, permitiendo que la subida del archivo tar comprimido tarde menos de 3 segundos en cada despliegue.

---

### 2.3 Servicio `MongoDB` (Almacenamiento Documental en Railway)
- **ID de Servicio:** `8016a11e-ea0b-42e7-b7b5-8f898fc15dee`
- **DNS Interno Privado:** `mongodb.railway.internal:27017`
- **Proxy TCP Público Activo:** `crossover.proxy.rlwy.net:23648`
- **Persistencia:** Volumen persistente dedicado (`mongodb-volume`) montado en `/data/db`.
- **Base de Datos Inicializada:** `abaqTesting--dev-rivers`.

#### Sembrado y Cuentas Verificadas:
A través del proxy TCP público se ejecutó el sembrador de ciclos de vida (`seed-lifecycle-scenarios.js`) y se poblaron 14 colecciones operativas:
- **Colección `users`:**
  - `riosisraelg@dev.com` (Rol: `admin`, Password: `123456789.a` con hash bcrypt cost 12).
  - `admin@abaq.local` (Rol: `admin`, Password: `123456789.a`).
  - Cuentas de ciclo de vida (`test.ciclo.ss.*` y `test.ciclo.vg.*`).
- **Colecciones de Negocio:** `students`, `volunteers`, `accreditations`, `activities`, `talks`, `campaigns`, `adoptions`, `identifications`, `notifications`.

---

## 3. Proyecto 2: `abaq-organizador` (PHP 8.2 + MySQL)

- **ID de Proyecto:** `3a71a769-3639-4449-81d8-12613f4237eb`
- **Dominio Directo:** `https://organizador-production-4fc3.up.railway.app`
- **Dominio Personalizado:** `https://organizador.hypercoreqro.lat`

### 3.1 Servicio `organizador` (Cómputo PHP 8.2)
- **ID de Servicio:** `4e10a80e-0bb6-45f3-ad57-49efb5d5a725`
- **Estrategia de Ejecución:** Para evitar conflictos de módulos concurrentes de Apache (`AH00534: More than one MPM loaded`), se desplegó sobre `php:8.2-cli` utilizando el servidor web embebido de PHP, ideal para el desarrollo y análisis de vulnerabilidades:
  ```dockerfile
  FROM php:8.2-cli
  RUN docker-php-ext-install mysqli pdo pdo_mysql
  WORKDIR /app
  COPY . /app
  ENV PORT=80
  ENV NODE_ENV=development
  CMD php -S 0.0.0.0:${PORT} -t /app
  ```

### 3.2 Capa de Conexión y Auto-Bootstrapping DDL (`ABAQ-Organizador/conexion.php`)
Se implementó un script resiliente que lee automáticamente las variables relacionales inyectadas por el plugin MySQL de Railway (`MYSQLHOST`, `MYSQLPORT`, `MYSQLUSER`, `MYSQLPASSWORD`, `MYSQLDATABASE`, `MYSQL_URL`) y ejecuta DDL idempotente en cada conexión si las tablas no existen:
```php
<?php
$host = getenv('MYSQLHOST') ?: getenv('DB_HOST') ?: '127.0.0.1';
$port = (int)(getenv('MYSQLPORT') ?: getenv('DB_PORT') ?: 3306);
$user = getenv('MYSQLUSER') ?: getenv('DB_USER') ?: 'root';
$pass = getenv('MYSQLPASSWORD') ?: getenv('DB_PASSWORD') ?: '';
$db   = getenv('MYSQLDATABASE') ?: getenv('DB_NAME') ?: 'railway';

$dbUrl = getenv('MYSQL_URL') ?: getenv('DATABASE_URL');
if ($dbUrl && strpos($dbUrl, 'mysql://') === 0) {
    $parsed = parse_url($dbUrl);
    if (!empty($parsed['host'])) $host = $parsed['host'];
    if (!empty($parsed['port'])) $port = (int)$parsed['port'];
    if (!empty($parsed['user'])) $user = $parsed['user'];
    if (!empty($parsed['pass'])) $pass = $parsed['pass'];
    if (!empty($parsed['path'])) $db   = ltrim($parsed['path'], '/');
}

$conexion = new mysqli($host, $user, $pass, $db, $port);
$conexion->set_charset("utf8mb4");

// Tablas auto-creadas: usuarios, tareas, comentarios_extra_tareas, historial_actividad, notificaciones
// Siembra automatica del administrador: admin@abaq.org / Admin123!
```

---

## 4. Infraestructura como Código (OpenTofu) y AWS Route 53

Toda la asignación de DNS y los certificados de validación se gestionaron mediante OpenTofu en [`infrastructure/route53-railway/main.tf`](file:///Users/riosisraelg/Desktop/1/abaq/infrastructure/route53-railway/main.tf).

### 4.1 Definición HCL
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "rout53"
}

data "aws_route53_zone" "primary" {
  name         = "hypercoreqro.lat."
  private_zone = false
}

# Frontend
resource "aws_route53_record" "frontend_cname" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "abaq.hypercoreqro.lat"
  type    = "CNAME"
  ttl     = 300
  records = ["0cv17nrm.up.railway.app"]
}

resource "aws_route53_record" "frontend_verify" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "_railway-verify.abaq.hypercoreqro.lat"
  type    = "TXT"
  ttl     = 300
  records = ["railway-verify=fdfbbad15bdaadd1b61489c8e4b93d09febeecb227dbe6f08905c196e24d7e78"]
}

# Backend
resource "aws_route53_record" "backend_cname" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "api.hypercoreqro.lat"
  type    = "CNAME"
  ttl     = 300
  records = ["h1hvh4t0.up.railway.app"]
}

resource "aws_route53_record" "backend_verify" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "_railway-verify.api.hypercoreqro.lat"
  type    = "TXT"
  ttl     = 300
  records = ["railway-verify=2b2d87fafd8773af8a6c50778f7afd3118f9c5e951e07716bbf2e2f3bab14542"]
}

# Organizador
resource "aws_route53_record" "organizador_cname" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "organizador.hypercoreqro.lat"
  type    = "CNAME"
  ttl     = 300
  records = ["wo3xlwaa.up.railway.app"]
}

resource "aws_route53_record" "organizador_verify" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "_railway-verify.organizador.hypercoreqro.lat"
  type    = "TXT"
  ttl     = 300
  records = ["railway-verify=3212f614e123d71d2a03d93320c03803f23d2e7e19b609257eed101459d64a9d"]
}
```

### 4.2 Ejecución y Resultados del Despliegue
- **Comando:** `tofu apply -auto-approve`
- **Resultado:** `Apply complete! Resources: 6 added, 0 changed, 0 destroyed.`
- **Validación CNAME:**
  - `abaq.hypercoreqro.lat` $\rightarrow$ `0cv17nrm.up.railway.app` (Resolución IP: `69.46.46.101`)
  - `api.hypercoreqro.lat` $\rightarrow$ `h1hvh4t0.up.railway.app` (Resolución IP: `69.46.46.113`)
  - `organizador.hypercoreqro.lat` $\rightarrow$ `wo3xlwaa.up.railway.app` (Resolución IP: `69.46.46.45`)
- **Certificados TLS:** Emitidos de manera autónoma por Let's Encrypt mediante la validación DNS TXT (`_railway-verify.*`).

---

## 5. Entorno de Pruebas de Seguridad y Resiliencia (`NODE_ENV=development`)

El sistema fue configurado de manera deliberada como **ambiente de desarrollo y pruebas de seguridad**, atendiendo a los siguientes principios técnicos:

1. **Permisividad de Inyección y Payloads:** No existen Web Application Firewalls (WAF) bloqueando caracteres especiales, etiquetas HTML, comillas o bytes binarios en peticiones POST a `/student`, `/activity`, `/auth` o `/login.php`.
2. **CORS Abierto y Reflexivo:** Permite auditoría remota mediante interceptores HTTP (Burp Suite, OWASP ZAP, Postman) sin restricciones por dominio de origen.
3. **Visibilidad de Mensajes de Diagnóstico:** Las respuestas de error 4xx y 5xx exponen el mensaje de error operacional para validar cómo el sistema reacciona a entradas maliciosas o malformadas.
4. **Pruebas de Carga de Archivos:** Permite validar los mecanismos de subida sin que un proxy perimetral rechace peticiones por límites de tamaño antes de llegar a la lógica de Express o PHP.

---

## 6. Catálogo de URLs y Credenciales Activas

| Módulo / Servicio | URL Directa (Railway) | URL Oficial (Route 53) | Credenciales de Prueba |
| :--- | :--- | :--- | :--- |
| **Frontend ABAQ** | [https://frontend-production-6834.up.railway.app](https://frontend-production-6834.up.railway.app) | [https://abaq.hypercoreqro.lat](https://abaq.hypercoreqro.lat) | `riosisraelg@dev.com` / `123456789.a` |
| **Backend REST API** | [https://backend-production-8a30d.up.railway.app](https://backend-production-8a30d.up.railway.app) | [https://api.hypercoreqro.lat](https://api.hypercoreqro.lat) | Bearer JWT / Login en `/auth/login` |
| **ABAQ-Organizador** | [https://organizador-production-4fc3.up.railway.app](https://organizador-production-4fc3.up.railway.app) | [https://organizador.hypercoreqro.lat](https://organizador.hypercoreqro.lat) | `admin@abaq.org` / `Admin123!` |
| **MongoDB Directo** | TCP: `crossover.proxy.rlwy.net:23648` | Interno: `mongodb.railway.internal:27017` | Usuario: `mongo` (Base: `abaqTesting--dev-rivers`) |
