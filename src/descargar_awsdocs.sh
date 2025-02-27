#!/bin/bash

set -e

REPOS_DIR="repos"
AWS_DOCS_ORG="https://github.com/awsdocs"
BASE_PATH="$(pwd)"
MAX_FILE_SIZE_MB=200   # Tamaño máximo de cada archivo fuente en MB
MAX_WORDS=500000      # Máximo de palabras por archivo

echo "🔍 Obteniendo lista de repositorios de AWS Docs desde GitHub..."

# Obtener lista de repositorios (requiere `gh` CLI autenticado o usa `web scraping`)
REPO_LIST=$(curl -s "https://api.github.com/orgs/awsdocs/repos?per_page=100&page=1" | jq -r '.[].name')

# Limpiar entorno: eliminar directorios previos si existen
rm -rf "$REPOS_DIR"
mkdir -p "$REPOS_DIR"
cd "$REPOS_DIR"

# Paso 1: Clonar o actualizar submódulos
for REPO in $REPO_LIST; do
  if [ ! -d "$REPO" ]; then
    echo "🆕 Agregando submódulo para $REPO..."
    git submodule add "$AWS_DOCS_ORG/$REPO.git" "$REPO" || echo "⚠️ Error agregando $REPO"
  else
    echo "🔄 Actualizando submódulo $REPO..."
    (cd "$REPO" && git pull origin main || git pull origin master || echo "⚠️ Error en $REPO")
  fi
done

cd "$BASE_PATH"

# Paso 2: Organizar los archivos .md por temática (basado en nombre del repositorio)
echo "📑 Organizando archivos .md..."

mkdir -p "$BASE_PATH/aws_docs_fuentes"

# Recorrer los submódulos para encontrar y mover archivos .md
for REPO in $REPO_LIST; do
  REPO_PATH="$REPOS_DIR/$REPO"
  if [ -d "$REPO_PATH" ]; then
    # Buscar archivos .md en cada submódulo
    find "$REPO_PATH" -type f -name "*.md" | while read MD_FILE; do
      # Extraer tema del nombre del repositorio (simplemente usamos el nombre)
      THEME=$(basename "$REPO")
      DEST_DIR="$BASE_PATH/aws_docs_fuentes/$THEME"
      mkdir -p "$DEST_DIR"

      # Copiar el archivo .md al directorio correspondiente
      cp "$MD_FILE" "$DEST_DIR"
      echo "📄 Copiado: $MD_FILE a $DEST_DIR"
    done
  fi
done

echo "✅ Todos los archivos .md organizados."

# Paso 3: Comprimir archivos grandes si es necesario
echo "🔍 Comprobando el tamaño de los archivos .md..."

find "$BASE_PATH/aws_docs_fuentes" -type f -name "*.md" | while read MD_FILE; do
  FILE_SIZE_MB=$(du -m "$MD_FILE" | cut -f1)
  if [ "$FILE_SIZE_MB" -gt "$MAX_FILE_SIZE_MB" ]; then
    echo "⚠️ El archivo $MD_FILE excede el tamaño máximo permitido ($MAX_FILE_SIZE_MB MB). Compriéndolo..."
    gzip "$MD_FILE"
    echo "✅ Archivo comprimido: $MD_FILE"
  else
    echo "✅ El archivo $MD_FILE está dentro del límite de tamaño."
  fi
done

echo "✅ Proceso de organización y compresión completado."

# Paso 4: Confirmación de los archivos organizados
echo "📁 Archivos organizados en $BASE_PATH/aws_docs_fuentes"
