#!/bin/bash

echo "🔧 Correction de la virgule manquante dans mock-data.service.ts..."

# Trouver et corriger la ligne avec notes
sed -i '215s/\(`\)$/\1,/' src/app/services/mock-data.service.ts

echo "✅ mock-data.service.ts ligne 215 corrigée (virgule ajoutée)"
echo ""
echo "🔄 Redémarrez: ng serve"
