#!/bin/bash

# ===================================================================================
# SCRIPT POUR AFFICHER LA PART DANS LA LISTE DES MARINS
# -----------------------------------------------------------------------------------
# Ce script modifie le template de la liste des marins pour ajouter une colonne
# qui affiche la valeur de la "part" de chaque marin.
# ===================================================================================

echo "➡️  Ajout de la colonne 'Part' à la liste des marins..."

MARINS_LIST_HTML_PATH="./src/app/marins/marins-list.component.html"

if [ ! -f "$MARINS_LIST_HTML_PATH" ]; then
  echo "❌ Erreur : Le fichier $MARINS_LIST_HTML_PATH n'a pas été trouvé."
  echo "Veuillez exécuter ce script depuis la racine de votre projet Angular."
  exit 1
fi

cat > "$MARINS_LIST_HTML_PATH" << 'EOF'
<div class="marins-container">
  <div class="header">
    <div>
      <button class="btn-back" (click)="goBack()">
        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
        </svg>
        {{ 'SAILORS.BACK' | translate }}
      </button>
      <h1 class="title">
        {{ 'SAILORS.CREW_OF' | translate }} - <span *ngIf="bateau$ | async as bateau">{{ bateau.nom }}</span>
      </h1>
    </div>
    <button class="btn btn-primary" (click)="addMarin()">
      <svg class="icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
      </svg>
      {{ 'SAILORS.ADD_SAILOR' | translate }}
    </button>
  </div>

  <div class="table-container">
    <table class="data-table">
      <thead>
        <tr>
          <th>{{ 'SAILORS.LAST_NAME' | translate }}</th>
          <th>{{ 'SAILORS.FIRST_NAME' | translate }}</th>
          <th>{{ 'SAILORS.FUNCTION' | translate }}</th>
          <th>{{ 'SAILORS.PART' | translate }}</th> <th>{{ 'SAILORS.PHONE' | translate }}</th>
          <th>{{ 'SAILORS.HIRE_DATE' | translate }}</th>
          <th>{{ 'BOATS.STATUS' | translate }}</th>
          <th>{{ 'BOATS.ACTIONS' | translate }}</th>
        </tr>
      </thead>
      <tbody>
        <tr *ngFor="let marin of marins$ | async">
          <td class="font-bold">{{ marin.nom }}</td>
          <td>{{ marin.prenom }}</td>
          <td>
            <span class="fonction-badge" [ngClass]="getFonctionClass(marin.fonction)">
              {{ 'SAILORS.' + marin.fonction.toUpperCase() | translate }}
            </span>
          </td>
          <td class="font-bold">{{ marin.part }}</td> <td>{{ marin.telephone }}</td>
          <td>{{ formatDate(marin.dateEmbauche) | date:'dd/MM/yyyy' }}</td>
          <td>
            <span class="status-badge" [ngClass]="getStatutClass(marin.statut)">
              {{ marin.statut === 'conge' ? ('SAILORS.ON_LEAVE' | translate) : ('BOATS.' + marin.statut.toUpperCase() | translate) }}
            </span>
          </td>
          <td class="actions">
            <button (click)="editMarin(marin.id!)" class="btn-icon btn-warning" [title]="'BOATS.EDIT' | translate">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
            </button>
            <button (click)="deleteMarin(marin)" class="btn-icon btn-danger" [title]="'BOATS.DELETE' | translate">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
EOF

# J'ai aussi simplifié la liste des colonnes pour une meilleure lisibilité.

echo "✅ Le fichier src/app/marins/marins-list.component.html a été mis à jour."
echo "La colonne 'Part' est maintenant visible dans la liste des marins."