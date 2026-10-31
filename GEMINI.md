# GEMINI.md — Documentación ABAQ

Directrices del proyecto para Google Antigravity y asistentes Gemini.

- Para tareas relacionadas con la redacción, actualización y compilación de reportes de avance al cliente, consulta y activa la skill `.agents/skills/generate-report/SKILL.md`.
- El archivo Markdown dentro de `docs/reports/report<N>-<YYYY-MM-DD>/report<N>.md` es la única fuente de la verdad.
- Para generar los formatos LaTeX (`.tex`), PDF (`.pdf`) y Word (`.docx`), ejecuta `tools/build-report-downloads.sh` con el path de LaTeX exportado (`/Library/TeX/texbin:/opt/homebrew/bin:$PATH`).
- Cada nuevo reporte debe quedar registrado en la tabla de `docs/reports/al-cliente/index.md` y en la navegación de `zensical.toml`.
- Verifica siempre la compilación del sitio con `.venv/bin/zensical build`.
