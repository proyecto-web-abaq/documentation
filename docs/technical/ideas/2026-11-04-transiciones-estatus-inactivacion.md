---
title: "Propuesta Técnica: Transiciones de Estatus, Modal Homologado de Inactivación y Sistema de Comentarios"
date: 2026-11-04
icon: lucide/shield-alert
author: "Equipo de Arquitectura e Ingeniería ABAQ"
status: "Propuesta para Revisión y Autorización"
---

# 🛡️ Propuesta y Diseño de Arquitectura: Transiciones de Estatus, Modal Homologado de Inactivación y Sistema de Comentarios Institucionales

- **Fecha de Creación:** 4 de noviembre de 2026
- **Estado:** 🟡 **Propuesta en Revisión para Autorización** (Fuente de Verdad del Sprint)
- **Ámbito:** Frontend Angular v22 Standalone & Backend Node.js / Express / MongoDB Atlas
- **Módulos Afectados:** Gestión de Voluntarios (`Student` y `Volunteer`), Autenticación (`AuthGuard`, `login`, `signup`), Onboarding (`ExpedienteRecibidoComponent`, `OnboardingStateService`), Perfiles de Autoservicio (`StudentProfile`, `VolunteerProfile`), Fichas Administrativas (`StudentDetail`, `VolunteerDetail`), Notificaciones (`email.js`, `notifications.js`).

---

## 1. Resumen Ejecutivo y Visión Holística

Durante la auditoría del ciclo de vida de los colaboradores en ABAQ, se identificaron cuatro áreas críticas de desacoplamiento entre el modelo de datos y la interfaz de usuario:

1. **Presentación Cruda de la Transición de Estatus:** En la vista de perfil activo (`/student-profile` y `/volunteer-profile`), la tarjeta de última transición muestra cadenas de código de backend sin formato (`expediente_aprobado`, `Aceptado`, fecha cruda), generando confusión en el usuario final.
2. **Carencia de Acción de Inactivación Administrativa:** La tabla general de voluntarios (`/student`) y las fichas de auditoría (`student-detail` y `volunteer-detail`) carecen de un mecanismo operativo para que un administrador pueda dar de baja o inactivar a un colaborador activo a su discreción.
3. **Falta de Guard de Seguridad y Homologación:** No existe un flujo unificado y protegido para ejecutar bajas administrativas, el cual debe exigir obligatoriamente la confirmación explícita mediante el **tipeo exacto del folio institucional** y la captura de un **comentario obligatorio** que justifique la acción.
4. **Desconexión del Campo `comments` en Onboarding y Correos:** En la pantalla de expediente recibido (`/onboarding/expediente`), tanto para aspirantes aprobados (`active`) como rechazados (`rejected`), no se muestra el contenedor de observaciones de la Coordinación, impidiendo que el aspirante rechazado conozca con exactitud qué corregir antes de su re-registro.
5. **Bloqueo y Ambigüedad en el Flujo de Re-Registro:** Si un aspirante rechazado (`accountStatus: 'rejected'`) intenta iniciar sesión o registrarse nuevamente, el sistema no tiene un flujo guiado: el login lo envía a un expediente sin botón de corrección, y el signup arroja un error tajante de `400 Email already registered` sin permitirle volver a rellenar su información bajo su rol original.

Este documento formaliza la arquitectura técnica, las especificaciones de requerimientos (funcionales y no funcionales) y el diseño modular de la solución para su revisión y autorización.

---

## 2. Desglose Modular de Arquitectura y Referencias de Código

```mermaid
flowchart TD
    subgraph UI_Admin["Módulo 4: UI Administrativa (Admin Only)"]
        T["Tabla General /student"] -->|Clic Inactivar| M["Módulo 3: InactivateVolunteerModalComponent"]
        D1["StudentDetail /student/:id"] -->|Clic Inactivar| M
        D2["VolunteerDetail /volunteer-detail/:id"] -->|Clic Inactivar| M
        D1 -->|Clic Rechazar| MR["Modal de Rechazo (Captura Observaciones)"]
        D2 -->|Clic Rechazar| MR
    end

    subgraph Modal_Guard["Módulo 3: Modal con Guard de Folio"]
        M --> G{"¿Folio Tipeado Coincide\ny Comentario no Vacío?"}
        G -->|No| B_DIS["Botón Deshabilitado"]
        G -->|Sí| B_ACT["Confirmar Inactivación\n(reason: administrative_decision)"]
    end

    subgraph Backend_Core["Módulo 1: Gobernanza Backend"]
        B_ACT --> EP["PATCH /student|volunteer/:id/account-status"]
        MR --> EP
        EP --> ASC["applyStatusChange(user, {toStatus, reason, comments})"]
        ASC --> DB[(MongoDB: statusHistory[] + fechaDesactivacion)]
    end

    subgraph Onboarding_ReReg["Módulo 2: Re-Registro y Expediente"]
        LOG["Login Aspirante Rechazado"] --> EXP["Expediente: Muestra Observaciones {{comments}}\n(Solo lectura, Contacto y Logout)"]
        SIGN["Aspirante en /auth/signup"] --> CHK{"Verificar Email en users"}
        CHK -->|Si rejected| ONBOARD["Completa Onboarding y Registro"]
        ONBOARD --> RE_REG["POST /auth/signup (reason: re_registration)"]
        RE_REG --> PURGE["Si cambió de rol: Purga registro anterior huérfano"]
        PURGE --> DB
    end

    subgraph UI_Profiles["Módulo 5: Visualización de Estatus"]
        DB --> P_INACT["Perfil Inactivo: Banner Rojo con Comentario y Fecha"]
        DB --> P_ACT["Perfil Activo: Tarjeta Amigable Institucional"]
    end
```

---

### Módulo 1: Gobernanza de Estados y Comentarios en Backend (`backend-status-governance`)

* **Referencias de Código (`ref`):**
  * [`backend/utils/status-history.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/utils/status-history.js)
  * [`backend/models/student.model.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/models/student.model.js#L420-L450)
  * [`backend/models/volunteer.model.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/models/volunteer.model.js#L260-L290)
  * [`backend/controllers/student.controller.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/controllers/student.controller.js#L329-L380)
  * [`backend/controllers/volunteer.controller.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/controllers/volunteer.controller.js#L223-L270)
  * [`backend/controllers/accreditation.controller.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/controllers/accreditation.controller.js#L263-L281)

#### 1.1 Catálogo Oficial de Causales Internas (`reason`)
El campo `reason` en `statusHistory` es un identificador técnico interno de base de datos. Se establecen formalmente 6 causales oficiales:

| Causal Técnica (`reason`) | Naturaleza | Transición de Estado | Roles a los que Aplica | Descripción Operativa |
| :--- | :--- | :--- | :--- | :--- |
| **`initial_signup`** | Automática (Sistema) | `null` ➔ `pending` | Estudiante y Voluntario | Registro inicial completo de onboarding y registro. Estado por defecto en base de datos. |
| **`admin_approval`** | Manual (Admin) | `pending` ➔ `active` | Estudiante y Voluntario | Aceptación y alta formal por Coordinación tras auditar expediente. Soporta notas de bienvenida en `comments`. |
| **`admin_rejection`** | Manual (Admin) | `pending` ➔ `rejected` | Estudiante y Voluntario | Rechazo de solicitud con observaciones obligatorias capturadas en modal para corrección del aspirante. |
| **`hours_completed`** | Automática (Sistema) | `active` ➔ `inactive` | **Solo Estudiantes (SS)** | Conclusión reglamentaria de 480 horas curriculares. Emite certificado de término oficial. |
| **`administrative_decision`**| Manual (Admin) | `active` ➔ `inactive` | Estudiante y Voluntario | Baja administrativa ejecutada a discreción del admin mediante el nuevo modal con guard de folio. |
| **`re_registration`** | Automática (Sistema) | `rejected` ➔ `pending` | Estudiante y Voluntario | Re-registro e ingreso de nuevo formulario tras haber sido rechazado previamente. |

#### 1.2 Regla de Inactividad y Desconexión de Certificados
* **Estado del Módulo de Certificados:** Se toma en cuenta que el subsistema de generación de certificados está actualmente bajo revisión en una rama externa independiente. Por ende:
  * Las interfaces no deben generar ni consultar datos *mock* de certificados.
  * **En casos de inactividad o baja administrativa (`administrative_decision`, `inactivity_60_days`):** Queda estrictamente desconectado cualquier botón o llamada a emisión de certificados, ya que la baja por inactividad carece de mérito.
* **Conclusión por 480 horas (`hours_completed`):** Es la única transición a `inactive` que dispara el envío de la notificación de finalización para estudiantes (`sendCompletionEmail`).

#### 1.3 Endpoints HTTP y Conexión de `applyStatusChange`
Los endpoints `PATCH /student/:id/account-status` y `PATCH /volunteer/:id/account-status` deben:
1. Validar que la petición provenga de un usuario con rol `admin` (`protect`, `restrictToAdmin`).
2. Recibir del cuerpo (`req.body`): `{ accountStatus, reason, comments }`.
3. Invocar centralizadamente el helper:
   ```javascript
   applyStatusChange(doc, {
     toStatus: accountStatus,
     reason: reason || (accountStatus === "inactive" ? "administrative_decision" : (accountStatus === "rejected" ? "admin_rejection" : "admin_approval")),
     comments: comments || "",
     changedBy: req.user.email,
   });
   ```
4. Si `accountStatus === 'inactive'`, fijar `doc.fechaDesactivacion = new Date()`. Si pasa a `active`, fijar `doc.fechaDesactivacion = null`.
5. Persistir el documento y retornar el registro actualizado en `data.document`.

---

### Módulo 2: Flujo de Re-Registro, Cambio de Rol y Blindaje de Seguridad (`auth-re-registration-and-security`)

* **Referencias de Código (`ref`):**
  * [`backend/controllers/auth.controller.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/controllers/auth.controller.js#L131-L280)
  * [`backend/middlewares/auth.middleware.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/middlewares/auth.middleware.js#L87-L111)
  * [`frontend/src/app/guards/auth.guard.ts`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/guards/auth.guard.ts#L25-L35)
  * [`frontend/src/app/components/login/login.component.ts`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/login/login.component.ts#L101-L113)
  * [`frontend/src/app/components/onboarding/expediente-recibido.component.ts`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/onboarding/expediente-recibido.component.ts#L430-L460)

#### 2.1 Flujo A: El usuario intenta entrar desde `/auth/login` (Ruta Natural del Aspirante Registrado)
1. **Redirección Obligatoria al Expediente:** Cuando un aspirante rechazado ingresa sus credenciales en `/auth/login`, el backend autentica la identidad y devuelve `accountStatus: 'rejected'`. El controlador de login y el `AuthGuard` interceptan la navegación y lo redirigen **siempre y de forma forzosa a `/onboarding/expediente`**.
2. **Interfaz de Expediente Rechazado:** En `/onboarding/expediente`, el aspirante visualiza:
   * Encabezado de alerta: *Solicitud no aprobada*.
   * **Caja destacada de Observaciones de la Coordinación:** `{{ comments }}` (el motivo formal por el cual no fue admitido, ej. documentación ilegible, falta de sello institucional, link de nube sin permisos).
   * Su número de folio institucional original.
3. **Las dos únicas acciones habilitadas para el aspirante en Expediente:**
   * **Acción 1: Cerrar Sesión (`btn-expediente-logout`):** Destruye el token local y redirige a `/auth/login`.
   * **Acción 2: Contactar a Coordinación (`btn-contact-rejected`):** Enlace de aclaración formal vía correo.
   * **Preservación del Layout Original:** En `/onboarding/expediente` **no se agregan botones de cambio de rol ni de re-registro**. La pantalla permanece limpia y fiel a su diseño original, sirviendo estrictamente para informar el estatus y exponer las observaciones de la Coordinación. Si el aspirante desea re-registrarse o cambiar de rol, lo hace de forma natural a través de `/auth/signup` fuera de su expediente.

#### 2.2 Flujo de Re-Registro y Cambio de Rol en `/auth/signup` (Fuera de Expediente)
El proceso de re-registro e interceptación ocurre íntegramente en la vista de registro `/auth/signup`:

1. El aspirante entra a `/auth/signup`, selecciona la modalidad deseada (`SS` o `VG`) e ingresa su correo y contraseña.
2. Al procesar el registro, el sistema verifica si el correo ya existe en la colección `users`:
   * **Si el usuario existe y su estatus es `rejected`:**
     * **Caso 1: Re-registro en la misma modalidad (Mismo Rol):**
       * Sobrescribe los datos en el documento existente de la colección (`students` o `volunteers`).
       * Actualiza la contraseña (`passwordHash`).
       * Cambia el estatus a `accountStatus: 'pending'`.
       * Agrega una entrada en `statusHistory` con `reason: 're_registration'` y comentario automático formal.
     * **Caso 2: Re-registro con cambio de modalidad (Cambio de Rol: `SS` ➔ `VG` o `VG` ➔ `SS`):**
       * Actualiza el rol del usuario en la colección `users` (`user.role = nuevoRol`).
       * Crea el nuevo documento correspondiente en la colección destino (`volunteers` si pasó a VG, o `students` si pasó a SS) con los nuevos datos de onboarding y registro.
       * **¿Qué sucede con el registro viejo? (Resolución Arquitectónica):**
         El documento anterior en la otra colección **se elimina/purga de la base de datos de forma atómica** (`Student.deleteOne` o `Volunteer.deleteOne`).
         * *Fundamento técnico:* Al haber sido un trámite rechazado, nunca estuvo formalmente activo, no acumuló horas curriculares ni asistencias válidas. Purgar el documento viejo previene documentos huérfanos con el mismo correo, elimina conflictos con índices únicos de MongoDB y evita que consultas como `checkExpedienteStatus` lean el registro obsoleto de la colección equivocada.
       * Se establece `accountStatus: 'pending'` y se registra en `statusHistory` con `reason: 're_registration'` y comentario formal de cambio de modalidad.
   * **Si el usuario existe y su estatus NO es `rejected` (`active`, `pending`, `inactive`):**
     * Se mantiene el bloqueo estricto de seguridad `400 Email already registered` para proteger cuentas en proceso o activas.

#### 2.3 Blindaje Estricto de Seguridad y Limitaciones de Acceso
Conforme a las mejores prácticas de gobernanza y seguridad de la información:

1. **Aislamiento en Backend (Cero Acceso a Datos o API):**
   * El middleware [`requireActiveAccount`](file:///Users/riosisraelg/Desktop/1/abaq/backend/middlewares/auth.middleware.js#L93-L111) está activo en todas las rutas operativas (`/activity`, `/accreditation`, `/campaigns`, `/identification`, `/talks`, `/adoptions`, `/pets`, `/contact`).
   * Se extiende `requireActiveAccount` a los endpoints de perfil de usuario (`PATCH /student/me` y `PATCH /volunteer/me`).
   * **Resultado:** Todo aspirante en estado `pending` o `rejected` que intente ejecutar peticiones REST de lectura o escritura a la base de datos recibe de inmediato un `403 Forbidden` (`Acceso denegado: tu expediente se encuentra en estado '${status}'`).
   * Únicamente tienen permitida la lectura de su propia sesión básica (`GET /auth/me`) y de su estatus de expediente (`GET /auth/expediente-status`).
2. **Aislamiento en Frontend (Guard de Enrutamiento Infranqueable):**
   * El [`AuthGuard`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/guards/auth.guard.ts#L25-L35) valida que si `user.accountStatus === 'pending' || user.accountStatus === 'rejected'`, la única ruta navegable sea `/onboarding/expediente`. Si el usuario desea corregir o cambiar de modalidad, lo efectúa ingresando al flujo de onboarding y registro en `/auth/signup` fuera de la sesión autenticada.
   * Cualquier intento manual de escribir en la barra del navegador `/home`, `/student-profile`, `/my-accreditations` o `/activity-list` es interceptado y retornado a `/onboarding/expediente`.

---

### Módulo 3: Componente Modal Reutilizable de Inactivación con Guard de Folio (`frontend-inactivate-modal`)

* **Referencias de Código (`ref`):**
  * Directorio del nuevo componente: `frontend/src/app/components/shared/inactivate-volunteer-modal/`
  * Servicios: [`student.service.ts`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/services/student.service.ts), [`volunteer.service.ts`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/services/volunteer.service.ts)

#### 3.1 Especificación del Componente Standalone
Un componente Angular Standalone desacoplado y reutilizable, con diseño institucional basado en el Design System de ABAQ:

```typescript
@Component({
  selector: 'app-inactivate-volunteer-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './inactivate-volunteer-modal.html',
  styleUrls: ['./inactivate-volunteer-modal.scss'],
})
export class InactivateVolunteerModalComponent {
  @Input({ required: true }) targetId!: string;
  @Input({ required: true }) targetFolio!: string;
  @Input({ required: true }) targetName!: string;
  @Input({ required: true }) targetRole!: 'student' | 'volunteer';

  @Output() confirmed = new EventEmitter<{ reason: string; comments: string }>();
  @Output() cancelled = new EventEmitter<void>();

  typedFolio: string = '';
  comments: string = '';
  isSubmitting: boolean = false;
  errorMessage: string | null = null;
}
```

#### 3.2 Guard de Seguridad por Folio
* Para prevenir bajas accidentales o clics involuntarios, el modal renderiza una advertencia destructiva.
* Contiene un campo de entrada: `Escribe exactamente "${targetFolio}" para confirmar`.
* El botón principal **"Inactivar Cuenta Definitivamente"** permanece deshabilitado (`disabled`) hasta que se cumplan dos condiciones simultáneas:
  1. `typedFolio.trim() === targetFolio.trim()` (coincidencia exacta caracter por caracter).
  2. `comments.trim().length > 0` (el administrador debe redactar obligatoriamente la justificación de la baja).

#### 3.3 Gestión de Causal Invisible (`reason`)
* Para el administrador, el valor técnico `reason` es 100% invisible.
* El componente envía automáticamente `reason: 'administrative_decision'`.
* El textarea de `comments` se presenta vacío, sin textos precargados arbitrarios, permitiendo que el administrador capture sus observaciones institucionales con absoluta discreción y claridad.

---

### Módulo 4: Puntos de Acceso Homologados en UI de Administración (`frontend-admin-access`)

* **Referencias de Código (`ref`):**
  * [`frontend/src/app/components/student/student.component.html`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/student/student.component.html#L457-L466)
  * [`frontend/src/app/components/student/student.component.ts`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/student/student.component.ts)
  * [`frontend/src/app/components/student-detail/student-detail.html`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/student-detail/student-detail.html#L177-L208)
  * [`frontend/src/app/components/volunteer-detail/volunteer-detail.html`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/volunteer-detail/volunteer-detail.html#L180-L212)

#### 4.1 Gestión de Comentarios para los Tres Cambios de Estado Administrativos
El administrador gestiona comentarios para los dos roles de voluntarios (`student` y `volunteer`) en las tres transiciones administrativas:

1. **Inactivar Cuenta (`active` ➔ `inactive`):**
   * Dispara el `InactivateVolunteerModalComponent`.
   * Exige el guard de folio exacto y comentario obligatorio a discreción del administrador.
2. **Rechazar Solicitud (`pending` ➔ `rejected`):**
   * Se sustituye el `confirm()` nativo del navegador por un modal institucional de rechazo.
   * Solicita obligatoriamente las **Observaciones de Rechazo** (`comments`), las cuales se guardan en `statusHistory` con `reason: 'admin_rejection'` y se despliegan al aspirante en `/onboarding/expediente`.
3. **Aceptar Solicitud (`pending` ➔ `active`):**
   * En la acción de alta, se registra en `statusHistory` con `reason: 'admin_approval'`.
   * Si el administrador no especifica notas particulares, se inyecta la plantilla predeterminada: *"Expediente validado satisfactoriamente por la Coordinación de ABAQ"*.

#### 4.2 Punto de Acceso 1: Tabla de Voluntarios (`/student`)
* En ambas pestañas (`ss` y `general`):
  * Para colaboradores con `accountStatus === 'active'`, se agrega junto a *"Ver detalle"* el botón destructivo de baja con ícono `person_off`.
  * Para solicitudes en `accountStatus === 'pending'`, el botón de rechazo abre el modal de captura de observaciones.
* Al confirmar el modal, la tabla refresca reactivamente el registro, enviando al usuario inactivo al fondo de la lista con fila gris atenuada.

#### 4.3 Punto de Acceso 2: Fichas de Detalle (`student-detail` y `volunteer-detail`)
* En la cabecera / hero de ambas fichas para colaboradores activos:
  * Botón institucional: `[person_off] Inactivar Colaborador` (outline rojo/advertencia).
* Al confirmar, la vista actualiza su estado local atómicamente y renderiza de inmediato la **Tarjeta de Registro Inactivo**.

---

### Módulo 5: Visualización Contextual de Estatus y Comentarios en Perfiles y Expediente (`frontend-status-display`)

* **Referencias de Código (`ref`):**
  * [`student-profile.html`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/student-profile/student-profile.html#L152-L181)
  * [`volunteer-profile.html`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/volunteer-profile/volunteer-profile.html#L150-L180)
  * [`student-detail.html`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/student-detail/student-detail.html#L215-L252)
  * [`volunteer-detail.html`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/volunteer-detail/volunteer-detail.html#L215-L252)
  * [`expediente-recibido.component.ts`](file:///Users/riosisraelg/Desktop/1/abaq/frontend/src/app/components/onboarding/expediente-recibido.component.ts)

#### 5.1 Tarjeta Amigable de Estatus Activo en "Mi Perfil"
Se elimina la presentación cruda de variables de backend (`expediente_aprobado`, `Aceptado`). En su lugar se renderiza un contenedor institucional informativo:

```html
<div class="status-active-card">
  <div class="status-badge-row">
    <span class="status-dot green"></span>
    <span class="status-badge-title">ESTATUS DE LA CUENTA · COLABORADOR ACTIVO</span>
  </div>
  <p class="status-active-desc">
    Expediente digital verificado y aprobado formalmente por la Coordinación de ABAQ. Cuentas con acreditación vigente para participar en actividades y registrar horas.
  </p>
  @if (lastStatusChange?.comments) {
    <div class="status-welcome-note">
      <span class="material-symbols-outlined text-sm">chat</span>
      <span><strong>Mensaje de la Coordinación:</strong> {{ lastStatusChange.comments }}</span>
    </div>
  }
  @if (lastStatusChange?.date) {
    <span class="status-active-date">Alta registrada: {{ lastStatusChange.date | date:'dd/MM/yyyy HH:mm' }}</span>
  }
</div>
```

#### 5.2 Banners de Cuenta Inactiva Homologados
* **En el Perfil Personal del Voluntario (`student-profile` y `volunteer-profile`):**
  > 🛑 **Cuenta Inactiva / Servicio Concluido:** {{ lastStatusChange?.comments || 'Baja administrativa registrada.' }}  
  > *Fecha de Desactivación: {{ student.fechaDesactivacion | date:'dd/MM/yyyy' }} · Causal: Decisión Administrativa*
* **En la Vista Administrativa (`student-detail` y `volunteer-detail`):**
  > ℹ️ **Registro Inactivo:** {{ lastStatusChange?.comments || 'Baja administrativa registrada.' }}  
  > *Inactivado el: {{ student.fechaDesactivacion | date:'dd/MM/yyyy HH:mm' }} por {{ lastStatusChange?.changedByEmail || 'Coordinación' }}*

#### 5.3 Caja de Observaciones en `/onboarding/expediente`
Se actualizan los controladores del backend (`/auth/me` y `/expediente-status`) para exponer `comments` y `lastStatusChange`. En la interfaz:
1. **Estado `active`:** Tarjeta oficial de felicitación acompañada de:
   > 💬 **Mensaje de Bienvenida de la Coordinación:** *"{{ comments }}"*
2. **Estado `rejected`:** Contenedor de alerta ámbar/rojo con observaciones para corrección del aspirante:
   > ⚠️ **Observaciones de la Coordinación para tu Solicitud:**  
   > *"{{ comments }}"*  
   > *Las únicas acciones en pantalla son `[🚪 Cerrar Sesión]` y `[✉️ Contactar a Coordinación]`. Si el aspirante desea corregir y volver a enviar su expediente o cambiar de rol, lo realiza libremente en `/auth/signup` fuera del expediente.*

---

### Módulo 6: Análisis Integral y Comparativo de Notificaciones Transaccionales (Resend API) (`email-notifications`)

* **Referencias de Código (`ref`):**
  * [`backend/utils/email.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/utils/email.js)
  * [`backend/utils/notifications.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/utils/notifications.js)
  * [`backend/controllers/student.controller.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/controllers/student.controller.js)
  * [`backend/controllers/volunteer.controller.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/controllers/volunteer.controller.js)
  * [`backend/controllers/accreditation.controller.js`](file:///Users/riosisraelg/Desktop/1/abaq/backend/controllers/accreditation.controller.js)

#### 6.1 Matriz de Diagnóstico y Contraste: Estado Actual vs Estado Propuesto

| Evento / Transición | Estado Actual en Código (`email.js` / `notifications.js`) | Estado Propuesto en esta Solución | Brecha Identificada (Gap) | ¿Emite Certificado? |
| :--- | :--- | :--- | :--- | :--- |
| **1. Aceptación de Expediente**<br>`pending` ➔ `active`<br>(`admin_approval`) | Existe `sendAcceptanceEmail`. Envía saludo institucional, regla de permanencia de 60 días para SS y enlace a Carta de Aceptación. | Se preserva la plantilla y se inyecta la **Caja Destacada de Bienvenida** (`comments`) si el administrador la capturó. | Falta inyectar el callout de comentarios (`comments`) en el cuerpo del correo. | **Sí** (Carta de Aceptación firmada). |
| **2. Rechazo de Expediente**<br>`pending` ➔ `rejected`<br>(`admin_rejection`) | **INEXISTENTE.** Ningún correo se envía cuando el administrador rechaza un expediente en el backend. | Se implementa `sendRejectionEmail` con callout de alerta ámbar/rojo conteniendo las **Observaciones de Coordinación** (`comments`), instruyendo al aspirante cómo corregir en `/auth/signup`. | **Brecha Crítica:** El aspirante no recibe retroalimentación por correo y desconoce el rechazo hasta volver a autenticarse. | **NO** (Bajo ninguna circunstancia). |
| **3. Baja Administrativa Discrecional**<br>`active` ➔ `inactive`<br>(`administrative_decision`) | No existe plantilla específica para baja manual por Coordinación. Solo existe aviso por días de inactividad (`day60`). | Se adapta/despacha notificación formal de baja administrativa que expone el motivo obligatorio redactado en el modal (`comments`), fecha y folio. | Carencia de correo contextualizado para bajas administrativas no motivadas por abandono de días. | **NO** (Estrictamente prohibido sin mérito). |
| **4. Alertas Preventivas de Inactividad**<br>Día 30 y Día 45<br>(`inactivityStage`) | Implementadas en `email.js` (`sendInactivityWarningEmail` con `stage: 'day30'` y `stage: 'day45'`). | Se mantienen operativas como avisos preventivos amarillos/naranjas informando el tiempo restante antes de la baja definitiva. | Conexión con los flujos de auditoría del sistema sin requerir cron demoníaco. | **NO** |
| **5. Baja por 60 Días de Abandono**<br>`active` ➔ `inactive`<br>(`day60`) | Implementada en `email.js` (`sendInactivityWarningEmail` con `stage: 'day60'`). Notifica que la medida administrativa fue ejecutada de oficio. | Se homologa el remitente y formato para alinearlo a la gobernanza de bajas de ABAQ. | Se mantiene el mensaje resolutivo de corte. | **NO** |
| **6. Conclusión de 480 Horas**<br>`active` ➔ `inactive`<br>(`hours_completed`) | Implementada en `email.js` (`sendCompletionEmail`), invocada desde `accreditation.controller.js` al validar 480 hrs para SS. | Se mantiene como el único correo de finalización con mérito. *Nota: enlace a certificado queda desconectado temporalmente mientras la rama externa de certificados concluye.* | Preservar plantilla verde de honor y felicitaciones. | **Sí** (Exclusivo para SS con 480 hrs). |
| **7. Nueva Solicitud para Coordinación**<br>`null` ➔ `pending`<br>(`initial_signup`) | Implementada en `email.js` (`sendNewUserRegistrationAdminEmail`). Se despacha a `ADMIN_EMAIL` con datos del formulario. | Se garantiza su disparo en el registro inicial de ambos roles (`SS` y `VG`). | Ninguna brecha funcional; la plantilla actual es completa. | **N/A** (Correo interno). |

---

#### 6.2 Despliegue Visual en Vivo (HTML Previews) de las Plantillas de Correo Electrónico

A continuación se despliegan las vistas preliminares reales de las plantillas transaccionales formateadas con el motor HTML en línea de ABAQ Querétaro, tal como las recibe el usuario en su bandeja de entrada:

=== "1. Aceptación Oficial (admin_approval)"

    <div style="background: #f1f5f9; padding: 24px; border-radius: 12px; margin: 16px 0;">
      <div style="font-family: system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; padding: 28px; border-radius: 16px; border: 1px solid #e2e8f0; color: #1e293b; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
        <div style="text-align: center; margin-bottom: 20px;">
          <span style="display: inline-block; background: #1d3d69; color: #ffffff; font-weight: 800; padding: 6px 14px; border-radius: 999px; font-size: 11px; letter-spacing: 1px;">ABAQ QUERÉTARO · BIENESTAR ANIMAL</span>
        </div>
        <h1 style="color: #1d3d69; font-size: 22px; margin: 0 0 12px; text-align: center;">¡Felicidades, Valeria Gómez Mendoza! 🎉</h1>
        <p style="font-size: 14.5px; line-height: 1.6; color: #334155;">
          La coordinación de ABAQ ha validado y aprobado satisfactoriamente tu expediente digital (Folio <strong>SS-261103-VG</strong>). ¡Bienvenida oficialmente a nuestra comunidad de <strong>Servicio Social (480 horas)</strong>!
        </p>
        
        <!-- Callout Box con Comentarios de la Coordinación -->
        <div style="margin: 20px 0; padding: 16px 20px; background: #f0fdf4; border-left: 4px solid #16a34a; border-radius: 8px; color: #14532d; font-size: 14px; line-height: 1.6;">
          <strong style="display: block; margin-bottom: 4px; font-size: 14px;">💬 Mensaje de Bienvenida de la Coordinación:</strong>
          <em>"Bienvenida al equipo de bienestar animal. Tu horario asignado para el taller presencial de inducción y primeros auxilios veterinarios es este viernes a las 10:00 AM en el refugio central. Recuerda presentar tu credencial escolar vigente."</em>
        </div>

        <!-- Cláusula de Permanencia en Servicio Social -->
        <div style="margin: 18px 0; padding: 14px 18px; background: #fffbeb; border-left: 4px solid #d97706; border-radius: 8px; color: #92400e; font-size: 13.5px; line-height: 1.5;">
          <strong style="display: block; margin-bottom: 4px;">⚠️ NOTA OFICIAL DE PERMANENCIA EN SERVICIO SOCIAL:</strong>
          Conforme al reglamento interno de ABAQ, acumular <strong>2 meses (60 días) continuos de inactividad o ausencia sin notificación previa</strong> a la Coordinación causa directamente la <strong>baja definitiva</strong> del programa (medida administrativa de oficio).
        </div>

        <div style="text-align: center; margin: 26px 0;">
          <a href="#" style="display: inline-block; background: #7cb042; color: #ffffff; text-decoration: none; font-weight: 700; padding: 13px 24px; border-radius: 10px; font-size: 14.5px; box-shadow: 0 2px 4px rgba(124,176,66,0.3);">
            📄 Ver y Descargar Carta de Aceptación y Felicitación
          </a>
        </div>
        <p style="font-size: 12.5px; color: #64748b; text-align: center; margin-bottom: 0;">
          Asociación de Bienestar Animal Querétaro (ABAQ) · Dirección de Servicio Social y Voluntariado
        </p>
      </div>
    </div>

=== "2. Rechazo de Expediente (admin_rejection)"

    <div style="background: #f1f5f9; padding: 24px; border-radius: 12px; margin: 16px 0;">
      <div style="font-family: system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; padding: 28px; border-radius: 16px; border: 1px solid #e2e8f0; color: #1e293b; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
        <div style="text-align: center; margin-bottom: 20px;">
          <span style="display: inline-block; background: #dc2626; color: #ffffff; font-weight: 800; padding: 6px 14px; border-radius: 999px; font-size: 11px; letter-spacing: 1px;">ABAQ QUERÉTARO · EXPEDIENTE DIGITAL</span>
        </div>
        <h1 style="color: #991b1b; font-size: 21px; margin: 0 0 12px; text-align: center;">Observaciones sobre tu Solicitud de Registro 📋</h1>
        <p style="font-size: 14.5px; line-height: 1.6; color: #334155;">
          Estimado(a) <strong>Rodrigo Salinas Arce</strong> (Folio de trámite <strong>SS-261103-RS</strong>),<br><br>
          Agradecemos tu interés en integrarte al programa de Servicio Social de ABAQ Querétaro. Tras la revisión minuciosa efectuada por el Comité de Coordinación, te informamos que tu expediente <strong>no ha podido ser aprobado en esta etapa</strong> debido a inconsistencias documentales.
        </p>

        <!-- Callout Box Destacado con Observaciones del Admin -->
        <div style="margin: 22px 0; padding: 18px 20px; background: #fef2f2; border-left: 4px solid #dc2626; border-radius: 8px; color: #991b1b; font-size: 14px; line-height: 1.6;">
          <strong style="display: block; margin-bottom: 6px; font-size: 14.5px;">⚠️ Observaciones de la Coordinación para Corrección:</strong>
          <em>"El documento de constancia de vigencia de derechos adjunto no cuenta con el sello institucional de la universidad y el enlace a la carpeta digital de documentos se encuentra como 'privado' (requiere permisos públicos de lectura). Por favor actualiza los archivos para validar tu horario."</em>
        </div>

        <p style="font-size: 14px; line-height: 1.6; color: #475569;">
          <strong>¿Cómo continuar tu proceso?</strong><br>
          Puedes iniciar sesión para revisar tus observaciones o dirigirte a la página de registro oficial de ABAQ para reingresar tus datos con las correcciones indicadas utilizando este mismo correo:
        </p>

        <div style="text-align: center; margin: 26px 0;">
          <a href="#" style="display: inline-block; background: #1d3d69; color: #ffffff; text-decoration: none; font-weight: 700; padding: 13px 24px; border-radius: 10px; font-size: 14.5px;">
            ✏️ Ingresar a la Plataforma de Registro
          </a>
        </div>
        
        <p style="font-size: 12.5px; color: #64748b; line-height: 1.5; text-align: center; margin-bottom: 0;">
          Para cualquier duda o aclaración, puedes responder a este correo o escribir a <a href="mailto:coordinacion@hypercoreqro.lat" style="color: #1d3d69; font-weight: 600;">coordinacion@hypercoreqro.lat</a>.<br>
          Coordinación de Servicio Social y Voluntariado · ABAQ.
        </p>
      </div>
    </div>

=== "3. Baja Administrativa Discrecional (administrative_decision)"

    <div style="background: #f1f5f9; padding: 24px; border-radius: 12px; margin: 16px 0;">
      <div style="font-family: system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; padding: 28px; border-radius: 16px; border: 1px solid #e2e8f0; color: #1e293b; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
        <div style="text-align: center; margin-bottom: 20px;">
          <span style="display: inline-block; background: #475569; color: #ffffff; font-weight: 800; padding: 6px 14px; border-radius: 999px; font-size: 11px; letter-spacing: 1px;">ABAQ QUERÉTARO · RESOLUCIÓN ADMINISTRATIVA</span>
        </div>
        <h2 style="color: #1e293b; font-size: 20px; margin: 0 0 12px; text-align: center;">Notificación Oficial de Baja Administrativa 🛑</h2>
        <p style="font-size: 14.5px; line-height: 1.6; color: #334155;">
          Estimado(a) <strong>Carlos Eduardo Ortiz</strong> (Folio <strong>VG-261103-CO</strong>),<br><br>
          Por medio del presente comunicado, la Coordinación de la Asociación de Bienestar Animal Querétaro (ABAQ) te notifica formalmente que se ha hecho efectiva la <strong>baja definitiva</strong> de tu registro en el sistema institucional.
        </p>

        <!-- Callout Box con Comentario del Modal Admin -->
        <div style="margin: 20px 0; padding: 18px 20px; background: #fef2f2; border-left: 4px solid #b91c1c; border-radius: 8px; color: #991b1b; font-size: 14px; line-height: 1.6;">
          <strong style="display: block; margin-bottom: 6px; font-size: 14.5px;">📋 Motivo y Dictamen de la Coordinación:</strong>
          <em>"Baja administrativa aplicada de común acuerdo a petición del colaborador por motivos de reubicación laboral fuera del estado. Agradecemos su compromiso en las campañas de esterilización comunitaria."</em>
        </div>

        <div style="background: #f8fafc; border: 1px solid #cbd5e1; border-radius: 8px; padding: 14px 18px; margin: 18px 0; font-size: 13.5px; line-height: 1.6; color: #334155;">
          <p style="margin: 2px 0;"><strong>Fecha de Desactivación:</strong> 04/11/2026</p>
          <p style="margin: 2px 0;"><strong>Causal Registrada:</strong> Decisión Administrativa (Baja manual)</p>
          <p style="margin: 2px 0;"><strong>Estatus Operativo:</strong> Inactivo (Acceso suspendido a actividades)</p>
          <p style="margin: 2px 0; color: #64748b; font-size: 12.5px;"><em>* Este movimiento administrativo no genera constancia ni certificado de conclusión curricular.</em></p>
        </div>

        <div style="text-align: center; margin: 24px 0;">
          <a href="mailto:coordinacion@hypercoreqro.lat" style="display: inline-block; background: #475569; color: #ffffff; text-decoration: none; font-weight: 700; padding: 12px 22px; border-radius: 8px; font-size: 14px;">
            ✉️ Contactar a Coordinación ABAQ
          </a>
        </div>

        <p style="font-size: 12.5px; color: #64748b; line-height: 1.5; text-align: center; margin-bottom: 0;">
          Asociación de Bienestar Animal Querétaro (ABAQ) · Dirección Operativa
        </p>
      </div>
    </div>

=== "4. Alertas de Inactividad (Día 30, 45 y 60)"

    <div style="background: #f1f5f9; padding: 24px; border-radius: 12px; margin: 16px 0;">
      <div style="font-family: system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; padding: 28px; border-radius: 16px; border: 1px solid #e2e8f0; color: #1e293b; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
        <div style="text-align: center; margin-bottom: 20px;">
          <span style="display: inline-block; background: #ea580c; color: #ffffff; font-weight: 800; padding: 6px 14px; border-radius: 999px; font-size: 11px; letter-spacing: 1px;">ABAQ QUERÉTARO · SERVICIO SOCIAL</span>
        </div>
        <h2 style="color: #c2410c; font-size: 20px; margin: 0 0 14px; text-align: center;">2º Aviso Urgente: Próximo a Corte de Inactividad ⚠️</h2>
        <p style="font-size: 14.5px; line-height: 1.6; color: #334155;">
          Hola <strong>Esteban Navarro</strong> (Folio <strong>SS-261025-EN</strong>),<br><br>
          Se registran <strong>45 días continuos sin registro de actividades</strong> ni justificación presentada ante la Coordinación de Servicio Social de ABAQ.
        </p>
        
        <div style="margin: 18px 0; padding: 14px 18px; background: #fff7ed; border-left: 4px solid #ea580c; border-radius: 8px; color: #9a3412; font-size: 14px; line-height: 1.5;">
          <strong>⚠️ ATENCIÓN URGENTE:</strong> Te restan únicamente <strong>15 días</strong> antes de alcanzar los 60 días límite reglamentarios. Si no registras actividad o justificas tu ausencia a la brevedad, la organización aplicará directamente tu baja definitiva de oficio.
        </div>

        <div style="text-align: center; margin: 26px 0;">
          <a href="#" style="display: inline-block; background: #1d3d69; color: #ffffff; text-decoration: none; font-weight: 700; padding: 12px 22px; border-radius: 8px; font-size: 14px;">
            Ver actividades disponibles en la plataforma
          </a>
        </div>
        <p style="font-size: 12.5px; color: #64748b; line-height: 1.5; text-align: center; margin-bottom: 0;">
          Coordinación de Servicio Social · Asociación de Bienestar Animal Querétaro (ABAQ).
        </p>
      </div>
    </div>

=== "5. Conclusión Curricular (480 Horas SS)"

    <div style="background: #f1f5f9; padding: 24px; border-radius: 12px; margin: 16px 0;">
      <div style="font-family: system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; background: #f0fdf4; padding: 28px; border-radius: 16px; border: 1px solid #bbf7d0; color: #14532d; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
        <div style="text-align: center; margin-bottom: 18px;">
          <span style="display: inline-block; background: #166534; color: #ffffff; font-weight: 800; padding: 6px 14px; border-radius: 999px; font-size: 11px;">SERVICIO SOCIAL CONCLUIDO · 480 HORAS</span>
        </div>
        <h1 style="color: #14532d; font-size: 23px; margin: 0 0 12px; text-align: center;">¡Muchas felicidades, Mariana Torres! 🐾🎓</h1>
        <p style="font-size: 14.5px; line-height: 1.6; color: #166534;">
          Has concluido y acreditado satisfactoriamente tus <strong>480 horas curriculares de Servicio Social</strong> en Bienestar Animal con ABAQ (Folio <strong>SS-261025-MT</strong>). Agradecemos enormemente tu constancia, profesionalismo y vocación por los animales.
        </p>
        <div style="text-align: center; margin: 26px 0;">
          <a href="#" style="display: inline-block; background: #1d3d69; color: #ffffff; text-decoration: none; font-weight: 700; padding: 14px 26px; border-radius: 10px; font-size: 14.5px; box-shadow: 0 2px 4px rgba(29,61,105,0.3);">
            🏅 Descargar Certificado de Finalización Oficial
          </a>
        </div>
        <p style="font-size: 12.5px; color: #15803d; text-align: center; margin-bottom: 0;">
          Asociación de Bienestar Animal Querétaro (ABAQ) · Dirección General
        </p>
      </div>
    </div>

=== "6. Nueva Solicitud a Coordinación (Admin)"

    <div style="background: #f1f5f9; padding: 24px; border-radius: 12px; margin: 16px 0;">
      <div style="font-family: system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; padding: 28px; border-radius: 16px; border: 1px solid #e2e8f0; color: #1e293b; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
        <div style="text-align: center; margin-bottom: 20px;">
          <span style="display: inline-block; background: #1d3d69; color: #ffffff; font-weight: 800; padding: 6px 14px; border-radius: 999px; font-size: 11px; letter-spacing: 1px;">ABAQ QUERÉTARO · ADMINISTRACIÓN</span>
        </div>
        <h2 style="color: #1d3d69; font-size: 21px; margin: 0 0 12px; text-align: center;">Nueva Solicitud de Ingreso Recibida 📋</h2>
        <p style="font-size: 14px; line-height: 1.6; color: #334155;">
          Se ha completado el registro de un nuevo aspirante en la plataforma y su expediente se encuentra en espera de validación administrativa.
        </p>

        <div style="margin: 18px 0; padding: 16px 20px; background: #f8fafc; border: 1px solid #cbd5e1; border-radius: 10px; font-size: 14px; line-height: 1.7; color: #1e293b;">
          <p style="margin: 0 0 4px;"><strong>Nombre:</strong> Fernando Pacheco Gómez</p>
          <p style="margin: 4px 0;"><strong>Correo:</strong> fpacheco@alumnos.uaq.mx</p>
          <p style="margin: 4px 0;"><strong>Modalidad:</strong> <span style="background: #e2e8f0; padding: 2px 8px; border-radius: 6px; font-weight: 600;">Servicio Social (SS)</span></p>
          <p style="margin: 4px 0;"><strong>Folio:</strong> SS-261104-FP</p>
          <p style="margin: 4px 0;"><strong>Institución / Escuela:</strong> Universidad Autónoma de Querétaro (UAQ)</p>
          <p style="margin: 4px 0;"><strong>Carrera:</strong> Medicina Veterinaria y Zootecnia</p>
          <p style="margin: 4px 0; color: #d97706; font-weight: 600;">Estado inicial: ⏳ Pendiente de aceptación</p>
        </div>

        <div style="text-align: center; margin: 26px 0;">
          <a href="#" style="display: inline-block; background: #1d3d69; color: #ffffff; text-decoration: none; font-weight: 700; padding: 13px 24px; border-radius: 10px; font-size: 14.5px;">
            👥 Gestionar en la Tabla de Voluntarios
          </a>
        </div>
        <p style="font-size: 12.5px; color: #64748b; text-align: center; margin-bottom: 0;">
          Panel Administrativo ABAQ · Notificación Interna Automática
        </p>
      </div>
    </div>

---

#### 6.3 Infraestructura, Resiliencia y Reglas de Despacho Técnico (Resend API v1)

1. **Canal Oficial de Salida:**
   * Endpoint oficial: `POST https://api.resend.com/emails` con autorización `Bearer process.env.resend` (o `process.env.RESEND_API_KEY`).
   * Remitente primario homologado: `ABAQ Querétaro <notificaciones@hypercoreqro.lat>`.
   * En caso de dominios no verificados en entornos locales o sandbox de prueba, el helper cuenta con fallback automático a `ABAQ Querétaro <onboarding@resend.dev>` y redirección al propietario de la cuenta Resend.
2. **Desacoplamiento No Bloqueante (Fire-and-Forget Resiliente):**
   * Toda llamada a `sendEmail`, `sendAcceptanceEmail`, `sendRejectionEmail` y `sendInactivityWarningEmail` se ejecuta de forma asíncrona dentro de los controladores (`student.controller.js`, `volunteer.controller.js`).
   * Los fallos en el proveedor de correos (errores de cuota, falta de conectividad o tokens expirados) se capturan mediante bloques `.catch(err => console.error(...))` y **bajo ninguna circunstancia revierten ni bloquean la transacción de base de datos** (`statusHistory` persiste de manera segura).
3. **Gobernanza de Certificados en Correos:**
   * **Bajas y Rechazos:** Tienen estrictamente prohibido generar links a certificados o constancias.
   * **Conclusión con Mérito (480 hrs):** Mantiene la firma de tokens con `createCertificateHashToken`, respetando el congelamiento temporal del motor de certificados mientras la rama externa concluye su revisión.

---

## 3. Requisitos de Ingeniería (SRS - Software Requirements Specification)

### Requisitos Funcionales (RF)

* **RF-01 (Estatus Default y Bloqueo de Acceso):** Todo aspirante registrado debe crearse con `accountStatus: 'pending'`. Mientras conserve este estatus o `rejected`, el `AuthGuard` de Angular debe redirigir forzosamente a `/onboarding/expediente`, bloqueando cualquier interacción operativa o lectura de actividades.
* **RF-02 (Actualización Segura de Estatus en Backend):** Los endpoints `PATCH /student/:id/account-status` y `PATCH /volunteer/:id/account-status` deben ser exclusivos para rol `admin`, aceptar `{ accountStatus, reason, comments }`, registrar la transición mediante `applyStatusChange`, actualizar `fechaDesactivacion` y despachar la notificación correspondiente por Resend.
* **RF-03 (Modal Reutilizable con Guard de Folio):** El sistema debe proveer un componente modal único (`InactivateVolunteerModalComponent`) que requiera escribir el folio exacto del colaborador y un comentario no vacío para habilitar el botón de confirmación de baja.
* **RF-04 (Puntos de Acceso Homologados):** El botón para inactivar cuentas debe integrarse en la tabla general de voluntarios (`/student`) para ambos roles, así como en las cabeceras de `student-detail` y `volunteer-detail`, abriendo el mismo modal.
* **RF-05 (Re-Registro Idempotente y Purga de Huérfanos al Cambiar de Rol):** El sistema debe permitir el re-registro de aspirantes con `accountStatus === 'rejected'` ingresando a `/auth/signup`. Si se re-registra en la misma modalidad (`SS` o `VG`), actualiza contraseña e información y pasa a `pending` con `reason: 're_registration'`. Si cambia de modalidad (`SS` ➔ `VG` o `VG` ➔ `SS`), crea el nuevo documento en la colección destino, actualiza `users.role` y purga atómicamente el documento rechazado anterior en la otra colección para evitar duplicados o colisiones. En `/onboarding/expediente` no existen botones de re-registro; solo se despliegan las observaciones y las opciones de cerrar sesión o contactar a Coordinación.
* **RF-06 (Tarjeta Amigable en Perfil Activo):** Las vistas `/student-profile` y `/volunteer-profile` deben sustituir el texto técnico crudo (`expediente_aprobado`) por una tarjeta con redacción institucional, fecha formateada y notas de bienvenida.
* **RF-07 (Exposición de Observaciones en Expediente):** La vista `/onboarding/expediente` debe desplegar en estado `active` el mensaje de bienvenida y en estado `rejected` el contenedor de observaciones con el texto exacto capturado en `comments`.
* **RF-08 (Gobernanza y Desconexión de Certificados):** Las bajas por inactividad o decisión administrativa tienen estrictamente prohibido generar, firmar o emitir certificados o constancias de finalización. El módulo de certificados se mantiene desconectado y sin datos mock durante su revisión en rama externa.
* **RF-09 (Notificación Transaccional de Rechazo con Observaciones):** El sistema debe incorporar la función `sendRejectionEmail` en `backend/utils/email.js` y `notifications.js`, despachando automáticamente un correo con callout box ámbar/rojo conteniendo las observaciones de Coordinación (`comments`) cuando un administrador rechaza un expediente.
* **RF-10 (Inyección de Observaciones en Correos de Aceptación y Baja):** Las plantillas de correo de aceptación (`sendAcceptanceEmail`) y baja administrativa (`sendInactivityWarningEmail` o `sendAdministrativeInactivationEmail`) deben inyectar dinámicamente la caja destacada con el comentario institucional capturado por el administrador.

### Requisitos No Funcionales (RNF)

* **RNF-01 (Seguridad y Control de Acceso RBAC):** Las acciones de cambio de estatus y consulta de bitácora deben estar blindadas mediante JWT y restricción exclusiva a `role === 'admin'`.
* **RNF-02 (Modularidad y Principio DRY):** El modal de inactivación debe ser un único componente standalone reutilizado en los tres puntos de acceso de la plataforma, evitando duplicación de lógica o estilos.
* **RNF-03 (Integridad y Trazabilidad en Base de Datos):** Ningún cambio de estatus debe ocurrir sin una entrada atómica en el arreglo `statusHistory`, preservando `fromStatus`, `toStatus`, `reason`, `comments`, `changedByEmail` y `date`.
* **RNF-04 (Experiencia de Usuario y Prevención de Errores):** El guard de tipeo de folio debe prevenir errores destructivos accidentales en operaciones de administración de personal.
* **RNF-05 (Fidelidad al Sistema de Diseño):** Todos los nuevos componentes y estados visuales deben alinearse a las variables tipográficas, radios de borde y paleta de color institucional de ABAQ (`DESIGN.md`).
* **RNF-06 (Resiliencia Asíncrona en Envíos de Correo):** El despacho de correos electrónicos a través de la API de Resend no debe bloquear el hilo principal de Node.js ni revertir actualizaciones exitosas en la base de datos si ocurre un error de transporte HTTP.

---

## 4. Matriz de Trazabilidad: Módulo vs Requisitos

| Módulo de Arquitectura | Requisitos Funcionales Cubiertos | Componentes / Archivos Clave |
| :--- | :--- | :--- |
| **Módulo 1: Gobernanza Backend** | RF-02, RF-08 | `status-history.js`, `student.controller.js`, `volunteer.controller.js` |
| **Módulo 2: Re-Registro Idempotente** | RF-01, RF-05 | `auth.controller.js`, `auth.guard.ts`, `expediente-recibido.component.ts` |
| **Módulo 3: Modal con Guard de Folio** | RF-03 | `inactivate-volunteer-modal.component.ts` (Nuevo) |
| **Módulo 4: Puntos de Acceso Admin** | RF-04 | `student.component.html`, `student-detail.html`, `volunteer-detail.html` |
| **Módulo 5: Visualización de Estatus** | RF-06, RF-07 | `student-profile.html`, `volunteer-profile.html`, `expediente-recibido.component.ts` |
| **Módulo 6: Notificaciones Resend** | RF-02, RF-08, RF-09, RF-10, RNF-06 | `email.js`, `notifications.js` |
