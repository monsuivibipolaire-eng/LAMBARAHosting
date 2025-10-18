#!/bin/bash

# Script pour corriger le problème de routage du module des marins dans le projet Angular.

# Le problème : Le BateauxModule ne sait pas comment charger le MarinsModule.
# La solution : Ajouter une route enfant au BateauxModule pour charger
# paresseusement (lazy load) le MarinsModule lorsque l'URL correspond à ':bateauId/marins'.

BATEAUX_MODULE_PATH="./src/app/bateaux/bateaux.module.ts"

# Vérifier si le fichier existe avant de le modifier
if [ ! -f "$BATEAUX_MODULE_PATH" ]; then
  echo "❌ Erreur : Le fichier $BATEAUX_MODULE_PATH n'a pas été trouvé."
  echo "Veuillez exécuter ce script depuis la racine de votre projet Angular."
  exit 1
fi

echo "🔧 Application du correctif de routage pour les marins..."

# Remplacer le contenu du fichier bateaux.module.ts avec la version corrigée
cat > "$BATEAUX_MODULE_PATH" << 'EOF'
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { RouterModule, Routes } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';

import { BateauxListComponent } from './bateaux-list.component';
import { BateauFormComponent } from './bateau-form.component';

const routes: Routes = [
  { path: '', component: BateauxListComponent },
  { path: 'add', component: BateauFormComponent },
  { path: 'edit/:id', component: BateauFormComponent },
  // ✅ CORRECTION : Ajout de la route pour charger le module des marins
  { 
    path: ':bateauId/marins', 
    loadChildren: () => import('../marins/marins.module').then(m => m.MarinsModule) 
  }
];

@NgModule({
  declarations: [
    BateauxListComponent,
    BateauFormComponent
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    RouterModule.forChild(routes),
    TranslateModule
  ]
})
export class BateauxModule { }
EOF

echo "✅ Le fichier $BATEAUX_MODULE_PATH a été mis à jour avec succès."
echo "Le problème de routage des marins devrait être résolu."