#!/bin/bash

set -e

# Directorios de trabajo
OUTPUT_DIR="fuentes"  # Directorio donde se generarán los archivos .md

# Crear el directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"
echo "✅ Directorio de salida '$OUTPUT_DIR' creado o ya existente."

# Crear archivo de salida con contenido de ejemplo
OUTPUT_FILE="$OUTPUT_DIR/holamundo.md"
echo "📄 Generando archivo 'holamundo.md'..."

# Inicializamos el archivo de salida con "Hola Mundo"
echo "# Hola Mundo" > "$OUTPUT_FILE"
echo "✅ Archivo 'holamundo.md' generado."

# Configurar el nombre y correo del usuario para el commit
git config --global user.name "github-actions"
git config --global user.email "github-actions@github.com"

# Subir el archivo generado a tu repositorio
echo "🔄 Añadiendo el archivo .md generado a git..."
git add "$OUTPUT_FILE"
git commit -m "Añadir archivo holamundo.md"
git push || { echo "⚠️ Error al hacer push"; exit 1; }

echo "✅ Archivo 'holamundo.md' subido con éxito."
