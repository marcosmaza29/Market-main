#!/bin/sh
# Descarga los SVG oficiales de Material Symbols (Outlined) desde el repositorio
# google/material-design-icons, fijado a un commit para que el resultado sea reproducible.
set -eu
COMMIT=737e3324305806514d7909874fa1818ae1808232
BASE="https://raw.githubusercontent.com/google/material-design-icons/$COMMIT/symbols/web"
DESTINO="$(dirname "$0")/../src/main/webapp/WEB-INF/iconos"
mkdir -p "$DESTINO"
grep -v '^\s*#' "$(dirname "$0")/iconos.txt" | grep -v '^\s*$' | while read -r nombre; do
  curl -fsS "$BASE/$nombre/materialsymbolsoutlined/${nombre}_24px.svg" -o "$DESTINO/$nombre.svg" \
    || { echo "No existe el icono: $nombre" >&2; exit 1; }
done
echo "Iconos descargados en $DESTINO"
