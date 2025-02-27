#!/bin/bash

set -e

# Directorios de trabajo
BASE_PATH="$(pwd)"
REPOS_DIR="repos"  # Directorio donde se encuentran los submódulos
OUTPUT_DIR="fuentes"  # Directorio donde se generarán los archivos .md

# Crear el directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"
echo "✅ Directorio de salida '$OUTPUT_DIR' creado o ya existente."

# Asegúrate de que los submódulos estén correctamente inicializados
echo "🔄 Actualizando submódulos..."
git submodule update --init --recursive

# Recorremos cada submódulo uno por uno
for REPO_DIR in "$REPOS_DIR"/*; do
  if [ -d "$REPO_DIR" ]; then
    REPO_NAME=$(basename "$REPO_DIR")  # Nombre del repositorio (submódulo)
    echo "🔄 Procesando el submódulo: $REPO_NAME..."

    # Sincronizar el submódulo
    git submodule update --remote "$REPO_DIR" || { echo "⚠️ Error al actualizar submódulo: $REPO_NAME"; exit 1; }

    # Crear archivo de salida para cada repositorio
    OUTPUT_FILE="$OUTPUT_DIR/$REPO_NAME.md"
    echo "📄 Generando archivo unificado para $REPO_NAME..."

    # Inicializamos el archivo de salida
    > "$OUTPUT_FILE"
    echo "  ✅ Archivo de salida vacío creado: $OUTPUT_FILE"

    # Buscar todos los archivos dentro del submódulo, incluso los binarios
    find "$REPO_DIR" -type f | xargs -I {} bash -c '
    FILE="{}"
      echo "    🔍 Procesando archivo: $FILE"

      # Si el archivo es de texto, lo concatenamos al archivo de salida
        >> "$OUTPUT_FILE" cat "$FILE"
        cat "$FILE" >> "$OUTPUT_FILE"
        printf "\n\n" >> "$OUTPUT_FILE"  # Añadir separación entre archivos de texto
      else
        echo "    ⚠️ Saltando archivo binario o no texto: $FILE"
      fi
    '

    echo "✅ Archivo generado: $OUTPUT_FILE"

    # Subir el archivo generado a tu repositorio
    echo "🔄 Añadiendo el archivo .md generado a git..."
    git add "$OUTPUT_FILE"
    git commit -m "Add generated .md file for $REPO_NAME"
    git push || { echo "⚠️ Error al hacer push para $REPO_NAME"; exit 1; }

    echo "✅ Archivo .md subido para $REPO_NAME"
  else
    echo "⚠️ No se encontró el directorio del submódulo: $REPO_DIR"
  fi
done

echo "✅ Proceso de unificación y subida de archivos .md completado."
