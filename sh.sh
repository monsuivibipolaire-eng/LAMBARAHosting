#!/bin/bash

echo "🔧 Correction des erreurs TS2304 et TS2339 dans salaires-list.component.ts..."

FILE="src/app/salaires/salaires-list.component.ts"

# 1. Sauvegarde
cp "$FILE" "${FILE}.bak_$(date +%Y%m%d_%H%M%S)"
echo "📝 Sauvegarde créée : ${FILE}.bak_$(date +%Y%m%d_%H%M%S)"

# 2. Remplacer Facture par FactureVente partout
perl -i -pe 's/\bFacture\b/FactureVente/g' "$FILE"
echo "✅ Remplacement de 'Facture' par 'FactureVente'"

# 3. Corriger le cast allFactures as Facture[] → as FactureVente[]
perl -i -pe 's/allFactures as Facture\[\]/allFactures as FactureVente[]/' "$FILE"
echo "✅ Correction du cast allFactures"

# 4. Remplacer dateFacture par dateVente
perl -i -pe 's/f\.dateFacture/f.dateVente/g' "$FILE"
echo "✅ Remplacement de 'dateFacture' par 'dateVente'"

# 5. Vérifier les imports : importer FactureVente et retirer Facture
perl -i -pe '
  # ajouter import FactureVente si manquant
  unless (/FactureVente.*from.*facture-vente.model/) {
    s|(import .*facture-model.*;)|$1\nimport { FactureVente } from "..\/models\/facture-vente.model";|
  }
  # retirer import { Facture } from '../models/facture.model';
  s|import \{ Facture \} from ..\/models\/facture.model';||;
' "$FILE"
echo "✅ Imports mis à jour"

# 6. Retirer toute référence à dateFacture dans les templates
perl -i -pe 's/\$\{this\.formatDate\(f\.dateFacture\)\}/\$\{this.formatDate(f.dateVente)\}/g' "$FILE"
echo "✅ Templates mis à jour"

echo ""
echo "🎉 Corrections appliquées avec succès !"
echo "➡️  Recompilez votre application pour vérifier."
