#!/bin/bash

set -e

# Directorios de trabajo
BASE_PATH="$(pwd)"
REPOS_DIR="repos"  # Directorio donde se encuentran los submódulos
OUTPUT_DIR="fuentes"  # Directorio donde se generarán los archivos .md
LINKS_FILE="aws_links.txt"  # Archivo donde guardaremos los enlaces encontrados
MAX_WORDS=500000  # Límite de palabras por archivo
MAX_SIZE=200000000  # Límite de tamaño por archivo en bytes (200MB)

# Limpiar los directorios previos
echo "🧹 Limpiando directorios previos..."
rm -rf "$REPOS_DIR" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
echo "✅ Directorios 'repos' y 'fuentes' eliminados."

# Limpiar el archivo de enlaces anteriores
> "$LINKS_FILE"

# Asegúrate de que los submódulos estén correctamente inicializados
echo "🔄 Actualizando submódulos..."
git submodule update --init --recursive

# Función para dividir archivos grandes
split_file() {
    local file=$1
    local repo_name=$2
    local file_size=$(stat -c %s "$file")
    local word_count=$(wc -w < "$file")
    
    if [ $word_count -gt $MAX_WORDS ] || [ $file_size -gt $MAX_SIZE ]; then
        echo "⚠️ El archivo '$file' es demasiado grande. Dividiéndolo..."
        
        # Dividir el archivo en fragmentos de 500,000 palabras
        split -l $MAX_WORDS "$file" "$OUTPUT_DIR/$repo_name-part-"
        echo "✅ El archivo '$file' ha sido dividido en partes más pequeñas."
    else
        echo "✅ El archivo '$file' está dentro de los límites de tamaño."
    fi
}

# Función para procesar enlaces encontrados
process_links() {
    local link=$1
    local output_file="fuentes/${link//\//_}.md"  # Reemplazamos las barras por guiones bajos

    # Comprobar si el archivo ya existe
    if [ -f "$output_file" ]; then
        echo "✅ El archivo '$output_file' ya existe. Saltando..."
        return
    fi

    echo "🔄 Procesando enlace: $link..."

    # Obtener el contenido de la página
    content=$(curl -s "$link")

    if [ -z "$content" ]; then
        echo "⚠️ No se pudo obtener contenido de $link"
        return
    fi

    # Crear el archivo .md con el contenido obtenido
    echo "# Contenido de $link" > "$output_file"
    echo "$content" >> "$output_file"
    
    # Verificar si el archivo generado es muy grande y dividirlo si es necesario
    split_file "$output_file" "$link"
}

# Recorremos cada submódulo uno por uno
for REPO_DIR in "$REPOS_DIR"/*; do
  if [ -d "$REPO_DIR" ]; then
    REPO_NAME=$(basename "$REPO_DIR")  # Nombre del repositorio (submódulo)
    
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
    find "$REPO_DIR" -type f | while read -r FILE; do
      if file "$FILE" | grep -q 'text'; then
        echo "    🔍 Procesando archivo: $FILE"
        cat "$FILE" >> "$OUTPUT_FILE"
        echo -e "\n\n" >> "$OUTPUT_FILE"  # Añadir separación entre archivos de texto

        # Buscar enlaces que empiecen con 'http://docs.aws.amazon.com/'
        grep -o 'http://docs.aws.amazon.com/[^"]*' "$FILE" >> "$LINKS_FILE"
      else
        echo "    ⚠️ Saltando archivo no textual: $FILE"
      fi
    done

    echo "✅ Archivo generado: $OUTPUT_FILE"
    
    # Verificar si el archivo generado es muy grande y dividirlo si es necesario
    split_file "$OUTPUT_FILE" "$REPO_NAME"

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

# Si encontramos enlaces, procesarlos
if [ -s "$LINKS_FILE" ]; then
  echo "✅ Enlaces encontrados y guardados en '$LINKS_FILE'. Procesando..."
  while read -r link; do
    process_links "$link"
  done < "$LINKS_FILE"
else
  echo "⚠️ No se encontraron enlaces de AWS Docs para procesar."
fi

echo "✅ Proceso de unificación y subida de archivos .md completado."
