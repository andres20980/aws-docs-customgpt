#!/bin/bash

set -e

# Directorios de trabajo
REPOS_DIR="repos"  # Directorio donde se encuentran los submódulos
OUTPUT_DIR="fuentes"  # Directorio donde se generarán los archivos .md

# Crear el directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"
echo "✅ Directorio '$OUTPUT_DIR' creado."

# Asegúrate de que los submódulos estén correctamente inicializados
echo "🔄 Actualizando submódulos..."
git submodule update --init --recursive

# Obtener todos los repositorios de awsdocs usando la API de GitHub, manejando la paginación
AWS_DOCS_ORG="awsdocs"
REPO_LIST=()
PAGE=1
while : ; do
  REPOS=$(curl -s "https://api.github.com/orgs/$AWS_DOCS_ORG/repos?per_page=100&page=$PAGE" | jq -r '.[].name')
  if [ -z "$REPOS" ]; then
    break
  fi
  REPO_LIST+=($REPOS)
  ((PAGE++))
done

# Recorremos todos los repositorios de awsdocs
for REPO_NAME in "${REPO_LIST[@]}"; do
  echo "🔄 Procesando el repositorio: $REPO_NAME..."

  # Agregar el submódulo para el repositorio si no está agregado
  if [ ! -d "$REPOS_DIR/$REPO_NAME" ]; then
    git submodule add "https://github.com/$AWS_DOCS_ORG/$REPO_NAME.git" "$REPOS_DIR/$REPO_NAME"
  fi

  # Actualizamos el submódulo
  git submodule update --remote "$REPOS_DIR/$REPO_NAME" || { echo "⚠️ Error al actualizar submódulo: $REPO_NAME"; exit 1; }

  # Crear archivo de salida para cada repositorio
  OUTPUT_FILE="$OUTPUT_DIR/$REPO_NAME.md"
  echo "📄 Generando archivo unificado para $REPO_NAME..."

  # Inicializamos el archivo de salida
  > "$OUTPUT_FILE"
  echo "  ✅ Archivo de salida vacío creado: $OUTPUT_FILE"

  # Buscar todos los archivos dentro del submódulo, sin importar la extensión
  find "$REPOS_DIR/$REPO_NAME" -type f | while read -r FILE; do
    echo "    🔍 Procesando archivo: $FILE"

    # Si el archivo tiene texto, lo concatenamos al archivo de salida
    if file "$FILE" | grep -q 'text'; then
      cat "$FILE" >> "$OUTPUT_FILE"
      echo -e "\n\n" >> "$OUTPUT_FILE"  # Añadir separación entre archivos
    else
      echo "    ⚠️ Saltando archivo binario o no textual: $FILE"
    fi
  done

  echo "✅ Archivo generado: $OUTPUT_FILE"

  # Subir el archivo generado a tu repositorio
  echo "🔄 Añadiendo el archivo .md generado a git..."
  git add "$OUTPUT_FILE"
  git commit -m "Añadir archivo .md generado para $REPO_NAME"
  git push || { echo "⚠️ Error al hacer push para $REPO_NAME"; exit 1; }

  echo "✅ Archivo .md subido para $REPO_NAME"
done

echo "✅ Proceso de unificación y subida de archivos .md completado."
