#!/bin/bash

echo "=== DIAGNOSTIC DES FACTURES ==="
echo ""

echo "1️⃣ Vérification du service FactureService..."
if grep -q "private collectionName = 'factures'" src/app/services/facture.service.ts; then
    echo "✅ Collection 'factures' trouvée"
else
    echo "❌ Collection 'factures' non trouvée"
fi

echo ""
echo "2️⃣ Vérification du MockDataService..."
if grep -q "await this.factureService.addFacture(facture)" src/app/services/mock-data.service.ts; then
    echo "✅ Appel addFacture trouvé"
else
    echo "❌ Appel addFacture non trouvé"
fi

echo ""
echo "3️⃣ Vérification de l'interface Facture..."
if grep -q "export interface Facture" src/app/models/facture.model.ts; then
    echo "✅ Interface Facture trouvée"
else
    echo "❌ Interface Facture non trouvée"
fi

echo ""
echo "4️⃣ Vérification de l'interface DetailPoisson..."
if grep -q "export interface DetailPoisson" src/app/models/facture.model.ts; then
    echo "✅ Interface DetailPoisson trouvée"
else
    echo "❌ Interface DetailPoisson non trouvée"
fi

