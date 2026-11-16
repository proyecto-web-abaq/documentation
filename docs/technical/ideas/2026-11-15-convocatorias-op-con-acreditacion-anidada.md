# Convocatorias OP con Acreditación Anidada

!!! warning "Estado: Propuesta pendiente de validación"
    Rama: `dev-rivers2-(feat)-actividad-acreditacion-anidada` (frontend, backend y documentación). No se ha modificado código.

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
4. La regla de horas de eventos no coincide con el reglamento: el código da **× 4** a "Limpieza de refugio", y el reglamento indica **2×1 para todo Evento ABAQ, incluido el apoyo en refugios**.

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

Según lo acordado con ABAQ: **Campaña de esterilización**, **Apoyo a refugio (paseo o limpieza)**, **Módulo de adopción**, **Plática de bienestar animal** y **Otro** (se detalla en las indicaciones).

### 2.3 Regla de horas (reglamento)

- **Evento ABAQ (cualquier categoría):** horas acreditadas = **duración × 2** (2×1 por hora de participación). La duración se calcula **en el servidor** a partir del horario de la convocatoria (`startTime`–`endTime`).
- **Servicio Social:** el valor sugerido es `duración × 2`, limitado a las horas pendientes del estudiante. Al validar, la coordinación puede **ajustarlo** dentro de `0 … tope` (por ejemplo, si el voluntario llegó tarde o se retiró antes), además de calificar y comentar.
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

## 6. Decisiones a validar

1. **Modelo:** ¿opción A (acreditación con `activityRef`)? *Recomendada.*
2. **Folios:** convocatoria `OP-EVE-…` y una acreditación `OP-EVE-…` propia por inscrito, ligadas por `activityRef`. ¿De acuerdo?
3. **Evento ABAQ individual:** ¿se conserva la opción 1 de "Registrar participación" para eventos no publicados (marchas, apoyos imprevistos)? *Recomendado conservarla para excepciones.*
4. **Refugio:** ¿se aplica el reglamento (× 2) en lugar del × 4 actual para registros nuevos?
5. **Ajuste de horas:** ¿el admin puede subir las horas por encima de `duración × 2` (hasta el tope de horas pendientes) o solo bajarlas?
6. **Históricos `AC`:** ¿se conservan como solo lectura (recomendado) o se renombran a `OP`?

## 7. Plan de implementación (tras validación)

1. **Backend · seguridad (S-1 a S-4):** primero, porque cierra riesgos actuales.
2. **Backend · modelo:** `eventCategory`, estado `cancelled`, índices, folio `OP-EVE` en publicación, cálculo de duración en el servidor.
3. **Backend · flujo:** inscripción crea la acreditación (S-5 atómico); evaluación sobre la acreditación; una sola vía de suma de horas; cancelación.
4. **Script de migración** con `--dry-run`, probado sobre `MongoDB-GZwo` (desarrollo).
5. **Frontend:** selector de categoría en plantillas, tabla de evaluación sobre acreditaciones, Participación unificada, folios `OP`.
6. **Pruebas:** unitarias de reglas de horas y permisos; e2e de inscripción concurrente, IDOR y doble conteo; build y pruebas del frontend.
7. **Despliegue en desarrollo** (`dev-rivers2`) para validación con ABAQ antes de producción.
