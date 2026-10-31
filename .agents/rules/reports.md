---
description: Reglas obligatorias para la creación y compilación de reportes quincenales al cliente ABAQ.
globs: docs/reports/**/*.md
---

# Reglas de Reportes ABAQ

1. **Estructura fija**: Todo reporte debe incluir título H1, tabla de metadatos (Fecha, Versión, Estado, Preparado por), bloque de descargas (`!!! abstract "Descargas"`), Resumen Ejecutivo, Introducción, Secciones técnicas, Backend, Frontend, Evidencia visual, Estado actual y Próximos pasos.
2. **Formatos sincronizados**: Cada reporte completado debe contar con su correspondiente `.tex`, `.pdf` y `.docx` generados con `tools/build-report-downloads.sh`.
3. **Registro completo**: Toda nueva entrega debe registrarse en `docs/reports/al-cliente/index.md` y en `zensical.toml`.
4. **Verificación**: Antes de concluir, ejecutar `.venv/bin/zensical build` para garantizar integridad de enlaces.
