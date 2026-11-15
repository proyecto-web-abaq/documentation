# Carta Oficial, Constancias Individuales y Notificaciones por Correo en el Módulo de Pláticas

- **Fecha:** 2026-11-15
- **Estado:** Implementado
- **Autor:** Equipo Antigravity / ABAQ Querétaro
- **Módulos Afectados:** Backend (`controllers/talk.controller.js`, `routes/talk.route.js`, `models/talk.model.js`, `utils/talkLetterDocx.js`, `utils/talkLetterPdf.js`, `utils/email.js`), Frontend (`PublicTalkForm`, `TalkDetailComponent`, `TalkService`), Documentación Técnica (`srs.md`, `architecture.md`, `design-system.md`).

---

## 1. Contexto y Justificación Institucional

La **Asociación de Amor y Bienestar Animal en Querétaro A.C. (ABAQ)** es una Organización de la Sociedad Civil (OSC / ONG) legalmente constituida en el Estado de Querétaro. Como donataria y promotora del bienestar animal y la tenencia responsable, ABAQ tiene la obligación estatutaria y legal de **rendir cuentas periódicamente ante dependencias de gobierno** (Secretaría de Desarrollo Social, Direcciones Municipales de Protección Animal, Secretaría de Educación del Estado) y autoridades académicas sobre sus programas de educación e impacto comunitario.

Las pláticas educativas sobre bienestar animal, medicina preventiva y esterilización representan un eje medular de impacto social cuantificable. Por ello, el módulo de pláticas requería:
1. **Generación de Carta Oficial y Reporte de Impacto Social** en dos formatos estandarizados:
   - **Microsoft Word (.DOCX):** Para edición y anexos institucionales requeridos por trámites gubernamentales.
   - **Formato PDF / HTML Imprimible:** Para consulta inmediata, firma digital, impresión directa y archivo.
2. **Constancias individuales de participación** para cada asistente con folio oficial de trazabilidad (`CP-AAMMDD-XXXX-NN`).
3. **Vista posterior al envío del formulario:** Eficiente, intuitiva y segura, donde los usuarios y coordinadores puedan descargar de inmediato la carta oficial y las constancias de los participantes.
4. **Notificaciones automáticas por correo electrónico:** Envío de correo a todos los participantes con su constancia digital única, resaltando el compromiso de ABAQ con el impacto social y la rendición de cuentas.
5. **Eficiencia en recursos (Zero-Puppeteer):** Máximo cuidado de los recursos de cómputo en contenedores Railway (~16-36 MB RAM), sin navegadores headless pesados ni bloqueos en el hilo principal de Node.js.

---

## 2. Arquitectura de la Solución

```
+-----------------------------------------------------------------------------------+
|                        MÓDULO DE PLÁTICAS ABAQ QUERÉTARO                          |
+-----------------------------------------------------------------------------------+
        |
        +---> Envío de Formulario (Público o Admin)
        |       |
        |       +---> Backend Talk Controller (`createTalk`)
        |               |
        |               +---> Generación de Tokens AES-256-GCM por Participante
        |               +---> Cálculo de Folio Institucional (`ABAQ-PL-2026-XXXXXX`)
        |               +---> Guardado en MongoDB
        |               |
        |               +---> DISPATCH ASÍNCRONO DE CORREOS (Non-blocking Promise.allSettled)
        |               |       |--> Resend API (`https://api.resend.com/emails`)
        |               |       |--> Actualización de `emailStatus` ("sent" | "failed")
        |               |
        |               +---> Respuesta HTTP 201 Inmediata (<120ms)
        |
        +---> Vista de Éxito / Dashboard de Impacto Social (`PublicTalkForm`)
        |       |
        |       +---> Tarjeta de Carta Oficial (DOCX & PDF)
        |       +---> Métricas de Impacto (Total Asistentes, Género, Notificados)
        |       +---> Padrón de Constancias con Botón "Ver" y "Copiar Enlace Seguro"
        |
        +---> Generadores de Documentos (Zero-Puppeteer)
                |
                +---> `talkLetterDocx.js`: Generación binaria nativa en memoria con `docx` (<15ms)
                +---> `talkLetterPdf.js`: HTML vectorial autocontenido con `@media print` y barra de acción
                +---> `certificates.js`: Constancias individuales con assets Base64 y sellos institucionales
```

---

## 3. Especificación Técnica

### 3.1. Carta Oficial de Realización y Reporte de Impacto Social

Tanto en `.docx` como en `.pdf`, la carta institucional incluye:
- **Membrete Oficial:** Logotipo de alta resolución de ABAQ Querétaro, razón social completa (*Asociación de Amor y Bienestar Animal en Querétaro A.C.*), R.F.C., Registro Estatal de OSC.
- **Folio Institucional:** Formato estandarizado `ABAQ-PL-AAAA-XXXXXX`.
- **Asunto Oficial:** *Carta Oficial de Realización y Reporte de Impacto Social en Materia de Bienestar Animal*.
- **Destinatario:** *A QUIEN CORRESPONDA / AUTORIDADES EDUCATIVAS, GUBERNAMENTALES Y DE VINCULACIÓN SOCIAL*.
- **Cuerpo Certificador:** Declaración formal del evento, tema impartido, fecha, sede y desglose de participantes.
- **Ejes de Impacto Social Acreditados:**
  1. *Sensibilización Ciudadana:* Cinco libertades de bienestar animal y prevención del maltrato animal.
  2. *Tutela Responsable y Sanidad:* Medicina preventiva, vacunación y esterilización ética.
  3. *Acreditación y Transparencia:* Trazabilidad digital y rendición de cuentas ante dependencias gubernamentales.
- **Padrón de Asistentes:** Tabla con número progresivo, nombre completo, sexo, edad, folio de constancia y estado de acreditación.
- **Firmas y Validación:** Coordinación General y Dirección de Bienestar Animal, lema oficial y trazabilidad digital.

### 3.2. Estrategia Zero-Puppeteer para Generación de DOCX y PDF

Para evitar el uso de Chromium / Puppeteer (que demanda entre 300 MB y 1 GB de memoria RAM y genera caídas por falta de memoria en contenedores de Railway), la plataforma implementa una estrategia nativa de alto rendimiento:

1. **Microsoft Word (.DOCX):** Utiliza la librería nativa de Node.js `docx`, construyendo el árbol de objetos de párrafos, tablas con celdas sombreadas `#1d3d69`, imágenes y pies de página con numeración dinámica (`PageNumber.CURRENT` de `PageNumber.TOTAL_PAGES`). El buffer resultante se transmite como stream `Content-Type: application/vnd.openxmlformats-officedocument.wordprocessingml.document` en menos de 15 ms.
2. **PDF / HTML Imprimible:** Utiliza una plantilla HTML5/CSS3 autocontenida con activos base64 embebidos (logo y marca de agua institucional), fuentes tipográficas del sistema y reglas estrictas de impresión:
   ```css
   @page {
     size: letter portrait;
     margin: 15mm 15mm 15mm 15mm;
   }
   @media print {
     .action-bar { display: none !important; }
     .official-document { border: none !important; box-shadow: none !important; }
     .participants-table tr { page-break-inside: avoid; }
   }
   ```
   Cuenta con una barra superior flotante con botones directos:
   - *🖨️ Imprimir / Guardar en PDF* (invoca `window.print()` nativo).
   - *📥 Descargar en Word (.DOCX)* (enlace directo al endpoint binario).
   - *📋 Copiar Enlace* (copia el enlace de validación digital).

### 3.3. Notificaciones Asíncronas por Correo Electrónico

El servicio de correos (`sendTalkCertificateEmail`) utiliza la infraestructura transaccional de **Resend** con fallback seguro:
- Cada participante que registra su correo recibe un correo institucional personalizado con el tema de la plática, fecha, sede y su **Folio Oficial de Constancia**.
- Un botón principal CTA lleva al participante directamente a su constancia electrónica autenticada con token HMAC/AES-256-GCM.
- El envío se gestiona mediante un ciclo en segundo plano con `Promise.allSettled`, asegurando que la respuesta HTTP al formulario no se bloquee ni se degrade si un correo experimenta latencia o rebote.
- Se registra en MongoDB el campo `emailStatus` (`sent`, `failed`, `no_email`) y `emailSentAt`.

### 3.4. Vista Posterior al Envío del Formulario (`PublicTalkForm`)

Al enviar el formulario, el usuario accede inmediatamente a una interfaz rica y accesible:
1. **Tarjeta de Carta Oficial:** Accesos directos para ver/imprimir la carta en PDF, descargarla en DOCX o copiar su enlace permanente.
2. **Métricas de Impacto:** Cuadrícula con total de asistentes, asistentes mujeres, hombres y total de notificados por correo electrónico.
3. **Padrón de Constancias de Participantes:** Filas interactivas por cada participante mostrando su nombre, folio asignado, insignia de estado de correo (`✉️ Enviada` o `⚠️ Sin correo`), botón para ver y descargar la constancia individual, y botón para copiar el enlace seguro con retroalimentación visual al portapapeles.
4. **Diseño Responsivo Completo:** Adaptación para móviles (`<= 640px`), tabletas (`641px - 1024px`) y computadoras de escritorio (`> 1024px`).

### 3.5. Estandarización de Vistas de Detalle: Header Hero, Super Brief Card y Modal de Confirmación Escrita ("yes")

Para garantizar consistencia transversal en todos los módulos de Base de Datos (`talks`, `adoptions`, `campaigns`, `identifications`):
1. **Hero Header Canónico (`.admin-hero.detail-hero`)**:
   - Incorpora la fila superior `.hero-header-row` con eyebrow, pastilla de tipo, botón de folio interactivo con copiado al portapapeles y subtítulo formateado en hora local.
   - Layout estandarizado de botones en `.hero-actions-row`: *"Actualizar datos"* (con spinner animado), *"Nueva acreditación"* (modal con preselección contextual), cartas oficiales (PDF/DOCX) y *"Borrar registro"*.
   - Fila de estadísticas integradas en el gradiente (`.hero-stats-row`) con tarjetas semitransparentes (`.hero-stat-card`).
2. **Componente Reutilizable Super Brief Card (`<app-db-record-brief-card>`)**:
   - Base visual estándar para todos los formularios de Base de Datos. Expone un resumen ejecutivo de alta densidad con título, folio, insignias de estatus, panel de métricas (`.brief-metrics-panel`) y clúster de botones de acción reflejados tanto fuera como dentro de la tarjeta.
3. **Modal de Confirmación Escrita con "yes" (`<app-update-confirm-modal>`)**:
   - Mecanismo de seguridad deliberado que despliega la Super Brief Card dentro del modal y requiere al operador teclear de forma manual la palabra **`yes`** para desbloquear la actualización y sincronización de datos con el servidor.
4. **Actualización Reactiva de Etiquetas:**
   - Todas las etiquetas (folios, contadores, estados de correo electrónico, indicadores de encuestas) se calculan mediante *getters* y se refrescan al instante con `cdr.detectChanges()`.

---

## 4. Endpoints API Implementados

| Método | Ruta | Acceso | Descripción |
|---|---|---|---|
| `GET` | `/talk/public/:id/letter/docx` | Público (Rate Limiting) | Descarga binaria de la Carta Oficial en formato Word (.docx). |
| `GET` | `/talk/public/:id/letter/pdf` | Público (Rate Limiting) | Renderizado HTML/PDF imprimible de la Carta Oficial. |
| `GET` | `/talk/:id/letter/docx` | Protegido (Admin) | Descarga de la Carta Oficial para administradores. |
| `GET` | `/talk/:id/letter/pdf` | Protegido (Admin) | Vista de la Carta Oficial para administradores. |
| `GET` | `/certificate/talk/:hashToken` | Público (Rate Limiting) | Renderizado de la Constancia individual de participación. |
| `POST`| `/talk/public` | Público (Turnstile) | Creación de plática, emisión de folios y disparo asíncrono de correos. |
| `POST`| `/talk` | Protegido (Admin) | Creación administrativa de plática con generación de cartas y constancias. |
| `GET` | `/talk/:id` | Protegido (Admin) | Detalle de la plática con folios, estados de correo y enlaces de constancias. |

---

## 5. Beneficios para la Organización

1. **Cumplimiento y Rendición de Cuentas:** Facilita a ABAQ entregar reportes institucionales inmediatos en Word o PDF a las autoridades de gobierno sin trabajo manual.
2. **Validación Comunitaria:** Cada asistente cuenta con una constancia digital verificable con sello institucional y folio trazable.
3. **Ahorro de Infraestructura:** El enfoque Zero-Puppeteer reduce a cero los picos de CPU y RAM en el servidor de Railway.
4. **Seguridad Robusta:** Los enlaces de constancias y cartas están protegidos por tokens AES-256-GCM, rate limiting anti-DoS y Turnstile anti-bot.
