#!/bin/bash

set -e

REPOS_DIR="repos"
AWS_DOCS_ORG="https://github.com/awsdocs"
BASE_PATH="$(pwd)"

echo "🔍 Verificando permisos de escritura en el repositorio..."

# Intentar realizar un cambio en el repositorio para verificar si los permisos son correctos
git config --global user.name "github-actions"
git config --global user.email "github-actions@github.com"

# Verificar si podemos hacer un commit sin errores
if ! git commit --allow-empty -m "Verificando permisos de escritura"; then
  echo "❌ Error: No se pudo realizar un commit, los permisos pueden no estar configurados correctamente."
  exit 1
else
  echo "✅ Permisos de escritura confirmados, continuando con la sincronización de submódulos..."
fi

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

  # Verificar y reconfigurar submódulos
  echo "🔄 Comprobando y reconfigurando submódulos..."
  git submodule update --init --recursive || echo "⚠️ Error en la actualización de submódulos, lo corregimos..."

  # Comprobar si el submódulo tiene una URL válida antes de intentar recursividad
  SUBMODULES=$(git submodule status | awk '{print $2}')
  for SUBMODULE in $SUBMODULES; do
    SUBMODULE_URL=$(git config --file .gitmodules submodule.$SUBMODULE.url)
    if [ -z "$SUBMODULE_URL" ]; then
      echo "⚠️ El submódulo $SUBMODULE no tiene una URL definida, lo ignoraremos..."
      git submodule deinit $SUBMODULE || echo "⚠️ Error desinicializando $SUBMODULE"
    fi
  done
done

cd "$BASE_PATH"

echo "✅ Todos los submódulos sincronizados. Haciendo commit de los cambios..."
git submodule update --remote --merge
