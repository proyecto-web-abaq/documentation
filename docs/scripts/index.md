---
title: Scripts y Herramientas CLI
icon: lucide/terminal
---

# 💻 Scripts y Herramientas CLI

<div style="background: linear-gradient(135deg, rgba(36, 54, 111, 0.06) 0%, rgba(123, 191, 79, 0.08) 100%); border-left: 4px solid #24366f; border-radius: 8px; padding: 18px 22px; margin-bottom: 28px;">
  <div style="font-size: 0.8rem; font-weight: 800; color: #7bbf4f; letter-spacing: 1px; text-transform: uppercase; margin-bottom: 4px;">
    SISTEMA INTEGRAL ABAQ QUERÉTARO · AUTOMATIZACIÓN Y OPERACIONES
  </div>
  <div style="font-size: 1.05rem; color: #1e293b; line-height: 1.5; font-weight: 500;">
    Catálogo centralizado de scripts de terminal, herramientas de mantenimiento, utilidades de sembrado y tareas automatizadas para desarrollo local, control de calidad (QA) y operaciones de staging.
  </div>
</div>

***

## Catálogo de Scripts Disponibles

<div class="grid cards" markdown>

-   :lucide-database-zap:{ .lg .middle } __[🌱 Sembrado de Base de Datos (`seed.sh`)](seed-db.md)__

    ---

    <span style="display: inline-block; background: #ecfdf5; color: #047857; font-size: 0.72rem; font-weight: 800; padding: 2px 8px; border-radius: 9999px; border: 1px solid #a7f3d0; margin-bottom: 8px;">
      BASH + NODE.JS · STAGING & DEV
    </span>

    Orquestador integral de sembrado para MongoDB Atlas (`abaqTesting--dev-rivers`). Genera el ciclo de vida completo de estudiantes y voluntarios, asigna folios institucionales deterministas, puebla los 14 modelos de la plataforma, enriquece documentos históricos y sincroniza el manifiesto `cuentas-ciclo-vida.json`.

    * **Ubicación:** `seed.sh` (raíz) y `backend/scripts/seed-lifecycle-scenarios.js`
    * **Flags Clave:** `--all`, `--lifecycle`, `--models`, `--clean`, `--backfill-folios`, `--summary`, `--db`
    * **Seguridad:** Purga atómica acotada a `@abaq.local` sin tocar administradores ni datos de producción.

    [:octicons-arrow-right-24: Ver Documentación de seed.sh](seed-db.md)

</div>

***

## Inventario Rápido de Comandos

| Script / Comando | Lenguaje | Propósito | Entorno | Documentación |
| :--- | :--- | :--- | :--- | :--- |
| **`./seed.sh`** | Bash / Node.js 20+ | Sembrado completo de 14 modelos, cuentas de ciclo de vida y generación de folios | Dev / Staging | [Documentación de `seed-db.md`](seed-db.md) |
| **`./seed.sh --clean`** | Bash / Node.js 20+ | Purga segura de registros de prueba (`@abaq.local` y `[TEST-*]`) | Dev / Staging | [Sección de Limpieza](seed-db.md#34-limpiar-completamente-los-registros-de-prueba) |
| **`./seed.sh --backfill-folios`** | Bash / Node.js 20+ | Enriquecimiento retroactivo de folios `OP-*` y `AC-*` para documentos antiguos | Dev / Staging | [Sección de Backfill](seed-db.md#33-enriquecer-documentos-viejos-sin-folio) |

***

## Requisitos de Ejecución del Entorno

Para ejecutar los scripts de esta sección es necesario contar con:

1. **Intérprete Bash y Node.js:** Node.js v20 o superior y entorno Unix/macOS/WSL.
2. **Dependencias Backend:** Ejecutar previamente `npm install` en la carpeta `backend/`.
3. **Variables de Entorno (`.env`):** Archivo `backend/.env` configurado con la cadena `MONGO_URI`.
4. **Lista Blanca de Red (Atlas Network Access):** Tu dirección IP pública debe estar autorizada en el cluster de MongoDB Atlas. Consulta la [guía de solución en `seed-db.md`](seed-db.md#7-diagnostico-de-conexion-y-lista-blanca-de-ips-en-atlas).
