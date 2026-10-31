# KIRO.md — Documentación ABAQ

This file provides project-level instructions for Kiro AI and Kiro Crew agents.

## Repository Purpose

This repository houses the technical documentation and client delivery reports for the **ABAQ** social service management platform.

## Agent Skills

- **Report Generation Skill**: Access `.kiro/skills/generate-report/SKILL.md` (or slash command `/generate-report`) to author, structure, and compile client progress reports.
- **Steering Rule**: Consult `.kiro/steering/reports.md` for specific formatting and validation rules.

## Core Workflows

1. **New Report Creation**:
   - Write `docs/reports/report<N>-<YYYY-MM-DD>/report<N>.md`.
   - Update `docs/reports/al-cliente/index.md` and `zensical.toml`.
2. **Build Outputs**:
   - Run `export PATH="/Library/TeX/texbin:/opt/homebrew/bin:$PATH && tools/build-report-downloads.sh docs/reports/report<N>-<YYYY-MM-DD>/report<N>.md"`.
3. **Site Verification**:
   - Run `.venv/bin/zensical build`.
