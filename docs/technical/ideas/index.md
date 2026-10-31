---
title: Ideas y Propuestas Técnicas
icon: lucide/lightbulb
---

# 💡 Ideas y Propuestas Técnicas

Esta sección consolida las iniciativas técnicas, propuestas arquitectónicas y análisis de factibilidad para la evolución y protección de la plataforma **ABAQ Querétaro**.

***

<div class="grid cards" markdown>

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

    Propuesta de archivado y desactivacion de usarios en el ssitema de usarios volunteers student y general
-   :lucide-database-backup: **[Desactivacion de usarios](../archiveUsers.md)**

    ---

    Esquema de copias de seguridad automatizadas a Azure Blob Storage, restauración granular con dry-run y archivado por semestres lectivos.

</div>

***

## Resumen de Propuestas Activas

| Propuesta / Módulo | Área de Impacto | Estado | Documento de Referencia |
| :--- | :--- | :--- | :--- |
| **Cloudflare Proxy & Turnstile** | Seguridad, WAF y Anti-Bot | Propuesta Técnica / Guía DNS | [Ver documento](../cloudflare-waf-turnstile-proposal.md) |
| **Big Data y Analítica de Expedientes** | Business Intelligence y Tiempos | Implementado en Backend / Fase 1 | [Ver documento](../data-analysis-expedientes.md) |
| **Arquitecturas Azure y Costeo** | Infraestructura Cloud y FinOps | Propuesta auditada con precios reales | [Ver documento](../cloud-deployment.md) |
| **Diseño de Pipelines CI/CD** | DevOps y Automatización | Propuesta de diseño con GitHub Actions | [Ver documento](../cicd-pipelines-design.md) |
| **Sistema de Notificaciones** | Comunicación y Regla de Inactividad | Propuesta en evolución | [Ver documento](../notificaciones-design.md) |
| **Perfil con Aprobación de Cambios** | UX y Gestión de Expediente | Propuesta de diseño | [Ver documento](../perfil-usuario-design.md) |
| **Respaldos y Recuperación de Datos** | Continuidad y Contingencia | Propuesta de diseño | [Ver documento](../datos-respaldo-recuperacion-design.md) |
