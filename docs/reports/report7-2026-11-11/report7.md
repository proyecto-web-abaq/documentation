# Reporte de Avance No. 7

| | |
|---|---|
| **Fecha** | 11 de noviembre de 2026 |
| **Versión** | v1.2.0 |
| **Estado** | En integración y homologación técnica |
| **Preparado por** | Equipo de Desarrollo ABAQ |

---

## Resumen ejecutivo

Durante el presente periodo quincenal se consolidaron avances cruciales en la estandarización de la plataforma ABAQ:
1. **Homologación Visual y de Identidad**: Integración de héroes administrativos estandarizados (`admin-hero`) con métricas contextuales integradas y enlaces directos de retorno en todas las vistas de gestión.
2. **Módulo de Constancias de Plática para Público en General**: Especificación formal de requerimientos (SRS) y arquitectura de software para la emisión y consulta pública de constancias de asistencia comunitaria sin requerir cuentas de usuario institucionales.
3. **Directiva de Reutilización de Componentes**: Homologación del motor de constancias en backend (`certificates.js`), tokens criptográficos inviolables AES-256-GCM (`v2.`), y reutilización del componente de píldora de interacción `<app-folio-pill>` en todos los roles con folios canónicos `OP-TLK-YYMMDD-HEX`.

---

## 1. Introducción

El presente reporte consolida los avances desarrollados durante el sprint de cierre de ciclo previo a la entrega final. Los trabajos se concentraron en eliminar redundancias de código, garantizar la seguridad perimetral y extender el beneficio de la plataforma hacia la comunidad en general que participa en eventos cívicos de bienestar animal.

---

## 2. Acuerdos y Seguimiento

- **Reutilización Estricta de Componentes**: Evitar la duplicación de plantillas o motores paralelos de generación de constancias. Todo reconocimiento emitido por ABAQ utiliza el motor base de `template.html` con tipografías vectoriales embebidas y barras de acción responsive.
- **Acceso Público Verificado**: Permitir que cualquier asistente a pláticas públicas pueda consultar y descargar su constancia sin crear cuenta institucional ni ingresar credenciales de acceso.
- **Desacoplamiento Estricto**: Mantener separadas las constancias curriculares de Servicio Social (Inicio y Término 480h) de los reconocimientos de participación ciudadana.

---

## 3. Cambios en el Servidor (Backend)

- **Tokens Criptográficos Inviolables AES-256-GCM**:
  - Implementación de tokens opacos `v2.<base64url>` con IV aleatorio de 12 bytes y etiqueta de autenticación de 16 bytes.
  - Validación de integridad matemática que bloquea manipulaciones de nombres o identificadores en la URL con respuesta HTTP 403.
- **Ruta Pública de Constancias (`GET /certificate/v/:hashToken`)**:
  - Desacoplamiento de la restricción de autenticación para constancias de plática (`certType === 'talk'`).
  - Mitigación DoS mediante rate limiting por IP (máximo 60 peticiones en 15 minutos).
- **Controlador y Modelo de Pláticas (`Talk`)**:
  - Generación determinista de folios de interacción `OP-TLK-YYMMDD-HEX` para cada participante.
  - Protección anti-bot con Cloudflare Turnstile en `/talk/public`.

---

## 4. Cambios en la Aplicación Web (Frontend)

- **Formulario Público `/formularios/platicas`**:
  - Captura dinámica de participantes con validación de campos y widget anti-bot Turnstile.
  - Mensajes de confirmación con enlaces directos para consulta de constancias.
- **Detalle y Gestión Administrativa (`TalkDetailComponent`)**:
  - Homologación de `admin-hero` con información contextual de sede, fecha y participantes.
  - Reutilización de `<app-folio-pill>` para exhibir los folios `OP-TLK-...` de oportunidad en cada tarjeta de asistente.
- **Canvas de Constancia Responsive**:
  - Escalado bidimensional en cliente gobernado por la variable CSS `--cert-scale`.
  - Visualización óptima en pantallas de escritorio ($1175\text{px} \times 782\text{px}$) y dispositivos móviles ($\le 480\text{px}$).
  - Exportación nítida en PNG vía `html2canvas` (con Web Share API) y guardado en PDF vía `window.print()`.

---

## 5. Evidencia Visual y Arquitectura

- **Documentación Técnica Maestra**:
  - Publicación del documento formal [`srs-constancias-platicas.md`](../../technical/srs-constancias-platicas.md) bajo estándares ISO/IEC/IEEE 29148:2018 e ISO/IEC/IEEE 42010:2022.
  - Diagrama de secuencia de registro, tokenización y renderizado autocontenido en Mermaid.
  - Matriz comparativa de desacoplamiento entre constancias de Estudiantes, Voluntarios y Comunidad.

---

## 6. Estado Actual del Proyecto

| Módulo / Componente | Estado | Verificación |
|---|---|---|
| Motor de Constancias Criptográficas | Homologado | Verificación matemática AES-256-GCM activa |
| Píldoras de Folio `<app-folio-pill>` | Operativo | Integrado en todas las vistas administrativas |
| Formulario Público de Pláticas | En Producción | Protegido con Cloudflare Turnstile |
| Documentación Técnica SRS | Aprobada | Disponible en portal Zensical (`/technical/srs-constancias-platicas`) |

---

## 7. Próximos Pasos

1. Validación final de impresión y exportación en navegadores Safari, Chrome y Firefox en entornos móviles iOS/Android.
2. Preparación del cierre del proyecto y reporte final No. 8 (25 de noviembre de 2026).
