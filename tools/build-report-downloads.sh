#!/usr/bin/env bash
#
# build-report-downloads.sh
# Genera los descargables (PDF y DOCX) de un reporte a partir de su
# Markdown principal (el que usa Zensical como fuente del sitio).
#
# Uso:
#   tools/build-report-downloads.sh docs/reports/report1-2026-08-19/report1.md
#
# Requisitos:
#   - pandoc (brew install pandoc)
#   - una distribucion LaTeX con xelatex (MacTeX: /Library/TeX/texbin)
#
# Salida:
#   <carpeta-del-reporte>/latex/<nombre>.pdf
#   <carpeta-del-reporte>/latex/<nombre>.docx

set -euo pipefail

# --- LaTeX en PATH (MacTeX no siempre esta exportado en shells no-login) ---
export PATH="/Library/TeX/texbin:/opt/homebrew/bin:$PATH"

SRC_MD="${1:?Debe indicar la ruta al Markdown principal del reporte}"

if [[ ! -f "$SRC_MD" ]]; then
  echo "ERROR: no existe el archivo fuente: $SRC_MD" >&2
  exit 1
fi

REPORT_DIR="$(cd "$(dirname "$SRC_MD")" && pwd)"
BASENAME="$(basename "$SRC_MD" .md)"
OUT_DIR="$REPORT_DIR/latex"
mkdir -p "$OUT_DIR"

TMP_MD="$(mktemp -t "${BASENAME}.XXXXXX").md"
cleanup() { rm -f "$TMP_MD"; }
trap cleanup EXIT

# --- Sanear la sintaxis especifica de Zensical/Material para pandoc ---
#  1) Elimina el frontmatter YAML (--- ... ---) del inicio.
#  2) Elimina el bloque de admonition "Descargas" (!!! abstract ... hasta linea en blanco doble).
#  3) Convierte encabezados de admonition "!!! tipo \"Titulo\"" en un parrafo en negrita.
#  4) Elimina marcadores de indentacion de contenido de admonitions.
#  5) Elimina iconos :lucide-...: y :material-...:.
awk '
  # Saltar frontmatter YAML inicial
  NR==1 && $0=="---" { infm=1; next }
  infm==1 && $0=="---" { infm=0; next }
  infm==1 { next }
  { print }
' "$SRC_MD" > "$TMP_MD.step1"

# Eliminar iconos emoji-style de Material
sed -E 's/:lucide-[a-z0-9-]+:|:material-[a-z0-9-]+:/''/g' "$TMP_MD.step1" > "$TMP_MD.step2"

# Procesar admonitions linea a linea
awk '
  BEGIN { in_adm=0 }
  # Inicio de admonition: !!! tipo "Titulo"  o  !!! tipo
  /^[[:space:]]*!!! / {
    line=$0
    sub(/^[[:space:]]*!!! +[a-zA-Z]+[[:space:]]*/, "", line)
    gsub(/^"|"$/, "", line)
    if (line != "") print "**" line "**"
    in_adm=1
    next
  }
  {
    if (in_adm==1) {
      if ($0 ~ /^[[:space:]]*$/) { in_adm=0; print ""; next }
      sub(/^[[:space:]]{1,4}/, "", $0)
      print $0
      next
    }
    print $0
  }
' "$TMP_MD.step2" > "$TMP_MD"

rm -f "$TMP_MD.step1" "$TMP_MD.step2"

# --- Metadatos de titulo/subtitulo tomados del H1 del documento ---
TITLE="$(grep -m1 '^# ' "$SRC_MD" | sed 's/^# //')"

echo "==> Generando PDF: $OUT_DIR/$BASENAME.pdf"
pandoc "$TMP_MD" \
  --from=markdown+pipe_tables \
  --metadata title="${TITLE:-Reporte ABAQ}" \
  --metadata author="Equipo de Desarrollo ABAQ" \
  --pdf-engine=xelatex \
  -V geometry:margin=1in \
  -V mainfont="Helvetica Neue" \
  -V colorlinks=true \
  --toc \
  -o "$OUT_DIR/$BASENAME.pdf"

echo "==> Generando DOCX: $OUT_DIR/$BASENAME.docx"
pandoc "$TMP_MD" \
  --from=markdown+pipe_tables \
  --metadata title="${TITLE:-Reporte ABAQ}" \
  --metadata author="Equipo de Desarrollo ABAQ" \
  --toc \
  -o "$OUT_DIR/$BASENAME.docx"

echo "==> Listo:"
echo "    $OUT_DIR/$BASENAME.pdf"
echo "    $OUT_DIR/$BASENAME.docx"
