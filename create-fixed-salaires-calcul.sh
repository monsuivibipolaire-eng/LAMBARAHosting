#!/bin/bash

FILE="src/app/salaires/salaires-list.component.ts"
echo "🔧 Correction complète du calcul des revenus..."

# Sauvegarde
cp "$FILE" "${FILE}.bak_$(date +%Y%m%d_%H%M%S)"

# Ajouter l'import FactureVente si manquant
if ! grep -q "import.*FactureVente.*from.*facture-vente.model" "$FILE"; then
    perl -i -pe "s/(import.*Facture.*from.*facture.model.*)/import { FactureVente } from '..\/models\/facture-vente.model';/" "$FILE"
fi

# Ajouter l'import FactureVenteService
if ! grep -q "import.*FactureVenteService" "$FILE"; then
    perl -i -pe "s/(import.*SortieService.*)/\$1\nimport { FactureVenteService } from '..\/services\/facture-vente.service';/" "$FILE"
fi

# Ajouter le service dans le constructor
if ! grep -q "factureVenteService: FactureVenteService" "$FILE"; then
    perl -i -pe "s/(private translate: TranslateService)/private factureVenteService: FactureVenteService,\n    \$1/" "$FILE"
fi

# Modifier la ligne qui calcule les factures dans calculerSalaires
perl -i -pe "s/const allFactures = selectedSorties\.flatMap\(s => s\.factures\);/\/\/ Charger toutes les factures depuis factures-vente\n      const allFacturesArrays = await Promise.all(\n        this.selectedSortiesIds.map(sortieId =>\n          this.factureVenteService.getFacturesBySortie(sortieId).pipe(take(1)).toPromise()\n        )\n      );\n      const allFactures = allFacturesArrays.flat();/" "$FILE"

echo "✅ Fichier corrigé!"
echo ""
echo "📊 Modifications appliquées:"
echo "  1. ✓ Import de FactureVente ajouté"
echo "  2. ✓ Import de FactureVenteService ajouté"  
echo "  3. ✓ FactureVenteService ajouté au constructor"
echo "  4. ✓ Chargement des factures depuis 'factures-vente'"
echo ""
echo "🎯 Recompilez et testez le calcul des salaires!"
