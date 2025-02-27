name: Sync and Upload AWS Docs Submodules

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  sync-repos:
    runs-on: ubuntu-latest

    steps:
      # Paso 1: Checkout del repositorio
      - name: 📥 Checkout del repositorio
        uses: actions/checkout@v4
        with:
          submodules: true
          fetch-depth: 0

      # Paso 2: Configurar Git con el token personal
      - name: 🔑 Configurar Git con token personal
        env:
          GH_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
        run: |
          git config --global user.name "github-actions"
          git config --global user.email "github-actions@github.com"
          git remote set-url origin https://x-access-token:${GH_TOKEN}@github.com/${{ github.repository }}.git

      # Paso 3: Ejecutar script Bash
      - name: 🧑‍💻 Ejecutar script Bash
        env:
          GH_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
        run: bash src/descargar_awsdocs.sh
