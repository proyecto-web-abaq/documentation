---
title: Ideas y Propuestas Técnicas
icon: lucide/lightbulb
---

# 💡 Ideas y Propuestas Técnicas

Esta sección consolida las iniciativas técnicas, propuestas arquitectónicas y análisis de factibilidad para la evolución y protección de la plataforma **ABAQ Querétaro**.

!!! note "Estado de cada idea"

    - :lucide-circle-check: **Aplicada:** implementada en el código, sin pendientes.
    - :lucide-circle-x: **Con pendientes:** propuesta sin implementar o implementada en parte; la tarjeta indica qué falta.

***

<div class="grid cards" markdown>

-   :lucide-circle-x: **[Integración de la Auditoría de Seguridad en dev-rivers2 (2026-11-19)](./2026-11-19-integracion-audit-h11-dev-rivers2.md)**

    ---

    **Pendiente:** La rama de integración está lista y probada, pero aún no se sube ni se fusiona en `dev-rivers2`.

    Integra en el backend todo `security/audit-h11` sobre `dev-rivers2` en la rama `security/audit-h11-integracion` (38/38 suites en verde). Para cada tema muestra el código que viene, el que teníamos y el que queda, con la evidencia de cada decisión: CORS sin apertura fuera de producción, vinculación solo por `authId`, listas de campos permitidos completadas con los campos que el sistema sí usa, dos errores de la fusión automática corregidos, pruebas modificadas y variables nuevas en Railway.

-   :lucide-circle-x: **[Sesiones Seguras y Revocación de JWT, Hallazgo H-09 (2026-11-19)](./2026-11-19-sesiones-jwt-revocacion-h09.md)**

    ---

    **Pendiente:** Propuesta sin implementar: el JWT sigue en localStorage y sin revocación.

    Cierre del hallazgo H-09 de la auditoría del 16 de noviembre, que la rama `security/audit-h11` resuelve solo en parte: el JWT sigue en `localStorage`, dura 7 días y no puede revocarse. Propone una versión de sesión en el usuario (`tokenVersion`) para revocar al cerrar sesión, cambiar la contraseña o desactivar la cuenta, y en una segunda etapa un token de acceso corto en memoria con renovación rotada en cookie `httpOnly` sobre el dominio final.

-   :lucide-circle-check: **[Estadísticas Duales con Costos Oficiales Railway, Respaldo y Rollback Integral (BD + Bucket S3), Guard Anti-Abuso de 8h y Auditoría OWASP WSTG (2026-11-15)](./2026-11-15-estadisticas-costos-railway-respaldo-dual-bd-bucket-s3-seguridad.md)**

    ---

    Propuesta integral (arquitectura, costos, UX ciudadana y seguridad web) para `/admin/backups` y toda la plataforma: división del encabezado en dos contenedores gemelos reutilizando `.hero-stats-grid` y `.hero-stat-card` (Base de datos y Almacenamiento de archivos en Bucket S3) con cálculo mensual oficial de Railway + diferencial de crecimiento ($\Delta$) sin exponer fórmulas en pantalla, caché de 5 min, cooldown de 60 s y *hint* de fecha única (`Última actualización: DD/MM/AAAA`); respaldo tri-modal en lenguaje llano (**"archivos"** / **"documentos guardados"**, sin jerga técnica), manifiesto `v3.0.0`, validación pre-descarga `validateBackupReadiness`, rollback con soporte S3 reutilizando el modal de vista previa bajo política estricta *Zero-Overwrite*, guardián universal de descargas (`downloadGuard.js` + `localStorage` 8h + *Circuit Breaker* anti-egreso) y auditoría integral OWASP WSTG / Top 10:2021 (`H-01`–`H-09`).

-   :lucide-circle-check: **[Gobernanza Narrativa: Separación Conceptual entre Actividades Colectivas (1 de 11 opciones) y Participación Individual 1:1, Trilogía de Roles y Flujo de Verificación (2026-11-15)](./2026-11-15-narrativa-participacion-vs-actividades-roles.md)**

    ---

    Refactorización integral de la narrativa y arquitectura de información institucional en toda la plataforma: erradicación de la etiqueta confusa "Nueva acreditación" a favor de "Registrar participación" / "Registrar participación a colaborador"; distinción formal entre actividades grupales institucionales (eventos convocados por ABAQ) y participaciones individuales con evidencia (.PDF) sujetas a revisión; unificación estricta de los 3 roles (Estudiante de Servicio Social, Voluntario General y Coordinación de Voluntariado); y rediseño pedagógico de `<app-new-accreditation-modal>` con banner informativo de verificación institucional que aclara que el registro no es automático sino auditado por la Coordinación.

-   :lucide-circle-check: **[Carta Oficial (DOCX y PDF), Constancias Individuales y Notificaciones Asíncronas por Correo en Pláticas (2026-11-15)](./2026-11-15-carta-oficial-constancias-notificaciones-platicas.md)**

    ---

    Generación automatizada de la Carta Oficial de Realización y Reporte de Impacto Social en Microsoft Word (`.docx`) y PDF/HTML imprimible para rendición de cuentas institucional de ABAQ (ONG donataria) ante dependencias de gobierno y autoridades educativas; emisión de constancias digitales individuales con folios de trazabilidad (`CP-AAMMDD-XXXX-NN`) y tokens seguros AES-256-GCM; vista de éxito post-envío de formulario y detalle administrativo con métricas de impacto y copiado rápido de enlaces; y despacho de notificaciones de correo en segundo plano vía Resend API con arquitectura Zero-Puppeteer de ultra bajo consumo de recursos (RAM ~2MB).

-   :lucide-circle-check: **[Carga de Archivos Drag & Drop, Nueva Acreditación Contextual, Borrado Seguro en Tarjetas y Actualización Reactiva de Datos (2026-11-15)](./2026-11-15-reutilizacion-carga-archivos-drag-drop-acreditacion-borrado-formularios.md)**

    ---

    Estandarización y reutilización transversal de componentes en el formulario de adopción y los 4 módulos administrativos de Base de Datos: `<app-file-dropzone>` para carga de documentos con drag & drop nativo (.PDF <= 15MB); botón de "Nueva acreditación" en héroes reutilizando `<app-new-accreditation-modal>` con `initialAccreditationType` contextual (`ADOPTION`, `CAMPAIGN`, `IDENTIFICATION`, `TALK`); botón "Actualizar datos" reactivo con ícono giratorio; acción destructiva de "Borrar" en tarjetas con modal de confirmación obligatoria ("borrar") reutilizando `<app-delete-confirm-modal>`; y diseño responsivo optimizado para móviles (320px–640px), tabletas (641px–1024px) y escritorio.

-   :lucide-circle-check: **[Convocatorias OP con Acreditación Anidada (2026-11-15)](./2026-11-15-convocatorias-op-con-acreditacion-anidada.md)**

    ---

    Las convocatorias de Evento ABAQ generan la acreditación de cada participante a partir de su inscripción, con folio visible `OP-EVE` de la convocatoria, evaluación desde el detalle de la actividad y suma de horas atómica (ADR-36).

-   :lucide-circle-check: **[Retroalimentación en Foco de Acción ([appActionFeedback]), Erradicación de Banners Estáticos y Cero Desplazamiento (2026-11-14)](./2026-11-14-retroalimentacion-en-foco-de-accion-appActionFeedback.md)**

    ---

    Transformación reactiva de botones in situ (`[appActionFeedback]`) con preservación geométrica estricta de ancho y alto (CLS = 0); micro-copy compacto basado en íconos (`✓` / `✕`); máquina de estados determinista (`idle` &rarr; `loading` &rarr; `success`/`error` &rarr; `self-healing`); y erradicación integral de banners estáticos (`status-feedback-alert`) que provocaban saltos de pantalla y dispersión visual del usuario.

-   :lucide-circle-x: **[Migración de Documentos a Bucket Railway y Seguridad de Endpoints (2026-11-13)](./2026-11-13-migracion-documentos-bucket-railway.md)**

    ---

    **Pendiente:** Aún quedan campos `cloudUrls` y `evidenceUrl` como enlaces en la interfaz.

    Centralización integral de los documentos PDF del sistema (reglamentos, documentos personales INE/CV, adopciones y evidencias) en el bucket S3 de Railway con validación por *magic bytes*, eliminación de campos redundantes de enlaces externos (`cloudUrls`), autenticación obligatoria en endpoints de carga, tokens cifrados ligados a sesión y *rate limiting* silencioso de 8 horas.

-   :lucide-circle-check: **[Vista Unificada de Participación y Acreditaciones, Agenda de 2 Semanas y Pipeline de 3 Fases sin Mutación de Backend (2026-11-13)](./2026-11-13-vista-unificada-participacion-agenda-dos-semanas-pipeline-tres-fases.md)**

    ---

    Unificación de `/activity-list` y `/my-accreditations` en un lienzo de 1 columna (`1500px`) bajo un arnés de reutilización estricta de componentes reales sin cambios de esquema en MongoDB; Agenda abierta de las próximas 2 semanas con tarjeta compacta `section.next-activity-spotlight`; barra de progreso de 3 fases (`.step-pipeline`) sin píldoras duplicadas; separación de información vital vs. cajón desplegable `Ver detalles` (`Indicaciones:` vs `Comentario de solicitud:`); y partición en 2 vistas por corte temporal de 7 días.

-   :lucide-circle-check: **[Homologación Visual de Encabezados (Admin Heroes), Borrado Validado en Formularios, Acreditación Desacoplada de Voluntarios y Optimización Móvil (2026-11-12)](./2026-11-12-homologacion-heroes-borrado-formularios-acreditacion-voluntarios-responsividad.md)**

    ---

    Homologación integral de cabeceras `.admin-hero` con gradiente institucional y tarjetas de conteo de registros en los 4 formularios de servicio social; diálogo modal validador de borrado con guard de tipeo obligatorio ("borrar") y estado en progreso anti doble-clic; componente ampliado y reutilizable de nueva acreditación con selector por folio y omisión estricta de horas para voluntarios generales; resolución de conflicto de eventos de foco/blur en `CustomSelectComponent` y mitigación de desbordamiento en iPhone SE (375px).

-   :lucide-circle-check: **[Tablero Kanban y Notificaciones Mínimas con Resend (2026-11-09)](./2026-11-09-estrategia-kanban-notificaciones-resend.md)**

    ---

    Estrategia integral de flujo de tareas (corrección de bug de cancelación en Kanban, mitigación de flickering, soporte táctil/móvil) y arquitectura de notificaciones mínimas indispensables por correo vía Resend API (activación de cuenta, asignación y término) evitando fatiga de alertas.

-   :lucide-circle-check: **[Turnstile Anti-Bot en Todas las Superficies Públicas y Despliegue Railway (2026-11-06)](./2026-11-06-turnstile-antibot-todas-las-superficies-publicas.md)**

    ---

    Extensión de Cloudflare Turnstile a las 7 rutas públicas sin autenticación (login, signup estudiante/voluntario y formularios públicos de adopción, campaña, identificación y charla), validación canónica `siteverify`, ampliación de dominios del widget (`hypercoreqro.lat` + `*.up.railway.app`), DNS preservado en Route 53 y publicación con `railway up` sin GitHub conectado.

-   :lucide-circle-x: **[Usabilidad Táctil en Móviles/Tabletas, Pestañas Unificadas, Píldoras Anti-Deformación y Constancias PNG (2026-11-05)](./2026-11-05-usabilidad-tactil-pestanas-tablas-constancias-png.md)**

    ---

    **Pendiente:** Falta la generación de constancias en imagen PNG.

    Propuesta integral de refinamiento táctil: unificación de la tabla administrativa de voluntarios en una sola vista reactiva por pestañas (sin tablas duplicadas apiladas), blindaje geométrico del badge de pendientes (`.pending-chip-btn`) para evitar deformaciones circulares en pantallas pequeñas (< 430px), scroll horizontal continuo en historial (`/volunteers/history`), descarga fidedigna del diploma en PNG y desacoplamiento de leyendas criptográficas en la UI web.

-   :lucide-circle-check: **[Deshidratación, Manifiesto Dual (.zip + .txt MD) y Rehidratación (2026-11-04)](./2026-11-04-deshidratacion-respaldos-rehidratacion.md)**

    ---

    Corrección del empaquetador ZIP (Archiver v8), descarga dual de paquete binario más archivo complementario `.txt` en Markdown para legibilidad humana, gobernanza de rehidratación con preservación de `+passwordHash`, matriz de prevención de colisiones y validación en seco (*dry-run*).

-   :lucide-circle-check: **[Paginación UI/UX, Cohesión Relacional y Publicador de Endpoints (2026-11-04)](./2026-11-04-paginacion-datos-relacionales.md)**

    ---

    Estandarización de paginación en todas las vistas con componente standalone `<app-pagination>`, datos sintéticos con vinculación histórica por voluntario/estudiante, nomenclatura semántica `[DEBUG-*]` y publicación automatizada vía endpoints REST.

-   :lucide-circle-check: **[Transiciones de Estatus, Modal de Inactivación y Comentarios (2026-11-04)](./2026-11-04-transiciones-estatus-inactivacion.md)**

    ---

    Propuesta integral: homolagación de tarjetas amigables de estatus, componente modal de inactivación con guard de tipeo de folio, comentarios obligatorios a discreción del admin, re-registro de rechazados preservando rol y visibilidad en onboarding.

-   :lucide-circle-x: **[Protección Perimetral Cloudflare (WAF y Turnstile) (2026-11-03)](../cloudflare-waf-turnstile-proposal.md)**

    ---

    **Pendiente:** Turnstile está activo, pero el proxy y el WAF de Cloudflare no se implementaron.

    Integración de Cloudflare Reverse Proxy Edge, WAF con Rate Limiting y validación inteligente de personas con Turnstile para Login y Onboarding (Signup).

-   :lucide-circle-check: **[Sistema de Notificaciones (2026-11-03)](../notificaciones-design.md)**

    ---

    Estrategia en evolución para avisos automáticos por correo electrónico (hitos de 120h/240h/360h/480h, corte de inactividad de 2 meses) y notificaciones in-app.

-   :lucide-circle-x: **[Datos: Respaldo, Recuperación y Ciclo de Vida (2026-11-03)](../datos-respaldo-recuperacion-design.md)**

    ---

    **Pendiente:** Quedan decisiones pendientes (D-T1 a D-T5) y el destino Azure no se adoptó.

    Esquema de copias de seguridad hacia Azure Blob Storage y consola local `/backup` con descubrimiento dinámico de modelos Mongoose (`getModelRegistry()`, métricas `activeCollections / totalCollections`, omisión automática de campos `select: false` en `.xlsx` e inclusión íntegra en `.zip` JSON para rollback), restauración con *dry-run* y retención activa sin purgas automáticas de 12 meses ni procesos cron en segundo plano.

-   :lucide-circle-check: **[Ciclo de Vida, Inactivación, Deshidratación y Folios (2026-11-03)](../ciclo-vida-voluntarios-deshidratacion-design.md)**

    ---

    Diseño arquitectónico integral para colaboradores (`student` y `volunteer`): máquina de estados (`accountStatus`), primer ingreso y re-registro idempotente; paso a `inactive` por acreditación de 480 h (`student`) o gestión administrativa manual (sin barrido `node-cron` de 45/60 días ni ventana/purga automática de 12 meses / `365` días); persistencia en listados (con `inactive` al fondo) y `/volunteers/history` hasta corte manual en `/backup`; elegibilidad inmediata de todo `inactive` con fecha efectiva (`fechaDesactivacion || updatedAt || createdAt <= cutoffDate`, tope al día actual UTC), corte indivisible Opción A y resolución `users` vía `authId || userId`; flujo guiado bajo demanda en 4 pasos (1. Analizar sistema en una pasada sin N+1 con aviso temporal de `3.5 s` en el botón si no hay fechas disponibles, 2. Elegir fecha en memoria, 3. Descargar `.zip` con `X-Purge-Token` de 15 min, 4. Borrar registros); bitácoras (`statusHistory`, `DehydrationAuditLog`) y folios `AC`/`OP` de 3 letras.

-   :lucide-circle-check: **[Registro de Implementación: Ciclo de Vida, Folios, Deshidratación y Notificaciones (2026-11-03)](./2026-11-03-registro-implementacion-ciclo-vida-folios-notificaciones.md)**

    ---

    Registro de lo que quedó implementado en backend y frontend para los 8 módulos del ciclo de vida de colaboradores (antes «Implementación M5»): estados de cuenta, folios, deshidratación y notificaciones, con los commits de referencia.

-   :lucide-circle-x: **[Big Data y Analítica de Expedientes (2026-10-31)](../data-analysis-expedientes.md)**

    ---

    **Pendiente:** Solo la fase 1 está implementada en el backend.

    Motor de inteligencia operativa sobre marcas de tiempo de expedientes, percentiles de llenado, auditoría de SLA de 24-48h, mapa de calor y detección de anomalías.

-   :lucide-circle-x: **[Despliegue en la Nube (Azure): Tres Arquitecturas y Costeo (2026-10-18)](../cloud-deployment.md)**

    ---

    **Pendiente:** No se adoptó: el despliegue quedó en Railway.

    Tres modelos de arquitectura de nube (App Service, Container Apps, VM con Docker Compose) analizados y costeados para 100 usuarios concurrentes con el grant de 2,000 USD de Azure.

-   :lucide-circle-x: **[Diseño de Pipelines CI/CD (2026-10-14)](../cicd-pipelines-design.md)**

    ---

    **Pendiente:** No implementado: sustituido por el issue #4 (CI/CD en Railway).

    Propuesta de automatización de entrega continua mediante GitHub Actions para frontend, backend y aprovisionamiento de infraestructura automatizada.

-   :lucide-circle-x: **[Perfil del Usuario y Flujo de Aprobación (2026-10-14)](../perfil-usuario-design.md)**

    ---

    **Pendiente:** El flujo de aprobación de cambios del perfil no está implementado.

    Propuesta de gestión de cuenta, autenticación de dos factores (2FA) y flujo de edición de datos con aprobación administrativa sin suspensión del acceso.

</div>

***

## Resumen de Propuestas Activas

| Propuesta / Módulo | Área de Impacto | Estado | Documento de Referencia |
| :--- | :--- | :--- | :--- |
| **Integración de security/audit-h11 en dev-rivers2** | Seguridad, Backend y Despliegue | Integración Lista para Revisión (20 nov 2026) | [Ver documento](./2026-11-19-integracion-audit-h11-dev-rivers2.md) |
| **Sesiones Seguras y Revocación de JWT (H-09)** | Seguridad, Autenticación y Frontend | Propuesta Técnica Pendiente (19 nov 2026) | [Ver documento](./2026-11-19-sesiones-jwt-revocacion-h09.md) |
| **Estadísticas Duales con Costos Railway, Respaldo/Rollback (BD + Bucket S3), Guard 8h y Auditoría OWASP WSTG** | Respaldos, Finanzas Railway, Almacenamiento S3, UX y Seguridad Web | En Validación Documental (15 nov 2026) | [Ver documento](./2026-11-15-estadisticas-costos-railway-respaldo-dual-bd-bucket-s3-seguridad.md) |
| **Tablero Kanban y Notificaciones Mínimas con Resend** | Gestión de Tareas, UX Móvil, Notificaciones y Correo | Implementado y Estable en Dev (9 nov 2026) | [Ver documento](./2026-11-09-estrategia-kanban-notificaciones-resend.md) |
| **Turnstile Anti-Bot en Superficies Públicas y Despliegue Railway** | Seguridad, Anti-Bot, Frontend, Backend y Despliegue | En Implementación (6 nov 2026) | [Ver documento](./2026-11-06-turnstile-antibot-todas-las-superficies-publicas.md) |
| **Deshidratación, Manifiesto Dual y Rehidratación** | Respaldos, Criptografía, UI y Base de Datos | Propuesta Aprobada — Fuente de Verdad (4 nov 2026) | [Ver documento](./2026-11-04-deshidratacion-respaldos-rehidratacion.md) |
| **Transiciones de Estatus, Modal de Inactivación y Comentarios** | Ciclo de Vida, Seguridad, UI y Notificaciones | Propuesta para Autorización (4 nov 2026) | [Ver documento](./2026-11-04-transiciones-estatus-inactivacion.md) |
| **Cloudflare Proxy & Turnstile** | Seguridad, WAF y Anti-Bot | Propuesta Técnica / Guía DNS (3 nov 2026) | [Ver documento](../cloudflare-waf-turnstile-proposal.md) |
| **Big Data y Analítica de Expedientes** | Business Intelligence y Tiempos | Implementado en Backend / Fase 1 (31 oct 2026) | [Ver documento](../data-analysis-expedientes.md) |
| **Arquitecturas Azure y Costeo** | Infraestructura Cloud y FinOps | Propuesta auditada con precios reales (18 oct 2026) | [Ver documento](../cloud-deployment.md) |
| **Diseño de Pipelines CI/CD** | DevOps y Automatización | Propuesta de diseño con GitHub Actions (14 oct 2026) | [Ver documento](../cicd-pipelines-design.md) |
| **Sistema de Notificaciones** | Comunicación y Regla de Inactividad | Propuesta en evolución (3 nov 2026) | [Ver documento](../notificaciones-design.md) |
| **Perfil con Aprobación de Cambios** | UX y Gestión de Expediente | Propuesta de diseño (14 oct 2026) | [Ver documento](../perfil-usuario-design.md) |
| **Respaldos y Recuperación de Datos** | Continuidad y Contingencia | Propuesta de diseño (3 nov 2026) | [Ver documento](../datos-respaldo-recuperacion-design.md) |
| **Ciclo de Vida, Deshidratación y Folios** | Gestión de Voluntarios, BD, Auditoría y UI | Propuesta Técnica en Refinamiento Activo (3 nov 2026) | [Ver documento](../ciclo-vida-voluntarios-deshidratacion-design.md) |
| **Registro de Implementación: Ciclo de Vida, Folios y Notificaciones** | Gestión de Voluntarios, Backend y Frontend | Implementado (3 nov 2026) | [Ver documento](./2026-11-03-registro-implementacion-ciclo-vida-folios-notificaciones.md) |
