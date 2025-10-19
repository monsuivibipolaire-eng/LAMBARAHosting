#!/bin/bash
set -e

echo "🔧 Restauration complète de salaires-list.component.html depuis backup..."

HTML="src/app/salaires/salaires-list.component.html"

# Trouver le dernier backup valide AVANT les modifications destructives
BACKUPS=$(ls -t "${HTML}.bak_"* 2>/dev/null)

if [ -z "$BACKUPS" ]; then
    echo "❌ ERREUR: Aucun fichier de sauvegarde trouvé!"
    echo "Le fichier HTML a été corrompu et il n'y a pas de backup."
    echo "Vous devez restaurer manuellement depuis votre contrôle de version (git)."
    exit 1
fi

# Prendre le backup le plus ancien (avant toutes les corruptions)
OLDEST_BACKUP=$(echo "$BACKUPS" | tail -1)
echo "📦 Restauration depuis: $OLDEST_BACKUP"

cp "$OLDEST_BACKUP" "$HTML"

echo "✅ Fichier HTML restauré!"
echo ""
echo "⚠️  IMPORTANT: Ne plus utiliser de scripts automatiques sur ce fichier."
echo "Pour supprimer le bouton 'Calculer', éditez MANUELLEMENT le fichier:"
echo "   $HTML"
echo ""
echo "Recherchez et supprimez UNIQUEMENT le bloc:"
echo "   <button ...>Calculer...</button>"
echo ""
echo "➡️ Recompilez ensuite votre application."
