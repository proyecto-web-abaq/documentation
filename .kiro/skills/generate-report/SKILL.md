---
name: generate-report
description: Create, format, validate, and compile bi-weekly progress reports (Reportes de Avance) for ABAQ Querétaro in Markdown, LaTeX (.tex), PDF (XeLaTeX), and Word (.docx). Use this skill whenever creating, drafting, dictating, updating, or compiling client reports (Reporte No. 0 to 8) in the documentation repository.
---

# ABAQ Report Generator Skill

This skill guides Kiro through creating, formatting, and compiling bi-weekly client progress reports (*Reportes de Avance*) for **ABAQ Querétaro**.

All reports follow a standardized structure and must be available in four formats:
1. **Markdown (`.md`)**: The primary source of truth, rendered by Zensical on the documentation site.
2. **LaTeX (`.tex`)**: Standalone LaTeX source using XeLaTeX formatting.
3. **PDF (`.pdf`)**: Formatted document with table of contents, compiled via XeLaTeX.
4. **Word (`.docx`)**: Generated via Pandoc.

---

## 1. Directory & File Naming Conventions

Reports live under `docs/reports/` in the documentation repository:

```text
docs/reports/
├── report0-2026-07-29/
│   └── report0.md
├── report1-2026-08-19/
│   ├── report1.md
│   └── latex/
│       ├── report1.tex
│       ├── report1.pdf
│       └── report1.docx
├── report6-2026-10-26/
│   ├── report6.md
│   └── latex/
│       ├── report6.tex
│       ├── report6.pdf
│       └── report6.docx
```

- **Folder naming**: `report<N>-<YYYY-MM-DD>` (e.g. `report3-2026-09-16`).
- **Markdown file**: `report<N>.md` inside the folder.
- **Compiled outputs**: `latex/report<N>.tex`, `latex/report<N>.pdf`, `latex/report<N>.docx`.
- **Image attachments (optional)**: `attachments/` folder adjacent to `report<N>.md`.

---

## 2. Standard Report Markdown Structure

Every report MUST follow this exact structure:

```markdown
# Reporte de Avance No. <N>

| | |
|---|---|
| **Fecha** | <Día de Mes de Año> |
| **Versión** | <vX.Y.Z> |
| **Estado** | <En desarrollo / En planeación / Cierre> |
| **Preparado por** | Equipo de Desarrollo ABAQ |

---

!!! abstract "Descargas"
    Puedes descargar este documento en los siguientes formatos:
    
    - :lucide-file-text: **[Descargar PDF](latex/report<N>.pdf)**
    - :lucide-file: **[Descargar Word (.docx)](latex/report<N>.docx)**
    - :lucide-code: **[Descargar fuente LaTeX (.tex)](latex/report<N>.tex)**
    - :lucide-video: **[Ver grabación de la sesión](<URL>)** <!-- opcional si existe -->

## Resumen ejecutivo

<Párrafos en español profesional resumiendo los acuerdos clave y el estado general.>

---

## 1. Introducción

<Contexto de la reunión, participantes oficiales y objetivos del período.>

---

## 2. <Tema Principal de la Sesión / Detalles del Acuerdo / Infraestructura>

<Subsecciones temáticas con tablas, roles, acuerdos y decisiones técnicas.>

---

## 3. Cambios en el Servidor (Backend)

<Tabla y viñetas con cambios de código o endpoints. Si no hubo cambios: "Sin modificaciones registradas en código fuente durante este período.">

---

## 4. Cambios en la Aplicación Web (Frontend)

<Tabla y viñetas con nuevas pantallas, rutas o componentes. Si no hubo cambios: "Sin modificaciones registradas en código fuente durante este período.">

---

## 5. Evidencia Visual

<Imágenes en attachments/ con leyendas descriptivas. Si no hubo cambios visuales: "No aplica para esta entrega (sin modificaciones de interfaz registradas).">

---

## 6. Estado Actual del Proyecto

!!! info "<Título del Estado>"
    <Descripción concisa del estado y salud de los entregables.>

---

## 7. Próximos Pasos

1. **<Área o Hito>:**
    - 1.1 <Acción inmediata>
    - 1.2 <Acción subsecuente>
```

---

## 3. Step-by-Step Execution Workflow

When instructed to create, update, or compile a report:

### Step 1: Create or Update the Markdown Source
1. Create `docs/reports/report<N>-<YYYY-MM-DD>/report<N>.md`.
2. Ensure flawless Spanish, professional terminology, and correct metadata table.
3. If attachments exist, place them in `docs/reports/report<N>-<YYYY-MM-DD>/attachments/`.

### Step 2: Update Navigation & Indexes
1. **Update client index**: In `docs/reports/al-cliente/index.md`, add or update the row in the table:
   ```markdown
   | [Reporte No. <N>](../report<N>-<YYYY-MM-DD>/report<N>.md) | <DD mes YYYY> | <versión> | <Descripción breve> |
   ```
2. **Update Zensical navigation**: In `zensical.toml`, add under `nav -> Reportes -> Al cliente`:
   ```toml
   { "Reporte No. <N>" = "reports/report<N>-<YYYY-MM-DD>/report<N>.md" },
   ```

### Step 3: Compile Downloads (.tex, .pdf, .docx)
Run `tools/build-report-downloads.sh` with PATH exported:

```bash
export PATH="/Library/TeX/texbin:/opt/homebrew/bin:$PATH"
tools/build-report-downloads.sh docs/reports/report<N>-<YYYY-MM-DD>/report<N>.md
```

This script:
1. Strips YAML frontmatter and Zensical material emojis.
2. Formats callouts/admonitions for Pandoc.
3. Generates standalone LaTeX (`latex/report<N>.tex`) with `geometry:margin=1in` and `Helvetica Neue`.
4. Compiles PDF (`latex/report<N>.pdf`) via `xelatex`.
5. Compiles Word document (`latex/report<N>.docx`).

### Step 4: Verify the Documentation Build
Run the site builder to confirm zero broken links or navigation errors:

```bash
.venv/bin/zensical build
```

---

## 4. Pending Reports Management

When creating a placeholder report for sessions whose content will be dictated later:
- Set status in metadata table to `En elaboración`.
- Add warning callout:
  ```markdown
  !!! warning "Documento en elaboración"
      Este reporte corresponde a la sesión número <N> de seguimiento quincenal. Su contenido está preparado en blanco para ser dictado y completado paulatinamente.
  ```
- Leave sections in place with `!!! note "Pendiente de contenido"` placeholders.
- Do NOT compile `.pdf` or `.docx` until content is dictated by the user.
