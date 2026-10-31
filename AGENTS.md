# AGENTS.md — Documentación ABAQ

This file provides rules and instructions for autonomous coding agents (Google Antigravity, agy CLI, and open agent standards) working in this repository.

## Repository Overview

Technical, operative, and progress report documentation for **ABAQ Querétaro**. Built with **Zensical** and exported to downloadable formats with **Pandoc** and **XeLaTeX**.

## Agent Guidelines & Skills

- **Progress Reports Skill**:
  - Always activate `.agents/skills/generate-report/SKILL.md` when asked to create, draft, or compile progress reports (*Reportes de Avance*).
  - Single source of truth: `docs/reports/report<N>-<YYYY-MM-DD>/report<N>.md`.
  - Required downloadable outputs: `latex/report<N>.tex`, `latex/report<N>.pdf`, `latex/report<N>.docx`.
  - Mandatory registry: Update `docs/reports/al-cliente/index.md` and `zensical.toml` whenever adding or renaming reports.

## Build and Compilation Commands

- **Build site**:
  ```bash
  .venv/bin/zensical build
  ```
- **Compile report downloads**:
  ```bash
  export PATH="/Library/TeX/texbin:/opt/homebrew/bin:$PATH"
  tools/build-report-downloads.sh docs/reports/report<N>-<YYYY-MM-DD>/report<N>.md
  ```

## Writing Quality Standards

- Language: Formal, precise Spanish.
- Structure: Follow established layout from Reportes 1, 2, and 6.
- Verification: Always run `zensical build` to ensure 0 broken links or anchors before finalizing changes.
