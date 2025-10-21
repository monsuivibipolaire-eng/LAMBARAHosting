#!/bin/bash

# ==============================================================================
#  Script de correction pour le bug d'enregistrement des paiements
#  Projet: Angular - Lambara
# ==============================================================================

# Définir le chemin du fichier à corriger
FILE_PATH="src/app/salaires/salaires-list.component.ts"

# Vérifier si le fichier cible existe
if [ ! -f "$FILE_PATH" ]; then
  echo "❌ Erreur : Le fichier $FILE_PATH n'a pas été trouvé."
  echo "Veuillez exécuter ce script depuis la racine de votre projet Angular."
  exit 1
fi

echo "🔧 Application du correctif pour le bug de paiement dans $FILE_PATH..."

# --- Étape 1: Capturer la référence du document retournée par Firestore ---
# On modifie la ligne qui sauvegarde le calcul pour stocker la référence (docRef)
# qui contient l'ID du nouveau document.
#
# Ligne originale : await this.salaireService.saveCalculSalaire(calculData);
# Ligne corrigée : const docRef = await this.salaireService.saveCalculSalaire(calculData);
#
sed -i.bak 's/await this.salaireService.saveCalculSalaire(calculData);/const docRef = await this.salaireService.saveCalculSalaire(calculData);/' "$FILE_PATH"

# --- Étape 2: Assigner le nouvel objet avec l'ID à la variable 'dernierCalcul' ---
# On modifie la ligne qui affecte l'objet à la variable locale pour y inclure
# l'ID que nous venons de récupérer.
#
# Ligne originale : this.dernierCalcul = calculData as CalculSalaire;
# Ligne corrigée : this.dernierCalcul = { ...calculData, id: docRef.id } as CalculSalaire;
#
sed -i.bak2 's/this.dernierCalcul = calculData as CalculSalaire;/this.dernierCalcul = { ...calculData, id: docRef.id } as CalculSalaire;/' "$FILE_PATH"

# Vérifier si les modifications ont réussi (vérification simple)
if grep -q "const docRef = await" "$FILE_PATH" && grep -q "id: docRef.id" "$FILE_PATH"; then
  echo "✅ Correction appliquée avec succès !"
  echo "Le composant va maintenant correctement sauvegarder l'ID du calcul,"
  echo "ce qui permettra aux paiements d'être enregistrés correctement."
else
  echo "❌ Échec de l'application du correctif. Veuillez vérifier le fichier manuellement."
  # Restaurer les backups en cas d'échec partiel
  mv "${FILE_PATH}.bak" "$FILE_PATH"
  rm -f "${FILE_PATH}.bak2"
  exit 1
fi

# Nettoyer les fichiers de sauvegarde créés par sed
rm -f "${FILE_PATH}.bak"
rm -f "${FILE_PATH}.bak2"

echo "👍 Terminé."