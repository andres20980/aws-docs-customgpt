#!/bin/bash

set -e

REPOS_DIR="repos"
AWS_DOCS_ORG="https://github.com/awsdocs"
BASE_PATH="$(pwd)"

echo "🔍 Obteniendo lista de repositorios de AWS Docs desde GitHub..."

# Obtener lista de repositorios (requiere `gh` CLI autenticado o usa `curl`)
REPO_LIST=$(curl -s "https://api.github.com/orgs/awsdocs/repos?per_page=100&page=1" | jq -r '.[].name')

# Verificar si los repositorios ya están configurados como submódulos o no
mkdir -p "$REPOS_DIR"
cd "$REPOS_DIR"

# Iterar sobre la lista de repositorios
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

# Realizar un `git submodule update` para actualizar todos los submódulos
echo "✅ Todos los submódulos sincronizados. Haciendo commit de los cambios..."

git submodule update --remote --merge

# Verificar si hubo cambios en los submódulos
if git diff --staged --quiet; then
  echo "No hay cambios para hacer commit."
else
  echo "🔥 Realizando commit y push de los cambios..."
  git add .
  git commit -m "🔄 Actualización automática de submódulos de AWS Docs"
  git push
fi
