# Especificación de Requerimientos de Software (SRS)
**Estándar:** ISO/IEC/IEEE 29148:2018  
**Proyecto:** Plataforma Web ABAQ (Servicio Social, Censo Comunitario y Documentación Pedagógica)  
**Módulos:** Autenticación, Onboarding en 4 Fases, Certificados Criptográficos, Respaldos y Rollback, Seguridad y Reglas de Negocio, Paridad SS/VG y Auditoría de Expediente  
**Versión:** 2026.10.31 (CalVer)  
**Fecha:** 2026-10-31 (Histórico CalVer: 2026.10.30 · 2026.10.22 · 2026.09.03)  
**Estado:** Aprobado en Producción Real (Angular 22 + MongoDB / Sin datos simulados)  
**Autores:** Equipo de Ingeniería de Requerimientos y Arquitectura ABAQ  

---

## 1. Introducción

### 1.1 Propósito
El propósito de este documento es especificar formalmente los requerimientos del sistema para la plataforma **ABAQ**, integrando:
1. El flujo de registro e inducción guiado en **4 Fases (Onboarding)** con autoguardado reactivo en `localStorage`, outline adaptativo responsivo, validación bajo protesta de decir verdad sin IA ni respuestas vagas, y arquitectura *Zero-File* mediante enlaces a la nube.
2. La segregación estricta de lógica y reglas de negocio entre **Estudiantes de Servicio Social (`SS`)** (meta de 480 horas, 10 horas de inducción, 11 actividades con valores de acreditación, regla de inactividad de 2 meses) y **Voluntarios Generales (`VG`)** (participación comunitaria sin acreditación de horas escolares).
3. El motor criptográfico de emisión y verificación de **Certificados y Constancias Oficiales** bajo demanda con firmas HMAC-SHA256, sin almacenamiento de binarios PDF en el servidor.
4. El subsistema de **Respaldos, Exportación Multi-Formato (JSON Streaming y ExcelJS) y Rollback de Datos** con verificación previa en seco (*dry-run*).
5. Las suites de tablas operativas de alta densidad, formularios dinámicos y la documentación pedagógica del código fuente.

### 1.2 Alcance del Sistema
- **Frontend (Angular 22 Standalone Components)**: Vistas reactivas sin `NgModule`, inyección funcional `inject()`, reactividad RxJS, persistencia debounced en cliente, outline responsivo centrado en viewport (>1024px) y completamente oculto en tablets/móviles (<=1024px), controles personalizados accesibles (`CustomSelectComponent` y `CustomDatepickerComponent`), generación de PDFs en cliente con `html2pdf.js` y `@media print`.
- **Backend (Node.js v24 / Express v4.19 / Mongoose v8.4)**: API RESTful conectada a MongoDB real (sin mock data), autenticación JWT stateless, cifrado bcrypt factor 12, motor criptográfico de constancias (`backend/utils/certificates.js`), servicio de exportación y rollback (`services/backup.service.js`), y cálculo de ciclo de vida con regla de 2 meses de inactividad.
- **Suite de Documentación y Comentarios Pedagógicos**: Anotación técnica bajo estándares JSDoc y TSDoc, garantizando cero regresión en tiempo de ejecución (*Zero AST Regression*).

### 1.3 Definiciones, Acrónimos y Abreviaturas
- **SRS**: *Software Requirements Specification* (ISO/IEC/IEEE 29148:2018).
- **SS / VG**: Estudiante de Servicio Social / Voluntario General.
- **Onboarding 4 Fases**: Flujo secuencial guiado: 01 Perfil, 02 Inducción, 03 Sobre Mí, 04 Documentos y Legal + Expediente Recibido.
- **Zero-File Architecture**: Modelo de operación donde el servidor no almacena archivos PDF ni imágenes aportados por los usuarios, sustituyéndolos por URLs públicas verificadas en la nube (Google Drive / OneDrive) y casillas de consentimiento informado.
- **HMAC-SHA256**: Código de autenticación de mensajes basado en hash criptográfico utilizado para emitir y validar certificados con tokens URL-safe `st_[id]_[certType]_[hmac32]`.
- **RBAC**: *Role-Based Access Control* (`admin`, `student`, `volunteer`).
- **Dry-run**: Simulación en seco sin escrituras para validar integridad de datos antes de un rollback.

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

## 3. Requerimientos de Onboarding Guiado en 4 Fases y Experiencia de Usuario

### `[SRS 9.5.11.2 Requerimientos Funcionales - Onboarding en 4 Fases]`

- **RF-ONB-01 (Elección de Rol Inicial en Signup / Paso 0)**:
  - En `/auth/signup`, el usuario debe seleccionar obligatoriamente su rol de ingreso mediante dos opciones mutuamente excluyentes: `Estudiante de Servicio Social (SS)` o `Voluntario General (VG)`.
  - La selección de rol bifurca la ruta del onboarding y el endpoint final de persistencia (`/auth/signup` para SS vs. `/auth/signup-volunteer` para VG).
  - No se permiten botones para alternar de rol dentro del flujo de inducción; si el usuario desea cambiar de rol, debe regresar al formulario de Signup inicial.

- **RF-ONB-02 (Fase 1: Perfil Académico para Estudiante SS)**:
  - **Identidad Personal**: Nombres, Apellido Paterno, Apellido Materno y Fecha de Nacimiento.
  - **CURP Oficial**: Validación obligatoria de Clave Única de Registro de Población (18 caracteres alfanuméricos en mayúsculas con formato canónico mexicano).
  - **Institución y Carrera**: Selección asistida mediante selector combobox de universidades de Querétaro (UAQ, ITQ, UTEQ, Anáhuac, UVM, UPQ, UNAQ, ENEQ, ITESM) y sugerencias de licenciatura/ingeniería.
  - **Esquema de Periodo Compuesto**: Control horizontal en un solo renglón al 100% del ancho del contenedor que combina:
    1. Selector de esquema temporal (`semestre`, `cuatrimestre`, `trimestre`, `bimestre`, `tetramestre`, `anual`, `modular`).
    2. Campo numérico editable del periodo en curso (`periodNumber`, p. ej. `1`, `4`, `7`).
    3. Campo de texto bloqueado en gris con estilo gramatical de orden posicional calculado dinámicamente (`· er Semestre`, `· to Cuatrimestre`, `· er Bimestre`, etc.), impidiendo truncamientos visuales en tablets y móviles.
  - **Fechas de Servicio Social**: Selectores de fecha de arranque (`fechaArranque`) y fecha de conclusión (`fechaConclusion`), con etiqueta y ayuda contextual explícita indicando que corresponden al compromiso del servicio social en ABAQ y no a las fechas de egreso de la carrera universitaria.

- **RF-ONB-03 (Fase 1: Perfil Personal y Modular para Voluntario General VG)**:
  - Nombres, Apellidos y Fecha de Nacimiento.
  - Campo de ocupación actual (`occupation`).
  - Formación académica modular repetible (`degrees`), permitiendo agregar múltiples grados con nivel (`preparatoria`, `tecnico`, `licenciatura`, `especialidad`, `maestria`, `doctorado`, `posdoctorado`), institución, título obtenido y estado (`completado`, `en_curso`, `trunco`).

- **RF-ONB-04 (Fase 1: Canales de Telefonía y WhatsApp)**:
  - Teléfono celular principal obligatorio (exactamente 10 dígitos numéricos sin prefijo fijo `(LADA 442)`).
  - Casilla de verificación si cuenta con WhatsApp: si está marcada, sincroniza automáticamente el número celular; si está desmarcada, habilita un campo alternativo para ingresar el número de WhatsApp.
  - Casilla opcional para contacto secundario con campo de teléfono a 10 dígitos.

- **RF-ONB-05 (Fase 1: Presencia en Redes Sociales)**:
  - Sección 04 opcional para registrar nombres de usuario/handles en las plataformas donde el postulante tenga presencia activa: Facebook, Instagram, TikTok, Twitter / X, YouTube y LinkedIn.
  - Cada campo debe incluir un distintivo visual (*badge*) con el ícono y color representativo de la marca (`f`, `◎`, `♪`, `𝕏`, `▶`, `in`).

- **RF-ONB-06 (Fase 2: Módulos de Inducción Oficiales y Reflexiones Independientes)**:
  - Despliegue de los 6 módulos formativos oficiales de bienestar animal:
    1. *1. Conociendo ABAQ*: Enlaces a la web oficial y a las 5 redes sociales institucionales (Facebook, Instagram, LinkedIn, TikTok, Twitter/X).
    2. *2. Plática de Bienestar Animal ABAQ*: Presentación oficial en Canva.
    3. *3. Arquetipos de Marca*: Video en YouTube con identificación del arquetipo institucional "El Inocente".
    4. *4. Entrenamiento DISC*: Video en YouTube sobre estilos de comunicación.
    5. *5. Entrenamiento Generaciones*: Video en YouTube sobre sinergia intergeneracional.
    6. *6. La Neurociencia de las Emociones*: Conferencia en YouTube de la Dra. Marian Rojas Estapé.
  - Por cada módulo, el postulante debe redactar obligatoriamente **tres reflexiones independientes**:
    - *¿Qué me gustó?* (`liked`)
    - *¿Qué considero lo más importante?* (`important`)
    - *¿Qué puede mejorar?* (`improve`)
  - **Campos en Blanco por Defecto**: Todos los campos de texto deben iniciar vacíos (`""`), mostrando sugerencias de redacción únicamente como texto de fondo (*placeholder*) que desaparece al teclear y reaparece si el campo queda vacío.

- **RF-ONB-07 (Fase 2: Declaración Bajo Protesta de Decir Verdad y Evaluación sin IA)**:
  - Cada módulo incluye una casilla de verificación individual que certifica formalmente haber revisado de inicio a fin y asimilado el material formativo.
  - Alerta legal obligatoria: El sistema debe advertir explícitamente que la evaluación se basa en el texto redactado de las reflexiones. Cualquier falta de asimilación, respuestas vagas, genéricas o generadas con inteligencia artificial provocará la cancelación inmediata de la solicitud, debiendo el postulante registrarse nuevamente desde cero.

- **RF-ONB-08 (Fase 2: Segregación Estricta de Acreditación de Horas)**:
  - **Estudiante de Servicio Social (`SS`)**: La inducción acredita formalmente **10 horas** de servicio social. El encabezado de la fase incluye el distintivo `✨ Acredita 10 Horas de Servicio Social`, la barra superior refleja `Acredita 10h` / `✨ 10h Acreditadas`, y se despliega la nota oficial: *"NOTA: En caso de Servicio Social, esta presentación será válida por 10 horas, además de que te permitirá continuar"*.
  - **Voluntario General (`VG`)**: No acredita horas académicas. El título se muestra como `Módulos de Inducción ABAQ`, se oculta completamente cualquier badge de 10 horas, la barra superior muestra `100% Completa`, y se omite la nota de validez escolar.

- **RF-ONB-09 (Fase 3: Sobre Mí)**:
  - Captura de biografía personal (`bioPersonal`), chips de selección rápida de intereses cotidianos (`intereses`), talentos y habilidades (`talentos`), propuesta de aportes a ABAQ (`aportesAbaq`), experiencia con animales de compañía (`animalExperience` y `descExperiencia`), y motivación para integrarse a la asociación (`motivacionAbaq`).

- **RF-ONB-10 (Fase 3: Priorización de las 11 Actividades del Reglamento Oficial)**:
  - Mecanismo interactivo de reordenamiento de mayor a menor preferencia mediante controles de flecha arriba (`keyboard_arrow_up`) y abajo (`keyboard_arrow_down`), integrando las 11 actividades institucionales del reglamento:
    1. Eventos ABAQ (2x1 doble por cada hora de participación).
    2. Vincular placa de identificación con proveedor ABAQ (5 h).
    3. Vincular esterilización de perro o gato con ABAQ (10 h).
    4. Vincular adopción responsable colaboración ABAQ Adopcan/Adopta Michu con 15 días de prueba (100 h).
    5. Vincular y coordinar módulo de adopción en evento o espacio público (40 h).
    6. Coordinar plática de Bienestar Animal >=50 personas (50 h).
    7. Coordinar campaña a bajo costo >=60 animales inscritos (100 h).
    8. Difundir proyecto ABAQ gratuitamente en medios masivos (30 h).
    9. Publicaciones y reposts en redes sociales etiquetando a ABAQ (5 h + 1 h por cada 5 reacciones).
    10. Consecución de fondos para el objeto social ABAQ ($50 = 1 h).
    11. Actividades administrativas eventuales grupo WhatsApp (Horas por definir).
  - **Segregación de Visualización**: Los estudiantes (`SS`) ven el desglose de horas acreditables y una nota aclaratoria institucional. Los voluntarios generales (`VG`) ven la descripción de la actividad limpia de referencias a horas académicas.

- **RF-ONB-11 (Fase 4: Documentos en la Nube / Zero-File)**:
  - El postulante proporciona enlaces compartidos públicos (Google Drive o OneDrive) para:
    1. Identificación oficial vigente (INE o credencial universitaria).
    2. Currículum Vitae o Ficha de presentación.
    3. Constancia de estudios/Kardex universitario (`SS`) o Comprobante de domicilio/estudios (`VG`).
  - Alerta técnica destacada solicitando abrir los enlaces en **ventana de incógnito** antes de enviar, verificando que cualquier revisor de ABAQ pueda consultarlos sin solicitar permisos de acceso.

- **RF-ONB-12 (Fase 4: Consentimiento Legal y Firma Digital Informada)**:
  - 5 casillas de verificación obligatorias que constituyen la firma digital:
    1. Aceptación del Reglamento de Servicio Social o Voluntariado ABAQ (con visor modal).
    2. Aceptación del Aviso de Privacidad y Manejo de Datos Personales (con visor modal).
    3. Aceptación de Políticas de Servicio y Código de Ética (con visor modal).
    4. Declaración de Enlaces de Nube Públicos y Vigentes por al menos un mes.
    5. Consentimiento formal de Voluntariado y Veracidad de Información.
  - Advertencia obligatoria: Para estudiantes SS, 2 meses de inactividad no notificada causará la baja automática del programa.

- **RF-ONB-13 (Expediente Recibido y Transición Visual)**:
  - Al enviar la Fase 4, se crea la cuenta en estado `pending` y se asigna un folio único (`SS-YYMMDD-XX` o `VG-YYMMDD-XX`).
  - La pantalla `ExpedienteRecibidoComponent` desvanece suavemente el navbar superior de fases sin alterar la posición vertical de la tarjeta de felicitación (*zero layout shift*), disparando inmediatamente una animación de confeti ligero.

- **RF-ONB-14 (Auto-Guardado Reactivo en `localStorage`)**:
  - Todo cambio en cualquier campo de las 4 fases se persiste automáticamente en `localStorage` con debounce de 400ms.
  - Se vincula el evento `window:beforeunload` para salvaguardar el borrador ante cierres abruptos o recargas.
  - Cada sección (`<legend>`) incluye un distintivo minimalista a la derecha: `cloud_done Guardado`.

- **RF-ONB-15 (Outline Responsivo Adaptativo)**:
  - En pantallas de escritorio (`> 1024px`), el outline de subsecciones permanece fijo y centrado a la mitad de la altura de la pantalla (`top: 50vh; transform: translateY(-50%)`) a la izquierda con barras indicadoras, mientras el formulario se desplaza verticalmente.
  - En pantallas medianas, tabletas y móviles (`<= 1024px`), el outline se oculta completamente (`display: none !important;`), permitiendo que el formulario aproveche el 100% del ancho sin interferencias táctiles.

- **RF-ONB-16 (Controles de Entrada Especializados y Teclado Accesible)**:
  - `CustomSelectComponent`: Combobox *focus-first* con filtrado predictivo y navegación por flechas, Enter, Escape y Tab.
  - `CustomDatepickerComponent`: Permite teclear números crudos sin guiones ni diagonales, formateando automáticamente con barras (`DD/MM/AAAA`), manteniendo accesible el calendario emergente interactivo.
  - Contador Dinámico de Faltantes: El banner de advertencia calcula en tiempo real el número exacto de campos pendientes antes de permitir avanzar a la siguiente fase.

### `[SRS 9.5.11.3 Requerimientos Funcionales - Encuestas Comunitarias]`
El formulario de censo animal (`/survey/form/submit` y `FormComponent`) debe agrupar dinámicamente las preguntas en tarjetas temáticas y construir subsecciones dinámicas para mascotas registradas mediante `FormArray`.

### `[SRS 9.4.3 Requerimientos No Funcionales - Usabilidad e Interacción]`
- **RNF-UX-01 (Navegación por Teclado Permanente)**:
  - `Enter`: Valida campos requeridos y avanza de sección.
  - `Shift + Enter` / `Esc`: Retrocede preservando el estado de todos los datos introducidos.
  - `Tab` / `Flechas`: Cicla y selecciona opciones sin necesidad de ratón.
- **RNF-UX-02 (Barra Superior de 4 Fases con Micro-Segmentos)**: Barra sticky superior con progreso porcentual global y píldoras segmentadas por subsección completada.
- **RNF-UX-03 (Identidad Visual ABAQ)**: Navy `#24366f`, Forest Green `#5ca83a`, fondo `#f8fafc`, bordes redondeados y transiciones suaves.

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
- **RF-FOL-01 (Folio de expediente obligatorio en la raíz del esquema - Prohibición de valores null)**: Cada registro de estudiante (`SS`) y voluntario general (`VG`) debe persistir obligatoriamente en la raíz del documento de base de datos el atributo `folio` con formato `<TIPO>-<AAMMDD>-<NN>`, p. ej. `SS-261022-07` o `VG-261022-03` (ver [auth-design §5.1](auth-design.md#51-folio-de-expediente)). En el sistema de ABAQ **no se permite bajo ninguna circunstancia un registro con folio `null` o sin definir**: es un requerimiento mandatorio de negocio y arquitectura. Se aplica validación estricta (`required: true`) a nivel de esquema Mongoose, hook de ciclo de vida `pre('validate')` para garantizar su generación antes de guardar, y rutinas de integridad que aseguran que el 100% de los documentos históricos cuenten con su folio institucional permanente e inmutable. El folio es estrictamente de sólo lectura tanto para el usuario como para la administración.
- **RF-FOL-02 (Folio de oportunidad)**: cada vinculación que genera horas a un estudiante recibe `OP-AAMMDD-00000`.
- **RF-FOL-03 (Folio de acreditación)**: cada solicitud de acreditación de horas recibe `AC-AAMMDD-00000`.
- **RF-FOL-04 (Uso del folio)**: el estudiante usa el folio `OP` o `AC` como referencia para pedir aclaraciones o correcciones de horas al administrador.
- **RF-FOL-05 (Alcance)**: los folios `OP` y `AC` existen solo para estudiantes SS y los ven el estudiante y el administrador. El voluntario general no recibe estos folios.
- **RF-EXP-01 (Gestión de Documentos de Expediente en la Nube y Verificación en Incógnito)**: En cumplimiento estricto con la arquitectura Cero Archivos (ADR-05), el sistema prohíbe la subida y almacenamiento de archivos binarios o PDFs en el servidor. Todas las vistas de expediente digital (`StudentDetail` y `VolunteerDetail`) gestionan la documentación (Identificación INE, Currículum Vitae, Comprobante de domicilio/estudios, Carta de aceptación, Constancia de plática, Carta de término, Reportes de actividades) exclusivamente mediante enlaces compartidos públicos de Google Drive, OneDrive o nubes institucionales. La interfaz debe:
  1. Presentar de forma obligatoria y prominente la advertencia e instrucción de probar cada enlace en una ventana de incógnito para certificar accesibilidad pública sin solicitar permisos ni accesos restringidos.
  2. Proveer acciones de apertura directa en pestaña nueva (`target="_blank"`), registro/edición de enlaces mediante modal reactivo con botón de prueba inmediata, y retiro/eliminación controlada.
  3. Previsualizar el estado (`☁️ Enlace configurado` vs `⏳ Pendiente`) y la URL compartida para cada documento del ciclo.

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

### 7.7 Resoluciones de Diseño Implementadas (v2.2.0)
- **Registro de Voluntario General Resuelto**: El registro para el voluntario general (`VG`) quedó formalizado e implementado en las 4 Fases con bifurcación de rol desde Signup (ver `RF-ONB-01` a `RF-ONB-16`):
  - Fase 1: Perfil personal con ocupación y grados modulares (`degrees`).
  - Fase 2: Inducción formativa con omisión estricta de las 10 horas escolares.
  - Fase 3: Sobre mí con las 11 actividades limpias de referencias a horas académicas.
  - Fase 4: Ligas a la nube y 5 consentimientos legales.
  - Expediente Recibido: Folio `VG-YYMMDD-XX` y estado `pending`.
- **Asignación de Folios `OP` y `AC`**: Se generan de forma determinista mediante el timestamp del evento y el correlativo del año en curso.

---

## 8. Módulo de Respaldos, Exportación de Datos y Rollback del Sistema (v2.2.0)

### 8.1 Propósito y Contexto Operativo
El módulo de Respaldos (*Backups & Disaster Recovery*) responde a la necesidad de garantizar la soberanía de los datos, facilitar auditorías externas y permitir una recuperación rápida (*rollback*) ante incidentes operativos, errores de captura masiva o fallos de infraestructura. A diferencia de las políticas a nivel de nube (Azure Blob Storage o MongoDB Atlas automated snapshots), este módulo dota a las administradoras y coordinadoras de ABAQ de autonomía directa desde el portal web para:
1. Exportar en un solo clic toda la información institucional en **archivos JSON comprimidos (.zip)** aptos para re-inyección (*rollback*).
2. Exportar la base de datos completa a un libro de **Excel (.xlsx)** estructurado en hojas independientes para análisis contable, informes a patronato y auditoría humana.
3. Ejecutar un procedimiento de **restauración y reversión (rollback)** mediante la carga de un archivo `.zip` generado previamente, con validación en seco (*dry-run*) obligatoria.

### 8.2 Arquitectura del Artefacto de Respaldo (.zip)
El archivo comprimido `.zip` generado por el backend sigue la siguiente estructura estandarizada:
```
abaq-backup-YYYY-MM-DD-HHmmss.zip
├── manifest.json                  # Metadatos del respaldo, versión del esquema, hash SHA-256
├── collections/
│   ├── users.json                 # Cuentas, credenciales cifradas y roles
│   ├── students.json              # Expedientes de estudiantes de Servicio Social
│   ├── volunteers.json            # Voluntarios generales y perfiles
│   ├── activities.json            # Convocatorias de actividades
│   ├── quickactivities.json       # Actividades rápidas institucionales
│   ├── accreditations.json        # Registro de horas acreditadas y periodos
│   ├── talks.json                 # Pláticas de inducción y asistencias
│   ├── campaigns.json             # Campañas de esterilización
│   ├── adoptions.json             # Adopciones y seguimiento
│   ├── identifications.json       # Placas de identificación registradas
│   ├── joinrequests.json          # Solicitudes de ingreso a la plataforma
│   ├── surveys.json               # Encuestas y censos de bienestar animal
│   ├── contacts.json              # Contactos y seguimientos comunitarios
│   └── pets.json                  # Censo animal y mascotas vinculadas
```

### `[SRS 8.3 Requerimientos Funcionales - Respaldo y Rollback]`

- **RF-BKP-01 (Generación de Respaldo Completo en Formato JSON Comprimido)**:
  - El sistema debe permitir al usuario administrador generar un respaldo íntegro de las 14 colecciones activas de MongoDB.
  - Cada colección se exporta como un archivo `.json` formateado como un arreglo de documentos BSON/JSON puros, preservando tipos primitivos (fechas ISO, ObjectIDs en `$oid`).
  - El paquete completo se comprime en formato `.zip` mediante streaming HTTP directo hacia el cliente.

- **RF-BKP-02 (Manifiesto de Integridad y Versionado)**:
  - Todo respaldo `.zip` debe incluir obligatoriamente en la raíz un archivo `manifest.json` con:
    - `version`: Versión del esquema del respaldo (e.g. `2.2.0`).
    - `timestamp`: Marca de tiempo en formato ISO 8601 de la generación.
    - `generator`: Correo electrónico del usuario administrador que solicitó el respaldo.
    - `collections`: Mapa de colecciones respaldadas indicando número de documentos y tamaño en bytes.
    - `checksums`: Mapa de hashes SHA-256 calculados para cada archivo JSON contenido en el paquete.

- **RF-BKP-03 (Generación de Respaldo en Libro de Excel Multi-Hoja .xlsx)**:
  - El sistema debe ofrecer la descarga consolidada de la base de datos en formato Microsoft Excel (`.xlsx`).
  - El libro generado debe contener una hoja de cálculo (*worksheet*) independiente por cada modelo del sistema (`Estudiantes`, `Voluntarios`, `Actividades`, `Acreditaciones`, `Adopciones`, `Campañas`, `Identificaciones`, `Pláticas`, `Encuestas`, `Mascotas`, `Contactos`, `Solicitudes`, `Usuarios`, `Actividades Rápidas`).
  - Los encabezados de columna deben formatearse con estilos institucionales (fila fija, fondo azul marino corporativo `#24366f`, tipografía en blanco y texto en negrita).
  - Las columnas deben auto-ajustar su ancho según la longitud de los datos.
  - Los campos de contraseñas (`passwordHash`) deben ser omitidos expresamente de la exportación a Excel para prevenir fugas de credenciales en auditorías operativas.
  - Los objetos anidados y arreglos simples deben ser aplanados o concatenados de forma legible (e.g. etiquetas separadas por comas).

- **RF-BKP-04 (Descarga Directa Local sin Persistencia de Basura)**:
  - El endpoint de exportación (`/backup/download/json` y `/backup/download/excel`) debe transmitir los archivos directamente al navegador del administrador mediante encabezados `Content-Disposition: attachment; filename="abaq-backup-..."`.
  - El servidor no debe retener archivos temporales huérfanos en disco una vez terminada o abortada la descarga.

- **RF-BKP-05 (Validación Previa en Seco para Rollback / Dry-Run)**:
  - Antes de ejecutar cualquier sobreescritura en la base de datos, el administrador debe subir el archivo `.zip` al endpoint de restauración.
  - El sistema debe descomprimir en memoria o directorio temporal seguro, validar la presencia y firma del `manifest.json`, y verificar la validez de los esquemas JSON de cada colección.
  - El backend debe devolver un **reporte de validación preliminar** (*dry-run summary*):
    - Conteo de registros actuales en base de datos vs. registros a restaurar por colección.
    - Detección de posibles conflictos o documentos corruptos.
    - Estado de aprobación de integridad del archivo.

- **RF-BKP-06 (Ejecución Controlada de Rollback / Restauración)**:
  - La restauración efectiva de datos solo puede ejecutarse tras la confirmación explícita del administrador (enviando el parámetro `confirm=true` o token de confirmación generado en el dry-run).
  - El rollback debe limpiar las colecciones objetivo y re-inyectar los documentos del respaldo manteniendo las llaves primarias `_id` para garantizar la integridad referencial histórica.
  - Si una colección crítica falla durante la inyección, el sistema debe abortar y registrar el evento en el log de auditoría.

- **RF-BKP-07 (Control de Acceso Estricto RBAC)**:
  - Todos los endpoints del módulo (`/backup/*`) deben estar protegidos con validación de token JWT y requerir estrictamente `role: "admin"`.
  - Cualquier intento de acceso por parte de usuarios con rol `student`, `volunteer` o no autenticados debe ser rechazado con código `403 Forbidden` o `401 Unauthorized`.

- **RF-BKP-08 (Interfaz de Administración Simplificada)**:
  - La sección en el frontend debe ubicarse en la ruta `/admin/backups` y ser accesible desde el menú de navegación del administrador.
  - La vista debe presentar:
    - Tarjeta de métricas vitales: Estado de conexión a la base de datos, total de colecciones activas y conteo global de documentos.
    - Tarjeta de acción de Respaldo JSON: Botón destacado para descargar el archivo `.zip` comprimido con descripción de su uso para rollback.
    - Tarjeta de acción de Exportación Excel: Botón destacado para descargar el archivo `.xlsx` multi-hoja para consulta gerencial.
    - Panel de Rollback / Restauración: Zona de arrastre de archivo (*drag-and-drop*) o selector para cargar el `.zip`, modal de advertencia crítica (*danger style*) y confirmación en dos pasos antes de proceder.

### `[SRS 8.4 Requerimientos No Funcionales - Respaldos y Rollback]`

- **RNF-BKP-01 (Uso Eficiente de Memoria y Streaming)**:
  - La generación de los paquetes `.zip` y `.xlsx` debe apoyarse en streaming (`archiver` y `exceljs`) para procesar grandes volúmenes de documentos sin agotar el heap de memoria de Node.js.

- **RNF-BKP-02 (Tiempo de Respuesta para Exportación)**:
  - Para bases de datos de hasta 100,000 documentos, la generación del archivo `.zip` debe iniciar la descarga en el cliente en menos de 5 segundos.

- **RNF-BKP-03 (Seguridad Criptográfica y Sanitización)**:
  - El hash SHA-256 del manifiesto garantiza que el archivo de respaldo no ha sido alterado manualmente entre su descarga y su posterior uso en un rollback.

- **RNF-BKP-04 (Diseño Visual y Consistencia UX)**:
  - La vista del frontend debe adherirse al sistema de diseño definido en `DESIGN.md`: colores institucionales (Navy `#24366f`, Emerald Green `#5ca83a`), tarjetas estilizadas con elevación suave, estados de carga accesibles (`spinners`), y mensajes de retroalimentación claros mediante alertas o *toasts*.

### 8.5 Criterios de Aceptación (Acceptance Criteria)

- [ ] **AC-BKP-01 (Descarga de Respaldo JSON)**: Un administrador hace clic en "Descargar Respaldo JSON" y recibe un archivo `.zip` que contiene las 14 colecciones en `.json` más el `manifest.json`.
- [ ] **AC-BKP-02 (Descarga de Libro Excel)**: Un administrador hace clic en "Descargar Excel" y recibe un archivo `.xlsx` válido que abre correctamente en Excel, LibreOffice o Numbers, conteniendo 14 pestañas con formato y sin el campo `passwordHash`.
- [ ] **AC-BKP-03 (Protección de Acceso)**: Peticiones no autenticadas o con rol distinto a `admin` son rechazadas con error HTTP 401 o 403.
- [ ] **AC-BKP-04 (Dry-run de Rollback)**: Al subir un archivo `.zip` de respaldo, la interfaz muestra primero una tabla comparativa con el conteo de documentos actuales vs. respaldados y solicita confirmación explícita.
- [ ] **AC-BKP-05 (Rollback Exitoso)**: Al confirmar el rollback, la base de datos se restaura con el contenido exacto del respaldo manteniendo los `_id` de los documentos.
- [ ] **AC-BKP-06 (Integración en Navegación)**: El enlace a "Respaldos" aparece en el menú del administrador y redirige a `/admin/backups`.

---

## 9. Emisión y Verificación Criptográfica de Certificados (v2.2.0)

### `[SRS 9.5.11.5 Requerimientos Funcionales - Certificados y Constancias Oficiales]`

- **RF-CERT-01 (Token Criptográfico HMAC-SHA256)**:
  - El acceso a cualquier certificado o constancia oficial debe realizarse exclusivamente a través de un token criptográfico generado en backend con formato: `st_[id]_[certType]_[hmac32]`.
  - El token es calculado combinando el identificador del usuario, el tipo de constancia y el secreto criptográfico del entorno (`CERTIFICATE_SECRET` o `JWT_SECRET`).
  - La verificación del token debe ejecutarse mediante comparación de tiempo constante (`crypto.timingSafeEqual`) para neutralizar ataques basados en tiempo.

- **RF-CERT-02 (Carta de Aceptación y Felicitación)**:
  - Generada dinámicamente mediante `renderAcceptanceCertificateHtml(...)` disponible tanto para Estudiantes de Servicio Social (`SS`) como para Voluntarios Generales (`VG`).
  - El texto del cuerpo se adapta automáticamente según el rol:
    - Para `SS`: Certifica haber acreditado la inducción y haber sido aceptado oficialmente en el Servicio Social (480 horas) de ABAQ.
    - Para `VG`: Certifica haber completado su inducción y haber sido aceptado oficialmente como Voluntario General de Bienestar Animal.

- **RF-CERT-03 (Certificado de Finalización de Servicio Social 480 Horas)**:
  - Generado dinámicamente mediante `renderCompletionCertificateHtml(...)` y reservado estrictamente para estudiantes `SS` que hayan completado y acreditado el 100% de las 480 horas requeridas.

- **RF-CERT-04 (Plantilla Autocontenida en Memoria RAM)**:
  - El generador de constancias debe incrustar directamente en el HTML de respuesta las fuentes tipográficas oficiales (`GreatVibes-Regular.ttf` y `CrimsonText-Regular.ttf`) y los gráficos institucionales (`logo_highres_trans.png` y `new_watermark_trans.png`) en formato Base64.
  - Los recursos en Base64 se cargan una única vez en memoria en el inicio del servidor (`loadSubmoduleAssets`), manteniendo el consumo en ~2.2 MB fijos de RAM.
  - El tamaño del HTML generado es de ~2.77 MB y se genera en menos de 30 milisegundos por documento.

- **RF-CERT-05 (Barra de Herramientas y Compilación en Cliente)**:
  - La respuesta HTML incluye una barra superior interactiva (`.abaq-top-bar`) con:
    - Botón "📥 Descargar PDF": Compila el lienzo (`#certificateRoot`) a un archivo `.pdf` en alta resolución (escala 2, unit px, formato [1122, 793], orientación landscape) mediante `html2pdf.js` directamente en el navegador del usuario.
    - Botón "🖨️ Imprimir": Dispara `window.print()` con estilos `@media print` optimizados que fuerzan `print-color-adjust: exact !important` y ocultan la barra de herramientas.

- **RF-CERT-06 (Sello de Verificación Oficial Criptográfico)**:
  - Todo documento emitido incluye en el pie de página un sello centrado no editable con:
    - Folio institucional oficial (`SS-YYMMDD-XX` o `VG-YYMMDD-XX`).
    - Firma criptográfica abreviada en mayúsculas (`tokenShort`).
    - Leyenda de validación oficial de ABAQ Querétaro.

---

## 10. Reglas de Negocio Institucionales y Ciclo de Vida (v2.2.0)

### `[SRS 9.5.11.6 Requerimientos Funcionales - Reglas de Negocio y Ciclo de Vida]`

- **RF-LIFECYCLE-01 (Regla de Desvinculación por 2 Meses de Inactividad)**:
  - En estricto apego al Reglamento de Servicio Social ABAQ, 2 meses (60 días naturales) de inactividad no previamente notificada causará la baja o cancelación automática del programa de servicio social.
  - El sistema debe comparar en tiempo real la fecha actual contra la última fecha de actividad o asistencia registrada del estudiante, marcando visualmente en los paneles de administración aquellos colaboradores que se encuentren en riesgo o superen el umbral de inactividad.

- **RF-LIFECYCLE-02 (Tope de Horas y Carta de Aceptación)**:
  - Ningún estudiante de servicio social puede superar el tope de horas estipulado por su institución educativa (máximo legal de 480 horas).
  - La acreditación de horas en la base de datos se detiene automáticamente al alcanzar las 480 horas, habilitando la emisión del Certificado de Finalización.

- **RF-LIFECYCLE-03 (Restricciones Universitarias en Consecución de Fondos)**:
  - Para la actividad 10 del reglamento (consecución de fondos para el objeto social ABAQ a razón de $50.00 = 1 hora):
    - **Universidad Anáhuac**: Solo se acredita hasta el 50% del total de horas requeridas (máximo 240 horas).
    - **Tecnológico de Monterrey (ITESM) y Tec Milenio**: No aplica la actividad 10 para acreditación de horas.

- **RF-LIFECYCLE-04 (Segregación de Vistas por Rol)**:
  - Las vistas de administración (`StudentComponent`, `VolunteerDetailComponent`) presentan tablas separadas y específicas según el tipo de colaborador, evitando mezclar expedientes académicos de servicio social con registros de voluntariado general.

---

## 11. Tablas Operativas y Visualización Integral de Expedientes (v2.2.0)

### `[SRS 9.5.11.7 Requerimientos Funcionales - Tablas Operativas]`

- **RF-TAB-01 (Tablas de Alta Densidad Operativa)**:
  - Las listas administrativas de estudiantes y voluntarios deben implementarse como tablas de alta densidad informativa con contraste visual, bordes sutiles y tipografía clara.
  - Deben ofrecer:
    - Barra de búsqueda reactiva por nombre, correo, matrícula, CURP o escuela.
    - Paginación y selección de tamaño de página.
    - Indicadores de estado visuales (*badges* de color para cuentas activas, pendientes, rechazadas o en riesgo).

- **RF-TAB-02 (Visualización Contextual Completa en Perfiles y Detalles)**:
  - Las vistas de detalle (`StudentDetailComponent`, `StudentProfileComponent`, `VolunteerDetailComponent`, `VolunteerProfileComponent`) deben exponer íntegramente todos los datos recolectados en el onboarding:
    - CURP y matrícula del estudiante.
    - Esquema y avance de periodo académico compuesto (`periodType`, `periodNumber`, `semestre`).
    - Fechas de servicio social (`fechaArranque`, `fechaConclusion`).
    - Cuentas de redes sociales con prefijos de marca interactivos.
    - Formación académica modular y ocupación en voluntarios generales.
    - Balance de horas: Horas a cubrir, horas acreditadas y horas pendientes.

---

## 12. Especificaciones de Cierre, Paridad SS/VG y Seguridad en Onboarding (v2.3.0)

### `[SRS 12.1 Requerimientos Funcionales - Ciclo de Vida del Expediente Recibido]`

- **RF-EXP-STATUS-01 (Estados del Expediente Digital)**:
  - Todo usuario recién registrado en onboarding transiciona de forma inmediata a la vista reactiva de expediente digital (`ExpedienteRecibidoComponent`), con estado inicial `pending`.
  - El expediente soporta cuatro estados operacionales:
    1. `pending` (Pendiente de revisión documental).
    2. `in_review` (En revisión por coordinación ABAQ).
    3. `accepted` / `active` (Aceptado y activado en plataforma).
    4. `rejected` (Rechazado con motivo de aclaración).

- **RF-EXP-UI-01 (Diferenciación Visual de Tarjetas por Rol)**:
  - La columna lateral derecha del expediente recibido debe adaptar su contenido y disposición según el tipo de colaborador (`SS` vs `VG`):
    - **Estudiante de Servicio Social (`SS`)**:
      1. *Tarjeta de 10 Horas*: Destacada con fondo gradiente corporativo e icono de destello (`✨ 10 Horas de Servicio Social`), indicando que al ser aceptada su solicitud se le acreditarán 10 horas curriculares por el proceso de inducción.
      2. *Tarjeta de Tiempo de Respuesta*: Indicando un plazo formal de atención de 24 a 48 horas hábiles en estricto orden de registro.
      3. *Tarjeta de Regla de Continuidad*: Indicando la cláusula del reglamento sobre baja por inactividad no notificada mayor a 2 meses, con canal de aclaraciones (`admision.servicio@abaq.org.mx`).
    - **Voluntario General (`VG`)**:
      1. *Tarjeta de Tiempo de Respuesta*: 24 a 48 horas hábiles.
      2. *Tarjeta de Nota de Voluntariado General*: Aclarando que su colaboración es cívica y voluntaria en Querétaro, omitiendo cualquier mención a horas escolares o baja académica.
      3. *Alineación Centrada*: Ambas tarjetas se centran verticalmente (`col-right-vg`) a la altura de las fechas y métricas de tiempo de la columna izquierda para evitar vacíos visuales.

- **RF-EXP-ANIM-01 (Animación de Celebración y Navbar Inmutable)**:
  - Al completar la fase 4 y entrar al expediente, la barra superior de 4 fases se oculta limpiamente y se dispara una animación de confeti festivo por una sola vez en la sesión. La animación no vuelve a reproducirse en recargas posteriores para no degradar la experiencia de usuario.

- **RF-EXP-POLL-01 (Comprobación Reactiva sin Bloqueo)**:
  - La consulta manual o automática del estado (`checkDbStatus`) debe implementar un operador `timeout({ first: 3500 })` y un operador `finalize()` en RxJS.
  - La bandera `isCheckingStatus` debe restablecerse obligatoriamente a `false` al completarse la petición o al alcanzar el tiempo límite, garantizando que el botón de verificación nunca quede congelado en estado "Comprobando...".

### `[SRS 12.2 Requerimientos Funcionales - Algoritmo Determinista de Folios]`

- **RF-FOL-ALGO-01 (Estructura Canónica de Folio)**:
  - El sistema genera folios atómicos y deterministas con la estructura:
    - Servicio Social: `SS-YYMMDD-HEX` (p. ej. `SS-261030-01`).
    - Voluntariado General: `VG-YYMMDD-HEX` (p. ej. `VG-261030-01`).
  - La generación se ejecuta a nivel de backend durante el registro (`auth.controller.js`), calculando el consecutivo diario mediante conteo atómico sobre la colección correspondiente.

- **RF-FOL-PERSIST-01 (Persistencia e Indexación en Base de Datos)**:
  - El atributo `folio` es persistido obligatoriamente en la raíz de los modelos `student.model.js` y `volunteer.model.js`.
  - Cuenta con índice único y validación estricta para garantizar que ningún usuario carezca de folio institucional.

- **RF-FOL-DISP-01 (Visibilidad Permanente en Tablas y Perfiles)**:
  - El folio de expediente se muestra como columna fija en las tablas operativas de administración (`student.component.html`), en el encabezado de las vistas de expediente recibido y en las fichas de detalle/perfil de ambos roles.

### `[SRS 12.3 Requerimientos Funcionales - Telemetría y Métricas de Auditoría de Tiempos]`

- **RF-TIME-01 (Captura de Tiempos del Onboarding)**:
  - El sistema captura y persiste timestamps precisos en los modelos de `Student` y `Volunteer`:
    - `fechaInicioFormularioExpediente`: Registrada al cargar por primera vez la Fase 1.
    - `fechaFinFormularioExpediente`: Registrada al pulsar el botón de envío y confirmación en la Fase 4.
    - `tiempoLlenadoMinutosExpediente`: Valor numérico en minutos calculado automáticamente en el servidor:
      $$\text{tiempoLlenadoMinutosExpediente} = \text{round}\left(\frac{\text{fechaFin} - \text{fechaInicio}}{60000}\right)$$
    - `fechaEmisionExpediente`: Timestamp formal de generación del expediente digital.
    - `fechaAceptacionExpediente`: Timestamp del momento en que coordinación aprueba la cuenta.
    - `fechaExpedicionExpediente`: Timestamp de emisión de la constancia oficial de acreditación.
  - Estas métricas alimentan el subsistema de análisis de datos y auditoría de fricción en el registro.

### `[SRS 12.4 Requerimientos Funcionales - Paridad de Datos e Integridad SS vs VG]`

- **RF-PARITY-01 (Paridad Integral de Atributos)**:
  - Los esquemas de datos en base de datos y mappers TypeScript garantizan paridad estricta entre estudiantes y voluntarios generales en los siguientes campos de onboarding:
    - Identificación y contacto: `curp`, teléfono principal, teléfono de emergencia, redes sociales.
    - Personalidad y aportes: `bioPersonal`, `intereses`, `talentos`, `aportesAbaq`, `motivacionAbaq`.
    - Experiencia con bienestar animal: `animalExperience` (booleano), `descExperiencia` (texto explicativo).
    - Priorización de actividades: `rankedActivities` (arreglo de 7 actividades institucionales priorizadas).
    - Documentos en la nube: `cloudUrls` (`ine`, `comprobanteDomicilio`, `curpDoc`, `constanciaEstudios`, etc.).
    - Consentimientos legales: `consents` (términos, aviso de privacidad, normativas de bienestar animal, y carta compromiso para SS).
    - Reflexiones de inducción: `inductionReflections` (arreglo de respuestas a los 6 módulos interactivos).

- **RF-PARITY-02 (Diferenciación de Formación Académica)**:
  - Estudiantes (`SS`): Modelo mono-carrera (`school`, `career`, `semester`, `matricula`).
  - Voluntarios Generales (`VG`): Colección modular dinámica de estudios (`degrees`):
    - `degree`: Grado obtenido o cursado (Licenciatura, Maestría, Doctorado, Técnico, Bachillerato, Diplomado).
    - `institution`: Casa de estudios.
    - `fieldOfStudy`: Área de conocimiento o especialidad.
    - `graduationYear`: Año de egreso o fecha prevista.
    - `status`: Estado actual (`Titulado`, `Pasante`, `En curso`, `Trunco`).

- **RF-PARITY-03 (Límites de Edición en Mi Perfil vs Administración)**:
  - **Vista Colaborador (`StudentProfileComponent`, `VolunteerProfileComponent`)**:
    - Campos de sólo lectura inmutables: Folio, CURP, escuela/grados académicos, matrícula, horas acumuladas, estatus del expediente y consentimientos legales.
    - Campos editables por el colaborador: Biografía personal, teléfono de contacto y enlaces a redes sociales.
  - **Vista Administración (`StudentDetailComponent`, `VolunteerDetailComponent`)**:
    - Acceso total de lectura y edición autorizada sobre todos los campos del expediente, incluyendo cambio de estatus, horas validadas y modal de gestión de URLs en la nube.

### `[SRS 12.5 Requerimientos de Seguridad - Confinamiento RBAC de Cuentas Pendientes]`

- **RF-SEC-PENDING-01 (Aislamiento Estricto de Cuentas en Revisión)**:
  - Cuando un estudiante o voluntario concluye el onboarding, recibe un token JWT cuyo payload identifica el rol y el estado de la cuenta (`status: 'pending'`).
  - Mientras el estatus no sea `active` o `accepted`:
    - El token tiene acceso permitido **únicamente** a los endpoints de auto-consulta de estado: `/auth/me` y `/auth/expediente-status`.
    - Cualquier intento de acceder a colecciones o endpoints operativos (charlas `/talks`, campañas `/campaigns`, acreditaciones `/accreditations`, actividades `/activities`, pase de lista, exportación o lectura general de base de datos) es interceptado por el middleware `auth.middleware.js` y rechazado con código HTTP `403 Forbidden`.
    - Esta protección a nivel de API garantiza que un usuario avanzado no pueda interactuar con la base de datos ni consultar datos de terceros a través de peticiones HTTP manuales antes de ser aprobado.

- **RF-SEC-BOT-01 (Protección Perimetral y Anti-Bot con Cloudflare Turnstile Proxy)**:
  - Los formularios públicos de `/login` y `/signup` se integran con Cloudflare Turnstile para verificar de forma pasiva y sin CAPTCHAs invasivos que la solicitud proviene de un ser humano.
  - El backend valida el token `cf-turnstile-response` mediante llamada segura a `https://challenges.cloudflare.com/turnstile/v0/siteverify` antes de procesar contraseñas o generar documentos.
  - Se implementa arquitectura de Proxy Inverso Cloudflare sobre el dominio institucional con reglas de firewall WAF y limitación de tasa (*rate limiting*) para mitigar ataques DDoS y ataques de fuerza bruta.

---

## 13. Módulo de Ciclo de Vida, Inactivación Automática y Deshidratación de Base de Datos (v2.4.0)

### `[SRS 13.1 Requerimientos Funcionales - Máquina de Estados del Usuario]`

- **RF-STATE-01 (Enum Unificado de Estado de Cuenta)**:
  - Los esquemas `Student` y `Volunteer` implementan de forma obligatoria el atributo `accountStatus` con el enum: `['pending', 'active', 'inactive', 'rejected']`.
  - El estado inicial al concluir el onboarding en 4 fases es `pending`.

- **RF-STATE-02 (Aislamiento de Cuentas Pendientes en Login)**:
  - Si un usuario con `accountStatus: 'pending'` inicia sesión, el sistema intercepta la navegación y lo redirige exclusivamente a `/onboarding/expediente`. Se bloquea el acceso a rutas internas mediante `AuthGuard`.

- **RF-STATE-03 (Primer Ingreso Obligatorio tras Aceptación)**:
  - Los esquemas `Student` y `Volunteer` incorporan el campo booleano `primerIngresoRealizado` (default: `false`).
  - Al autenticarse por primera vez tras ser aprobado por el administrador (`accountStatus: 'active'` y `primerIngresoRealizado: false`), el usuario es redirigido a `/onboarding/expediente`.
  - En esta pantalla, el colaborador visualiza su confirmación de alta, descarga su **Carta de Aceptación y Felicitación Oficial** (`cartaAceptacion`), y pulsa el botón **"Ingresar a la Plataforma ABAQ"**.
  - Al hacer clic en dicho botón, el frontend solicita al backend la actualización persistente `primerIngresoRealizado: true` y lo redirige a la vista inicial de su rol (`/activity-list`).
  - En inicios de sesión subsecuentes (`primerIngresoRealizado: true`), el usuario ya no pasa por el expediente e ingresa directamente a su rol.
  - Si el usuario intenta forzar la navegación por URL a `/activity-list` antes de pulsar el botón de primer ingreso, `AuthGuard` lo devuelve a `/onboarding/expediente`.

- **RF-STATE-04 (Re-registro Idempotente de Usuarios Rechazados)**:
  - Cuando un administrador rechaza una solicitud, el backend actualiza `accountStatus: 'rejected'` y registra el motivo en `statusHistory`. No se elimina el documento de MongoDB.
  - El correo electrónico del colaborador **no queda bloqueado**.
  - Si un usuario rechazado vuelve a registrarse con su mismo correo, el backend reutiliza su `_id` original:
    1. Reemplaza los datos personales, académicos y respuestas de formulario.
    2. Hashea y actualiza la nueva contraseña.
    3. Limpia las causales de rechazo previas.
    4. Cambia `accountStatus` a `'pending'`.
    5. Inserta una entrada en `statusHistory` con motivo `'re_registration'`.

- **RF-STATE-05 (Bitácora statusHistory y Trazabilidad de Comentarios)**:
  - Cada entrada de `statusHistory` en `Student` y `Volunteer` debe persistir: `previousStatus`, `newStatus`, `changedAt`, `changedBy` (ObjectId del User admin o `'system_cron'`), `changedByEmail` (`req.user.email` o `'system_cron'`), `changedByRole` (`'admin' | 'system'`), `reason` y `comments`.
  - **Alineación con el Esquema de Usuarios:** Como el modelo `User` en MongoDB no cuenta con atributo de nombre propio para las cuentas de rol `admin`, la auditoría se asocia fehacientemente al correo electrónico autenticado (`changedByEmail = req.user.email`).
  - **Llenado Autónomo vs. Manual:**
    - Eventos del sistema (cumplimiento de 480 hrs, inactividad a los 60 días, re-registro): El sistema asigna un comentario institucional predeterminado.
    - Eventos manuales del Administrador (rechazo de expediente, baja discrecional, aceptación): La interfaz web despliega un modal con campo de texto para que el admin justifique el dictamen. Si se deja en blanco, aplica un comentario formal por defecto.
  - **Visibilidad en Interfaz de Expediente (`/onboarding/expediente`)**:
    - Aplica a ambos roles de voluntario (`SS` y `VG`).
    - En estado `accepted` (`active`), muestra el comentario de aprobación y felicitación institucional de la Coordinación (`comments`).
    - En estado `rejected`, despliega la tarjeta destacada con las *"Observaciones de la Coordinación: {{comments}}"*, instruyendo qué corregir antes del re-registro.
  - **Consumo en Notificaciones Resend:**
    - El cuerpo del correo transaccional incorpora el campo `comments` en una caja destacada (*callout*), asegurando que el voluntario conozca formalmente la razón del cambio de estado en su bandeja de entrada.

### `[SRS 13.2 Requerimientos Funcionales - Inactivación Automática Dual]`

- **RF-AUTO-01 (Inactivación Inmediata por Cumplimiento de 480 Horas)**:
  - Aplica exclusivamente al rol `student` (Servicio Social).
  - En la misma transacción donde el administrador aprueba una acreditación y el total de horas acreditadas alcanza o supera las 480 horas, el backend:
    1. Actualiza `accountStatus = 'inactive'`.
    2. Asigna `fechaDesactivacion = Date.now()`.
    3. Genera la URL con token criptográfico para el **Certificado de Finalización Oficial** (`renderCompletionCertificateHtml`).
    4. Registra el evento en `statusHistory` con motivo `'hours_completed'`.
    5. Despacha vía Resend el correo transaccional de finalización con el enlace de descarga oficial.

- **RF-AUTO-02 (Inactivación Integral por 2 Meses de Inactividad - 60 Días)**:
  - Aplica a ambos roles de voluntarios (`student` y `volunteer`).
  - La última actividad se calcula mediante:
    $$\text{fechaUltimaActividad} = \max(\text{lastLogin}, \text{fechaUltimaAcreditacion}, \text{fechaInscripcionActividad}, \text{fechaAceptacionExpediente})$$
  - Un proceso programado (Cron Job diario en backend) evalúa los días de ausencia:
    - **A los 45 días continuos sin actividad (15 días antes del corte):** Envía al voluntario el correo de alerta preventiva urgente (`sendInactivityWarningEmail(stage='day45')`).
    - **A los 60 días continuos sin actividad:** Actualiza `accountStatus = 'inactive'`, asigna `fechaDesactivacion = Date.now()`, registra en `statusHistory` (`'inactivity_60_days'`) y envía el correo de rescisión por abandono (`sendInactivityWarningEmail(stage='day60')`). No se emite constancia de mérito.

- **RF-AUTO-03 (Desactivación Administrativa)**:
  - El administrador puede desactivar manualmente a un colaborador desde la tabla de voluntarios, especificando el motivo del cese en `statusHistory` (`'administrative_decision'`). La emisión de constancia queda restringida únicamente a casos donde concluyó formalmente.

### `[SRS 13.3 Requerimientos Funcionales - Permisos y Restricción Operativa de Inactivos]`

- **RF-INACT-01 (Modo de Solo Consulta Histórica Previa a la Baja)**:
  - Un usuario con `accountStatus: 'inactive'` puede autenticarse para consultar su perfil e historial pasado.
  - El endpoint `GET /activities` detecta si el usuario está inactivo e inyecta el filtro obligatorio:
    $$\{ \text{createdAt}: \{ \$lte: \text{fechaDesactivacion} \} \}$$
    Impidiendo que reciba convocatorias o actividades creadas con posterioridad a su baja.

- **RF-INACT-02 (Bloqueo de Acciones de Modificación e Inscripción)**:
  - Toda petición de un usuario inactivo para inscribirse a actividades (`POST /activities/:id/enroll`), solicitar nuevas acreditaciones (`POST /accreditations`) o editar datos del expediente es interceptada y rechazada con código HTTP `403 Forbidden`.

- **RF-INACT-03 (Banner Fijo de Comentario de Inactivación en Perfiles de Usuario y Administración)**:
  - **Perfil Personal del Voluntario (`/volunteer-profile` o perfil de estudiante):**
    - Cuando la cuenta tiene `accountStatus: 'inactive'`, la vista de perfil muestra de **forma fija y permanente en la parte superior (inmediatamente debajo del header)** un banner destacado que le comunica su estatus de baja/inactivo, la fecha de desactivación, la causal (`reason`) y el comentario explicativo oficial (`comments`).
  - **Ficha del Voluntario en Administración (`StudentDetailComponent` y `VolunteerDetailComponent`):**
    - Mientras el colaborador inactivo sea visible en las interfaces normales operativas ($< 12$ meses), la ficha de detalle que consulta el administrador renderiza permanentemente en la parte superior (cerca del header) una tarjeta informativa con el comentario del cambio a `inactive`, el responsable (`changedByEmail`), la fecha y la causal, permitiendo que el admin distinga de inmediato la justificación de la baja (cumplimiento de horas, inactividad de 60 días, o baja administrativa).

### `[SRS 13.4 Requerimientos Funcionales - Visibilidad Escalonada y Voluntarios Pasados]`

- **RF-VIS-01 (Ventana Operativa de 12 Meses en Tabla Principal)**:
  - Los colaboradores inactivos con menos de 12 meses de antigüedad desde su `fechaDesactivacion` permanecen en la tabla general de voluntarios (`/volunteers` o `/student`).
  - La fila del registro se estiliza con fondo gris claro (`#f1f5f9`) y texto atenuado (`#64748b`), ordenándose al final de la paginación.

- **RF-VIS-02 (Retiro de Vistas Operativas a los 12 Meses)**:
  - Al cumplirse 1 año (365 días) de su fecha de desactivación, los registros quedan excluidos de la consulta principal y sólo son accesibles en la vista de historial.

- **RF-VIS-03 (Vista Dedicada de Voluntarios Pasados - `/volunteers/history`)**:
  - Se implementa un botón principal en el encabezado de voluntarios: *"Ver Voluntarios Pasados"*, que redirige a `/volunteers/history`.
  - La vista cuenta con dos pestañas alimentadas por Aggregation Pipelines que proyectan de forma ligera los campos exactos:
    1. **Pestaña Estudiantes Pasados:** Nombre completo, contacto (teléfono y correo), edad, fecha en la organización, fecha de activación, fecha de desactivación, total de acreditaciones, total de horas cubiertas, tipo de periodo cursado (enum universitario) y universidad.
    2. **Pestaña Voluntarios Generales Pasados:** Nombre completo, contacto, edad, fecha en la organización, fecha de activación, fecha de desactivación y total de acreditaciones (sin conteo de horas).
    3. **Pestaña Bitácora de Estados:** Visualización del historial de transiciones (`statusHistory`).

### `[SRS 13.5 Requerimientos Funcionales - Deshidratación Indivisible de Base de Datos]`

- **RF-DEHYD-01 (Principio del Corte Limpio e Indivisible)**:
  - El sistema no permite purgas parciales. Para que una actividad u oportunidad sea purgada y deshidratada, **no puede haber ni un solo alumno activo** vinculado a ella.
  - Si una actividad u oportunidad cuenta con al menos un alumno activo o con inactividad menor a 1 año, **no se elimina nada** y permanece íntegra en la base de datos operativa.
  - Cuando se cumple la condición (todos los participantes inactivos $> 1$ año y actividad/oportunidad concluida en el pasado), se purga simultáneamente todo el bloque relacional: el usuario inactivo, sus acreditaciones y los registros hijos de las oportunidades pasadas.

- **RF-DEHYD-02 (Catálogo Unificado de Oportunidades - 11 Modalidades)**:
  - El concepto de oportunidad abarca cualquier vía formal de participación en ABAQ. El proceso de deshidratación barre los modelos de las 11 opciones operativas:
    `EVENT`, `INDUCTION`, `IDENTIFICATION`, `STERILIZATION`, `ADOPTION`, `ADOPTION_MODULE`, `TALK`, `CAMPAIGN`, `MEDIA`, `SOCIAL_MEDIA`, `DONATION` y `ADMINISTRATIVE`.
  - Las plantillas maestras de actividades rápidas (`QuickActivity`) quedan permanentemente excluidas de la purga.

### `[SRS 13.6 Requerimientos Funcionales - Flujo en Dos Pasos y Token Criptográfico de Purga]`

- **RF-PURGE-01 (Tercera Columna en Sección de Respaldos e Indicador de Carga Operativa)**:
  - En la vista `/backup` ("Generar y Descargar Copias Locales"), la cuadrícula de acciones se extiende a un **diseño de tres columnas (3 tarjetas)**:
    - *Tarjeta 1:* Respaldo Completo del Sistema (`.ZIP / JSON` para rollback).
    - *Tarjeta 2:* Libro Consolidado en Excel (`.XLSX` para auditoría y patronato).
    - *Tarjeta 3:* Corte y Deshidratación de Base de Datos (`.ZIP / PURGA` para depuración histórica).
  - La Tarjeta 3 expone de forma obligatoria una **alerta visual preventiva de procesamiento**:
    > *"⚠️ Aviso: Se recomienda ejecutar esta operación fuera de horarios operativos durante el día. La verificación relacional de las 14 colecciones, empaquetado y purga demandan recursos intensivos de CPU y base de datos que podrían ralentizar el portal."*
  - La tarjeta integra un control dropdown para seleccionar la fecha de corte, el botón del Paso 1 (*"1. Descargar Corte Limpio (.zip)"*) y el botón del Paso 2 (*"2. Purgar Registros de la BD"*).

- **RF-PURGE-02 (Paso 1: Descarga y Emisión de Token de Purga)**:
  - Al pulsar *"Descargar Corte Limpio (.zip)"*, el backend procesa los registros de usuarios inactivos $> 1$ año y oportunidades concluidas que cumplan el principio de corte indivisible.
  - Genera el archivo ZIP descargable en la máquina local del administrador con los JSONs y `manifest.json` con hash SHA-256.
  - El backend emite en la cabecera HTTP un token criptográfico de un solo uso: `X-Purge-Token` (con TTL de 15 minutos).

- **RF-PURGE-03 (Paso 2: Borrado Bloqueante Condicionado)**:
  - El botón *"Purgar registros de la BD"* se encuentra deshabilitado por defecto y se habilita únicamente cuando el cliente posee un `purgeToken` válido emitido tras la descarga exitosa.
  - Al presionar el botón y confirmar con credenciales de administrador en modal de seguridad, el backend valida el token y ejecuta la purga atómica de los documentos respaldados en MongoDB.

### `[SRS 13.7 Requerimientos Funcionales - Rehidratación Idempotente y Auditoría]`

- **RF-REHYD-01 (Rehidratación por Subida de Paquete ZIP)**:
  - El administrador puede subir un archivo ZIP de deshidratación previamente descargado en `/backup`.
  - El backend procesa los JSONs y efectúa un `bulkWrite` con `replaceOne` y `upsert: true`, restaurando los documentos con sus identificadores `_id` y relaciones originales exactas.

- **RF-AUDIT-01 (Bitácora Granular de Deshidratación y Rehidratación - DehydrationAuditLog)**:
  - Toda operación de corte/purga (`dehydrate_purge`) y de rehidratación (`rehydrate_restore`) se registra de forma obligatoria e inmutable en la colección `DehydrationAuditLog`.
  - **Identidad del Ejecutor:** Registra `adminId` (`ObjectId` ref `User`) y `email` (`req.user.email` del administrador en sesión), garantizando trazabilidad ante la ausencia de campo de nombre en el modelo de administración.
  - **Trazabilidad y Folio Operativo:** Asigna un folio único determinista `operationFolio` (p. ej. `DEHYD-YYYYMMDD-HEX`), `cutoffDate`, `executedAt`, `durationMs` y estado (`completed`, `failed`, `rolled_back`).
  - **Integridad Criptográfica del Paquete:** Registra `fileName`, `sha256` (hash hexadecimal de 64 caracteres del archivo ZIP generado), `fileSizeBytes` y versión de manifiesto.
  - **Métricas Globales:** Registra `totalCollectionsAffected`, `totalDocumentsPurged`, `totalBytesFreed`, `preExecutionStorageBytes` y `postExecutionStorageBytes`.
  - **Desglose Granular por Colección:** Almacena un arreglo tipado `collections` que desglosa detalladamente para cada modelo retirado: `collectionName`, `modelKey`, `modelName`, `documentCount`, `estimatedBytesFreed`, `purgedDocumentIds` (arreglo de ObjectIds purgados), `sampleFoliosOrEmails` y `filterCriteria` aplicado.
  - **Alcance Estricto de Purgas y Preservación:**
    - *Modelos Purgables (12):* `students`, `volunteers`, `users` (únicamente con rol `student` o `volunteer`), `accreditations`, `activities` (concluidas sin alumnos activos), `notifications` (asociadas a usuarios archivados, ~41.4% del volumen histórico), `surveys`, `contacts`, `identifications`, `talks`, `campaigns` y `adoptions`.
    - *Modelos Preservados Permanentemente (4):* `quickactivities` (plantillas maestras reutilizables), `users` con rol `'admin'`, `pets` (censo comunitario de bienestar animal) y `DehydrationAuditLog`.

### `[SRS 13.8 Requerimientos Funcionales - Notificaciones Exclusivas a Voluntarios]`

- **RF-NOTIF-01 (Despacho Exclusivo al Correo de los Voluntarios vía Resend)**:
  - Todas las notificaciones transaccionales del ciclo de vida son **exclusivamente para los voluntarios** (a su correo personal registrado).
  - No existen notificaciones a los administradores ni se implementa interfaz web in-app ni campana de notificaciones.
  - Los 4 disparadores de correo transaccional son:
    1. Aceptación de expediente (`sendAcceptanceEmail`).
    2. Alerta preventiva a los 45 días de inactividad (`sendInactivityWarningEmail` etapa 45).
    3. Baja por 60 días de inactividad (`sendInactivityWarningEmail` etapa 60).
    4. Conclusión de vinculación (`sendCompletionEmail`, diferenciando horas y certificado oficial para estudiantes, vs agradecimiento sin horas para voluntarios generales).

### `[SRS 13.9 Requerimientos Funcionales - Homologación Visual de Encabezados]`

- **RF-UI-01 (Encabezados Homologados con Gradiente Institucional)**:
  - Todas las vistas principales de ambos roles adoptan el patrón de diseño `.admin-hero` / `.page-hero` con el contenedor en gradiente institucional (`linear-gradient(135deg, #1f2f63 0%, #24366f 35%, #2d6a2e 78%, #5ca83a 100%)`).
  - Aplica a: `/admin/home`, `/student`, `/activity`, `/backup`, `/volunteers/history`, `/activity-list`, `/activity-detail`, `/volunteer-profile` y `/survey`.

### `[SRS 13.10 Requerimientos Funcionales - Folios Deterministas de Interacción y Desacoplamiento]`

- **RF-FOL-01 (Nomenclatura Determinista de Solicitud de Interacción AC y OP)**:
  - El sistema asigna un folio determinista obligatorio para cada interacción de voluntariado:
    - `AC-YYMMDD-HEX`: Para postulaciones e inscripciones en actividades colectivas (`assignedActivities`).
    - `OP-CAT-YYMMDD-HEX`: Para solicitudes de validación de horas y participaciones en el catálogo de 12 oportunidades especializadas (`accreditations`).
  - **Catálogo Mnemónico Estandarizado de 3 Letras (`CAT`):** Resuelve la colisión triple de la raíz `AD`: `EVE` (Event), `IND` (Induction), `IDE` (Identification), `STE` (Sterilization), `ADO` (Adoption), `MOD` (Adoption Module), `TLK` (Talk), `CAM` (Campaign), `MED` (Media), `SOC` (Social Media), `DON` (Donation), `ADM` (Administrative).
  - **Diferenciación Operativa por Rol:**
    - Para `student`: Respalda y valida horas acreditadas hacia la meta de 480 horas curriculares.
    - Para `volunteer`: Certifica asistencia y participación cívica con garantía estricta de cero horas curriculares (`valueInHours: 0`, `validatedHours: 0`).

- **RF-FOL-02 (Arquitectura de Desacoplamiento por Doble Arreglo Embebido y Cero-Null)**:
  - Tanto `Student` como `Volunteer` alojan sus propios arreglos autosuficientes `assignedActivities` y `accreditations`.
  - **Garantía Anti-Null en Deshidratación:** Al ejecutar el corte (Opción A), el colaborador inactivo $> 1$ año se exporta al paquete ZIP (`students.json` o `volunteers.json`) con su historial completo embebido, eliminándose de Atlas sin dejar registros huérfanos ni campos nulos (`studentRef: null` erradicado al 100%).
  - Las actividades colectivas compartidas permanecen vivas en Atlas si cuentan con al menos un participante activo.
  - **Restauración Transparente:** La rehidratación con `bulkWrite` (`replaceOne` con `upsert: true`) restaura al colaborador con sus dos listados completos y folios deterministas intactos, restableciendo su historial sin dependencias foráneas.




