#!/bin/bash

set -e

# Directorios de trabajo
BASE_PATH="$(pwd)"
REPOS_DIR="repos"  # Directorio donde se encuentran los submódulos
OUTPUT_DIR="fuentes"  # Directorio donde se generarán los archivos .md

# Limpiar directorios previos si existen
echo "🧹 Limpiando directorios previos..."
rm -rf "$REPOS_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
echo "✅ Directorio '$OUTPUT_DIR' creado."

# Asegúrate de que los submódulos estén correctamente inicializados
echo "🔄 Actualizando submódulos..."
git submodule update --init --recursive

# Recorremos cada submódulo uno por uno
for REPO_DIR in "$REPOS_DIR"/*; do
  if [ -d "$REPO_DIR" ]; then
    REPO_NAME=$(basename "$REPO_DIR")  # Nombre del repositorio (submódulo)
    
    echo "🔄 Comprobando si el submódulo '$REPO_NAME' está actualizado..."
    # Actualizar solo si el submódulo no está actualizado
    git -C "$REPO_DIR" pull || { echo "⚠️ Error al actualizar el submódulo: $REPO_NAME"; continue; }

    # Crear archivo de salida para cada repositorio
    OUTPUT_FILE="$OUTPUT_DIR/$REPO_NAME.md"
    echo "📄 Generando archivo unificado para '$REPO_NAME'..."

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

    # Buscar enlaces a http://docs.aws.amazon.com/ y generar archivos adicionales
    echo "🔍 Buscando enlaces a http://docs.aws.amazon.com/..."
    grep -o 'http://docs.aws.amazon.com/[^"]*' "$OUTPUT_FILE" | while read -r LINK; do
      # Crear archivo adicional para cada enlace encontrado
      LINK_FILE="$OUTPUT_DIR/$(echo "$LINK" | sed 's/[^a-zA-Z0-9]/_/g').md"
      echo "📄 Generando archivo para el enlace '$LINK'..."
      echo "# Enlace: $LINK" > "$LINK_FILE"
      echo "🔗 Enlace encontrado en $REPO_NAME" >> "$LINK_FILE"
      # Aquí podrías agregar código para obtener el contenido del enlace, si es necesario
    done

    # Subir los archivos generados para cada submódulo
    echo "🔄 Añadiendo el archivo .md generado a git..."
    git add "$OUTPUT_FILE"
    git commit -m "Añadir archivo .md generado para $REPO_NAME"
    git push "https://x-access-token:${GH_TOKEN}@github.com/$GITHUB_REPOSITORY.git" main || { echo "⚠️ Error al hacer push para $REPO_NAME"; exit 1; }

    echo "✅ Archivo .md subido para $REPO_NAME"
  else
    echo "⚠️ No se encontró el directorio del submódulo: $REPO_DIR"
  fi
done

# Procesar enlaces adicionales encontrados en los repositorios y crear md para cada uno
echo "✅ Proceso de unificación y subida de archivos .md completado."
