#!/bin/bash

set -e

# Directorio de trabajo
BASE_PATH="$(pwd)"
REPOS_DIR="repos"  # Directorio donde se encuentran los submódulos
OUTPUT_DIR="fuentes"  # Directorio donde se generarán los archivos .md

# Crear el directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"

# Recorremos cada submódulo uno por uno
for REPO_DIR in "$REPOS_DIR"/*; do
  if [ -d "$REPO_DIR" ]; then
    REPO_NAME=$(basename "$REPO_DIR")  # Nombre del repositorio (submódulo)
    
    echo "🔄 Procesando el submódulo: $REPO_NAME..."

    # Sincronizar el submódulo
    git submodule update --remote "$REPO_NAME"

    # Creamos un archivo de salida para cada repositorio
    OUTPUT_FILE="$OUTPUT_DIR/$REPO_NAME.md"
    echo "📄 Generando archivo unificado para $REPO_NAME..."

    # Inicializamos el archivo de salida
    > "$OUTPUT_FILE"

    # Buscamos y unificamos todos los archivos de texto dentro del submódulo
    find "$REPO_DIR" -type f \( -iname "*.md" -o -iname "*.txt" \) | while read -r FILE; do
      echo "  🔍 Procesando archivo: $FILE"
      cat "$FILE" >> "$OUTPUT_FILE"
      echo -e "\n\n" >> "$OUTPUT_FILE"  # Añadir separación entre archivos
    done

    echo "✅ Archivo generado: $OUTPUT_FILE"

    # Subir el archivo generado a tu repositorio
    git add "$OUTPUT_FILE"
    git commit -m "Añadir archivo .md generado para $REPO_NAME"
    git push

    echo "✅ Archivo .md subido para $REPO_NAME"
  else
    echo "⚠️ No se encontró el directorio del submódulo: $REPO_DIR"
  fi
done

echo "✅ Proceso de unificación y subida de archivos .md completado."