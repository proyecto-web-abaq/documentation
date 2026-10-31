# Mapa de Interfaces y Prompts para Figma

**Proyecto:** Plataforma Web ABAQ (Servicio Social)
**Versión:** 1.0.0
**Fecha:** 2026-10-14
**Estado:** Insumo de diseño (prompts para trabajar en Figma)
**Relacionado:** [Autenticación](auth-design.md) · [Perfil del Usuario](perfil-usuario-design.md) · [Notificaciones](notificaciones-design.md) · [Datos, Respaldo y Recuperación](datos-respaldo-recuperacion-design.md)

---

## 1. Propósito

Este documento **mapea todas las interfaces a diseñar** y plantea cada una como un **prompt descriptivo** para trabajarlas en Figma. Cada prompt describe propósito, audiencia, elementos y estados; **no** fija colores ni medidas exactas (eso se resuelve en Figma con la identidad de marca ABAQ).

!!! note "Convenciones transversales (aplican a todas las pantallas)"
    - Identidad visual ABAQ; soporte de **tema claro/oscuro**.
    - **Toasts** de notificación en la **esquina superior derecha** (visibles para administradores).
    - Compatibilidad con gestores de contraseñas (`autocomplete`), navegación por teclado en formularios por lotes.
    - Audiencia: **voluntario** (usuario final) y **administrador**.

## 2. Inventario de interfaces

| # | Pantalla | Audiencia |
|---|----------|-----------|
| 1 | Login | Voluntario / Admin |
| 2 | 2FA — reto en login (código 30 s) | Voluntario / Admin |
| 3 | Recuperar contraseña | Voluntario / Admin |
| 4 | Verificación de correo institucional | Voluntario |
| 5 | Signup — Fase 1 (cuenta + datos personales + académicos) | Voluntario |
| 6 | Signup — Fase 2 (onboarding / inducción) | Voluntario |
| 7 | Signup — Fase 3 (documentos: enlaces INE/CV) | Voluntario |
| 8 | Signup — Fase 4 (lectura + consentimiento del reglamento) | Voluntario |
| 9 | Pantalla de espera (cuenta pendiente, 24–48 h) | Voluntario |
| 10 | Navbar con botón de usuario | Voluntario / Admin |
| 11 | Perfil — Configuración de cuenta (contraseña, tema) | Voluntario |
| 12 | Perfil — Alta/gestión de 2FA (QR + backup codes) | Voluntario / Admin |
| 13 | Perfil — Mi solicitud (brief del registro) | Voluntario |
| 14 | Perfil — Edición de datos personales | Voluntario |
| 15 | Perfil — Cambios pendientes de aprobación | Voluntario |
| 16 | Admin — Bandeja de aprobación de cambios | Admin |
| 17 | Admin — Bulk load (con dry-run / reporte previo) | Admin |
| 18 | Admin — Respaldos (generar, listar, descargar) | Admin |
| 19 | Admin — Consola de ciclo de vida de datos | Admin |

---

## 3. Prompts por pantalla

### 1. Login
> Diseña una pantalla de inicio de sesión para la plataforma ABAQ de servicio social. El campo primario, con prioridad visual, es el **correo institucional** (identificador de acceso); debajo, el campo de **contraseña**. Botón principal "Iniciar sesión", enlace secundario "¿Olvidaste tu contraseña?" y enlace a "Crear cuenta". Compatible con gestores de contraseñas. Incluye estados: normal, error de credenciales, y carga. Tema claro/oscuro.

### 2. 2FA — reto en login
> Diseña la pantalla que aparece tras validar correo y contraseña, pidiendo el **código TOTP de 6 dígitos (válido 30 s)**. Muestra un campo de entrada de código segmentado, un temporizador o indicación de vigencia, y un enlace "Usar un código de respaldo". Estados: código válido, inválido y expirado.

### 3. Recuperar contraseña
> Diseña el flujo de recuperación de contraseña: (a) pantalla para ingresar el correo institucional y solicitar el enlace/código; (b) pantalla de confirmación "revisa tu correo"; (c) pantalla para establecer nueva contraseña (nueva + confirmación, 12–128 caracteres). Estados de éxito y error.

### 4. Verificación de correo institucional
> Diseña la pantalla de verificación del correo institucional tras el registro: mensaje indicando que se envió un enlace/código de verificación, acción para reenviar, y estado de "correo verificado" con continuación al flujo.

### 5. Signup — Fase 1
> Diseña el primer paso del registro, estilo *Typeform* (tarjetas secuenciales con barra de progreso y navegación por teclado). Agrupa: **creación de cuenta** (correo institucional, contraseña, confirmar contraseña), **datos personales** (nombre completo, teléfono, correo de contacto, fecha de presentación, redes sociales y confirmación de seguir canales oficiales) y **datos académicos** (institución, carrera, grado/semestre, matrícula, periodo de servicio social con fecha de inicio y conclusión). Incluye una aclaración destacada de que el periodo es el de colaboración con ABAQ, no el de graduación. Validación bloqueante por tarjeta.

### 6. Signup — Fase 2 (onboarding)
> Diseña el paso de onboarding/inducción: siete puntos secuenciales (Conociendo ABAQ, Plática de Bienestar Animal, Arquetipos de marca, DISC, Generaciones, Neurociencia de las emociones, "Sobre mí"). Por cada punto, tres campos de texto: **qué me gustó**, **qué considero lo más importante**, **qué puede mejorar**. Indicador de que al completar se acreditan 10 horas.

### 7. Signup — Fase 3 (documentos)
> Diseña el paso de documentos: campos para **enlace externo** del INE vigente y del Curriculum Vitae (no se suben archivos; se pega un enlace). Advertencia sobre la vigencia del enlace. Nota de que no se cargan archivos al servidor.

### 8. Signup — Fase 4 (consentimiento del reglamento)
> Diseña el paso de lectura y aceptación del reglamento: un panel desplazable con el **reglamento completo** y, al final, **tres casillas de verificación obligatorias e independientes** (leí y comprendí; acepto las obligaciones; confirmo haber completado inducción y documentos). El botón de continuar permanece deshabilitado hasta marcar las tres. Deja claro que esto sustituye la firma autógrafa.

### 9. Pantalla de espera
> Diseña la pantalla que ve el voluntario tras enviar su registro: estado **"cuenta pendiente / en corroboración"**, mensaje de que un administrador validará los datos en 24–48 horas, e indicación de volver más tarde. Botón de cerrar sesión. Tono tranquilizador, sin acciones que sugieran que algo falló.

### 10. Navbar con botón de usuario
> Diseña la barra de navegación superior con el **botón de usuario a la derecha** (avatar/iniciales + nombre). Al hacer clic, abre un menú con acceso a: Mi perfil, Configuración de cuenta, y Cerrar sesión. Muestra también el punto de entrada a notificaciones para administradores (toasts arriba a la derecha).

### 11. Perfil — Configuración de cuenta
> Diseña la sección de configuración de cuenta dentro del perfil: correo institucional en **solo lectura** (inmutable), **cambio de contraseña** (actual + nueva + confirmar), selector de **tema** (claro/oscuro/sistema) y acceso a la gestión de 2FA. Sin sección de Privacidad.

### 12. Perfil — Alta/gestión de 2FA
> Diseña el alta de **2FA obligatoria (TOTP)**: muestra el **código QR** para escanear con una app de autenticación, campo para confirmar con el primer código, y presentación de los **códigos de respaldo** (lista copiable/descargable, de un solo uso) con opción de regenerarlos. Estados: no configurada (forzando alta), configurada, regeneración.

### 13. Perfil — Mi solicitud
> Diseña una vista de resumen (brief) de todo lo que el voluntario capturó y entregó en el registro: datos personales, académicos, onboarding, documentos y aceptación del reglamento. Distingue claramente lo **editable** (datos personales, documentos) de lo **inmutable** (onboarding, opiniones, redes, consentimiento). Muestra el estado de la cuenta.

### 14. Perfil — Edición de datos personales
> Diseña el formulario de edición de datos personales editables (nombre completo, teléfono, institución, re-subir enlaces de INE y CV). Al guardar, muestra un aviso claro de que **el cambio no se aplica hasta que un administrador lo apruebe** y que **se notificará al administrador**. El dato vigente se sigue mostrando como actual.

### 15. Perfil — Cambios pendientes de aprobación
> Diseña la vista donde el voluntario ve sus **cambios propuestos en espera de aprobación**: por cada cambio, el valor actual vs. el valor propuesto y su estado (pendiente/aprobado/rechazado). Indicación de que mientras tanto el dato vigente no cambia.

### 16. Admin — Bandeja de aprobación de cambios
> Diseña la bandeja del administrador para revisar cambios propuestos por los usuarios. Por cada usuario, lista de cambios con valor actual vs. propuesto. Permite **aprobar/rechazar de forma granular (cambio por cambio)** y también **aprobar/rechazar todo el lote**. Al resolver, se aplica o descarta y se notifica.

### 17. Admin — Bulk load
> Diseña la interfaz de carga masiva: selección de **fuente** (respaldo del sistema o archivo Excel/CSV con formato), paso de **dry-run** que muestra un **reporte previo** (conteos, conflictos, registros inválidos), y confirmación explícita antes de inyectar. Deja claro que sin confirmar el reporte no se inyecta nada. Estados: validando, reporte listo, inyectando, resultado.

### 18. Admin — Respaldos
> Diseña la interfaz de respaldos para administradoras. Botón para **generar un respaldo manual**, eligiendo el alcance: **base de datos completa** o **por modelo**. Lista de respaldos **programados y manuales** con fecha, tamaño, origen (programado/manual) y **fecha de expiración** (cada respaldo se elimina a los 6 meses). Cada fila permite **descargar** o usarlo como fuente de **bulk load**. Muestra como información de solo lectura la frecuencia (2 por semana) y la permanencia (6 meses); no hay controles para cambiarlas. Esta pantalla es independiente de la consola de ciclo de vida.

### 19. Admin — Consola de ciclo de vida de datos
> Diseña una consola de solo lectura con acciones puntuales sobre las **tres fases** del ciclo de vida: **Activa** (base de datos), **Frío** (archivo de bajo costo) y **Rehidratación** (copias listas para descargar). Encabezado con tarjetas por fase y una de **total**: **ocupación en GB**, **% del total**, **costo mensual estimado** (rotulado "estimado, precio de lista", con la fecha del precio) y, para Activa, **% de capacidad** contra 32 GB. Una barra apilada muestra la proporción de cada fase. Debajo, dos tablas de ZIP: **Frío** (nombre, tamaño, fecha de archivado, acción "Rehidratar") y **Rehidratación** (nombre, tamaño, estado *en curso* / *listo*, prioridad, tiempo transcurrido, acciones "Descargar ZIP" y "Regresar a frío"). Al rehidratar, un diálogo pide elegir **prioridad estándar (hasta 15 h)** o **alta (menos de 1 h)**, con el costo estimado de cada una, y advierte que la descarga no es inmediata. No incluyas controles para cambiar la ventana activa ni las reglas de las fases; menciona en texto de ayuda que son parte del diseño del sistema.

---

## 4. Pendientes

- Ajustar el prompt 19 si cambia la decisión D-T1 (tier de Frío) del [diseño de datos](datos-respaldo-recuperacion-design.md#8-decisiones-pendientes): con Cold, la descarga desde Frío sería inmediata y el diálogo de prioridad desaparece.
- Ajustar prompts a los componentes y tokens de la identidad ABAQ una vez establecidos en Figma.
