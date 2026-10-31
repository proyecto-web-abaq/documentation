---
inclusion: fileMatch
fileMatch: docs/reports/**/*.md
---

# Kiro Steering: ABAQ Progress Reports

When working with files in `docs/reports/`:
- Keep all documentation in formal Spanish.
- Maintain the standardized metadata block and numbered section structure.
- Ensure any finished report has compiled `.tex`, `.pdf`, and `.docx` companion files via `tools/build-report-downloads.sh`.
- Update `docs/reports/al-cliente/index.md` and `zensical.toml` when adding reports.
- Confirm site integrity with `.venv/bin/zensical build`.
