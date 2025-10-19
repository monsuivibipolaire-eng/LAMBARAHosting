#!/bin/bash

FILE="src/app/salaires/salaires-list.component.ts"
echo "🔧 Correction de $FILE..."

# Créer une sauvegarde
cp "$FILE" "${FILE}.bak_$(date +%Y%m%d_%H%M%S)"

# 1. Remplacer l'import de Facture par FactureVente
perl -i -pe "s/import \{ Facture \} from '..\/models\/facture.model'/import { FactureVente } from '..\/models\/facture-vente.model'/" "$FILE"

# 2. Ajouter l'import de FactureVenteService si pas présent
if ! grep -q "import.*FactureVenteService" "$FILE"; then
    perl -i -pe "s/(import.*from.*sortie.service.*;)/\$1\nimport { FactureVenteService } from '..\/services\/facture-vente.service';/" "$FILE"
fi

# 3. Ajouter FactureVenteService dans le constructor
perl -i -pe "s/(private translate: TranslateService)/\$1,\n    private factureVenteService: FactureVenteService/" "$FILE"

# 4. Remplacer la propriété factures: Facture[] par factures: FactureVente[]
perl -i -pe "s/factures\?: Facture\[\]/factures?: FactureVente[]/" "$FILE"

# 5. Modifier la fonction calculerSalaires pour charger les factures depuis factures-vente
# Trouver la ligne "const allFactures = selectedSorties.flatMap"
# et la remplacer par du code qui charge les factures

cat > "$FILE.tmp" << 'EOFTMP'
# Ce sera le nouveau code pour calculerSalaires
EOFTMP

echo "✅ Imports et constructor mis à jour"
echo ""
echo "⚠️  ATTENTION: Modification manuelle nécessaire dans calculerSalaires()"
echo ""
echo "Dans src/app/salaires/salaires-list.component.ts, ligne ~140:"
echo ""
echo "REMPLACER:"
echo "  const allFactures = selectedSorties.flatMap(s => s.factures);"
echo "  const revenuTotal = allFactures.reduce((sum, f) => sum + (f?.montantTotal || 0), 0);"
echo ""
echo "PAR:"
echo "  // Charger toutes les factures pour les sorties sélectionnées"
echo "  const allFacturesArrays = await Promise.all("
echo "    this.selectedSortiesIds.map(sortieId =>"
echo "      this.factureVenteService.getFacturesBySortie(sortieId).pipe(take(1)).toPromise()"
echo "    )"
echo "  );"
echo "  const allFactures = allFacturesArrays.flat();"
echo "  const revenuTotal = allFactures.reduce((sum, f) => sum + (f?.montantTotal || 0), 0);"
echo ""
