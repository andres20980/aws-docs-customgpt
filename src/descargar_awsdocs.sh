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

# Obtener los 269 repositorios de AWS Docs
AWS_DOCS_REPOS=("AWS-Kinesis-Video-Documentation" "amazon-application-discovery-user-guide" "amazon-appstream2-developer-guide" ... )  # Rellena esta lista con todos los repos de AWS Docs

# Recorremos cada repositorio de AWS Docs
for REPO_NAME in "${AWS_DOCS_REPOS[@]}"; do
  echo "🔄 Procesando el submódulo: $REPO_NAME..."

  # Sincronizar el submódulo
  git submodule update --remote "$REPO_NAME" || { echo "⚠️ Error al actualizar submódulo: $REPO_NAME"; exit 1; }

  # Crear archivo de salida para cada repositorio
  OUTPUT_FILE="$OUTPUT_DIR/$REPO_NAME.md"
  echo "📄 Generando archivo unificado para $REPO_NAME..."

  # Inicializamos el archivo de salida
  > "$OUTPUT_FILE"
  echo "  ✅ Archivo de salida vacío creado: $OUTPUT_FILE"

  # Buscar todos los archivos dentro del submódulo, incluyendo texto, markdown, json, etc.
  find "$REPOS_DIR/$REPO_NAME" -type f | while read -r FILE; do
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
done

echo "✅ Proceso de unificación y subida de archivos .md completado."
