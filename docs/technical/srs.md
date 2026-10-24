# Especificación de Requerimientos de Software (SRS)
**Estándar:** ISO/IEC/IEEE 29148:2018  
**Proyecto:** Plataforma Web ABAQ (Servicio Social, Censo Comunitario y Documentación Pedagógica)  
**Módulos:** Autenticación, Experiencia Typeform, Seguridad, Documentación de Código y Guía de Lectura  
**Versión:** 2.1.0  
**Fecha:** 2026-10-22 (v2.0.0: 2026-09-03)  
**Estado:** Aprobado (v2.0.0) · Propuesta (§7, adiciones v2.1.0)  
**Autores:** Equipo de Ingeniería de Requerimientos ABAQ  

---

## 1. Introducción

### 1.1 Propósito
El propósito de este documento es especificar formalmente los requerimientos del sistema para la plataforma **ABAQ**, integrando:
1. La modernización y aseguramiento de los flujos de autenticación, alta administrativa protegida por clave secreta, compatibilidad con gestores de contraseñas (*password manager autofill*) y navegación por teclado en formularios por lotes (*Typeform-style*).
2. El sistema integral de documentación pedagógica y comentarios en código fuente (JSDoc para Node.js/Express y TSDoc para Angular 22), acompañado de una guía arquitectónica en español con un checklist interactivo modular (`docs/codebase-reading-guide.md`).

### 1.2 Alcance del Sistema
- **Frontend (Angular 22 Standalone)**: Vistas reactivas, componentes standalone, servicios con inyección funcional `inject()`, mappers de dominio/DTO, interceptores y guards de seguridad, dashboards con Chart.js y expediente digital con visor GridFS.
- **Backend (Node.js v24 / Express v4.19 / Mongoose v8.4)**: API RESTful modular, hashing bcrypt con factor 12, emisión y validación de tokens JWT stateless, streaming de archivos binarios mediante MongoDB GridFS, controladores CRUD generados con patrón factory y manejo centralizado de errores.
- **Suite de Documentación y Comentarios Pedagógicos**: Anotación técnica del 100% de los 80 archivos fuente no plantilla del sistema, garantizando cero regresión en tiempo de ejecución (*Zero AST Regression*) y preservación del comportamiento del software en la rama `docs-explanation`.

### 1.3 Definiciones, Acrónimos y Abreviaturas
- **SRS**: *Software Requirements Specification* (Especificación de Requerimientos de Software según ISO/IEC/IEEE 29148:2018).
- **AST**: *Abstract Syntax Tree* (Árbol de Sintaxis Abstracta generado por los parsers de JavaScript/TypeScript).
- **JSDoc**: Estándar de documentación formal mediante comentarios en bloques (`/** ... */`) para JavaScript.
- **TSDoc**: Estándar de documentación de TypeScript compatible con TypeDoc y analizadores semánticos.
- **GridFS**: Especificación y protocolo de MongoDB para almacenar y recuperar archivos que superan el límite de 16MB de documentos BSON mediante fragmentación en colecciones `files` y `chunks`.
- **Typeform UX**: Patrón interactivo de formularios presentado en tarjetas temáticas secuenciales asistidas por navegación de teclado.
- **RBAC**: *Role-Based Access Control* (Control de Acceso Basado en Roles: `admin`, `student` y `volunteer`).
- **SS / VG**: Estudiante de servicio social / Voluntario general.
- **Vinculación**: Oportunidad de ABAQ (plática, campaña de esterilización, adopción o placa de identificación) que genera horas para el estudiante vinculado.
- **DTO**: *Data Transfer Object* (Objeto de Transferencia de Datos).

### 1.4 Referencias Normativas
- **ISO/IEC/IEEE 29148:2018**: Systems and software engineering — Life cycle processes — Requirements engineering.
- **ISO/IEC/IEEE 42010:2022**: Software, systems and enterprise — Architecture description.
- **ISO/IEC/IEEE 12207:2017**: Systems and software engineering — Software life cycle processes.

---

## 2. Requerimientos de Seguridad, Contraseñas y Autenticación

### `[SRS 9.5.11.1 Requerimientos Funcionales - Contraseñas y Seguridad]`
- **RF-SEC-01 (Longitud y Entropía Extendida)**: El sistema debe admitir contraseñas de entre **12 y 128 caracteres**, soportando contraseñas complejas y frases de paso (*passphrases*).
- **RF-SEC-02 (Juego de Caracteres Especiales y Espacios)**: El sistema debe permitir cualquier carácter Unicode válido, espacios en blanco interiores y caracteres especiales (`!@#$%^&*()_+-=[]{}|;:,.<>?~/`).
- **RF-SEC-03 (Sin Truncamiento)**: El backend y el frontend no deben truncar ni modificar la cadena de la contraseña antes de su procesamiento criptográfico.
- **RF-SEC-04 (Registro Administrativo Protegido)**: La creación de cuentas con rol administrativo (`POST /auth/admin/register` y `/auth/admin-signup`) debe requerir obligatoriamente una clave secreta (`adminPasskey`) cotejada contra la variable de entorno `ADMIN_REGISTRATION_SECRET` del servidor.

### `[SRS 9.4.5 Requerimientos No Funcionales - Criptografía y Seguridad]`
- **RNF-SEC-01 (Hashing Criptográfico Robusto)**: Todas las contraseñas deben cifrarse mediante `bcryptjs` con factor de costo 12 (`salt rounds = 12`) previo a su inserción en MongoDB.
- **RNF-SEC-02 (Atributos de Autofill de Seguridad)**: Los campos de entrada de credenciales deben implementar obligatoriamente atributos `autocomplete="username"`, `autocomplete="new-password"` y `autocomplete="current-password"` para compatibilidad total con gestores de contraseñas.
- **RNF-SEC-03 (Exclusión de Contraseña en Consultas)**: El campo de contraseña en el esquema `User` debe configurarse con `select: false` para evitar divulgación involuntaria en respuestas REST.

---

## 3. Requerimientos de Formularios y Experiencia de Usuario (Typeform UX)

### `[SRS 9.5.11.2 Requerimientos Funcionales - Lotes Temáticos de Registro]`
El registro de alumnos (`/auth/signup`) se estructura en 4 lotes temáticos:
- **Lote 01 (Credenciales de Acceso)**: `correoInstitucional` (`autocomplete="username"`), `password` (`autocomplete="new-password"`, mín. 12 caracteres), y `confirmPassword`.
- **Lote 02 (Información Personal)**: `nombreCompleto`, `fechaNacimiento`, `correoPersonal` (con badge informativo de uso secundario), teléfono y redes sociales.
- **Lote 03 (Información Académica)**: `matricula`, `escuela`, `carrera`.
- **Lote 04 (Periodo de Servicio Social)**: `fechaArranque`, `fechaConclusion` (posterior a arranque), `semestre` y `horasMeta` (ej. 480 horas).

### `[SRS 9.5.11.3 Requerimientos Funcionales - Encuestas Comunitarias]`
El formulario de censo animal (`/survey/form/submit` y `FormComponent`) debe agrupar dinámicamente las preguntas en tarjetas temáticas y construir subsecciones dinámicas para mascotas registradas mediante `FormArray`.

### `[SRS 9.4.3 Requerimientos No Funcionales - Usabilidad e Interacción]`
- **RNF-UX-01 (Navegación por Teclado Permanente)**:
  - `Enter`: Valida los campos requeridos del lote actual y avanza a la siguiente tarjeta. En caso de error, resalta el campo con fallo y coloca el foco en él.
  - `Shift + Enter` / `Esc`: Retrocede a la tarjeta previa preservando el estado de todos los datos introducidos.
  - `Tab` / `Flechas`: Permite ciclar y seleccionar opciones de radio y campos sin necesidad de ratón.
- **RNF-UX-02 (Barra de Progreso Dinámica)**: Indicador visual continuo con porcentaje de completitud y contador textual de paso.
- **RNF-UX-03 (Identidad Visual ABAQ)**: Preservación de la paleta institucional, bordes redondeados y transiciones CSS GPU-accelerated no mayores a 300ms.

---

## 4. Requerimientos de Documentación y Comentarios Pedagógicos en Código

### `[SRS 9.5.11.4 Requerimientos Funcionales - Documentación Pedagógica y Guía de Lectura]`

- **RF-DOC-01 (Guía Maestra de Lectura del Código en Español - Blueprint Arquitectónico)**:
  - El sistema debe contar con un documento central `docs/codebase-reading-guide.md` redactado en español técnico y accesible.
  - Debe contener un **Mapa Mental Global** del sistema full-stack (MEAN stack moderno).
  - Debe explicar en detalle el **ciclo de vida de una petición HTTP en Express** (`backend/app.js`), detallando la secuencia de middlewares (CORS, body parsers, pug engine, enrutadores modulares, capturador 404 con `AppError` y middleware global de errores).
  - Debe detallar los **patrones ODM con Mongoose** (modelos, hooks, setters normalizadores de booleanos en encuestas, subdocumentos `assignedActivities` en estudiantes, y streaming binario con GridFS).
  - Debe explicar los **fundamentos de Angular 22** (filosofía standalone sin `NgModule`, inyección de dependencias funcional con `inject()`, reactividad con RxJS, ciclo de vida con `takeUntilDestroyed` y detección de cambios con `ChangeDetectorRef`, formularios reactivos y patrón adaptador con DTO mappers).
  - Debe ilustrar el **flujo de datos de extremo a extremo (E2E Data Flow)** desde el navegador hasta la persistencia en MongoDB y respuesta al usuario.

- **RF-DOC-02 (Comentarios JSDoc Pedagógicos en Backend)**:
  - El 100% de los **36 archivos fuente del backend** (Node.js / Express / Mongoose / GridFS / Pug) deben contener anotaciones estructuradas bajo el estándar **JSDoc en idioma inglés**.
  - Cada archivo debe incluir un encabezado formal con `@file`, `@description`, `@module`, y dependencias mediante `@requires`.
  - Cada controlador, middleware, función utilitaria y modelo debe documentar:
    - El propósito y rol del componente dentro de la arquitectura global.
    - El comportamiento específico de mecanismos del framework (e.g. delegación con `next()`, captura asíncrona con `catchAsync`, inyección de parámetros con `req.params`).
    - Parámetros formales (`@param`), valores de retorno (`@returns`) y excepciones potenciales (`@throws`).
    - Las estrategias de manejo de errores y mitigación de inconsistencias (e.g. rollback en `signup`, streaming seguro en `upload`).

- **RF-DOC-03 (Comentarios TSDoc Pedagógicos en Frontend)**:
  - El 100% de los **44 archivos fuente TypeScript del frontend** (Angular 22) deben contener anotaciones estructuradas bajo el estándar **TSDoc en idioma inglés**.
  - Cada componente, servicio, interfaz, interceptor, guard y mapper debe documentar:
    - La responsabilidad funcional del artefacto y su relación con otros servicios y componentes.
    - El uso de primitivas modernas de Angular (decoradores `@Component({ standalone: true })`, resolución con `inject()`, operadores RxJS, gestión de suscripciones con `DestroyRef`).
    - Los tipos de entrada/salida de métodos de servicio, emisiones de observables (`Observable<T>`), y transformaciones de DTOs a modelos de dominio (`student.mapper.ts`, `survey.mapper.ts`).
    - Estrategias de robustez ante fallos de red o errores HTTP.

- **RF-DOC-04 (Lista de Verificación Interactiva por Bloques de Dominio)**:
  - `docs/codebase-reading-guide.md` debe integrar una lista de verificación (*checklist*) interactiva dividida en **6 bloques funcionales**:
    1. *Bloque 1: Autenticación, Seguridad y Sesión* (15 archivos).
    2. *Bloque 2: Gestión de Estudiantes y Expediente Digital* (10 archivos).
    3. *Bloque 3: Encuestas Comunitarias y Formularios Dinámicos* (10 archivos).
    4. *Bloque 4: Gestión de Actividades y Acreditación de Horas* (10 archivos).
    5. *Bloque 5: Módulos Auxiliares (Mascotas, Contactos, Sobre Mí)* (14 archivos).
    6. *Bloque 6: Infraestructura, Subida de Archivos y Utilidades* (21 archivos).
  - Cada bloque debe iniciar con una introducción contextual de su arquitectura y rol dentro de la plataforma.
  - Cada archivo listado debe incluir una casilla de verificación markdown interactiva (`- [ ]`), un enlace relativo navegable hacia el archivo físico en el repositorio, y una descripción sintética de su responsabilidad técnica.

---

## 5. Requerimientos No Funcionales de Documentación y Estándares

### `[SRS 9.4.6 Requerimientos No Funcionales - Calidad de Código y Estándares]`

- **RNF-DOC-01 (Inocuidad de Ejecución / Zero AST Regression)**:
  - La inserción de comentarios JSDoc y TSDoc no debe alterar bajo ninguna circunstancia el árbol de sintaxis abstracta (AST) de ejecución, los flujos lógicos, identificadores de variables, firmas públicas, contratos de API ni pruebas unitarias/e2e existentes.
  - La ejecución de `node --check` en el backend y `npx ng build` en el frontend debe concluir con código de salida `0` y cero errores de compilación.

- **RNF-DOC-02 (Aislamiento de Ramas en Git / Branch Isolation)**:
  - Todas las modificaciones de documentación, guías de lectura y comentarios en código deben efectuarse y mantenerse estrictamente aisladas en la rama de trabajo `docs-explanation` en ambos repositorios/submódulos (`backend` y `frontend`).

- **RNF-DOC-03 (Estandarización de Formato y Disciplina Lingüística / Standardized Formatting)**:
  - Se debe acatar estrictamente la regla de separación lingüística:
    - Guías explicativas, manuales y especificaciones IEEE (`docs/`): Redacción en **español técnico**.
    - Comentarios en código fuente (JSDoc/TSDoc): Redacción en **inglés técnico**, manteniendo la uniformidad de etiquetas (`@param`, `@returns`, `@throws`, `@description`).

- **RNF-DOC-04 (Cobertura Total de Archivos / 100% File Coverage)**:
  - La cobertura de documentación en código debe alcanzar el **100% de los 80 archivos fuente no plantilla** catalogados en el inventario del proyecto (36 archivos en backend y 44 archivos en frontend).

---

## 6. Criterios de Aceptación (Acceptance Criteria)

### 6.1 Criterios de Documentación y Comentarios Pedagógicos
- [ ] **AC-DOC-01 (Guía de Lectura y Blueprint)**: El archivo `docs/codebase-reading-guide.md` existe en el repositorio, está escrito en español, incluye el mapa mental del sistema, los diagramas de flujo E2E y explica detalladamente el ciclo de vida de Express, los patrones Mongoose y la arquitectura Angular 22 Standalone.
- [ ] **AC-DOC-02 (Comentarios JSDoc en Backend)**: Los 36 archivos fuente del backend cuentan con comentarios JSDoc completos en inglés, detallando encabezados de archivo, funciones, controladores y modelos, superando la validación sintáctica de Node.js (`node --check`) con código de salida 0.
- [ ] **AC-DOC-03 (Comentarios TSDoc en Frontend)**: Los 44 archivos fuente TypeScript del frontend cuentan con anotaciones TSDoc completas en inglés, detallando componentes, servicios, guards, interceptores y mappers, compilando exitosamente con `npx ng build --configuration development` con código de salida 0.
- [ ] **AC-DOC-04 (Checklist Interactivo y Resolución de Enlaces)**: El checklist en `docs/codebase-reading-guide.md` incluye los 80 archivos divididos en los 6 bloques de dominio con casillas `- [ ]`, y el 100% de los enlaces relativos resuelven con éxito a archivos existentes en el árbol de trabajo.

### 6.2 Criterios Operativos del Sistema
- [ ] **AC-01 (Contraseñas de Alta Seguridad)**: Admisión y hashing de contraseñas de 12 a 128 caracteres con soporte de caracteres especiales y Unicode sin truncamiento.
- [ ] **AC-02 (Autofill en Gestores de Contraseñas)**: Compatibilidad validada con 1Password, Bitwarden, iCloud Keychain y Chrome Autofill.
- [ ] **AC-03 (Navegación Fluida por Teclado)**: Capacidad de navegación integral mediante teclado (`Enter`, `Tab`, flechas) a lo largo de formularios por lotes.
- [ ] **AC-04 (Validación Bloqueante por Lote)**: Imposibilidad de avanzar de tarjeta si los campos requeridos del lote actual no son válidos.
- [ ] **AC-05 (Preservación de Datos al Retroceder)**: Retención íntegra de la información capturada al regresar a lotes anteriores.
- [ ] **AC-06 (Asignación de Rol Admin y Passkey)**: Protección del endpoint `POST /auth/admin/register` mediante clave secreta, asignando `role: "admin"` únicamente con passkey correcta y rechazando con 403 Forbidden en caso de clave inválida.

---

## 7. Roles, navegación, vinculaciones y folios (adiciones v2.1.0)

Ideas acordadas el 2026-10-22 para la nueva interfaz. Complementan el [Diseño de Autenticación](auth-design.md) v1.1.0.

### 7.1 Roles y secciones por rol

La barra de navegación tiene dos estilos (vertical y horizontal). Ambos muestran **las mismas secciones**; solo cambia la presentación.

| Rol | Secciones principales | Menú de perfil |
|---|---|---|
| Administrador | Inicio · Voluntarios · Actividades · Acreditaciones · Vinculaciones · Respaldos | Reporte de información · Configuración |
| Estudiante (SS) | Inicio · Actividades · Acreditaciones | Reporte de información · Configuración |
| Voluntario general (VG) | Inicio · Actividades · Historial de colaboraciones | Reporte de información y actividades · Configuración |

### `[SRS 7.2 Requerimientos Funcionales - Roles y Navegación]`
- **RF-ROL-01 (Tres roles)**: el sistema distingue `admin`, `student` (SS) y `volunteer` (VG). Solo el estudiante SS acumula y valida horas; el voluntario general solo se inscribe a actividades y se registra su asistencia.
- **RF-ROL-02 (Secciones por rol)**: cada rol ve únicamente las secciones de la tabla 7.1.
- **RF-ROL-03 (Inicio del estudiante)**: el Inicio del estudiante es un panel nuevo; la información personal y las horas validadas viven en *Reporte de información*.
- **RF-ROL-04 (Configuración)**: *Configuración* reúne los datos de la cuenta que antes estaban en "Mi perfil" (estudiante y voluntario).
- **RF-ROL-05 (Reporte del voluntario general)**: *Reporte de información y actividades* muestra sus datos, redes y las actividades en que participó.
- **RF-ROL-07 (Filosofía de tiempo por pantalla)**:
  - *Inicio*: presente y futuro en una ventana corta de **14 días** (pendientes de hoy y lo que viene). Nada del pasado; ofrece un enlace al Reporte.
  - *Secciones* (Actividades, Acreditaciones, Vinculaciones, Voluntarios…): pasado, presente y futuro, con filtros **Próximas · En curso · Pasadas**.
  - *Reporte de información*: información completa de la persona y su pasado, incluidas **las dos acreditaciones** (horas validadas de actividades y solicitudes de acreditación). Se construye desde las antiguas páginas de inicio de Angular.
  - Lo que está en curso (adopción en prueba, placa pendiente, solicitud por validar) cuenta como presente.
- **RF-ROL-06 (Página de error general)**: cualquier ruta inexistente o petición fallida (404 u otro error de la API) muestra una sola página de error general.

### `[SRS 7.3 Requerimientos Funcionales - Vinculaciones]`
- **RF-VIN-01 (Sección del administrador)**: *Vinculaciones* es una sección del administrador con un menú desplegable de cuatro tipos: **Pláticas**, **Campañas**, **Adopciones** y **Placas de identificación**. Cada tipo tiene lista y detalle.
- **RF-VIN-02 (Registro solo por el administrador)**: por ahora solo el administrador registra vinculaciones.
- **RF-VIN-03 (Horas del estudiante)**: el estudiante suma las horas de una vinculación desde *Acreditaciones*.
- **Idea futura**: que el estudiante vea en una sección las vinculaciones donde aparece, y que el voluntario general pueda proponer oportunidades a ABAQ.

### `[SRS 7.4 Requerimientos Funcionales - Folios]`
- **RF-FOL-01 (Folio de expediente)**: cada registro recibe `<TIPO>-<AAMMDD>-<NN>`, p. ej. `SS-261022-07` (ver [auth-design §5.1](auth-design.md#51-folio-de-expediente)).
- **RF-FOL-02 (Folio de oportunidad)**: cada vinculación que genera horas a un estudiante recibe `OP-AAMMDD-00000`.
- **RF-FOL-03 (Folio de acreditación)**: cada solicitud de acreditación de horas recibe `AC-AAMMDD-00000`.
- **RF-FOL-04 (Uso del folio)**: el estudiante usa el folio `OP` o `AC` como referencia para pedir aclaraciones o correcciones de horas al administrador.
- **RF-FOL-05 (Alcance)**: los folios `OP` y `AC` existen solo para estudiantes SS y los ven el estudiante y el administrador. El voluntario general no recibe estos folios.

### `[SRS 7.5 Requerimientos No Funcionales - Folios e Interfaz]`
- **RNF-FOL-01 (Ceros ocultos)**: el backend guarda el consecutivo con cinco dígitos (`00007`); la interfaz lo muestra sin ceros a la izquierda (`OP-261022-7`).
- **RNF-FOL-02 (Reinicio anual)**: el consecutivo de `OP` y `AC` vuelve a 0 cada 1 de enero.
- **RNF-FOL-03 (Unicidad)**: ningún folio puede repetirse dentro de su tipo.
- **RNF-UI-01 (Navbar equivalente)**: las navbars vertical y horizontal exponen exactamente las mismas secciones y permisos.
- **RNF-UI-02 (Tema)**: todas las vistas funcionan en tema claro y oscuro con el sistema de diseño institucional.
- **RNF-UI-03 (TypeScript)**: las vistas nuevas del frontend React se escriben en TypeScript.

### 7.6 Criterios de aceptación
- [ ] **AC-ROL-01**: Cada rol ve solo sus secciones, igual en navbar vertical y horizontal.
- [ ] **AC-VIN-01**: El administrador abre *Vinculaciones* y elige uno de los cuatro tipos en un menú desplegable.
- [ ] **AC-FOL-01**: Un estudiante ve folios con el formato correcto y sin ceros a la izquierda.
- [ ] **AC-FOL-02**: El primer folio `OP` o `AC` de cada año empieza de nuevo en 1.
- [ ] **AC-ERR-01**: Una URL inexistente muestra la página de error general.

### 7.7 Pendientes de definición
- Fases y campos del registro para el voluntario general (las Fases 1–4 están pensadas para SS).
- Qué evento exacto asigna el folio `OP` (al registrar la vinculación o al vincular al estudiante).
