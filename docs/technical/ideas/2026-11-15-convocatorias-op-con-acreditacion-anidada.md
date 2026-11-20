---
title: "Convocatorias OP con Acreditación Anidada (2026-11-15)"
date: 2026-11-15
icon: lucide/circle-check
---
# Convocatorias OP con Acreditación Anidada

!!! success "Estado: Validada e implementada en rama de feature"
    Rama: `dev-rivers2-(feat)-actividad-acreditacion-anidada` (frontend, backend y documentación). Decisiones validadas el 15/11/2026 (§6); implementación descrita en §8. Pendiente: migración de la base de desarrollo y despliegue.

| Campo | Valor |
|---|---|
| Fecha | 15/11/2026 |
| Origen | Reunión con ABAQ del 15/11/2026: actividades y participaciones se perciben duplicadas, implican retrabajo y su distinción es difícil de entender. |
| Fuente de reglas | Reglamento de Voluntarios ABAQ, §2 "Actividades y Horas Acreditables" (`/reglamento`, `reglamento-voluntarios-abaq.pdf`). |
| Alcance | Actividades grupales, participaciones individuales, folios, evaluación, horas de Servicio Social y seguridad del flujo. |

## 1. Problema

Hoy existen dos conceptos paralelos:

- **Actividad grupal** (`Activity`, folio `AC-…`): la coordinación la publica, los voluntarios se inscriben y la coordinación valida asistencia y horas desde `assignedActivities` de cada expediente.
- **Participación individual** (`Accreditation`, folio `OP-CAT-…`): el voluntario la registra y la coordinación la aprueba o rechaza.

Consecuencias observadas:

1. Para el voluntario y la coordinación son "lo mismo dos veces": asistir a un evento puede quedar como actividad **y** como participación.
2. Las horas se suman al expediente por **dos caminos** (`updateParticipationStatus` y `approveAccreditation`), con riesgo de doble conteo y reglas distintas.
3. Desempeño y comentarios viven en dos estructuras diferentes.
4. El reglamento indica 2×1 para los Eventos ABAQ; ABAQ confirmó que la **limpieza de refugio acredita × 4** (regla institucional vigente), y el resto de categorías × 2.

## 2. Solución propuesta

> **Todo es una oportunidad (`OP`).** Una plantilla publicada es una **convocatoria `OP`** de categoría Evento, y cada inscripción crea automáticamente la **acreditación `OP` anidada** del voluntario. Ya no hay actividades genéricas `AC`.

### 2.1 Conceptos

| Concepto | Qué es | Folio |
|---|---|---|
| **Plantilla** (`QuickActivity`) | Datos reutilizables: título, descripción, **categoría de evento**, horario y cupo. | — |
| **Convocatoria** (`Activity` publicada) | Plantilla publicada con fecha. Es la "oportunidad" a la que se inscriben. | `OP-EVE-YYMMDD-HEX` |
| **Acreditación anidada** (`Accreditation` con `activityRef`) | Registro individual de cada inscrito: asistencia, desempeño, comentarios y horas. | `OP-EVE-YYMMDD-HEX` propio |
| **Vinculación** (`Accreditation` sin `activityRef`) | Lo que el voluntario consigue por su cuenta (placas, adopción, módulo, plática, medios, redes, recaudación, apoyo administrativo). | `OP-<CAT>-YYMMDD-HEX` |

### 2.2 Categorías de evento (definidas en la plantilla)

| Código | Categoría | Multiplicador |
|---|---|---|
| `STERILIZATION_CAMPAIGN` | Campaña de esterilización | × 2 |
| `SHELTER_WALK` | Apoyo a refugio · Paseo | × 2 |
| `SHELTER_CLEANING` | Apoyo a refugio · Limpieza | **× 4** |
| `ADOPTION_MODULE` | Módulo de adopción | × 2 |
| `TALK` | Plática de bienestar animal | × 2 |
| `OTHER` | Otro evento ABAQ | × 2 |
| `GENERAL` | Evento ABAQ (registros previos, no seleccionable) | × 2 |

### 2.3 Regla de horas (reglamento)

- **Evento ABAQ:** horas acreditadas = **duración × multiplicador de la categoría** (× 4 limpieza de refugio, × 2 el resto). La duración se calcula **en el servidor** a partir del horario de la convocatoria (`startTime`–`endTime`).
- **Servicio Social:** el valor sugerido es `duración × multiplicador`, limitado a las horas pendientes del estudiante. Al validar, la coordinación puede **sobrescribirlo** (clic en el campo selecciona el valor) hasta las horas pendientes del estudiante, además de calificar y comentar.
- **Voluntariado General:** no acumula horas; se registran asistencia, desempeño y comentarios, como hoy. Su modal no muestra horas.
- **Vinculaciones:** sin cambios; conservan sus horas fijas del reglamento (5, 10, 100, 40, 50, 30 h, 5 + 1/5 reacciones, 1 h por $50).

### 2.4 Flujo

```text
Coordinación                     Voluntario                         Coordinación
────────────                     ──────────                         ────────────
Plantilla (categoría, horario)
   │ publicar con fecha
   ▼
Convocatoria OP-EVE-…  ──────►  Se inscribe
                                   │ (servidor, atómico)
                                   ▼
                           Acreditación OP-EVE-… (pendiente)
                           horas sugeridas = duración × 2 (SS)
                                   │
                                   ▼                         Validar (asistió) → aprobada
                           Aparece en Participación  ──────► · horas (editable ≤ tope, SS)
                           y en su agenda                    · desempeño + comentario
                                                             No asistió → rechazada (0 h)
                                                             · desempeño + motivo obligatorio
```

- **Cancelar inscripción:** la acreditación pasa a `cancelled` (se conserva para auditoría) y libera el cupo.
- **Una sola vía para sumar horas:** la aprobación de la acreditación. Se retira la suma desde `updateParticipationStatus`.

### 2.5 Modelo de datos (recomendación: referencia, no copia completa)

| Opción | Ventaja | Riesgo |
|---|---|---|
| **A. Acreditación con `activityRef`** (recomendada) | Una sola fuente de verdad; la lista de participantes es `Accreditation.find({ activityRef })` con índice; la convocatoria no crece sin límite. | Requiere índice y consulta adicional. |
| B. Acreditación completa embebida en la convocatoria | Lectura en un solo documento. | Duplica datos; el documento crece con cada inscrito (límite de 16 MB); contención de escrituras al evaluar en paralelo. |

Con la opción A, el expediente conserva su resumen embebido actual (`accreditations[]` con folio, tipo, estado y horas) como **instantánea de solo lectura**, y `assignedActivities[]` deja de usarse para registros nuevos.

Campos nuevos o ajustados:

- `QuickActivity` y `Activity`: `eventCategory` (enum de §2.2); `durationMinutes` calculado en el servidor.
- `Activity`: `interactionFolio` con formato `OP-EVE-…` para registros nuevos.
- `Accreditation`: `eventCategory`; `status` admite `cancelled`; `hoursSuggested` (calculado en el servidor) separado de `hoursAccredited` (final); `evaluatedBy` y `evaluatedAt` para auditoría.
- Índices: únicos parciales `{ activityRef, studentRef }` y `{ activityRef, volunteerRef }` (impiden inscripciones duplicadas) e índice `{ activityRef, status }`.

## 3. Seguridad

Hallazgos en el código actual que este cambio debe cerrar:

| # | Hallazgo | Riesgo | Corrección propuesta |
|---|---|---|---|
| S-1 | `POST /accreditation` solo exige sesión activa y toma `studentRef`/`volunteerRef` del cuerpo. | IDOR: un voluntario puede crear acreditaciones a nombre de otra persona. | Para no-admin, el titular sale **siempre** de `req.user`; solo el admin puede indicar otro titular. |
| S-2 | El mismo endpoint acepta `performance`, `activityRef` y horas manuales del cuerpo. | Asignación masiva: un voluntario puede autocalificarse o vincularse a una convocatoria. | Lista blanca por rol; `performance`, `hoursAccredited`, `status` y `activityRef` solo los fija el servidor o el admin al evaluar. Las acreditaciones de evento **solo** se crean desde la inscripción. |
| S-3 | `GET /accreditation/student/:id` no valida titularidad. | Cualquier usuario autenticado lista las acreditaciones de otro. | Solo admin o el propio titular. |
| S-4 | `DELETE /accreditation/:id` no valida titularidad. | Cualquier usuario borra la acreditación pendiente de otro. | Solo admin o el propio titular, y solo si está pendiente. |
| S-5 | El cupo se valida contando y luego insertando. | Condición de carrera: inscripciones simultáneas pueden exceder el cupo. | Incremento atómico condicionado (`findOneAndUpdate` con `participantCount < maxParticipants` y `$inc`). |
| S-6 | Horas calculadas parcialmente con datos del cliente. | Manipulación de horas. | Duración y horas sugeridas calculadas en el servidor; el ajuste del admin se acota a `0 … tope` y queda auditado (`evaluatedBy`, valor sugerido frente a final). |

Controles adicionales:

- **Integridad sin transacciones:** si la base de Railway no es réplica, se crea primero la acreditación (protegida por el índice único) y luego se reserva el cupo, con compensación (borrado) si falla el segundo paso. Si es réplica, se usa una transacción de MongoDB.
- **Inmutabilidad:** una acreditación aprobada o rechazada no se modifica (ya existe esa regla para actividades validadas).
- **Validación de entrada:** `ObjectId` válidos, enums de categoría y estado, límites numéricos y `trim` de comentarios.
- **Limitación de frecuencia** en inscripción y registro de vinculaciones (reutiliza el limitador existente).
- **Respaldo y deshidratación:** el registro dinámico de colecciones incluye los campos nuevos; la deshidratación de convocatorias concluidas considera sus acreditaciones.

## 4. Interfaz (reutilizando componentes existentes)

- **Admin · Plantillas:** se agrega el selector "Categoría de evento" (reemplaza al "Tipo de actividad" sin efecto); el valor en horas se sigue calculando del horario y se muestra como "Duración: 4 h → acredita 8 h (SS)".
- **Admin · Detalle de convocatoria:** la tabla de evaluación actual (Validar / No asistió) opera sobre la acreditación anidada; el modal ya tiene horas editables (SS), desempeño y comentarios.
- **Voluntario · Participación:** una sola lista de oportunidades `OP`; desaparecen la distinción y la insignia "Actividad grupal"/"Participación individual". La categoría (Evento · Campaña, Vinculación · Placas…) identifica cada registro. La agenda y el calendario `.ics` siguen funcionando.
- **Registrar participación:** queda para **vinculaciones** (opciones 2–10) y, según se decida, para Evento ABAQ no publicado (ver §6).
- **Folio:** todas las píldoras son `OP` (`.folio-pill-op`); los `AC` históricos se muestran tal cual.

## 5. Migración (con simulación previa)

1. Script con `--dry-run` que reporta, sin escribir, cuántas inscripciones históricas generarían acreditación y con qué estado.
2. Por cada `assignedActivities[]` histórico: crear la acreditación vinculada (`registered`/`attended` → `pending`, `validated` → `approved` con `validatedHours`, `absent` → `rejected`, `cancelled` → `cancelled`), copiando desempeño y comentario. Es idempotente gracias al índice único.
3. **No** se vuelven a sumar horas: los expedientes ya tienen sumadas las validadas; la migración solo crea registros.
4. Las convocatorias y folios `AC` existentes se conservan como históricos de solo lectura; las nuevas nacen `OP-EVE`.

## 6. Decisiones validadas (15/11/2026)

| # | Decisión | Resolución |
|---|---|---|
| 1 | Modelo | La **acreditación (oportunidad) es la fuente de verdad**: ya tiene calificación, comentarios, horas y fecha; solo se agrega la **asistencia**. Referencia por `activityRef`. |
| 2 | Folios | Convocatoria e inscritos usan `OP-EVE` (sub-código ya existente). |
| 3 | Evento ABAQ individual | **Se conserva** (opción 1 de "Registrar vinculación") para eventos no publicados. |
| 4 | Refugio | **× 4** para limpieza de refugio; × 2 el resto. |
| 5 | Ajuste de horas | El admin **sobrescribe** las horas propuestas al validar la asistencia (clic selecciona el campo), con tope en las horas pendientes. |
| 6 | Folios `AC` previos | **Se sobrescriben** (datos de prueba): la migración los convierte a `OP-EVE`. |
| — | Narrativa | "Convocatoria" es lo principal (asistir y ayudar con tu tiempo); "Vinculación" es lo excepcional ("si consigues para ABAQ…"). |

## 7. Plan de implementación (tras validación)

1. **Backend · seguridad (S-1 a S-4):** primero, porque cierra riesgos actuales.
2. **Backend · modelo:** `eventCategory`, estado `cancelled`, índices, folio `OP-EVE` en publicación, cálculo de duración en el servidor.
3. **Backend · flujo:** inscripción crea la acreditación (S-5 atómico); evaluación sobre la acreditación; una sola vía de suma de horas; cancelación.
4. **Script de migración** con `--dry-run`, probado sobre `MongoDB-GZwo` (desarrollo).
5. **Frontend:** selector de categoría en plantillas, tabla de evaluación sobre acreditaciones, Participación unificada, folios `OP`.
6. **Pruebas:** unitarias de reglas de horas y permisos; e2e de inscripción concurrente, IDOR y doble conteo; build y pruebas del frontend.
7. **Despliegue en desarrollo** (`dev-rivers2`) para validación con ABAQ antes de producción.

## 8. Implementación (rama de feature)

### 8.1 Backend

- `utils/accreditationRules.js`: `EVENT_MULTIPLIERS` / `EVENT_TYPES` (catálogo único de categorías).
- `models/accreditation.model.js`: `attendance` (`registered`/`attended`/`absent`/`cancelled`), `hoursSuggested`, `evaluatedBy`, `evaluatedAt`, estado `cancelled`, desempeño `absent` e índices únicos parciales `{ activityRef, studentRef }` / `{ activityRef, volunteerRef }` + `{ activityRef, status }`.
- `models/activity.model.js` y `quickActivity.model.js`: `eventType`; la convocatoria nace con folio `OP-EVE-YYMMDD-HEX`.
- `controllers/activity.controller.js`: inscripción, cancelación, evaluación y participantes operan sobre la acreditación; `assignedActivities[]` queda como **proyección de solo lectura** (con `accreditationId`) que escribe solo el servidor. Rutas del API sin cambios.
- `services/hours.service.js`: **vía única** de suma de horas (`$inc` atómico + conclusión automática a las horas requeridas), usada por convocatorias y vinculaciones.
- `controllers/accreditation.controller.js`: S-1 a S-4 corregidos; las acreditaciones de convocatoria no se aprueban/rechazan/borran por la vía genérica; aprobación con transición atómica `pending → approved`; los listados de vinculaciones excluyen convocatorias (`?include=convocatorias` las agrega).
- `controllers/quickActivity.controller.js`: lista blanca de campos y herencia de `eventType` al publicar.
- Migración: `scripts/migrate-convocatorias-op.js --db <base> [--dry]` (idempotente, no vuelve a sumar horas); el sembrado de ciclo de vida la aplica al final.
- Pruebas: `tests/convocatoria-op.test.js` (17 casos: cupo concurrente, doble validación, IDOR, campos protegidos, migración). Requiere `mongodb-memory-server` como dependencia de desarrollo.

### 8.2 Frontend

- `services/event-categories.ts`: espejo de categorías y multiplicadores para vistas previas.
- Plantillas: selector **Categoría de evento** (reemplaza "Tipo de actividad", que no tenía efecto) y vista previa "Acredita N h de Servicio Social por persona"; la tarjeta muestra la categoría y su multiplicador.
- Detalle de convocatoria: tarjeta "Categoría" y "Duración → acredita"; el modal de evaluación propone las horas del servidor y permite sobrescribirlas.
- Narrativa: Convocatoria / Vinculación en Participación, menú móvil ("Registrar Vinculación", "Nueva Vinculación") y modal de registro.
- `app-folio-pill`: el color sale del prefijo del folio (`OP-`/`AC-`).

