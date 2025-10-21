#!/bin/bash

# ==============================================================================
#  Script de correction finale pour l'affichage de l'écran des avances.
#  Force le composant à appeler la bonne fonction pour n'afficher que les
#  avances non réglées.
# ==============================================================================

# Chemin du fichier à modifier
AVANCES_COMP="src/app/avances/avances.component.ts"
BACKUP_PATH="${AVANCES_COMP}.bak_final_avances_fix"

# Vérifier si le fichier cible existe
if [ ! -f "$AVANCES_COMP" ]; then
  echo "❌ Erreur : Le fichier $AVANCES_COMP n'a pas été trouvé."
  echo "Veuillez exécuter ce script depuis la racine de votre projet Angular."
  exit 1
fi

echo "💾 Création d'une sauvegarde de votre fichier original : $BACKUP_PATH"
cp "$AVANCES_COMP" "$BACKUP_PATH"

echo "🔧 Correction de l'appel de service dans '$AVANCES_COMP'..."
echo "Remplacement de 'getAvancesByBateau' par 'getUnsettledAvancesByBateau'..."

# Commande sed pour remplacer l'appel de l'ancienne fonction par la nouvelle
sed -i'' "s/this.avanceService.getAvancesByBateau(this.selectedBoat.id!)/this.avanceService.getUnsettledAvancesByBateau(this.selectedBoat.id!)/" "$AVANCES_COMP"

# Vérification
if grep -q "getUnsettledAvancesByBateau" "$AVANCES_COMP"; then
    echo "✅ Correction appliquée avec succès !"
    echo "L'écran 'Avances' est maintenant correctement configuré."
    rm -f "$BACKUP_PATH"
else
    echo "❌ Échec de l'application du correctif. Le fichier n'a pas été modifié."
    echo "Restauration du fichier original depuis le backup."
    mv "$BACKUP_PATH" "$AVANCES_COMP"
    exit 1
fi

echo "👍 Terminé. Veuillez relancer votre application."