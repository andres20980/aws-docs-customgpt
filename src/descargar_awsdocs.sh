#!/bin/bash

# Limpiar directorios previos
echo "🧹 Limpiando directorios previos..."
rm -rf repos fuentes
mkdir -p fuentes repos

# Descargar submódulos
echo "🔄 Actualizando submódulos..."
git submodule update --init --recursive --quiet

# Recorremos los repositorios de AWS Docs
for repo in $(ls repos/awsdocs); do
    echo "🔍 Procesando submódulo: $repo..."

    # Repositorio y ruta del archivo md de salida
    output_file="fuentes/awsdocs/$repo.md"

    # Verificar si ya se generó el archivo
    if [ -f "$output_file" ]; then
        echo "El archivo para $repo ya existe, omitiendo creación..."
        continue
    fi

    # Si no existe, procesamos los archivos dentro del repositorio
    echo "💾 Generando archivo unificado para $repo..."
    touch "$output_file"
    for file in $(find "repos/awsdocs/$repo" -type f -name "*.md" -o -name "*.txt"); do
        cat "$file" >> "$output_file"
    done

    # Filtrar enlaces de docs.aws.amazon.com
    grep -o 'http://docs.aws.amazon.com/[^"]*' "$output_file" > "fuentes/links_$repo.txt"

    # Limpiar el archivo de salida si está vacío
    if [ ! -s "$output_file" ]; then
        echo "El archivo $output_file está vacío, eliminando..."
        rm -f "$output_file"
    fi
done

# Subir los archivos generados
echo "🎉 Todos los archivos generados. Preparando para subir..."

# Este paso ahora solo sube si hay cambios en el repositorio
git diff --exit-code --quiet || git commit -am "Actualización de archivos de documentación de AWS"
