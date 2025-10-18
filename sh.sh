#!/bin/sh
set -e

GITHUB_USER="monsuivibipolaire-eng"
GITHUB_REPO="LAMBARAHosting"

echo "🔧 Vérification de la configuration..."

if [ ! -f "angular.json" ]; then
  echo "❌ Erreur : angular.json introuvable !"
  exit 1
fi

# Extraire le vrai outputPath depuis angular.json
OUTPUT_PATH=$(node -e "console.log(require('./angular.json').projects[Object.keys(require('./angular.json').projects)[0]].architect.build.options.outputPath)")
echo "📁 Output path détecté : $OUTPUT_PATH"

echo "📦 Commit des modifications..."
git add .
git commit -m "Fix: correction base-href pour GitHub Pages" || echo "Rien à commiter"

echo "🔗 Push sur GitHub..."
git push origin main

echo "🏗️ Build avec le bon base-href..."
ng build --configuration production --base-href=/$GITHUB_REPO/

echo "🚀 Déploiement sur GitHub Pages..."
npx angular-cli-ghpages --dir=$OUTPUT_PATH --repo=https://github.com/$GITHUB_USER/$GITHUB_REPO.git --branch=gh-pages

echo ""
echo "✅ Déploiement terminé !"
echo "👉 Attends 1-2 minutes puis visite :"
echo "   https://$GITHUB_USER.github.io/$GITHUB_REPO/"
