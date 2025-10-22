#!/bin/bash

# Ce script supprime les fichiers de backup (.bak et .bak_*)
# dans le dossier 'src' et ses sous-dossiers.

# Le dossier cible est 'src' (là où se trouve votre arborescence)
TARGET_DIR="src"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Erreur : Le dossier '$TARGET_DIR' n'existe pas."
    echo "Veuillez lancer ce script depuis le dossier parent de 'src'."
    exit 1
fi

echo "Recherche des fichiers de backup dans '$TARGET_DIR'..."
echo "-------------------------------------------------"

# Lister les fichiers qui seront supprimés pour vérification
# Nous cherchons les fichiers (-type f) dont le nom (-name)
# se termine par .bak OU (-o) par .bak_*
find "$TARGET_DIR" -type f \( -name "*.bak" -o -name "*.bak_*" \) -print

echo "-------------------------------------------------"
echo

# Demander confirmation à l'utilisateur
read -p "Voulez-vous vraiment supprimer tous les fichiers listés ci-dessus ? (o/N) " confirm

if [[ "$confirm" == "o" || "$confirm" == "O" ]]; then
    echo "Suppression en cours..."
    # Exécuter la suppression
    find "$TARGET_DIR" -type f \( -name "*.bak" -o -name "*.bak_*" \) -delete
    echo "Les fichiers de backup ont été supprimés."
else
    echo "Suppression annulée."
fi

exit 0
