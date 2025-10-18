#!/bin/sh
set -e

PROJECT="LAMBARAHost"
GITHUB_USER="monsuivibipolaire-eng"
GITHUB_REPO="$PROJECT"

echo "📦 Publication sur GitHub et déploiement GitHub Pages..."

# 1. S'assurer qu'on est dans le bon dossier
if [ ! -f "angular.json" ]; then
  echo "❌ Erreur : angular.json introuvable. Lance ce script depuis la racine du projet Angular !"
  exit 1
fi

# 2. Vérifier que les modifications sont commitées
echo "💾 Commit des modifications..."
git add .
git commit -m "Update: corrections et améliorations" || echo "⚠️ Rien à commiter"

# 3. Push sur GitHub
echo "🔗 Push sur GitHub..."
git push origin main

# 4. Build de l'application
echo "🏗️ Build de l'application Angular..."
ng build --configuration production

# 5. Déploiement sur GitHub Pages
echo "🚀 Déploiement sur GitHub Pages..."
ng deploy --base-href=/$GITHUB_REPO/

echo ""
echo "✅ Publication terminée !"
echo "👉 Repo GitHub : https://github.com/$GITHUB_USER/$GITHUB_REPO"
echo "👉 Site déployé : https://$GITHUB_USER.github.io/$GITHUB_REPO/"
