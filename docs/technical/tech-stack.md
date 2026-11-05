---
title: Stack Tecnológico
icon: lucide/layers
---

# Stack Tecnológico y Requisitos de Despliegue

**Proyecto:** Plataforma Web ABAQ (Servicio Social y Voluntariado General)  
**Versión:** 2.2.0  
**Fecha:** 2026-10-30 (v1.1.0: 2026-10-14)  
**Estado:** Inventario Verificado del Sistema Real en Producción (Angular v22 Standalone + Express Node.js v24 + MongoDB Atlas)  
**Relacionado:** [Arquitectura](architecture.md) · [Requerimientos del Sistema (SRS)](srs.md) · [Diseño de Autenticación y Onboarding](auth-design.md) · [Backend API](backend.md)

---

## 1. Propósito

Documentar el stack tecnológico de producción que compone el ecosistema web institucional de ABAQ, describiendo los frameworks, librerías, dependencias de ejecución, contratos de infraestructura y la resolución efectiva de las brechas técnicas históricas.

---

## 2. Stack Tecnológico de Producción (Verificado)

### 2.1 Backend — `/backend` (Node.js v24 + Express)

Verificado en `backend/package.json` y código fuente:

| Categoría | Tecnología / Librería | Versión | Propósito en el Sistema |
|---|---|---|---|
| **Runtime** | Node.js | `v24.x LTS` | Entorno de ejecución de servidor con soporte nativo para ES modules y Crypto de alto rendimiento. |
| **Framework Web** | Express | `^4.19.2` | Servidor HTTP RESTful, middleware de CORS, parsing de JSON y enrutamiento modular. |
| **ODM / Base de Datos** | Mongoose / MongoDB Atlas | `^8.4.4` (driver `^6.7.0`) | Modelado de datos (`Student`, `Volunteer`, `Activity`, `Accreditation`), validaciones de esquema e índices. |
| **Seguridad y Criptografía** | `crypto` (nativo) + `jsonwebtoken` (`^9.0.2`) + `bcryptjs` (`^2.4.3`) | Nativo / LTS | Emisión y validación de tokens JWT (7 días), hashing seguro de contraseñas y sellado criptográfico HMAC-SHA256 con protección de tiempo constante (`timingSafeEqual`). |
| **Generador de Folios Deterministas** | `crypto` nativo (`backend/utils/folio-generator.js`) | Nativo | Generación de folios de interacción de colaboradores sin colisiones: `AC-YYMMDD-HEX` (actividades) y `OP-CAT-YYMMDD-HEX` (12 modalidades mnemónicas). |
| **Motor de Certificados** | HTML5/CSS3 en memoria (`backend/utils/certificates.js`) | Nativo | Generación dinámica de cartas y constancias oficiales sin sobrecarga de Puppeteer (~2.2 MB RAM por petición). |
| **Exportación, Respaldos y Deshidratación** | `exceljs` (`^4.4.0`) + `multer` (`^1.4.5-lts.1`) + `archiver` (`^7.0.1`) | Producción | Respaldos integrales en JSON comprimido, cortes limpios indivisibles en ZIP para deshidratación, exportación Excel (`.xlsx`) y restauración granular. |
| **Validaciones** | `express-validator` | `^7.1.0` | Saneamiento de payloads, validación de CURP, correos y restricciones de campos. |
| **Correo Transaccional** | Nodemailer / Resend | `^6.9.14` | Envío de notificaciones de estado, cartas de bienvenida y avisos institucionales. |
| **Herramientas de QA y Sembrado** | CLI Node.js (`seed-lifecycle-scenarios.js`) + Bash (`seed.sh`) | Nativo | [Sembrado automatizado](../scripts/seed-db.md), enriquecimiento retroactivo de folios (`--backfill-folios`), purga atómica (`--clean`) y sincronización de JSON de prueba. |
| **Configuración** | `dotenv` | `^16.4.5` | Carga de variables de entorno con reintentos resilientes para sincronización con pipes de secretos. |

### 2.2 Frontend — `/frontend` (Angular 22 Standalone)

Verificado en `frontend/package.json` y componentes de Angular:

| Categoría | Tecnología / Librería | Versión | Propósito en el Sistema |
|---|---|---|---|
| **Framework SPA** | Angular Standalone | `^22.0.0` | Arquitectura moderna sin `NgModule` basada en componentes independientes, inyección de dependencias funcional y señales. |
| **Compilador / Tipado** | TypeScript | `~5.5.0` / `~6.0.0` | Tipado estricto para modelos de dominio (`Student`, `Volunteer`, `AssignedActivity`, `CloudUrls`). |
| **Sistema de Diseño y UI** | Bootstrap 5.3 + SCSS personalizado | `5.3.x` | Tokens institucionales (`#24366f`, `#5ca83a`), diseño responsivo adaptativo y componentes reutilizables. |
| **Componentes Visuales** | `@ng-bootstrap/ng-bootstrap` + `chart.js` | Reciente | Gráficos de progreso de horas (dona y líneas), modales accesibles y toolbars con búsqueda en tiempo real. |
| **Generación de PDFs en Cliente** | `html2pdf.js` / `jspdf` | Cliente | Renderizado y rasterización de certificados oficiales en formato A4 apaisado directo en el navegador del usuario. |
| **Efectos y UX** | `canvas-confetti` | Navegador | Celebración visual en la pantalla `/expediente-recibido`. |
| **Persistencia Local** | `localStorage` + RxJS | Nativo / `^7.8.0` | Auto-guardado reactivo en borrador local con debounce de 400 ms y listener `beforeunload`. |

### 2.3 Portal de Documentación — `/documentation` (Zensical)

Verificado en `documentation/zensical.toml`:

| Categoría | Tecnología / Herramienta | Versión | Propósito en el Sistema |
|---|---|---|---|
| **Generador de Sitio Estático** | Zensical (SSG en Python) | Reciente | Compilación ultra-rápida del portal de documentación a HTML/CSS/JS estático. |
| **Sintaxis y Renderizado** | Markdown + GFM + PyMdown Extensions | Estándar | Tablas avanzadas, admoniciones/callouts, bloques de código tabulados y fórmulas matemáticas. |
| **Diagramas Arquitectónicos** | Mermaid.js | Integrado | Renderizado de diagramas de estado, flujo C4, secuencias de autenticación y mapas de componentes. |
| **Iconografía** | Lucide Icons | Integrado | Iconos SVG semánticos en navegación, títulos de tarjetas y encabezados de página. |

---

## 3. Resolución de Brechas Arquitectónicas

En la versión actual de producción se resolvieron de forma definitiva las inconsistencias identificadas en etapas preliminares:

1. **Resolución de GridFS (Arquitectura Zero-File):**
   - *Brecha previa:* Dependencia de almacenamiento binario local y rutas `/upload`.
   - *Solución implementada:* Cero archivos en el servidor. Los postulantes registran enlaces públicos en la nube (Google Drive, OneDrive, iCloud) en `cloudUrls`. Los documentos institucionales (Carta de Aceptación, Certificado de Término) se sintetizan dinámicamente con sellos criptográficos.
2. **Generación de Certificados sin Puppeteer:**
   - *Brecha previa:* Uso de navegadores headless (Chromium) con alto consumo de memoria RAM (>300 MB por proceso) y bloqueos de I/O.
   - *Solución implementada:* Generador criptográfico ligero en Node.js (~2.2 MB RAM) que devuelve HTML5/CSS3 estilizado con tokens HMAC-SHA256, delegando la rasterización PDF al cliente mediante `html2pdf.js`.
3. **Flujo de Onboarding Unificado en 4 Fases:**
   - *Brecha previa:* Formularios de 5 o 6 lotes dispersos y falta de soporte para Voluntariado General.
   - *Solución implementada:* Componente standalone unificado `OnboardingPhaseComponent` con proceso de onboarding y registro guiado, outline adaptativo (oculto en tabletas y móviles `<=1024px`), control compuesto de periodo académico 100% full width, selector de redes con badges oficiales, y segregación estricta de horas (10h de inducción solo para `SS`).
4. **Subsistema de Respaldo y Rollback:**
   - *Brecha previa:* Ausencia de mecanismos de recuperación y exportación masiva.
   - *Solución implementada:* Módulo `/backup` en Express y componente `BackupComponent` en Angular que permiten exportaciones completas a JSON y Excel, y restauración con análisis preliminar (*dry-run*) y reversión atómica.
5. **Regla de Inactividad de 2 Meses:**
   - *Solución implementada:* Endpoint `POST /student/check-inactivity` y procedimientos de auditoría para baja preventiva de alumnos sin participaciones durante 60 días naturales.
