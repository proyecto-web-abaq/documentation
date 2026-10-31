# Reporte de Avance No. 6

| | |
|---|---|
| **Fecha** | 26 de octubre de 2026 |
| **Versión** | v1.1.0 |
| **Estado** | En desarrollo (Infraestructura y Despliegue) |
| **Preparado por** | Equipo de Desarrollo ABAQ y Consultoría Técnica |

---

!!! abstract "Descargas"
    Puedes descargar este documento en los siguientes formatos:
    
    - :lucide-file-text: **[Descargar PDF](latex/report6.pdf)**
    - :lucide-file: **[Descargar Word (.docx)](latex/report6.docx)**
    - :lucide-code: **[Descargar fuente LaTeX (.tex)](latex/report6.tex)**
    - :lucide-video: **[Ver grabación de la sesión](https://teams.microsoft.com/l/meetingrecap?driveId=b%2107Fn-TnF5Ui0l8Rgu8qBvlEeGZaatelEubk4irn-v_aq61IqHa-IQoy4hgnYmHud&driveItemId=01VBXFYXFSLVC5KGW6LFCKT7JYHLYCA7JK&sitePath=https%3A%2F%2Fabaq2-my.sharepoint.com%2F%3Av%3A%2Fg%2Fpersonal%2Fmar_ledezma_abaq_org_mx%2FIQCyXUXVGt5ZRKn9ODrwIH0qAQiXWSgAp1MfhJG8hoJFHEY&fileUrl=https%3A%2F%2Fabaq2-my.sharepoint.com%2Fpersonal%2Fmar_ledezma_abaq_org_mx%2FDocuments%2FGrabaciones%2FAvances+IT+ABAQ-20261026_91334%E2%80%AFa.m.-Grabaci%C3%B3n+de+la+reuni%C3%B3n.mp4%3Fweb%3D1&iCalUid=040000008200E00074C5B7101A82E00800000000F8C496A6EB64DD010000000000000000100000001303FA33EEEBC24483F036F8FF6E5D1E&threadId=19%3Ameeting_N2ZhODk3ODUtNmQ1Ny00YjRlLWJlMTYtMjc4YmQzMzYzZGEx%40thread.v2&organizerId=eec797ff-0209-48ac-92ea-b2c078b62786&tenantId=2876b5c1-692f-4d5a-ba3c-e4958f8791ce&callId=33a4accd-2688-4fc8-b14d-1b4153ad36b6&threadType=meeting&meetingType=Scheduled&subType=RecapSharingLink_RecapCore&recapType=RecordingAndTranscript)**

## Resumen ejecutivo

Este documento presenta el sexto reporte de avance del proyecto ABAQ. Durante esta sesión de trabajo se definió el plan de acción, la arquitectura de infraestructura en la nube y los proveedores de servicios que se utilizarán para el despliegue y puesta en producción de los dos aplicativos web de la organización: el **Sistema de Base de Datos** y el **Sistema de Gestión de Tareas**.

En la reunión participaron Ángel, Fernando Israel Ríos García (voluntario del equipo de base de datos y documentación), y los consultores profesionales Michelle y Leo, quienes asumirán la administración de la infraestructura técnica y los entornos de nube. Durante la sesión se otorgaron los accesos requeridos a la base de datos MongoDB y a la organización de GitHub donde residen los repositorios oficiales de ambos proyectos.

Asimismo, se acordó la política de direccionamiento web mediante la adopción del dominio de segundo nivel con TLD `.site` (`nombreAplicacion.abaq.site`), preservando de forma íntegra el dominio institucional principal (`abaq.org.mx`). Para el cómputo en la nube se seleccionó **Railway** (`railway.app`) como plataforma homogénea de despliegue. En este período no se registraron modificaciones de código en backend ni frontend, centrándose la totalidad del esfuerzo en los acuerdos estratégicos de despliegue y soporte operativo.

---

## 1. Introducción

El presente reporte documenta los acuerdos establecidos en la sexta sesión oficial de seguimiento (26 de octubre de 2026), cuyo objetivo primordial fue coordinar la infraestructura de despliegue para las aplicaciones desarrolladas por el equipo de servicio social durante el período agosto–diciembre de 2026.

Los temas centrales abordados en la sesión comprenden:

- **Equipo de trabajo e integración de consultores:** Coordinación entre los desarrolladores del sistema y el equipo de consultoría técnica (Michelle y Leo) para la futura administración de servidores.
- **Acceso a repositorios y base de datos:** Transferencia de accesos al código fuente en GitHub y a la base de datos central en MongoDB.
- **Estrategia de dominios y resolución DNS:** Selección del dominio `abaq.site` y estructura de subdominios para aislar los entornos internos de la imagen institucional.
- **Infraestructura en la nube:** Selección de Railway como proveedor de cómputo en la nube para el alojamiento unificado de servicios y bases de datos.

---

## 2. Acuerdos y Decisiones de Infraestructura

### 2.1 Integración del equipo técnico y consultoría

Se formalizó la incorporación de Michelle y Leo como consultores profesionales y administradores de la infraestructura técnica de ABAQ. Su función principal consiste en gestionar el aprovisionamiento de servidores en la nube y coordinar la configuración de los dominios institucionales.

| Participante | Rol / Función |
|---|---|
| Ángel | Coordinación y seguimiento de proyectos |
| Fernando Israel Ríos García | Voluntario ABAQ — Base de datos, documentación y gestión técnica de DNS |
| Johan Del Ángel González | Desarrollador principal — Arquitectura y soporte de base de datos |
| Michelle | Consultora profesional — Administración de infraestructura y nube |
| Leo | Consultor profesional — Administración de infraestructura y nube |

### 2.2 Accesos y repositorios del proyecto

Durante la sesión se proporcionaron los siguientes accesos al equipo de consultoría:

1. **Base de Datos MongoDB:** Acceso administrativo al clúster de base de datos del aplicativo de voluntarios.
2. **Organización en GitHub:** Incorporación a la organización oficial donde se encuentran resguardados los proyectos de software:
    - Repositorio del proyecto **Base de Datos ABAQ**.
    - Repositorio del proyecto **Gestión de Tareas** (incorporado el 27 de octubre de 2026).
3. **Inducción técnica:** Se realizó una sesión de contexto técnico explicando el alcance, modelo de datos y arquitectura de ambos sistemas para resolver dudas iniciales de los administradores.

### 2.3 Estrategia de dominio y administración DNS

Para garantizar una operación segura y profesional, se determinaron los siguientes lineamientos sobre las direcciones web:

- **Preservación del dominio institucional:** El dominio principal (`abaq.org.mx`) no se utilizará para los aplicativos internos de gestión, resguardando la marca e identidad corporativa de la asociación.
- **Uso del dominio `.site`:** Se determinó emplear el TLD `.site`, adoptando subdominios específicos bajo el formato: `nombreAplicacion.abaq.site` (por ejemplo, `basededatos.abaq.site` y `tareas.abaq.site`).
- **Panel y gestión de registros DNS:** Debido a las restricciones técnicas del proveedor actual (`Akky.mx`), que no cuenta con un gestor ágil de zonas DNS, se acordó definir un nuevo proveedor de gestión de dominio. En este nuevo panel se otorgará un rol técnico a Fernando Israel Ríos García con facultades para crear y actualizar los registros A, CNAME e IPs de los servicios.

### 2.4 Plataforma de despliegue en la nube (Railway)

Se seleccionó **Railway (`railway.app`)** como el proveedor oficial de Infraestructura como Servicio (IaaS/PaaS) para ABAQ por las siguientes ventajas:

- Despliegue homogéneo y automatizado desde los repositorios de GitHub.
- Soporte nativo para contenedores y servicios desacoplados (Frontend Angular / React, Backend Node.js y bases de datos).
- Gestión simplificada de variables de entorno, certificados SSL automáticos y métricas de consumo.

---

## 3. Cambios en el Servidor (Backend)

Sin modificaciones registradas en código fuente durante este período. La sesión estuvo orientada exclusivamente a la definición de infraestructura y acuerdos con los consultores técnicos.

---

## 4. Cambios en la Aplicación Web (Frontend)

Sin modificaciones registradas en código fuente durante este período.

---

## 5. Evidencia Visual

No aplica para esta entrega, debido a que no hubo modificaciones de interfaz ni nuevas pantallas desplegadas. La evidencia de los acuerdos tomados se encuentra registrada en la grabación oficial de la sesión en Microsoft Teams vinculada al inicio de este documento.

---

## 6. Estado Actual del Proyecto

!!! info "Fase de Infraestructura y Despliegue"
    Se consolidó la estrategia de infraestructura y se incorporó al equipo de consultoría técnica externa. Los aplicativos de Base de Datos y Gestión de Tareas se encuentran en preparación para su publicación en la nube bajo el dominio `abaq.site`.

---

## 7. Próximos Pasos

1. **Infraestructura en Railway:**
    - 1.1 Crear la cuenta institucional de Railway para ABAQ, documentar las credenciales y compartirlas de manera segura con el equipo de consultores.
    - 1.2 Configurar el entorno de proyectos y enlazar los repositorios de GitHub correspondientes.
2. **Gestión de Dominio y DNS:**
    - 2.1 Definir los identificadores definitivos de subdominio para la aplicación de Base de Datos y la aplicación de Gestión de Tareas.
    - 2.2 Concretar la adquisición o migración del dominio `abaq.site` al nuevo proveedor de DNS.
    - 2.3 Asignar el perfil técnico a Fernando Israel Ríos García para la configuración de registros DNS hacia las IPs de Railway.
3. **Canal de Soporte y Acompañamiento Técnico:**
    - 3.1 Establecer el canal de atención para dudas y consultas operativas vía llamada telefónica o WhatsApp, en un horario de lunes a viernes de 09:00 a 18:00 horas (CST).
    - 3.2 Para dudas inherentes a la arquitectura del sistema de base de datos, canalizar la comunicación con Johan Del Ángel González (desarrollador principal) y Fernando Israel Ríos García.
