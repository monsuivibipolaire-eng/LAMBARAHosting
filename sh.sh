#!/bin/sh
set -e

GITHUB_USER="monsuivibipolaire-eng"
GITHUB_REPO="LAMBARAHosting"

echo "🔧 Configuration du déploiement pour $GITHUB_REPO..."

if [ ! -f "angular.json" ]; then
  echo "❌ Erreur : angular.json introuvable !"
  exit 1
fi

echo "📦 Commit des modifications..."
git add .
git commit -m "Fix: base-href corrigé pour $GITHUB_REPO" || echo "Rien à commiter"

echo "🔗 Push sur GitHub..."
git push origin main

echo "🏗️ Build avec base-href=/$GITHUB_REPO/..."
ng build --configuration production --base-href=/$GITHUB_REPO/

# Détection automatique du dossier de build (cherche index.html)
echo "🔍 Recherche du dossier de build..."
OUTPUT_PATH=$(find dist/ -name "index.html" -exec dirname {} \; | head -n 1)

if [ -z "$OUTPUT_PATH" ]; then
  echo "❌ Erreur : index.html introuvable dans dist/"
  echo "Contenu de dist/ :"
  find dist/ -type f
  exit 1
fi

echo "✅ Dossier de build trouvé : $OUTPUT_PATH"

echo "🚀 Déploiement sur GitHub Pages..."
npx angular-cli-ghpages --dir=$OUTPUT_PATH --repo=https://github.com/$GITHUB_USER/$GITHUB_REPO.git --branch=gh-pages --no-silent

echo ""
echo "✅ Déploiement terminé !"
echo "👉 Attends 2-3 minutes puis visite :"
echo "   https://$GITHUB_USER.github.io/$GITHUB_REPO/"
echo ""
echo "💡 Vide le cache du navigateur :"
echo "   Cmd+Shift+R (Mac) ou Ctrl+Shift+R (Windows)"
