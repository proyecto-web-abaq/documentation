Estuve pensando en cómo podríamos manejar el ciclo de vida de los voluntarios dentro del sistema, sobre todo considerando que ABAQ no quiere perder nunca la información histórica de una persona.
La idea que más sentido me hace es separar dos conceptos: el estado del voluntario y dónde se almacena su información histórica.
1. Estados del voluntario
Podríamos manejar inicialmente tres estados:
🟢 Activo
    •    El voluntario puede iniciar sesión.
    •    Puede participar en actividades.
    •    Puede inscribirse, registrar participación, consultar sus horas, etc.
    •    Tiene interacción normal con el sistema.
🟡 Inactivo
    •    El voluntario sigue existiendo en la base de datos.
    •    Ya no puede realizar nuevas actividades o participaciones.
    •    La cuenta no se elimina.
    •    Su información histórica permanece disponible.
    •    La desactivación no la hace el propio voluntario; tendría que solicitarla a ABAQ y un administrador cambiaría su estado.
Todavía tendríamos que definir exactamente qué puede hacer un usuario inactivo. Una opción sería permitirle iniciar sesión únicamente para consultar su perfil y su historial, pero bloquear cualquier acción nueva.
🔵 Archivado
    •    Después de cierto periodo como inactivo, su información podría salir de la base de datos operativa.
    •    Antes de eliminarla de MongoDB, se generaría un respaldo histórico completo.
    •    El archivo histórico se almacenaría en un sistema externo de almacenamiento.
    •    Si algún día se necesitara recuperar esa información, existiría un proceso de restauración/reingreso.
Por lo tanto, el flujo sería:
ACTIVO → INACTIVO → ARCHIVADO

2. Historial de cambios de estado
También creo que sería importante no guardar únicamente el estado actual, sino tener un historial.
Por ejemplo:
{
  "statusHistory": [
    {
      "status": "active",
      "date": "2026-01-10"
    },
    {
      "status": "inactive",
      "date": "2026-08-20",
      "reason": "service_completed",
      "changedBy": "admin_id"
    }
  ]
}
Así podemos saber cuándo cambió de estado, por qué y quién realizó el cambio.
Esto sería especialmente importante si en algún momento ABAQ necesita consultar por qué una persona dejó de estar activa.

3. ¿Cuánto tiempo permanecería como inactivo?
Aquí todavía tendríamos que definirlo con ABAQ.
Podrían existir diferentes opciones, por ejemplo:
    •    6 meses
    •    12 meses
    •    24 meses
    •    Indefinidamente
Como propuesta inicial, podríamos considerar 12 meses, pero esto no tendría que tomarse como una decisión definitiva; habría que validarlo con las políticas de ABAQ y cualquier requisito legal/de privacidad que aplique.
La idea sería que durante ese periodo el registro siga en MongoDB, pero sin permitir que el usuario participe activamente en el sistema.

4. ¿Qué pasa después del periodo de retención?
Aquí es donde entraría el archivado.
La idea sería NO borrar primero y después intentar recuperar la información.
El proceso debería ser:
    1    El voluntario pasa a estado inactivo.
    2    Permanece inactivo durante el periodo definido.
    3    Se genera su archivo histórico.
    4    Se verifica que el archivo se haya creado correctamente y que contenga toda la información necesaria.
    5    Se guarda la información del archivo y su ubicación.
    6    Solo después de comprobar que el archivo está correctamente almacenado, se podría eliminar la información operativa de MongoDB.
Si por alguna razón falla el proceso de exportación o validación, no se elimina nada de MongoDB.

5. ¿En qué formato guardar la información?
Para esto creo que CSV funciona perfectamente, pero no recomendaría tener un solo CSV con absolutamente todo.
Un voluntario puede tener información relacionada con:
    •    Su perfil
    •    Actividades
    •    Participaciones
    •    Horas
    •    Acreditaciones
    •    Historial de estados
Por lo tanto, podríamos generar un paquete de archivos como:
archive-volunteer-12345/
├── volunteer.csv
├── activities.csv
├── participations.csv
├── accreditations.csv
└── status-history.csv
CSV tiene varias ventajas:
    •    Es ligero.
    •    Es fácil de generar desde Node.js.
    •    Se puede abrir directamente en Excel, Google Sheets o Numbers.
    •    No depende de una API de Excel.
    •    Es fácil de importar posteriormente a otro sistema.
    •    Es un formato bastante universal.
Sin embargo, también considero buena idea que exista un archivo JSON como respaldo estructurado principal, porque permite conservar mejor relaciones y estructuras que un CSV plano.
Entonces podría quedar:
JSON → respaldo estructurado principal
CSV → consulta y exportación humana
Excel → opcional, únicamente si ABAQ necesita reportes visuales

6. ¿Dónde guardaríamos los archivos?
La idea sería que los archivos históricos no se queden dentro de MongoDB.
MongoDB debería encargarse principalmente de la información operativa del sistema.
El histórico podría almacenarse en un servicio de almacenamiento de archivos, por ejemplo:
    •    Azure Blob Storage
    •    Amazon S3
    •    Google Cloud Storage
    •    Algún almacenamiento privado compatible con S3
Podríamos tener una estructura como:
ABAQ Archive/
├── 2026/
│   └── volunteers/
│       └── 12345/
│           ├── volunteer.json
│           ├── volunteer.csv
│           ├── activities.csv
│           ├── participations.csv
│           ├── accreditations.csv
│           └── status-history.csv/
│
└── 2027/
    └── volunteers/
        └── ...
Así tendríamos un histórico organizado por año y por voluntario.

7. También podríamos tener un manifest
Para cada archivo histórico podríamos guardar un pequeño registro que indique qué se archivó y cuándo.
Por ejemplo:
{
  "archiveId": "ARCH-2027-000123",
  "entity": "volunteer",
  "volunteerId": "12345",
  "archivedAt": "2027-10-27",
  "reason": "inactive",
  "files": [
    "volunteer.json",
    "volunteer.csv",
    "activities.csv",
    "participations.csv",
    "accreditations.csv",
    "status-history.csv"
  ]
}
Esto nos permitiría saber que el voluntario fue archivado, cuándo ocurrió y qué archivos forman parte de su histórico.

8. Lo importante
La idea general sería que MongoDB no sea nuestro archivo histórico infinito, pero tampoco perder información.
Tendríamos una separación entre:
Base de datos operativa
→ usuarios activos e inactivos que todavía necesitamos manejar dentro del sistema.
Almacenamiento histórico
→ información de voluntarios que ya no necesitan estar en la base operativa, pero cuyos registros ABAQ debe conservar.
Y lo más importante: nunca eliminaríamos información de MongoDB hasta comprobar que existe una copia histórica válida y completa.
Creo que esta estructura nos puede ayudar a mantener la base de datos más limpia a largo plazo sin sacrificar el historial de los voluntarios.
Lo que creo que todavía tendríamos que definir antes de implementarlo es principalmente:
    1    Qué puede y qué no puede hacer un voluntario inactivo.
    2    Si un inactivo puede iniciar sesión.
    3    Si puede consultar su historial.
    4    Cómo se reactiva un voluntario.
    5    Cuánto tiempo permanecerá inactivo.
    6    Qué información exacta se debe conservar en el archivo histórico.
    7    Qué servicio de almacenamiento externo utilizaríamos.
La idea sería que primero revisemos esto y lleguemos a un acuerdo antes de empezar a modificar el backend/base de datos.
