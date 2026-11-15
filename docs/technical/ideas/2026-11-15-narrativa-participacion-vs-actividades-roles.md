# Gobernanza Narrativa: Separación Conceptual entre Actividades Colectivas Institucionales (1 de 11 opciones) y Participación Individual 1:1, Trilogía de Roles y Flujo de Verificación

**Fecha:** 15 de Noviembre de 2026  
**Autor:** Antigravity (Google DeepMind) & Equipo ABAQ  
**Estado:** Implementado y Verificado en Rama `dev`  
**Referencias:** `documentation/docs/technical/srs.md` (Sección 25), `documentation/docs/technical/architecture.md` (ADR-31), `documentation/docs/technical/design-system.md` (Sección 13).

---

## 1. Motivación y Diagnóstico del Problema

En las versiones iniciales de la plataforma ABAQ existían tres fricciones conceptuales y lingüísticas detectadas durante la operación diaria:

1. **Ambigüedad entre "Actividad" y "Acreditación":**  
   Se utilizaban indistintamente los términos para referirse a eventos grupales colectivos (como pláticas comunitarias, paseos dominicales o jornadas masivas de esterilización) y a las participaciones individuales que un colaborador realiza y reporta a la organización.
2. **Falsa promesa de inmediatez en el botón "Nueva acreditación":**  
   El texto de los botones sugería que al presionarlos se generaba o acreditaba de forma automática una constancia u horas, cuando en la realidad de una Asociación Civil auditada por el gobierno se trata de una **solicitud formal de participación con comprobante en PDF sujeta a verificación por parte de la Coordinación**.
3. **Imprecisión en la denominación de roles:**  
   El uso genérico de "admin" o "administración" desdibujaba la figura empática y humana de la **Coordinación de Voluntariado y Servicio Social**, y a menudo confundía la distinción crucial entre **Estudiantes de Servicio Social** (sujetos a un compromiso curricular obligatorio de 480 horas) y **Voluntarios Generales** (participantes comunitarios altruistas sin presión de horas académicas).

---

## 2. Modelo Conceptual Unificado

```
                                    SISTEMA ABAQ
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
       ACTIVIDADES COLECTIVAS                       PARTICIPACIÓN INDIVIDUAL 1:1
     (Eventos Grupales ABAQ)                          (Colaborador ↔ Coordinación)
  ─────────────────────────────                   ───────────────────────────────────
  • 1 de las 11 opciones del catálogo.           • Interacción individual directa.
  • Convocatoria comunitaria pública.            • Solicitud respaldada con PDF.
  • Sede, fecha, cupo definido.                  • Requiere auditoría de Coordinación.
  • Pase de lista grupal.                        • Al validarse: ACREDITACIÓN OFICIAL.
```

### 2.1 Los 3 Roles del Sistema

1. **Estudiante de Servicio Social (`role: student`):**
   - Requisito universitario formal (meta de 480 horas).
   - Trámites de cartas de aceptación, reportes bimestrales y carta de término.
   - Cada participación validada le acumula horas académicas oficiales.
2. **Voluntario General (`role: volunteer`):**
   - Compromiso comunitario voluntario sin requerimiento curricular obligatorio.
   - Sus participaciones aprobadas quedan registradas en su expediente institucional y le otorgan constancias de labor comunitaria e insignias de bienestar animal.
3. **Coordinación / Coordinador(a) (`role: admin`):**
   - Responsable de la Coordinación de Voluntariado y Servicio Social de ABAQ.
   - Audita evidencias en PDF, emite retroalimentación, aprueba o solicita ajustes a las participaciones y programa las actividades colectivas.

---

## 3. Rediseño del Componente Modal y Botones de Acción

### 3.1 Botonera de Acción Homologada
Se reemplazó la etiqueta *"Nueva acreditación"* en todas las vistas de lista (`talk-list`, `campaign-list`, `adoption-list`, `identification-list`), vistas de detalle (`talk-detail`, `campaign-detail`, `adoption-detail`, `identification-detail`), tarjetas Super Brief (`DbRecordBriefCardComponent`) y perfiles de voluntario:
- Para Colaboradores: **`Registrar participación`**
- Para la Coordinación: **`Registrar participación a colaborador`** (en cabecera) o **`Registrar participación`** (en expedientes).
- En la interfaz de usuario se omite cualquier ratio técnico como *"1:1"*, priorizando un lenguaje natural y empático.

### 3.2 Componente Modal (`<app-new-accreditation-modal>`)
- **Eyebrow:** `Coordinación de Voluntariado · ABAQ`
- **Título reactivo:**
  - Colaborador: `Solicitud de registro de participación`
  - Coordinación: `Registrar participación de colaborador`
- **Banner Informativo de Verificación (`.accreditation-audit-banner`):**
  > **Proceso de verificación institucional:**  
  > *Este registro no se acredita de forma automática. Al enviar este formulario con tu documento comprobante (.PDF), la Coordinación de Voluntariado revisará tu evidencia para verificarla y emitir tu acreditación oficial (sumando horas curriculares si eres Estudiante de Servicio Social o acreditando tu constancia de impacto si eres Voluntario General).*
- **Botón de Envío:** `Enviar a revisión de Coordinación`

---

## 4. Verificación y Calidad

- **Compilación Frontend:** Ejecutada mediante `ng build -c production` resultando en 0 errores de compilación (`Build complete. Exit code: 0`).
- **Compatibilidad Multidispositivo:** Probado en resoluciones móviles (`320px – 640px`), tableta (`641px – 1024px`) y escritorio (`> 1024px`).
