#!/bin/bash

# Script pour supprimer tous les fichiers inutilisés (backups, temporaires, fixes) dans src/

BASE_DIR="src/app"

echo "🔍 Suppression des fichiers inutiles dans $BASE_DIR..."

# Extensions et motifs à supprimer
PATTERNS=(
  "*.bak"
  "*.bak_*"
  "*.bak.*"
  "*.tmp"
  "*.fix*"
  "*.backup"
  "*.backup_*"
  "*~"
)

# Supprimer les fichiers correspondants aux motifs
for pattern in "${PATTERNS[@]}"; do
  echo "🗑️  Suppression des fichiers $pattern"
  find "$BASE_DIR" -type f -name "$pattern" -print -exec rm -f {} +
done

# Supprimer également les dossiers vides résultants
echo "🧹 Suppression des dossiers vides"
find "$BASE_DIR" -type d -empty -print -delete

echo ""
echo "✅ Tous les fichiers inutiles ont été supprimés."
