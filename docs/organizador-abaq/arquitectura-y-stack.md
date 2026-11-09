# Arquitectura y Stack Tecnológico

El Organizador ABAQ fue concebido con una arquitectura **Vanilla PHP + MySQL**, prescindiendo intencionalmente de frameworks pesados para maximizar la velocidad de respuesta, minimizar el consumo de recursos en contenedores y facilitar su mantenimiento y portabilidad.

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología | Detalle |
|---|---|---|
| **Lenguaje Backend** | PHP 8.2 CLI | Scripts estructurados, orientados a API JSON y vistas server-side ligeras. |
| **Base de Datos** | MySQL 8.x | Extensiones `mysqli` y `pdo_mysql`. Soporte UTF8MB4. |
| **Frontend** | HTML5, CSS3, Vanilla JS | Diseño responsivo nativo, interacción drag-and-drop HTML5 y modales CSS. |
| **Servicio de Correo** | Resend API REST | Integración nativa vía cURL a `https://api.resend.com/emails`. |
| **Contenedorización** | Docker (`php:8.2-cli`) | Servidor embebido PHP escuchando en `0.0.0.0:${PORT}`. |
| **Plataforma Cloud** | Railway | Alojamiento de servicio web y base de datos relacional MySQL vinculada. |

---

## 🗄️ Esquema de Base de Datos

En `conexion.php`, el sistema implementa una auto-inicialización con `CREATE TABLE IF NOT EXISTS`:

```mermaid
erDiagram
    USUARIOS ||--o{ TAREAS : "gestiona / asignado a"
    USUARIOS ||--o{ COMENTARIOS_EXTRA_TAREAS : "escribe"
    USUARIOS ||--o{ HISTORIAL_ACTIVIDAD : "registra"
    USUARIOS ||--o{ NOTIFICACIONES : "recibe"
    TAREAS ||--o{ COMENTARIOS_EXTRA_TAREAS : "contiene"
    TAREAS ||--o{ NOTIFICACIONES : "origina"

    USUARIOS {
        int id PK
        string nombre
        string correo
        string password
        string rol
        tinyint activo
        tinyint verificado
        string token_verificacion
        datetime token_expiracion
        tinyint invitacion_enviada
        timestamp fecha_creacion
    }

    TAREAS {
        int id PK
        string nombre
        string responsable
        int responsable_id FK
        date fecha
        string prioridad
        string categoria
        text descripcion
        string estado
        decimal horas
        decimal presupuesto
        datetime fecha_inicio
        datetime fecha_completada
        timestamp fecha_creacion
    }
```

---

## 🔐 Manejo de Entornos y Configuración (.env)

El sistema cuenta con un cargador de entorno nativo (`env.php`):

1. **Prioridad de Variables:** Si una variable ya existe en el entorno del sistema (por ejemplo, inyectada por Railway o Docker), se respeta y no es sobreescrita.
2. **Carga Local:** Si existe el archivo `.env`, lo analiza línea por línea, omitiendo comentarios (`#`) y limpiando comillas, cargando los valores mediante `putenv()` y `$_ENV`.
3. **Conexión MySQL Dinámica:** `conexion.php` soporta de manera transparente variables independientes (`MYSQLHOST`, `MYSQLPORT`, `MYSQLUSER`, `MYSQLPASSWORD`, `MYSQLDATABASE`) o URLs de conexión consolidadas (`MYSQL_URL`, `DATABASE_URL`).
