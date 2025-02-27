#!/bin/bash

set -e

# Directorios y variables
REPOS_DIR="repos"
OUTPUT_DIR="fuentes"
BASE_PATH="$(pwd)"
AWS_DOCS_ORG="https://github.com/awsdocs"
REPO_LIST=$(curl -s "https://api.github.com/orgs/awsdocs/repos?per_page=100&page=1" | jq -r '.[].name')
MAX_FILE_SIZE=200000000  # 200MB en bytes
MAX_WORDS=500000  # Máximo de palabras permitido por fuente

echo "🔍 Iniciando la sincronización de submódulos..."

# Limpiar entorno previo
rm -rf "$REPOS_DIR" "$OUTPUT_DIR"
mkdir -p "$REPOS_DIR" "$OUTPUT_DIR"

# Cambiar al directorio de repositorios
cd "$REPOS_DIR"

# Sincronizar submódulos
for REPO in $REPO_LIST; do
  if [ ! -d "$REPO" ]; then
    echo "🆕 Agregando submódulo para $REPO..." >> "$BASE_PATH/sync.log"
    git submodule add "$AWS_DOCS_ORG/$REPO.git" "$REPO" >> "$BASE_PATH/sync.log" 2>&1 || echo "⚠️ Error agregando $REPO" >> "$BASE_PATH/sync.log"
  else
    echo "🔄 Actualizando submódulo $REPO..." >> "$BASE_PATH/sync.log"
    (cd "$REPO" && git pull origin main >> "$BASE_PATH/sync.log" 2>&1 || git pull origin master >> "$BASE_PATH/sync.log" 2>&1 || echo "⚠️ Error en $REPO" >> "$BASE_PATH/sync.log")
  fi
done

# Volver al directorio base
cd "$BASE_PATH"

echo "✅ Submódulos sincronizados. Procesando los archivos .md..."

# Paso 1: Extraer textos de todos los repositorios .md
for REPO in $REPO_LIST; do
  if [ -d "$REPOS_DIR/$REPO" ]; then
    echo "📄 Extrayendo archivos .md del repositorio $REPO..." >> "$BASE_PATH/extract.log"
    mkdir -p "$OUTPUT_DIR/$REPO"
    
    # Encontrar todos los archivos .md y extraer su contenido
    find "$REPOS_DIR/$REPO" -type f -name "*.md" | while read md_file; do
      repo_name=$(basename "$REPO")
      theme="${repo_name}"  # El nombre del repositorio será la temática
      output_file="$OUTPUT_DIR/$theme.md"

      echo "🔎 Procesando archivo: $md_file" >> "$BASE_PATH/extract.log"
      cat "$md_file" >> "$output_file"
      echo -e "\n\n---\n\n" >> "$output_file"  # Separador entre archivos
    done
  fi
done

# Paso 2: Unificar los .md por temática (nombre del repositorio)
echo "📚 Unificando los archivos .md por temática..." >> "$BASE_PATH/unify.log"

# Unificar el contenido
for REPO in $REPO_LIST; do
  theme="${REPO}"
  theme_file="$OUTPUT_DIR/$theme.md"

  # Si el archivo .md generado tiene un tamaño mayor que el límite (max 200MB o 500,000 palabras), lo dividimos
  if [ -f "$theme_file" ]; then
    file_size=$(stat -c %s "$theme_file")
    word_count=$(wc -w < "$theme_file")

    if [ $file_size -gt $MAX_FILE_SIZE ] || [ $word_count -gt $MAX_WORDS ]; then
      echo "⚠️ El archivo $theme.md excede el tamaño o número de palabras permitido, se dividirá en partes." >> "$BASE_PATH/unify.log"

      # Dividir el archivo en fragmentos más pequeños (si es necesario)
      split -l $MAX_WORDS "$theme_file" "$OUTPUT_DIR/${theme}_part_"
      
      # Limpiar el archivo original si fue dividido
      rm "$theme_file"
    fi
  fi
done

echo "✅ Procesamiento completado. Archivos generados en '$OUTPUT_DIR'."

# Paso 3: Listar los archivos generados
echo "📁 Archivos generados: " >> "$BASE_PATH/extract.log"
find "$OUTPUT_DIR" -type f -name "*.md" -exec ls -lh {} \; >> "$BASE_PATH/extract.log"

# Aquí podría ir la lógica de subida, pero ahora simplemente tenemos los archivos listos para ser verificados o subidos más tarde.
