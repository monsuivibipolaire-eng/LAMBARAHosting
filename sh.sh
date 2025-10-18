#!/bin/bash

# ===================================================================================
# SCRIPT POUR AJOUTER UN BOUTON "PRÉCÉDENT" AU FORMULAIRE DES SORTIES
# -----------------------------------------------------------------------------------
# Ce script modifie les fichiers du SortieFormComponent pour y ajouter
# un bouton "Précédent" dans l'en-tête du formulaire.
# ===================================================================================

echo "🚀 Ajout du bouton 'Précédent' au formulaire des sorties..."

TS_PATH="./src/app/sorties/sortie-form.component.ts"
HTML_PATH="./src/app/sorties/sortie-form.component.html"
SCSS_PATH="./src/app/sorties/sortie-form.component.scss"

# --- 1. Mettre à jour le fichier TypeScript (.ts) pour ajouter la fonction goBack() ---
if [ -f "$TS_PATH" ]; then
  echo "Mise à jour de $TS_PATH..."
cat > "$TS_PATH" << 'EOF'
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { SelectedBoatService } from '../services/selected-boat.service';
import { SortieService } from '../services/sortie.service';
import { AlertService } from '../services/alert.service';
import { Bateau } from '../models/bateau.model';

@Component({
  standalone: false,
  selector: 'app-sortie-form',
  templateUrl: './sortie-form.component.html',
  styleUrls: ['./sortie-form.component.scss']
})
export class SortieFormComponent implements OnInit {
  form!: FormGroup;
  isEditMode = false;
  id?: string;
  loading = false;
  selectedBoat: Bateau | null = null;

  constructor(
    private fb: FormBuilder,
    private sortieService: SortieService,
    private alertService: AlertService,
    private route: ActivatedRoute,
    private router: Router,
    private selectedBoatService: SelectedBoatService
  ) {}

  ngOnInit(): void {
    this.id = this.route.snapshot.paramMap.get('id') ?? undefined;
    this.isEditMode = !!this.id;
    
    this.selectedBoat = this.selectedBoatService.getSelectedBoat();
    if (!this.selectedBoat && !this.isEditMode) {
      this.alertService.error('Veuillez d\'abord sélectionner un bateau');
      this.router.navigate(['/dashboard/bateaux']);
      return;
    }
    
    this.form = this.fb.group({
      bateauId: [this.selectedBoat?.id || '', Validators.required],
      destination: ['', Validators.required],
      dateDepart: ['', Validators.required],
      dateRetour: ['', Validators.required],
      statut: ['en-cours', Validators.required],
      observations: ['']
    });

    this.form.get('bateauId')?.disable();

    if (this.isEditMode) {
      this.loadSortie();
    }
  }

  loadSortie(): void {
    this.sortieService.getSortie(this.id!).subscribe(sortie => {
      this.form.patchValue({
        ...sortie,
        dateDepart: this.formatDate(sortie.dateDepart),
        dateRetour: this.formatDate(sortie.dateRetour)
      });
    });
  }

  formatDate(date: any): string {
    if (date?.toDate) {
      return date.toDate().toISOString().split('T')[0];
    }
    if (date instanceof Date) {
      return date.toISOString().split('T')[0];
    }
    return '';
  }

  async onSubmit(): Promise<void> {
    if (this.form.valid) {
      this.loading = true;
      this.alertService.loading('Enregistrement en cours...');

      const data = {
        ...this.form.getRawValue(),
        dateDepart: new Date(this.form.value.dateDepart),
        dateRetour: new Date(this.form.value.dateRetour)
      };

      try {
        if (this.isEditMode) {
          await this.sortieService.updateSortie(this.id!, data);
          this.alertService.close();
          await this.alertService.success('La sortie a été modifiée avec succès', 'Modification réussie!');
        } else {
          await this.sortieService.addSortie(data);
          this.alertService.close();
          await this.alertService.success('La sortie a été ajoutée avec succès', 'Ajout réussi!');
        }
        this.router.navigate(['/dashboard/sorties']);
      } catch (error) {
        this.alertService.close();
        this.alertService.error('Erreur lors de l\'enregistrement');
      } finally {
        this.loading = false;
      }
    } else {
      this.markFormGroupTouched(this.form);
      this.alertService.warning('Veuillez remplir tous les champs requis', 'Formulaire incomplet');
    }
  }

  markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      formGroup.get(key)?.markAsTouched();
    });
  }

  cancel(): void {
    this.router.navigate(['/dashboard/sorties']);
  }

  // ✅ MÉTHODE POUR LE BOUTON "PRÉCÉDENT"
  goBack(): void {
    this.cancel();
  }
}
EOF
else
  echo "❌ Erreur : Le fichier $TS_PATH n'a pas été trouvé."
fi

# --- 2. Mettre à jour le fichier HTML ---
if [ -f "$HTML_PATH" ]; then
  echo "Mise à jour de $HTML_PATH..."
cat > "$HTML_PATH" << 'EOF'
<div class="form-container">
  <div class="form-header">
    <button class="btn-back" (click)="goBack()">
      <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
      </svg>
      {{ 'SAILORS.BACK' | translate }}
    </button>
    <h1 class="form-title">{{ (isEditMode ? 'SORTIES.EDIT' : 'SORTIES.ADD') | translate }}</h1>
  </div>

  <div class="selected-boat-info" *ngIf="selectedBoat">
    <div class="boat-badge">
      <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
      </svg>
      <span>{{ 'BOATS.BOAT' | translate }}: <strong>{{ selectedBoat.nom }}</strong> ({{ selectedBoat.immatriculation }})</span>
    </div>
  </div>

  <form [formGroup]="form" (ngSubmit)="onSubmit()" class="form">
    <div class="form-grid">
      
      <div class="form-group">
        <label class="form-label">{{ 'SORTIES.DESTINATION' | translate }} *</label>
        <input 
          type="text" 
          formControlName="destination" 
          class="form-input"
          [class.error]="form.get('destination')?.invalid && form.get('destination')?.touched">
        <span class="error-message" *ngIf="form.get('destination')?.hasError('required') && form.get('destination')?.touched">
          {{ 'FORM.REQUIRED' | translate }}
        </span>
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SORTIES.DATEDEPART' | translate }} *</label>
        <input 
          type="date" 
          formControlName="dateDepart" 
          class="form-input"
          [class.error]="form.get('dateDepart')?.invalid && form.get('dateDepart')?.touched">
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SORTIES.DATERETOUR' | translate }} *</label>
        <input 
          type="date" 
          formControlName="dateRetour" 
          class="form-input"
          [class.error]="form.get('dateRetour')?.invalid && form.get('dateRetour')?.touched">
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SORTIES.STATUT' | translate }} *</label>
        <select formControlName="statut" class="form-input">
          <option value="en-cours">{{ 'SORTIES.STATUS.ONGOING' | translate }}</option>
          <option value="terminee">{{ 'SORTIES.STATUS.COMPLETED' | translate }}</option>
          <option value="annulee">{{ 'SORTIES.STATUS.CANCELLED' | translate }}</option>
        </select>
      </div>

      <div class="form-group full-width">
        <label class="form-label">{{ 'SORTIES.OBSERVATIONS' | translate }}</label>
        <textarea formControlName="observations" class="form-input" rows="3"></textarea>
      </div>

    </div>

    <div class="form-actions">
      <button type="button" (click)="cancel()" class="btn btn-secondary" [disabled]="loading">
        {{ 'FORM.CANCEL' | translate }}
      </button>
      <button type="submit" class="btn btn-primary" [disabled]="loading">
        <span *ngIf="loading">{{ 'MESSAGES.SAVING' | translate }}...</span>
        <span *ngIf="!loading">{{ (isEditMode ? 'FORM.EDIT' : 'FORM.ADD') | translate }}</span>
      </button>
    </div>
  </form>
</div>
EOF
else
    echo "❌ Erreur : Le fichier $HTML_PATH n'a pas été trouvé."
fi

# --- 3. Mettre à jour le fichier SCSS ---
if [ -f "$SCSS_PATH" ]; then
    echo "Mise à jour de $SCSS_PATH..."
cat > "$SCSS_PATH" << 'EOF'
.form-container {
  max-width: 900px;
  width: 100%;
  background: white;
  border-radius: 0.75rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  padding: 2rem;
  margin: 0 auto;
}

.form-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 2rem;
  border-bottom: 2px solid #e5e7eb;
  padding-bottom: 1rem;

  .form-title {
    flex-grow: 1;
    font-size: 1.75rem;
    font-weight: 700;
    color: #1f2937;
    margin: 0;
    text-align: center;
    margin-right: -120px;
  }
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.form-group {
  display: flex;
  flex-direction: column;

  &.full-width {
    grid-column: 1 / -1;
  }
}

.form-label {
  font-weight: 600;
  color: #374151;
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
}

.form-input {
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 0.5rem;
  font-size: 1rem;
  transition: all 0.2s;
  width: 100%;
  &:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
  }

  &.error {
    border-color: #ef4444;
  }
}

textarea.form-input {
  resize: vertical;
  min-height: 80px;
}

.error-message {
  color: #ef4444;
  font-size: 0.75rem;
  margin-top: 0.25rem;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e5e7eb;
  flex-wrap: wrap;
}

.btn {
  padding: 0.75rem 2rem;
  border: none;
  border-radius: 0.5rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  white-space: nowrap;

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
}

.btn-primary {
  background-color: #3b82f6;
  color: white;

  &:hover:not(:disabled) {
    background-color: #2563eb;
    transform: translateY(-2px);
    box-shadow: 0 4px 6px rgba(59, 130, 246, 0.3);
  }
}

.btn-secondary {
  background-color: #6b7280;
  color: white;

  &:hover:not(:disabled) {
    background-color: #4b5563;
  }
}

@media (max-width: 768px) {
  .form-header .form-title {
    font-size: 1.5rem;
    margin-right: 0;
  }
  .form-container { padding: 1.5rem; }
  .form-grid { grid-template-columns: 1fr; gap: 1rem; }
  .form-actions { flex-direction: column-reverse; gap: 0.75rem; }
  .btn { width: 100%; justify-content: center; }
}

.selected-boat-info {
  margin-bottom: 2rem;
  
  .boat-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.75rem;
    background: #d1fae5;
    color: #065f46;
    padding: 1rem 1.5rem;
    border-radius: 0.75rem;
    border: 2px solid #10b981;
    font-size: 1rem;
    svg {
      width: 24px;
      height: 24px;
      flex-shrink: 0;
    }

    strong {
      font-weight: 700;
      color: #047857;
    }
  }
}
EOF
else
    echo "❌ Erreur : Le fichier $SCSS_PATH n'a pas été trouvé."
fi

echo "✅ Script terminé. Le bouton a été ajouté au formulaire des sorties."