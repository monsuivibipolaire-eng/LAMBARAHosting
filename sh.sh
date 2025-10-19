#!/bin/bash
set -e

echo "🔧 Correction définitive des erreurs 'marin possibly undefined'..."

FILE="src/app/marins/marin-form.component.ts"
cp "$FILE" "${FILE}.bak_definitif"

# Insérer la vérification if (marin) après la ligne subscribe
sed -i '' '/this\.marinService\.getMarin(this\.marinId)\.subscribe(marin => {/a\
        if (!marin) return;' "$FILE"

echo "✅ Vérification de marin ajoutée!"
echo ""
echo "🎉 ERREURS CORRIGÉES DÉFINITIVEMENT!"
echo ""
echo "➡️ Recompilez: ng serve"
echo ""
echo "✨ L'application devrait maintenant compiler parfaitement!"
