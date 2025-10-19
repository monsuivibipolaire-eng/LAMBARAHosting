#!/bin/bash
set -e

echo "🔧 Suppression des fichiers de sauvegarde et inutiles..."

# 1. Supprimer tous les fichiers *.bak et *.bak_* dans src/app
find src/app -type f \( -name '*.bak' -o -name '*.bak_*' \) -delete
echo "✅ Tous les fichiers *.bak* dans src/app supprimés"

# 2. Supprimer backups i18n
find src/assets/i18n -type f -name '*.bak_*' -delete
echo "✅ Backups i18n supprimés"

# 3. Supprimer fichiers temporaires et duplicats éventuels (*.orig, *~)
find src -type f \( -name '*.orig' -o -name '*~' \) -delete
echo "✅ Fichiers temporaires supprimés"

# 4. Supprimer anciens scripts de seed/mock non utilisés
find src/app/services -type f -name 'mock-data*.js' -delete
echo "✅ Anciens scripts mock supprimés"

# 5. Supprimer modules vides ou dossiers de tests si non utilisés (*.spec.ts)
find src/app -type f -name '*.spec.ts' -delete
echo "✅ Fichiers de test supprimés (*.spec.ts)"

# 6. Supprimer caches et dossiers node_modules éventuels dans src
find src -type d -name 'node_modules' -prune -exec rm -rf {} +
echo "✅ Dossiers node_modules dans src supprimés"

echo ""
echo "🎉 Nettoyage effectué! Votre arborescence src est maintenant débarrassée des fichiers inutiles."
