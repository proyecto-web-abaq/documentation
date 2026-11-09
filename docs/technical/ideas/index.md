---
title: Ideas y Propuestas Técnicas
icon: lucide/lightbulb
---

# 💡 Ideas y Propuestas Técnicas

Esta sección consolida las iniciativas técnicas, propuestas arquitectónicas y análisis de factibilidad para la evolución y protección de la plataforma **ABAQ Querétaro**.

***

<div class="grid cards" markdown>

-   :lucide-layout-grid: **[Tablero Kanban y Notificaciones Mínimas con Resend (2026-11-09)](./2026-11-09-estrategia-kanban-notificaciones-resend.md)**

    ---

    Estrategia integral de flujo de tareas (corrección de bug de cancelación en Kanban, mitigación de flickering, soporte táctil/móvil) y arquitectura de notificaciones mínimas indispensables por correo vía Resend API (activación de cuenta, asignación y término) evitando fatiga de alertas.

-   :lucide-shield-check: **[Turnstile Anti-Bot en Todas las Superficies Públicas y Despliegue Railway (2026-11-06)](./2026-11-06-turnstile-antibot-todas-las-superficies-publicas.md)**

    ---

    Extensión de Cloudflare Turnstile a las 7 rutas públicas sin autenticación (login, signup estudiante/voluntario y formularios públicos de adopción, campaña, identificación y charla), validación canónica `siteverify`, ampliación de dominios del widget (`hypercoreqro.lat` + `*.up.railway.app`), DNS preservado en Route 53 y publicación con `railway up` sin GitHub conectado.

-   :lucide-smartphone: **[Usabilidad Táctil en Móviles/Tabletas, Pestañas Unificadas, Píldoras Anti-Deformación y Constancias PNG (2026-11-05)](./2026-11-05-usabilidad-tactil-pestanas-tablas-constancias-png.md)**

    ---

    Propuesta integral de refinamiento táctil: unificación de la tabla administrativa de voluntarios en una sola vista reactiva por pestañas (sin tablas duplicadas apiladas), blindaje geométrico del badge de pendientes (`.pending-chip-btn`) para evitar deformaciones circulares en pantallas pequeñas (< 430px), scroll horizontal continuo en historial (`/volunteers/history`), descarga fidedigna del diploma en PNG y desacoplamiento de leyendas criptográficas en la UI web.

-   :lucide-database-backup: **[Deshidratación, Manifiesto Dual (.zip + .txt MD) y Rehidratación (2026-11-04)](./2026-11-04-deshidratacion-respaldos-rehidratacion.md)**

    ---

    Corrección del empaquetador ZIP (Archiver v8), descarga dual de paquete binario más archivo complementario `.txt` en Markdown para legibilidad humana, gobernanza de rehidratación con preservación de `+passwordHash`, matriz de prevención de colisiones y validación en seco (*dry-run*).

-   :lucide-layers: **[Paginación UI/UX, Cohesión Relacional y Publicador de Endpoints (2026-11-04)](./2026-11-04-paginacion-datos-relacionales.md)**

    ---

    Estandarización de paginación en todas las vistas con componente standalone `<app-pagination>`, datos sintéticos con vinculación histórica por voluntario/estudiante, nomenclatura semántica `[DEBUG-*]` y publicación automatizada vía endpoints REST.

-   :lucide-shield-alert: **[Transiciones de Estatus, Modal de Inactivación y Comentarios (2026-11-04)](./2026-11-04-transiciones-estatus-inactivacion.md)**

    ---

    Propuesta integral: homolagación de tarjetas amigables de estatus, componente modal de inactivación con guard de tipeo de folio, comentarios obligatorios a discreción del admin, re-registro de rechazados preservando rol y visibilidad en onboarding.

-   :lucide-shield-check: **[Protección Perimetral Cloudflare (WAF y Turnstile)](../cloudflare-waf-turnstile-proposal.md)**

    ---

    Integración de Cloudflare Reverse Proxy Edge, WAF con Rate Limiting y validación inteligente de personas con Turnstile para Login y Onboarding (Signup).

-   :lucide-bar-chart-3: **[Big Data y Analítica de Expedientes](../data-analysis-expedientes.md)**

    ---

    Motor de inteligencia operativa sobre marcas de tiempo de expedientes, percentiles de llenado, auditoría de SLA de 24-48h, mapa de calor y detección de anomalías.

-   :lucide-cloud: **[Despliegue en la Nube (Azure): Tres Arquitecturas y Costeo](../cloud-deployment.md)**

    ---

    Tres modelos de arquitectura de nube (App Service, Container Apps, VM con Docker Compose) analizados y costeados para 100 usuarios concurrentes con el grant de 2,000 USD de Azure.

-   :lucide-workflow: **[Diseño de Pipelines CI/CD](../cicd-pipelines-design.md)**

    ---

    Propuesta de automatización de entrega continua mediante GitHub Actions para frontend, backend y aprovisionamiento de infraestructura automatizada.

-   :lucide-bell: **[Sistema de Notificaciones](../notificaciones-design.md)**

    ---

    Estrategia en evolución para avisos automáticos por correo electrónico (hitos de 120h/240h/360h/480h, corte de inactividad de 2 meses) y notificaciones in-app.

-   :lucide-user-cog: **[Perfil del Usuario y Flujo de Aprobación](../perfil-usuario-design.md)**

    ---

    Propuesta de gestión de cuenta, autenticación de dos factores (2FA) y flujo de edición de datos con aprobación administrativa sin suspensión del acceso.

-   :lucide-database-backup: **[Datos: Respaldo, Recuperación y Ciclo de Vida](../datos-respaldo-recuperacion-design.md)**

    ---

    Esquema de copias de seguridad hacia Azure Blob Storage y consola local `/backup` con descubrimiento dinámico de modelos Mongoose (`getModelRegistry()`, métricas `activeCollections / totalCollections`, omisión automática de campos `select: false` en `.xlsx` e inclusión íntegra en `.zip` JSON para rollback), restauración con *dry-run* y retención activa sin purgas automáticas de 12 meses ni procesos cron en segundo plano.

-   :lucide-user-check: **[Ciclo de Vida, Inactivación, Deshidratación y Folios](../ciclo-vida-voluntarios-deshidratacion-design.md)**

    ---

    Diseño arquitectónico integral para colaboradores (`student` y `volunteer`): máquina de estados (`accountStatus`), primer ingreso y re-registro idempotente; paso a `inactive` por acreditación de 480 h (`student`) o gestión administrativa manual (sin barrido `node-cron` de 45/60 días ni ventana/purga automática de 12 meses / `365` días); persistencia en listados (con `inactive` al fondo) y `/volunteers/history` hasta corte manual en `/backup`; elegibilidad inmediata de todo `inactive` con fecha efectiva (`fechaDesactivacion || updatedAt || createdAt <= cutoffDate`, tope al día actual UTC), corte indivisible Opción A y resolución `users` vía `authId || userId`; flujo guiado bajo demanda en 4 pasos (1. Analizar sistema en una pasada sin N+1 con aviso temporal de `3.5 s` en el botón si no hay fechas disponibles, 2. Elegir fecha en memoria, 3. Descargar `.zip` con `X-Purge-Token` de 15 min, 4. Borrar registros); bitácoras (`statusHistory`, `DehydrationAuditLog`) y folios `AC`/`OP` de 3 letras.

</div>

***

## Resumen de Propuestas Activas

| Propuesta / Módulo | Área de Impacto | Estado | Documento de Referencia |
| :--- | :--- | :--- | :--- |
| **Tablero Kanban y Notificaciones Mínimas con Resend** | Gestión de Tareas, UX Móvil, Notificaciones y Correo | Implementado y Estable en Dev (9 nov 2026) | [Ver documento](./2026-11-09-estrategia-kanban-notificaciones-resend.md) |
| **Turnstile Anti-Bot en Superficies Públicas y Despliegue Railway** | Seguridad, Anti-Bot, Frontend, Backend y Despliegue | En Implementación (6 nov 2026) | [Ver documento](./2026-11-06-turnstile-antibot-todas-las-superficies-publicas.md) |
| **Deshidratación, Manifiesto Dual y Rehidratación** | Respaldos, Criptografía, UI y Base de Datos | Propuesta Aprobada — Fuente de Verdad (4 nov 2026) | [Ver documento](./2026-11-04-deshidratacion-respaldos-rehidratacion.md) |
| **Transiciones de Estatus, Modal de Inactivación y Comentarios** | Ciclo de Vida, Seguridad, UI y Notificaciones | Propuesta para Autorización (4 nov 2026) | [Ver documento](./2026-11-04-transiciones-estatus-inactivacion.md) |
| **Cloudflare Proxy & Turnstile** | Seguridad, WAF y Anti-Bot | Propuesta Técnica / Guía DNS | [Ver documento](../cloudflare-waf-turnstile-proposal.md) |
| **Big Data y Analítica de Expedientes** | Business Intelligence y Tiempos | Implementado en Backend / Fase 1 | [Ver documento](../data-analysis-expedientes.md) |
| **Arquitecturas Azure y Costeo** | Infraestructura Cloud y FinOps | Propuesta auditada con precios reales | [Ver documento](../cloud-deployment.md) |
| **Diseño de Pipelines CI/CD** | DevOps y Automatización | Propuesta de diseño con GitHub Actions | [Ver documento](../cicd-pipelines-design.md) |
| **Sistema de Notificaciones** | Comunicación y Regla de Inactividad | Propuesta en evolución | [Ver documento](../notificaciones-design.md) |
| **Perfil con Aprobación de Cambios** | UX y Gestión de Expediente | Propuesta de diseño | [Ver documento](../perfil-usuario-design.md) |
| **Respaldos y Recuperación de Datos** | Continuidad y Contingencia | Propuesta de diseño | [Ver documento](../datos-respaldo-recuperacion-design.md) |
| **Ciclo de Vida, Deshidratación y Folios** | Gestión de Voluntarios, BD, Auditoría y UI | Propuesta Técnica en Refinamiento Activo | [Ver documento](../ciclo-vida-voluntarios-deshidratacion-design.md) |
