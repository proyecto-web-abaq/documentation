---
title: "Guía: tareas programadas (cron) en Railway"
icon: lucide/alarm-clock
---

# Guía: tareas programadas (cron) en Railway

| Campo | Valor |
|---|---|
| Fecha | 17/11/2026 |
| Decisiones | ADR-37, ADR-38, ADR-40 y ADR-41 en [Arquitectura](../architecture.md) · [SRS §29, §30 y §33](../srs.md) |
| Tareas | Resumen semanal por correo · Recordatorio "es momento de validar" · Reporte semanal de la Coordinación |

Las tareas programadas **no** corren dentro del servidor web. Cada una es un servicio aparte de Railway que arranca a su hora, ejecuta un script del backend y termina. Así no se duplican con varias réplicas ni con reinicios del backend. La prueba `no-twelve-month-or-cron` prohíbe usar `node-cron` en `app.js`.

| Servicio de Railway | Script (`backend/`) | Cron (UTC) | Hora en Querétaro | Envía correo |
|---|---|---|---|---|
| `weekly-digest` | `node scripts/send-weekly-digest.js` | `0 9,13 * * 0,1` | Domingo y lunes 3:00 (prepara) y 7:00 (envía) | **Sí**, a las 7:00 |
| `validation-reminders` | `node scripts/send-validation-reminders.js` | `*/15 * * * *` | Cada 15 minutos | No (solo campana) |
| `admin-weekly-report` | `node scripts/send-admin-weekly-report.js` | `0 23 * * 0` | Domingo 17:00 | **Sí**, solo a los admins (sin campana) |

!!! warning "El resumen semanal envía correos reales"
    Cada ejecución de `weekly-digest` envía correos a los colaboradores activos de la base a la que apunta. Antes de programarlo en un entorno, haz la simulación de la sección 5 contra esa misma base.

---

## 1. Qué hace cada tarea

### 1.1 Resumen semanal (`weekly-digest`): cola en dos tiempos

El mismo comando corre a las 3:00 y a las 7:00 de Querétaro; el script decide qué hacer por la hora (o se fuerza con `--prepare` / `--send`).

**3:00, preparar (madrugada):**

1. Calcula la semana: el domingo anticipa la semana que empieza el lunes; el lunes usa la semana en curso.
2. Valida destinatarios: estudiantes SS y voluntarios con expediente **activo** en ese momento.
3. Reparte mitad y mitad entre quienes tienen correo: el domingo `ceil(N/2)` y el lunes el resto.
4. Arma cada correo y lo deja en cola en `WeeklyDigestDelivery` (`status: queued`, con asunto, HTML, texto y el aviso de campana). No envía ni consume cuota.

**7:00, enviar:**

1. Prepara lo que falte (por si la ejecución de las 3:00 no corrió).
2. Calcula el cupo del día: `RESEND_DAILY_LIMIT − enviados hoy − EMAIL_TRANSACTIONAL_RESERVE`. Los enviados hoy salen de `EmailUsage`, que suma todo correo del sistema, incluidas las constancias de pláticas.
3. Reclama cada entrada de la cola (`queued → sending`) y envía con la API batch de Resend (100 por petición, 600 ms entre peticiones). Al enviar, crea el aviso de campana y borra el contenido guardado.

Sin cupo, el domingo deja la entrada en cola para el lunes; el lunes la entrega **solo en la campana**. Un envío fallido queda en `failed` y vuelve a la cola en la siguiente preparación. Las cuentas de dominios de prueba (`.local`, `.test`, `.example`) nunca reciben correo, solo campana.

**Contenido:**

- Arriba, lo que viene esta semana: todas las convocatorias de la semana en una sola lista, con día, fecha, hora y horas que acredita (SS). No separa inscripciones: para que la preparación de las 3:00 del domingo las recoja, el admin publica a más tardar el sábado en la tarde o el domingo temprano.
- Abajo, lo que hizo la semana pasada: fecha y hora de la actividad, validada / no validada / pendiente, horas asignadas (SS) y fecha de validación.
- No incluye la bitácora de horas.

Registros de cada fase:

```text
🗂️  Resumen semanal 2026-11-23 (domingo) preparado: en cola por correo 42 · solo campana 3 · sin contenido 1 · para la siguiente ejecución 41 · ya procesados 0
📬 Resumen semanal 2026-11-23 (domingo) enviado: correos 42 (disponible hoy 80) · fallidos 0 · solo campana 3 (sin cupo 0) · en cola para el lunes 0
```

### 1.2 Recordatorio de validación (`validation-reminders`)

1. Busca las convocatorias terminadas en los últimos 7 días que aún no se revisaron (`validationReminderAt` vacío).
2. Una convocatoria termina el día de `dueDate` (o `startDate`) a su `endTime` en hora de Querétaro; sin `endTime`, a las 23:59.
3. Si tiene inscripciones **pendientes de evaluar**, envía a cada admin el aviso "Es momento de validar: …" con el número de inscripciones. Si no tiene, solo la marca como revisada.
4. Cada convocatoria se reclama una sola vez, de forma atómica; volver a ejecutar no duplica avisos.

Al terminar imprime:

```text
⏰ Convocatorias por validar: revisadas 3 · avisadas 1 · sin pendientes 2 · aún no terminan 0
```

### 1.3 Reporte semanal de la Coordinación (`admin-weekly-report`)

1. El domingo a las 17:00 resume la **semana en curso, de lunes a domingo** (hora de Querétaro).
2. Arma un solo correo con cifras agregadas, sin nombres ni datos de contacto de colaboradores:
    - Indicadores: convocatorias, inscripciones, horas SS acreditadas y pendientes por evaluar.
    - Tabla por grupo, **Servicio Social** (estudiantes y voluntarios SS) frente a **Voluntariado General**: activos, nuevos registros, inscripciones, asistencias, validadas, faltas, por evaluar, vinculaciones solicitadas, aprobadas y rechazadas, solicitudes pendientes, horas y desempeño promedio.
    - Rendimiento de cada convocatoria de la semana: folio, fecha y hora, inscritos frente a cupo, porcentaje de asistencia, validadas, faltas, por evaluar, horas otorgadas y desempeño promedio.
3. Lo envía a cada usuario admin con correo real. **Solo correo**: no crea aviso en la campana.
4. Cada admin lo recibe una vez por semana (`weeklydigestdeliveries` con `weekKey` `admin-AAAA-MM-DD`). Si no hay cupo ese día, no lo envía y lo reporta como "sin cupo".

Al terminar imprime:

```text
📊 Reporte admin admin-2026-11-16: enviados 2 · fallidos 0 · ya enviados 0 · sin cupo 0
```

---

## 2. Horario: Railway usa UTC

Los cron de Railway se programan en **UTC** y dos ejecuciones deben estar separadas al menos 5 minutos. Querétaro está en UTC−6 todo el año (México eliminó el horario de verano en 2022).

| Hora deseada en Querétaro | Expresión cron (UTC) |
|---|---|
| Domingo y lunes 3:00 y 7:00 (resumen: preparar y enviar) | `0 9,13 * * 0,1` |
| Domingo y lunes 7:00 | `0 13 * * 0,1` |
| Domingo y lunes 6:30 | `30 12 * * 0,1` |
| Domingo y lunes 9:00 | `0 15 * * 0,1` |
| Domingo 17:00 (reporte de la Coordinación) | `0 23 * * 0` |
| Cada 15 minutos | `*/15 * * * *` |
| Cada 30 minutos | `*/30 * * * *` |

Campos: `minuto hora día-del-mes mes día-de-la-semana` (0 = domingo, 1 = lunes). A las 13:00 y a las 23:00 UTC sigue siendo el mismo día en Querétaro, así que el día de la semana no cambia. Si mueves el reporte después de las 18:00 de Querétaro (00:00 UTC), el día en UTC pasa a lunes: usa `1` en el último campo.

---

## 3. Crear un servicio cron

La configuración como código (`railway.json` / `railway.toml`) está **obsoleta** en Railway: los servicios nuevos ya no pueden usarla y los existentes dejan de leerla el 01/12/2026. Por eso los cron se configuran desde el panel.

Repite estos pasos para cada tarea de la tabla inicial:

1. Abre el proyecto en Railway (`miabaq-abaq` para *development*; `abaq-dev-app` para producción) y selecciona el **entorno** correcto en la parte superior.
2. Elige **+ Create → GitHub Repo** y selecciona el repositorio del backend.
3. Renombra el servicio (**Settings → Service name**) a `weekly-digest`, `validation-reminders` o `admin-weekly-report`. Ese nombre se usa en las variables de referencia y en los registros.
4. En **Settings → Source**, fija la **rama** del entorno: `dev-rivers2` en *development* y `dev` en producción, la misma que el servicio `backend`.
5. En **Settings → Deploy**:
    - **Custom Start Command**: el script de la tabla inicial.
    - **Cron Schedule**: la expresión de la tabla inicial.
    - **Restart Policy**: `Never`. Si una ejecución falla, no debe reintentarse en bucle; la siguiente ejecución programada (o una manual) reintenta lo pendiente sin duplicar.
6. **Networking:** no generes dominio público; estos servicios no reciben tráfico.
7. Guarda. Railway mostrará el servicio como *Cron* con su próxima ejecución.

---

## 4. Variables de entorno

Usa **variables de referencia** al servicio `backend` del mismo entorno para no copiar secretos y para que una rotación se propague sola. En **Variables → New Variable**:

| Variable | Valor | `weekly-digest` y `admin-weekly-report` | `validation-reminders` | Para qué |
|---|---|---|---|---|
| `MONGODB_URI` | `${{backend.MONGODB_URI}}` | Sí | Sí | Conexión. **La base sale de la ruta del URI**: con esta variable los scripts ignoran `--db` y `TARGET_DB`. |
| `resend` | `${{backend.resend}}` | Sí | — | Llave de la API de Resend (el código también acepta `RESEND_API_KEY`). |
| `EMAIL_FROM` | `${{backend.EMAIL_FROM}}` | Sí | — | Remitente (dominio verificado en Resend). |
| `FRONTEND_URL` | URL pública del frontend del entorno | Sí | — | Enlaces del correo ("Ver convocatorias"). Sin ella, el script intenta deducirla de las variables de Railway. |
| `RESEND_DAILY_LIMIT` | `100` (opcional) | Sí | — | Cuota diaria del plan de Resend. Súbela si cambias de plan. |
| `EMAIL_TRANSACTIONAL_RESERVE` | `20` (opcional) | Sí | — | Correos que se dejan libres para aceptaciones, constancias, etc. del resto del día. |

!!! danger "Misma base que el backend"
    Si `MONGODB_URI` de un cron apunta a otra base, trabaja con datos equivocados y el contador `EmailUsage` no ve los correos del backend. Usa siempre `${{backend.MONGODB_URI}}` del **mismo entorno**.

Nunca pegues valores de secretos en tickets, chats ni en esta documentación.

---

## 5. Probar antes de programar

### 5.1 Simulación local contra la base del entorno (sin escribir)

Desde `backend/`, con el URI del entorno en la variable (sin imprimirlo):

```bash
# Resumen semanal: qué prepararía ahora (destinatarios y contenido); --preview guarda el HTML de cada correo
MONGODB_URI="<uri del entorno>" node scripts/send-weekly-digest.js --dry --preview ./preview-resumen

# Recordatorio: cuántas convocatorias avisaría ahora
MONGODB_URI="<uri del entorno>" node scripts/send-validation-reminders.js --dry

# Reporte de la Coordinación: a cuántos admins enviaría; --preview guarda el HTML
MONGODB_URI="<uri del entorno>" node scripts/send-admin-weekly-report.js --dry --preview ./reporte-admin.html
```

`--dry` calcula y reporta **sin escribir ni enviar**. Para la base de *development*, el URI público se obtiene con la CLI de Railway desde una carpeta vinculada (`railway link`), sustituyendo el host interno por el proxy TCP de `MongoDB-GZwo`.

### 5.2 Envío de prueba a un solo correo

Para revisar cómo se ve el correo sin tocar a los destinatarios reales:

```bash
node scripts/send-weekly-digest.js --to tu-correo@dominio.mx
```

- Arma el resumen de la semana con las convocatorias reales y un destinatario de muestra ("Prueba ABAQ"), sin datos personales de nadie.
- Asunto con prefijo `[Prueba]`.
- No escribe en `weeklydigestdeliveries` ni crea avisos: el envío programado del domingo y lunes no cambia.
- Sí suma en `emailusages` y no envía si no hay cupo ese día.

Para el reporte de la Coordinación: `node scripts/send-admin-weekly-report.js --to tu-correo@dominio.mx`. Envía las cifras reales de la semana en curso con asunto `[Prueba]` y no registra la entrega, así que el envío del domingo no cambia.

!!! warning "Ejecutarlo desde la laptop"
    `scripts/helpers/db-connection.js` recarga `backend/.env` con `override: true`, que **pisa** las variables que pases en la línea de comandos (incluidas la base y la llave de Resend). Para apuntar a un entorno de Railway desde la laptop, ejecútalo en el propio servicio (`railway cron run` / `railway ssh`) o en una carpeta sin `.env`. Dentro de Railway no hay `.env` y se usan las variables del servicio.

### 5.3 Ejecución manual en Railway

Con la CLI vinculada al proyecto, al entorno y al servicio cron:

```bash
railway cron run      # dispara el cron ahora (pide confirmación)
railway cron list     # ejecuciones recientes y su estado
railway logs          # salida de la ejecución
```

También puedes dispararlo y revisarlo desde el panel del servicio. Repetir una ejecución es seguro: el resumen no reenvía a quien ya se procesó esa semana y el recordatorio no repite convocatorias avisadas. **`weekly-digest` y `admin-weekly-report` envían correos reales.**

---

## 6. Verificar que funcionó

| Tarea | Registros | Base de datos | Campana |
|---|---|---|---|
| `weekly-digest` | Línea `📬 Resumen semanal …`; `❌ Resumen semanal fallido` indica error de conexión o configuración (código de salida 1) | `weeklydigestdeliveries`: un documento por persona y semana (`sent`, `in_app_only`, `skipped_empty` o `failed`). `emailusages`: el contador del día (UTC) aumentó | Aviso "Resumen semanal" para cada destinatario |
| `validation-reminders` | Línea `⏰ Convocatorias por validar …` | `activities.validationReminderAt` con la hora de revisión | Aviso "Es momento de validar: …" para cada admin |

En el panel de Resend aparecen los envíos del lote del resumen.

---

## 7. Solución de problemas

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| El cron no corrió a la hora | La ejecución anterior sigue **Active**: Railway omite la nueva mientras otra está en curso | Revisa los registros de la anterior. Los scripts cierran la conexión a MongoDB al terminar; si quedó colgado, detén ese despliegue. |
| Corrió a otra hora | Expresión pensada en hora local | Convierte a UTC (sección 2). |
| Resumen: `en cola para el lunes N` el domingo | Cupo agotado (constancias u otros correos ese día) | Normal: se envían el lunes. Revisa `emailusages` del día. |
| Resumen: a las 7:00 no salió nada y hay entradas `queued` | Falló la ejecución de las 7:00 | `railway cron run` o `node scripts/send-weekly-digest.js --send`. |
| Resumen: `solo campana … (sin cupo N)` el lunes | Cupo insuficiente | Normal: lo reciben en la campana. Si pasa seguido, sube `RESEND_DAILY_LIMIT` (plan de Resend) o baja la reserva. |
| Resumen: `fallidos N` | Error de Resend (429, dominio, llave) | Corrige la causa; el siguiente `railway cron run` reintenta solo los fallidos sin duplicar. |
| Recordatorio: no avisa una convocatoria terminada | No tiene inscripciones pendientes, terminó hace más de 7 días o su `endTime` es posterior | Revisa `validationReminderAt` y la fecha/hora de la convocatoria. |
| Enlaces del correo a otra URL | Falta `FRONTEND_URL` | Defínela en `weekly-digest`. |
| Datos de otro entorno | `MONGODB_URI` incorrecto | Usa `${{backend.MONGODB_URI}}` del mismo entorno. |

---

## 8. Cambiar el horario, pausar o retirar

- **Cambiar horario:** edita **Settings → Deploy → Cron Schedule** (sección 2). No requiere cambios de código.
- **Solo una fase a mano:** `node scripts/send-weekly-digest.js --prepare` o `--send`.
- **Pausar:** borra la expresión de *Cron Schedule*; el servicio deja de ejecutarse hasta que la vuelvas a poner.
- **Retirar:** elimina el servicio. Los datos (`weeklydigestdeliveries`, `emailusages`, `validationReminderAt`) permanecen y se respaldan con el resto de la base.

---

## 9. Lista de verificación por entorno

- [ ] Simulaciones `--dry` de ambos scripts contra la base del entorno revisadas (sección 5.1).
- [ ] `weekly-digest`: rama, comando, `0 9,13 * * 0,1`, reinicio `Never`, variables de la sección 4.
- [ ] `validation-reminders`: rama, comando, `*/15 * * * *`, reinicio `Never`, `MONGODB_URI` por referencia.
- [ ] `admin-weekly-report`: rama, comando, `0 23 * * 0`, reinicio `Never`, variables de la sección 4.
- [ ] Sin dominio público en ninguno.
- [ ] Primeras ejecuciones revisadas en registros, base de datos y campana (sección 6).
- [ ] Producción solo con autorización explícita y después de validarlo en *development*.
