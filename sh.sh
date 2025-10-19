#!/bin/bash

echo "🔧 Correction des erreurs TS2304 et TS2339 dans salaires-list.component.ts..."

FILE="src/app/salaires/salaires-list.component.ts"

# 1. Sauvegarde
cp "$FILE" "${FILE}.bak_$(date +%Y%m%d_%H%M%S)"
echo "📝 Sauvegarde créée"

# 2. Remplacer Facture par FactureVente
perl -i -pe 's/\bFacture\b/FactureVente/g' "$FILE"
echo "✅ Remplacement de 'Facture' par 'FactureVente'"

# 3. Corriger le cast allFactures as Facture[] → as FactureVente[]
perl -i -pe 's/allFactures as Facture\[\]/allFactures as FactureVente[]/' "$FILE"
echo "✅ Correction du cast allFactures"

# 4. Remplacer dateFacture par dateVente
perl -i -pe 's/f\.dateFacture/f.dateVente/g' "$FILE"
echo "✅ Remplacement de 'dateFacture' par 'dateVente'"

# 5. Retirer l'import de Facture (ancien modèle)
sed -i.bak "/import { Facture } from '..\/models\/facture.model';/d" "$FILE"
echo "✅ Suppression de l'import de Facture"

# 6. Ajouter import de FactureVente s'il manque
grep -q "import { FactureVente } from '../models/facture-vente.model';" "$FILE" || \
perl -i -pe "s|(import .*facture-vente.service.*;)|\1\nimport { FactureVente } from '../models/facture-vente.model';|" "$FILE"
echo "✅ Ajout de l'import de FactureVente si nécessaire"

echo ""
echo "🎉 Corrections appliquées avec succès !"
echo "➡️ Recompilez votre application."
