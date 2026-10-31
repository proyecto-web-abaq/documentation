# CLAUDE.md — Documentación ABAQ

This file provides instructions and guidelines for Claude Code when working in the `documentation` repository.

## Project Overview

This repository hosts the official technical and operational documentation for the **ABAQ** social service platform, built and published using **Zensical** (Material for MkDocs compatible Python documentation generator) and **Pandoc + XeLaTeX** for downloadable formats (PDF, Word, LaTeX).

## Key Commands

- **Build documentation site**:
  ```bash
  .venv/bin/zensical build
  ```
- **Serve documentation locally**:
  ```bash
  .venv/bin/zensical serve
  ```
- **Compile report downloads (.tex, .pdf, .docx)**:
  ```bash
  export PATH="/Library/TeX/texbin:/opt/homebrew/bin:$PATH"
  tools/build-report-downloads.sh docs/reports/report<N>-<YYYY-MM-DD>/report<N>.md
  ```

## Reports Workflow & Skill

Whenever creating, updating, or compiling progress reports (*Reportes de Avance*) for the client ABAQ Querétaro:
- Invoke the skill **`/generate-report`** located at `.claude/skills/generate-report/SKILL.md`.
- Keep Markdown files as the canonical source of truth in `docs/reports/report<N>-<YYYY-MM-DD>/report<N>.md`.
- Ensure all four formats are produced: `.md`, `.tex`, `.pdf`, and `.docx`.
- Always update `docs/reports/al-cliente/index.md` and `zensical.toml` after creating or updating a report.
- Verify site build with `.venv/bin/zensical build`.

## Coding & Documentation Standards

- Language: Professional, formal Spanish for all user-facing documentation and reports.
- Structure: Standardized header table, executive summary, numbered sections, and download callouts.
- Formatting: Admonition syntax `!!! <type> "<Title>"`, clean markdown tables, and KaTeX math syntax when required.
