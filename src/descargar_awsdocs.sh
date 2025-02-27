#!/bin/bash

set -e

REPOS_DIR="repos"
AWS_DOCS_ORG="https://github.com/awsdocs"
BASE_PATH="$(pwd)"

echo "🔍 Obteniendo lista de repositorios de AWS Docs desde GitHub..."

# Obtener lista de repositorios (requiere `gh` CLI autenticado o usa `web scraping`)
REPO_LIST=$(curl -s "https://api.github.com/orgs/awsdocs/repos?per_page=100&page=1" | jq -r '.[].name')

mkdir -p "$REPOS_DIR"
cd "$REPOS_DIR"

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

echo "✅ Todos los submódulos sincronizados. Haciendo commit de los cambios..."
git submodule update --remote --merge
