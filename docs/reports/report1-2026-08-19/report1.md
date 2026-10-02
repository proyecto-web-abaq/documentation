---
icon: lucide/file-text
---

# Reporte de Avance No. 1

| | |
|---|---|
| **Fecha** | 19 de agosto de 2026 |
| **Versión** | v1.0.0 |
| **Estado** | En planeación / Prototipado |
| **Preparado por** | Equipo de Desarrollo ABAQ |

---

!!! abstract "Descargas"
    Puedes descargar este documento en los siguientes formatos:
    
    - :lucide-file-text: **[Descargar PDF](latex/report1.pdf)**
    - :lucide-file: **[Descargar Word (.docx)](latex/report1.docx)**

## Resumen ejecutivo

Este documento presenta el primer reporte de avance del proyecto ABAQ. Durante este período se llevó a cabo la presentación oficial del primer prototipo funcional de la plataforma a la asociación ABAQ Querétaro, logrando alinear las expectativas sobre el diseño y la arquitectura del sistema. Se acordó el desarrollo de un sistema con accesos separados para administradores y estudiantes, garantizando la seguridad de la información. Finalmente, se negoció un esquema de trabajo de 8 entregas quincenales para la liberación del servicio social.

---

## 1. Introducción

Este documento resume los acuerdos y requerimientos recabados en la primera reunión oficial de seguimiento (19 de agosto de 2026) entre el equipo de desarrollo de software y ABAQ Querétaro. El propósito principal de la sesión fue validar el rumbo técnico del proyecto y formalizar las condiciones operativas.

---

## 2. Detalles del Acuerdo

### 2.1 Roles por equipo

El desarrollo del aplicativo está a cargo de un equipo de tres integrantes. Los tres conforman, de manera conjunta, el **equipo de base de datos del aplicativo**, responsable del modelo de datos que sustenta la plataforma.

| Integrante | Rol |
|---|---|
| Fernando Israel Ríos García | Documentación |
| Johan | Developer general |
| Brahn | Developer y diseñador gráfico |

El modelo de datos sobre el que trabaja este equipo está implementado en MongoDB (Mongoose) y se compone, en su estado actual, de las siguientes colecciones:

- **Estudiante (`Student`):** expediente del voluntario — nombre completo, matrícula, correos personal e institucional, escuela, carrera, fecha de arranque, auditor asignado, teléfono, fecha de nacimiento, horas (a cubrir, acreditadas y pendientes), documentos oficiales (carta de aceptación, carta de término, constancia de plática), redes sociales, periodo y estado de conclusión.
- **Contacto (`Contact`):** seguimiento de comunicaciones — correo de contacto, estudiante asociado, estado y fechas de seguimiento.
- **Encuesta (`Survey`):** instrumento de bienestar animal — estudiante asociado, datos de mascotas, esterilización, vacunación, condiciones de vida y campos de concientización.
- **Actividad (`Activity`):** actividades del servicio social — título, descripción, tipo (obligatoria, opcional o específica), fechas, valor en horas y horas validadas.

### 2.2 Fechas de entrega

Se acordó un esquema de **8 sesiones quincenales** (una cada 15 días) a partir de la primera sesión oficial del 19 de agosto de 2026. Se incluye además la sesión 0 correspondiente a la presesión de presentación inicial.

| Sesión N | Fecha | Descripción |
|---|---|---|
| 0 | 29 jul 2026 | Presesión de presentación inicial (ver Reporte No. 0) |
| 1 | 19 ago 2026 | Validación del prototipo y definición de requerimientos (Reporte No. 1) |
| 2 | 2 sep 2026 | Avance de seguridad y nuevas pantallas de administración (documentado en el Reporte No. 2, fechado el 9 sep 2026) |
| 3 | 16 sep 2026 | Seguimiento de desarrollo según próximos pasos acordados |
| 4 | 30 sep 2026 | Seguimiento de desarrollo según próximos pasos acordados |
| 5 | 14 oct 2026 | Seguimiento de desarrollo según próximos pasos acordados |
| 6 | 28 oct 2026 | Seguimiento de desarrollo según próximos pasos acordados |
| 7 | 11 nov 2026 | Seguimiento de desarrollo según próximos pasos acordados |
| 8 | 25 nov 2026 | Sesión de cierre y entrega final del sistema |

### 2.3 Acuerdos obtenidos

Sobre lo solicitado en la reunión, se obtuvieron los siguientes acuerdos:

1. **Entrega del modelo de datos de voluntarios:** se entregará un archivo Excel con el modelo de datos de los voluntarios guardados en la plataforma.
2. **Cumplimiento de las sesiones quincenales:** se cumplirá con el esquema de **8 sesiones quincenales** hasta diciembre de 2026, conforme al conteo iniciado en el primer reporte (19 de agosto de 2026), culminando con la entrega del sistema completo.

---

## 3. Cambios en el Servidor (Backend)

Sin información, no requerido.

---

## 4. Cambios en la Aplicación Web (Frontend)

Sin información, no requerido.

---

## 5. Evidencia Visual

Falta de información.

---

## 6. Estado Actual del Proyecto

!!! info "En Prototipado y Negociación"
    Se validó el prototipo funcional inicial y se acordó formalmente la liberación del servicio social a cambio de la entrega del sistema completo para diciembre de 2026.

---

## 7. Próximos Pasos

1. **Vistas Separadas:** Desarrollar y presentar el panel dividido entre Administrador y Estudiante.
2. **Datos de Prueba:** Alimentar la plataforma con registros de prueba realistas.
3. **Documentación Formal:** Elaborar un documento formal que detalle la propuesta técnica y el calendario de entregas.
