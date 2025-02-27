#!/bin/bash

set -e

# Directorios de trabajo
BASE_PATH="$(pwd)"
REPOS_DIR="repos"  # Directorio donde se encuentran los submódulos
OUTPUT_DIR="fuentes"  # Directorio donde se generarán los archivos .md

# Limpiar cualquier directorio anterior
echo "🧹 Limpiando directorios previos..."
rm -rf "$REPOS_DIR" "$OUTPUT_DIR"

# Crear directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"
echo "✅ Directorio de salida '$OUTPUT_DIR' creado."

# Inicializar los submódulos, si no están ya presentes, los añade
echo "🔄 Actualizando submódulos..."
git submodule update --init --recursive

# Recorremos los submódulos (repositorios) uno por uno
for REPO_DIR in "$REPOS_DIR"/*; do
  if [ -d "$REPO_DIR" ]; then
    REPO_NAME=$(basename "$REPO_DIR")  # Nombre del repositorio (submódulo)
    echo "🔄 Procesando el submódulo: $REPO_NAME..."

    # Verificar si el submódulo está actualizado
    cd "$REPO_DIR"
    git fetch
    if git diff --quiet HEAD origin/main; then
      echo "🔑 El submódulo '$REPO_NAME' ya está actualizado, omitiendo actualización."
    else
      echo "⚙️ El submódulo '$REPO_NAME' no está actualizado, actualizando..."
      git pull origin main
    fi

    # Crear archivo de salida para cada repositorio
    OUTPUT_FILE="$OUTPUT_DIR/$REPO_NAME.md"
    echo "📄 Generando archivo unificado para $REPO_NAME..."

    # Inicializamos el archivo de salida
    > "$OUTPUT_FILE"
    echo "  ✅ Archivo de salida vacío creado: $OUTPUT_FILE"

    # Buscar todos los archivos dentro del submódulo, incluyendo texto, markdown, json, etc.
    find "$REPO_DIR" -type f | while read -r FILE; do
      if file "$FILE" | grep -q 'text'; then
        echo "    🔍 Procesando archivo: $FILE"
        cat "$FILE" >> "$OUTPUT_FILE"
        echo -e "\n\n" >> "$OUTPUT_FILE"  # Añadir separación entre archivos de texto
      else
        echo "    ⚠️ Saltando archivo no textual: $FILE"
      fi
    done

    echo "✅ Archivo generado: $OUTPUT_FILE"

    # Subir el archivo generado a tu repositorio con autenticación
    echo "🔄 Añadiendo el archivo .md generado a git..."
    git add "$OUTPUT_FILE"
    git commit -m "Añadir archivo .md generado para $REPO_NAME"
    GIT_REPO_URL="https://x-access-token:${GH_TOKEN}@github.com/$GITHUB_REPOSITORY.git"
    git push "$GIT_REPO_URL" main || { echo "⚠️ Error al hacer push para $REPO_NAME"; exit 1; }

    echo "✅ Archivo .md subido para $REPO_NAME"
  else
    echo "⚠️ No se encontró el directorio del submódulo: $REPO_DIR"
  fi
done

echo "✅ Proceso de unificación y subida de archivos .md completado."
