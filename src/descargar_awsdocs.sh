#!/bin/bash

set -e

# Directorio donde se guardará el archivo
OUTPUT_DIR="fuentes"

# Crear el directorio si no existe
mkdir -p "$OUTPUT_DIR"
echo "✅ Directorio '$OUTPUT_DIR' creado."

# Crear el archivo 'holamundo.md'
OUTPUT_FILE="$OUTPUT_DIR/holamundo.md"
echo "# Hola Mundo" > "$OUTPUT_FILE"
echo "✅ Archivo '$OUTPUT_FILE' creado."

# Subir el archivo a GitHub
echo "🔄 Subiendo archivo a GitHub..."
git add "$OUTPUT_FILE"
git commit -m "🚀 Añadir archivo holamundo.md"
git push || { echo "⚠️ Error al hacer push"; exit 1; }

echo "✅ Archivo subido correctamente."
