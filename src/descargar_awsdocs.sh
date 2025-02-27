#!/bin/bash

set -e

# Directorios de trabajo
BASE_PATH="$(pwd)"
REPOS_DIR="repos"  # Directorio donde se encuentran los submódulos
OUTPUT_DIR="fuentes"  # Directorio donde se generarán los archivos .md

# Limpiar los directorios de trabajo previos
echo "🧹 Limpiando directorios previos..."
rm -rf "$REPOS_DIR" "$OUTPUT_DIR"  # Borrar los directorios 'repos' y 'fuentes'
echo "✅ Directorios 'repos' y 'fuentes' eliminados."

# Crear el directorio de salida 'fuentes' si no existe
mkdir -p "$OUTPUT_DIR"
echo "✅ Directorio '$OUTPUT_DIR' creado."

# Asegúrate de que los submódulos estén correctamente inicializados
echo "🔄 Actualizando submódulos..."
git submodule update --init --recursive

# Paso 1: Obtener todos los repositorios de la organización AWS Docs mediante la API de GitHub
echo "🔄 Obteniendo los repositorios de AWS Docs..."
REPOS=$(curl -s "https://api.github.com/orgs/awsdocs/repos?per_page=100&page=1" | jq -r '.[].full_name')

# Recorrer todos los repositorios
for REPO_NAME in $REPOS; do
  echo "🔄 Procesando el submódulo: $REPO_NAME..."

  # Comprobar si el submódulo está presente
  if ! git submodule status "$REPO_NAME"; then
    echo "⚠️ Submódulo $REPO_NAME no encontrado, añadiendo submódulo..."
    git submodule add "https://github.com/$REPO_NAME.git" "$REPOS_DIR/$REPO_NAME"
    git submodule update --init "$REPOS_DIR/$REPO_NAME"
  fi

  # Verificar si el directorio de salida para el repositorio está presente
  REPO_OUTPUT_DIR="$OUTPUT_DIR/$REPO_NAME"
  mkdir -p "$REPO_OUTPUT_DIR"
  echo "✅ Directorio '$REPO_OUTPUT_DIR' creado."

  # Crear archivo de salida para cada repositorio
  OUTPUT_FILE="$REPO_OUTPUT_DIR.md"
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
