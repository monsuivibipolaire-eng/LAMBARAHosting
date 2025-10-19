#!/bin/bash
set -e

echo "🔧 Correction montantTotal → montant dans salaires-list.component.ts..."

TS_FILE="src/app/salaires/salaires-list.component.ts"
cp "$TS_FILE" "${TS_FILE}.bak_$(date +%Y%m%d_%H%M%S)"

# 1. Remplacer f.montantTotal par f.montant (dans reduce)
sed -i '' 's/f\.montantTotal/f.montant/g' "$TS_FILE"

# 2. Remplacer f?.montantTotal par f?.montant
sed -i '' 's/f?\.montantTotal/f?.montant/g' "$TS_FILE"

# 3. Remplacer ${f.montantTotal par ${f.montant (dans template strings)
sed -i '' 's/\${f\.montantTotal/\${f.montant/g' "$TS_FILE"

echo "✅ Toutes les occurrences de montantTotal remplacées par montant"
echo "➡️ Recompilez: ng serve"
