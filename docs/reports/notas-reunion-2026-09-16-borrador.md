# Notas de Reunión — 16 de septiembre de 2026 (Borrador)

**Fecha:** 16 sept 2026, 13:59 CST
**Participantes:** Johan Del Ángel González, Fernando Israel Rios Garcia
**Estado:** Borrador — pendiente de revisión y validación con Brandon y la administración (Marlen / Lucy)

> [!NOTE]

> **Links**
>
>- Notas de la reunion: https://docs.google.com/document/d/1UZCTOz0R5ng-gmM_NL5swKIBMe18R2l6FK9_isYOLZA/edit?usp=sharing
>
>- Video de la reunion: https://drive.google.com/file/d/1GWaJlIUrifa6V6GVkC-tPPj5mWBtYlju/view?usp=sharing



---

## Resumen

Revisión técnica de procesos estudiantiles y optimización de la infraestructura de datos para mejorar la eficiencia operativa del sistema de servicio social.

- **Optimización del flujo estudiantil:** Definición del proceso de registro mediante correo institucional y validación de onboarding. La estructura integra una fase de verificación antes del acceso completo al sistema.
- **Estrategia de almacenamiento eficiente:** Se evita el almacenamiento de archivos pesados en el servidor; se usan datos estructurados en formato JSON y se generan los documentos bajo demanda para optimizar memoria y costos.
- **Interfaz administrativa y validación:** Modales de acción rápida para la gestión administrativa. La validación de asistencias se realiza fuera de la base de datos central (vía WhatsApp) para evitar su saturación.

---

## Decisiones acordadas

1. **Modelo de almacenamiento basado en JSON.** El sistema no almacenará archivos PDF directamente en el servidor; guardará la información estructurada en JSON y generará los documentos mediante scripts bajo demanda.
2. **Integración de campañas en el módulo de actividades.** No se crea una sección de menú separada para campañas; se categorizan dentro del módulo de actividades del servicio (posible renombre de la sección a "acciones" o "qué hacer").
3. **Uso de WhatsApp para el registro de asistencias.** Las y los estudiantes envían sus fotografías de asistencia al grupo de WhatsApp, evitando sobrecargar el almacenamiento del servidor con imágenes. Marlen valida las horas directamente en esa aplicación.
4. **Validación administrativa previa para cuentas nuevas.** Las cuentas recién creadas permanecen en estado *pendiente* hasta que un administrador verifique los datos y autorice el acceso al portal.

---

## Flujo de usuario propuesto (por etapas)

> Este flujo digitaliza y reemplaza el proceso en papel descrito en el *Reglamento de voluntarios ABAQ* (6 mayo 2026): inducción en PDF + envío de documentos + firma autógrafa en tinta azul. La interfaz sustituye la presentación y la firma, **pero conserva la obligación de que la persona lea, comprenda y acepte el reglamento y confirme haber realizado todo lo requerido.** El reglamento marca un plazo máximo de **5 días** para completar inducción y documentos.

### Fase 1 — Creación de cuenta y datos personales

- **1.1 Creación de cuenta.** Registro con **correo electrónico institucional** como identificador único de acceso, más contraseña.
- **1.2 Datos personales y de contacto.** Nombre completo, teléfono celular, correo, fecha de presentación. Redes sociales que maneja y seguimiento a los canales oficiales de ABAQ (Facebook, Instagram, LinkedIn, TikTok, Twitter y página web).
- **1.3 Información académica (servicio social).** Institución/escuela, carrera, grado escolar / semestre, matrícula y **periodo de servicio social** (fecha de arranque y de conclusión). Enfatizar en el formulario que es el periodo en el que se colabora con ABAQ, **no** el periodo de graduación.

### Fase 2 — Onboarding / inducción (acredita las primeras 10 horas)

Reemplaza la "presentación en PDF" de inducción. Por cada punto, la persona registra: **qué le gustó, qué considera lo más importante y qué puede mejorar** (en el mismo orden del reglamento):

- **2.1 Conociendo ABAQ** — página web y redes sociales (dar seguir en cada una).
- **2.2 Plática de Bienestar Animal ABAQ** (Canva).
- **2.3 Arquetipos de marca** — identificando el elegido por ABAQ: *El Inocente*.
- **2.4 Entrenamiento DISC.**
- **2.5 Entrenamiento Generaciones.**
- **2.6 La neurociencia de las emociones** (Marian Rojas Estapé).
- **2.7 "Sobre mí"** — perfil personal: talentos y cuáles puede compartir con ABAQ, experiencia con animales de compañía, por qué desea participar y en qué actividades le gustaría colaborar (en orden de prioridad).

> Al completar la Fase 2, el sistema acredita **10 horas** (validez de la inducción según el reglamento).

### Fase 3 — Documentos requeridos

- **3.1 INE vigente.**
- **3.2 Curriculum Vitae.**
- Envío/carga conforme a la política de almacenamiento (ver *Consideraciones técnicas*: preferir datos estructurados o enlace externo; el reglamento firmado se sustituye por la aceptación digital de la Fase 4).

### Fase 4 — Lectura, comprensión y aceptación del reglamento

Sustituye la firma autógrafa en tinta azul al borde de cada página. La interfaz debe garantizar lectura comprensiva y consentimiento explícito:

- **4.1 Lectura del reglamento** dentro de la plataforma (agradecimiento, actividades y tabla de horas, inducción, y **Convenio de colaboración en materia de servicio social**, incisos a–h: temporalidad, obligaciones, confidencialidad, conducta, retroalimentación mensual y devolución de recursos).
- **4.2 Aceptación explícita mediante casillas de verificación**, con constancia de que la persona:
  - ha **leído y comprendido** el reglamento y el convenio;
  - **acepta cumplir** las obligaciones y condiciones;
  - **confirma haber realizado** todo lo requerido en las Fases 1–3 (inducción y documentos).
- **4.3 Registro de la aceptación** (fecha, nombre y correo institucional) como equivalente digital de la firma; se conserva en JSON, no como PDF.

### Fase 5 — Estado pendiente y validación administrativa

- Tras enviar la información, la persona usuaria ve un estado de **"cuenta pendiente / en corroboración"**, informando que un administrador valida los datos y que revise la plataforma en **24–48 horas**.
- Una vez validado por la administración (Marlen), se autoriza el acceso completo al portal y se habilita el registro de actividades.

---

## Documentos del expediente del estudiante

| # | Documento | Notas |
|---|-----------|-------|
| 1 | Carta de aceptación | Emitida por Lucy |
| 2 | Constancia de introducción / onboarding | Antes "constancia de plática"; corresponde a las primeras 10 horas por videos introductorios |
| 3 | Certificado de término | Genera también carta de término (fácil de generar) |
| 4 | Reporte de actividades | Garantía para el voluntario y la administración ante discrepancias de horas. **No presentarlo así a Marlen** para evitar rechazo |

> Nota técnica: los documentos se almacenan como JSON; los PDF se generan bajo demanda mediante scripts en el backend cuando el cliente los descarga. Nunca se guardan PDF ni archivos comprimidos (.zip) en el servidor.

---

## Consideraciones técnicas

- **Almacenamiento:** Guardar PDFs directamente colapsaría la memoria del servidor (~500 MB) con cientos de voluntarios y elevaría costos, con riesgo de que la administración pause el proyecto. Solución: JSON + generación de PDF bajo demanda.
- **Imágenes / diseños personalizados:** Se solicita un **enlace externo** (p. ej. Google Drive) en lugar de cargar archivos al servidor. Advertir sobre la vigencia de los enlaces.
- **Interfaz de inicio de sesión:** Reorganizar los campos del formulario actual (de Félix). El correo institucional debe ser la prioridad visual como identificador de acceso; corregir el problema de compatibilidad con gestores de contraseñas.
- **Modales de acción rápida (vista administrativa):** Contenedores interactivos para que Marlen copie fácilmente teléfono y correo de los estudiantes sin salir de la sección de validación de actividades.
- **Registros de prueba:** Durante las pruebas con Type Form se eliminó por error el usuario administrador y se crearon múltiples registros innecesarios; depurar.

---

## Próximos pasos

### Johan Del Ángel González
- [ ] Documentar el flujo de usuario: diagramas de flujo y pasos desde el registro hasta el término del servicio.
- [ ] Implementar el formulario de registro y perfil (incluye videos de inducción y aceptación del reglamento mediante casillas de verificación en la interfaz, en sustitución de la firma autógrafa).
- [ ] Implementar modal de contacto (acción rápida para copiar teléfono/correo del estudiante).
- [ ] Optimizar el almacenamiento de documentos: scripts que generen PDF a partir de JSON, sin guardar PDFs en el servidor.
- [ ] Reorganizar campos de inicio de sesión (correo institucional y contraseña; identificador académico como prioridad visual).
- [ ] Consultar con Brandon la propuesta del nuevo flujo de usuario y la gestión de archivos PDF.
- [ ] Consultar requerimientos con Marlen para definir con exactitud los documentos necesarios y estandarizar la documentación.
- [ ] Asignar 2 o 3 tareas prácticas de programación a Fernando.

### Fernando Israel Rios Garcia
- [x] Enviar la documentación de requisitos: reglamento, requerimientos de registro y el PDF con la información necesaria.
- [x] Enviar las notas estructuradas (propuestas de flujo y menú) y compartir el documento resultante con Johan.

---

*Borrador generado a partir de las notas de la reunión (Notes by Gemini). Verificar precisión antes de distribuir.*
