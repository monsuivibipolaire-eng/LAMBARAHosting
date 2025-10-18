#!/bin/sh
set -e

# ⚠️ IMPORTANT : Utilise le nom EXACT de ton repo GitHub
GITHUB_USER="monsuivibipolaire-eng"
GITHUB_REPO="LAMBARAHosting"  # ← Avec "ing" !

echo "🔧 Vérification de la configuration..."

# Vérifier qu'on est dans le bon dossier
if [ ! -f "angular.json" ]; then
  echo "❌ Erreur : angular.json introuvable !"
  exit 1
fi

echo "📦 Commit des modifications..."
git add .
git commit -m "Fix: correction base-href pour GitHub Pages" || echo "Rien à commiter"

echo "🔗 Push sur GitHub..."
git push origin main

echo "🏗️ Build avec le bon base-href..."
ng build --configuration production --base-href=/$GITHUB_REPO/

echo "🚀 Déploiement sur GitHub Pages..."
npx angular-cli-ghpages --dir=dist/lambarahost --repo=https://github.com/$GITHUB_USER/$GITHUB_REPO.git --branch=gh-pages

echo ""
echo "✅ Déploiement terminé !"
echo "👉 Attends 1-2 minutes puis visite :"
echo "   https://$GITHUB_USER.github.io/$GITHUB_REPO/"
