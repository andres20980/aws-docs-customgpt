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

echo "🔍 Obteniendo lista de repositorios de AWS Docs desde GitHub..."

# Limpiar entorno previo
rm -rf "$REPOS_DIR" "$OUTPUT_DIR"
mkdir -p "$REPOS_DIR" "$OUTPUT_DIR"

# Cambiar al directorio de repositorios
cd "$REPOS_DIR"

# Sincronizar submódulos
for REPO in $REPO_LIST; do
  if [ ! -d "$REPO" ]; then
    echo "🆕 Agregando submódulo para $REPO..."
    git submodule add "$AWS_DOCS_ORG/$REPO.git" "$REPO" || echo "⚠️ Error agregando $REPO"
  else
    echo "🔄 Actualizando submódulo $REPO..."
    (cd "$REPO" && git pull origin main || git pull origin master || echo "⚠️ Error en $REPO")
  fi
done

# Volver al directorio base
cd "$BASE_PATH"

echo "✅ Submódulos sincronizados. Procesando los archivos .md..."

# Paso 1: Extraer textos de todos los repositorios .md
for REPO in $REPO_LIST; do
  if [ -d "$REPOS_DIR/$REPO" ]; then
    echo "📄 Extrayendo archivos .md del repositorio $REPO..."
    mkdir -p "$OUTPUT_DIR/$REPO"
    
    # Encontrar todos los archivos .md y extraer su contenido
    find "$REPOS_DIR/$REPO" -type f -name "*.md" | while read md_file; do
      repo_name=$(basename "$REPO")
      theme="${repo_name}"  # El nombre del repositorio será la temática
      output_file="$OUTPUT_DIR/$theme.md"

      echo "🔎 Procesando archivo: $md_file"

      # Extraer el contenido del archivo .md
      cat "$md_file" >> "$output_file"
      echo -e "\n\n---\n\n" >> "$output_file"  # Separador entre archivos
    done
  fi
done

# Paso 2: Unificar los .md por temática (nombre del repositorio)
echo "📚 Unificando los archivos .md por temática..."

# Unificar el contenido
for REPO in $REPO_LIST; do
  theme="${REPO}"
  theme_file="$OUTPUT_DIR/$theme.md"

  # Si el archivo .md generado tiene un tamaño mayor que el límite (max 200MB o 500,000 palabras), lo dividimos
  if [ -f "$theme_file" ]; then
    file_size=$(stat -c %s "$theme_file")
    word_count=$(wc -w < "$theme_file")

    if [ $file_size -gt $MAX_FILE_SIZE ] || [ $word_count -gt $MAX_WORDS ]; then
      echo "⚠️ El archivo $theme.md excede el tamaño o número de palabras permitido, se dividirá en partes."

      # Dividir el archivo en fragmentos más pequeños (si es necesario)
      split -l $MAX_WORDS "$theme_file" "$OUTPUT_DIR/${theme}_part_"
      
      # Limpiar el archivo original si fue dividido
      rm "$theme_file"
    fi
  fi
done

echo "✅ Procesamiento completado. Archivos generados en '$OUTPUT_DIR'."

# Paso 3: Listar los archivos generados
echo "📁 Archivos generados: "
find "$OUTPUT_DIR" -type f -name "*.md" -exec ls -lh {} \;

# Aquí podría ir la lógica de subida, pero ahora simplemente tenemos los archivos listos para ser verificados o subidos más tarde.
