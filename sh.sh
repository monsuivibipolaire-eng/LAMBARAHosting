#!/bin/sh
set -e

# ⚠️ IMPORTANT : Le nom EXACT du repo GitHub (avec "ing")
GITHUB_USER="monsuivibipolaire-eng"
GITHUB_REPO="LAMBARAHosting"

echo "🔧 Configuration du déploiement pour $GITHUB_REPO..."

if [ ! -f "angular.json" ]; then
  echo "❌ Erreur : angular.json introuvable !"
  exit 1
fi

# Extraire le outputPath
OUTPUT_PATH=$(node -e "const config = require('./angular.json'); const proj = Object.keys(config.projects)[0]; console.log(config.projects[proj].architect.build.options.outputPath || 'dist/' + proj.toLowerCase())")
echo "📁 Output path : $OUTPUT_PATH"

echo "📦 Commit des modifications..."
git add .
git commit -m "Fix: base-href corrigé pour $GITHUB_REPO" || echo "Rien à commiter"

echo "🔗 Push sur GitHub..."
git push origin main

echo "🏗️ Build avec base-href=/$GITHUB_REPO/..."
ng build --configuration production --base-href=/$GITHUB_REPO/

echo "✅ Vérification du build..."
if [ ! -f "$OUTPUT_PATH/index.html" ]; then
  echo "❌ Erreur : index.html introuvable dans $OUTPUT_PATH"
  echo "Contenu de dist/ :"
  ls -la dist/
  exit 1
fi

echo "🚀 Déploiement sur GitHub Pages..."
npx angular-cli-ghpages --dir=$OUTPUT_PATH --repo=https://github.com/$GITHUB_USER/$GITHUB_REPO.git --branch=gh-pages --no-silent

echo ""
echo "✅ Déploiement terminé !"
echo "👉 Attends 2-3 minutes puis visite :"
echo "   https://$GITHUB_USER.github.io/$GITHUB_REPO/"
echo ""
echo "💡 Si tu vois encore des erreurs 404, vide le cache :"
echo "   - Chrome/Edge : Ctrl+Shift+R (Windows) ou Cmd+Shift+R (Mac)"
echo "   - Firefox : Ctrl+F5"
