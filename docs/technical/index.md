---
title: Documentación Técnica
icon: lucide/folder-git-2
---

# Documentación Técnica

<div style="background: linear-gradient(135deg, rgba(36, 54, 111, 0.06) 0%, rgba(123, 191, 79, 0.08) 100%); border-left: 4px solid #24366f; border-radius: 8px; padding: 18px 22px; margin-bottom: 28px;">
  <div style="font-size: 0.8rem; font-weight: 800; color: #7bbf4f; letter-spacing: 1px; text-transform: uppercase; margin-bottom: 4px;">
    SISTEMA INTEGRAL ABAQ QUERÉTARO · INGENIERÍA DE SOFTWARE
  </div>
  <div style="font-size: 1.05rem; color: #1e293b; line-height: 1.5; font-weight: 500;">
    Centro de referencia técnica que consolida la especificación formal de requisitos, diagramas de arquitectura C4, stack operativo y la cartera de <strong>propuestas de evolución tecnológica</strong> para la plataforma institucional.
  </div>
</div>

***

## Áreas Principales de Ingeniería

<div class="grid cards" markdown>

-   :lucide-lightbulb:{ .lg .middle } __[💡 Ideas y Propuestas](ideas/index.md)__

    ---

    <span style="display: inline-block; background: #ecfdf5; color: #047857; font-size: 0.72rem; font-weight: 800; padding: 2px 8px; border-radius: 9999px; border: 1px solid #a7f3d0; margin-bottom: 8px;">
      🔥 EVOLUCIÓN & ALTA PRIORIDAD
    </span>

    Iniciativas de vanguardia técnica, seguridad perimetral, analítica avanzada e infraestructura:
    
    * **[Cloudflare WAF & Turnstile](cloudflare-waf-turnstile-proposal.md)**: Reverse Proxy Edge y anti-bot.
    * **[Big Data de Expedientes](data-analysis-expedientes.md)**: Motor analítico y SLA de 24-48h.
    * **[Tres Arquitecturas Azure](cloud-deployment.md)**: Modelado de despliegue y costeo real.
    * **[Pipelines CI/CD](cicd-pipelines-design.md)**: Automatización continua con GitHub Actions.
    * **[Notificaciones y Alertas](notificaciones-design.md)**: Avisos de hitos y regla de 2 meses.

    [:octicons-arrow-right-24: Explorar todas las propuestas (7)](ideas/index.md)

-   :lucide-clipboard-list:{ .lg .middle } __[📋 Requisitos del Sistema (SRS)](requisitos/index.md)__

    ---

    <span style="display: inline-block; background: #eff6ff; color: #1d4ed8; font-size: 0.72rem; font-weight: 800; padding: 2px 8px; border-radius: 9999px; border: 1px solid #bfdbfe; margin-bottom: 8px;">
      NORMA ISO/IEC/IEEE 29148:2018
    </span>

    Especificación formal de las capacidades funcionales, reglas de negocio y restricciones del sistema:
    
    * **[Especificación SRS (Software Requirements)](srs.md)**: Catálogo exhaustivo de casos de uso.
    * **Reglas de Servicio Social**: Meta obligatoria de 480 horas, corte por 60 días de inactividad.
    * **Voluntariado General**: Ciclo libre sin horas mínimas con constancia institucional.
    * **Requisitos no funcionales**: Seguridad JWT, tiempos de carga <1.5s y diseño responsive.

    [:octicons-arrow-right-24: Consultar Requisitos SRS](srs.md)

-   :lucide-drafting-compass:{ .lg .middle } __[📐 Arquitectura y Diseño](arquitectura-y-diseno/index.md)__

    ---

    <span style="display: inline-block; background: #faf5ff; color: #7e22ce; font-size: 0.72rem; font-weight: 800; padding: 2px 8px; border-radius: 9999px; border: 1px solid #e9d5ff; margin-bottom: 8px;">
      MODELO C4 & CLEAN ARCHITECTURE
    </span>

    Estructura modular del sistema, diagramas de flujo y modelado de interfaces:
    
    * **[Arquitectura C4](architecture.md)**: Diagramas de Contexto, Contenedores y Componentes.
    * **[Diseño de Autenticación](auth-design.md)**: Flujo de onboarding en 4 fases, validación e inmutabilidad.
    * **[Mapa de Interfaces Figma](ui-prompts-figma.md)**: Prompts y especificaciones de pantalla.
    * **Esquema de Datos Mongoose**: Modelos relacionales desacoplados de estudiantes y voluntarios.

    [:octicons-arrow-right-24: Ver Arquitectura C4](architecture.md)

-   :lucide-server-cog:{ .lg .middle } __[⚙️ Operación y Plataforma](operacion/index.md)__

    ---

    <span style="display: inline-block; background: #f0fdf4; color: #15803d; font-size: 0.72rem; font-weight: 800; padding: 2px 8px; border-radius: 9999px; border: 1px solid #bbf7d0; margin-bottom: 8px;">
      STACK TECNOLÓGICO & RUNTIME
    </span>

    Inventario técnico de producción, entornos y aprovisionamiento:
    
    * **[Stack Tecnológico Completo](tech-stack.md)**: Angular 19, Node.js 20+, Express y MongoDB Atlas.
    * **[Despliegue en la Nube](cloud-deployment.md)**: Opciones de hosting sobre grant Azure de \$2,000 USD.
    * **[Diseño de Pipelines](cicd-pipelines-design.md)**: Flujos CI/CD para frontend, backend e infraestructura.

    [:octicons-arrow-right-24: Ver Stack Tecnológico](tech-stack.md)

-   :lucide-kanban:{ .lg .middle } __[📊 Gestión del Proyecto](gestion-proyecto/index.md)__

    ---

    <span style="display: inline-block; background: #fff7ed; color: #c2410c; font-size: 0.72rem; font-weight: 800; padding: 2px 8px; border-radius: 9999px; border: 1px solid #fed7aa; margin-bottom: 8px;">
      SCRUM & ESTRATEGIA GIT
    </span>

    Planificación operativa, avance por sprints y políticas de control de versiones:
    
    * **[Matriz de Tareas y Progreso](tasks.md)**: Seguimiento granular de tareas y estado de completitud.
    * **[Estrategia de Ramas Git](gestion-proyecto/estrategia-ramas.md)**: Convención de ramas, commits y PRs.
    * **Auditoría de Entregables**: Sincronización con los 8 Reportes Quincenales.

    [:octicons-arrow-right-24: Ver Tareas y Progreso](tasks.md)

</div>

***

## 🗺️ Mapa Rápido de Referencia Técnica

| Categoría | Enfoque Principal | Documentos Clave | Estado Actual |
| :--- | :--- | :--- | :--- |
| **💡 Ideas y Propuestas** | Innovación, Perímetro WAF y Big Data | [Cloudflare WAF](cloudflare-waf-turnstile-proposal.md) · [Big Data](data-analysis-expedientes.md) · [Azure Cloud](cloud-deployment.md) · [CI/CD](cicd-pipelines-design.md) | Propuestas en Evaluación |
| **📋 Requisitos** | Alcance formal bajo norma ISO | [SRS Completo](srs.md) | Línea Base Aprobada |
| **📐 Arquitectura** | Modelo C4 y Flujos de Identidad | [C4 Architecture](architecture.md) · [Auth & Onboarding](auth-design.md) | En Producción |
| **⚙️ Operación** | Infraestructura y Despliegue | [Tech Stack](tech-stack.md) · [Cloud Deployment](cloud-deployment.md) | Documentado |
| **📊 Gestión** | Sprint Planning y Control de Versiones | [Tareas (Tasks)](tasks.md) · [Estrategia Git](gestion-proyecto/estrategia-ramas.md) | Seguimiento Activo |
