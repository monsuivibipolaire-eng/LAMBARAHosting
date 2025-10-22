#!/bin/bash

# Ce script crée le composant AvanceFormComponent, met à jour AvancesComponent
# et ajuste le routage pour utiliser un formulaire pleine page au lieu de SweetAlert.
# Il crée des sauvegardes des fichiers modifiés.

# Variables
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SRC_DIR="src"
AVANCES_DIR="$SRC_DIR/app/avances"
DASHBOARD_DIR="$SRC_DIR/app/dashboard"

# Fonction pour sauvegarder et remplacer/créer un fichier
replace_file() {
  local file_path="$1"
  local new_content_file="$2"
  local backup_path="${file_path}.bak_${TIMESTAMP}"

  # Créer le dossier parent si nécessaire
  mkdir -p "$(dirname "$file_path")"

  if [ -f "$file_path" ]; then
    echo "Sauvegarde de '$file_path' vers '$backup_path'..."
    cp "$file_path" "$backup_path"
    if [ $? -ne 0 ]; then
      echo "Erreur : Échec de la sauvegarde de '$file_path'. Abandon."
      exit 1
    fi

    echo "Remplacement de '$file_path'..."
    cat "$new_content_file" > "$file_path"
    if [ $? -ne 0 ]; then
      echo "Erreur : Échec du remplacement de '$file_path'. Vérifiez '$new_content_file'."
      # Restaurer si possible
      echo "Restauration depuis la sauvegarde..."
      cp "$backup_path" "$file_path"
      exit 1
    fi
    echo "  -> '$file_path' mis à jour."
  else
    echo "Création du fichier '$file_path'..."
    cat "$new_content_file" > "$file_path"
     if [ $? -ne 0 ]; then
      echo "Erreur : Échec de la création de '$file_path'."
      exit 1
    fi
    echo "  -> '$file_path' créé."
  fi
}

# --- Définition du nouveau contenu ---

# 1. Nouveau: src/app/avances/avance-form.component.ts
cat > /tmp/avance-form.component.ts << 'EOF'
import { Component, OnInit } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { AvanceService } from '../services/avance.service';
import { AlertService } from '../services/alert.service';
import { MarinService } from '../services/marin.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { Avance } from '../models/avance.model';
import { Marin } from '../models/marin.model';
import { Bateau } from '../models/bateau.model';
import { Observable } from 'rxjs';
import { take } from 'rxjs/operators';

@Component({
  selector: 'app-avance-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, TranslateModule],
  templateUrl: './avance-form.component.html',
  styleUrls: ['./avance-form.component.scss']
})
export class AvanceFormComponent implements OnInit {
  form!: FormGroup;
  isEditMode = false;
  avanceId?: string;
  selectedBoat: Bateau | null = null;
  marins$: Observable<Marin[]> | undefined;
  loading = false;
  pageTitle = '';

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private avanceService: AvanceService,
    private alertService: AlertService,
    private marinService: MarinService,
    private selectedBoatService: SelectedBoatService,
    private location: Location,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.selectedBoat = this.selectedBoatService.getSelectedBoat();
    if (!this.selectedBoat) {
      this.alertService.error(this.translate.instant('BOATS.NO_BOAT_SELECTED_DETAILS'));
      this.router.navigate(['/dashboard/bateaux']);
      return;
    }

    this.avanceId = this.route.snapshot.paramMap.get('id') ?? undefined;
    this.isEditMode = !!this.avanceId;
    this.pageTitle = this.isEditMode ? 'AVANCES.EDIT' : 'AVANCES.ADD';

    this.initForm();
    this.loadMarins();

    if (this.isEditMode && this.avanceId) {
      this.loadAvanceData();
    }
  }

  private initForm(): void {
    this.form = this.fb.group({
      marinId: ['', Validators.required],
      montant: [null, [Validators.required, Validators.min(0.01)]],
      dateAvance: [this.getTodayDate(), Validators.required],
      description: ['']
    });
  }

  private loadMarins(): void {
    if (this.selectedBoat?.id) {
      this.marins$ = this.marinService.getMarinsByBateau(this.selectedBoat.id);
    }
  }

  private loadAvanceData(): void {
    this.loading = true;
    this.avanceService.getAvance(this.avanceId!).pipe(take(1)).subscribe(avance => {
      if (avance) {
        this.form.patchValue({
          ...avance,
          dateAvance: this.formatDate(avance.dateAvance) // Format date for input
        });
      } else {
        this.alertService.error(this.translate.instant('MESSAGES.ERROR_GENERIC')); // Or a specific not found message
        this.goBack();
      }
      this.loading = false;
    }, error => {
      console.error('Error loading avance:', error);
      this.alertService.error();
      this.loading = false;
      this.goBack();
    });
  }

  getTodayDate(): string {
    return new Date().toISOString().split('T')[0];
  }

  formatDate(date: any): string {
    if (!date) return this.getTodayDate();
    const d = date.toDate ? date.toDate() : new Date(date);
    return d.toISOString().split('T')[0];
  }

  async onSubmit(): Promise<void> {
    if (this.form.invalid) {
        this.markFormGroupTouched(this.form);
        this.alertService.warning(this.translate.instant('FORM.REQUIRED_FIELDS'));
        return;
    }

    if (!this.selectedBoat) {
        this.alertService.error('Erreur: Bateau non sélectionné.'); // Should not happen normally
        return;
    }

    this.loading = true;
    this.alertService.loading(this.translate.instant('MESSAGES.SAVING'));
    const formValue = this.form.value;

    const avanceData: Omit<Avance, 'id'> = {
      bateauId: this.selectedBoat.id!,
      marinId: formValue.marinId,
      montant: formValue.montant,
      dateAvance: new Date(formValue.dateAvance),
      description: formValue.description?.trim() || undefined, // Set undefined if empty
      calculSalaireId: undefined // Ensure it's not set when adding/editing manually
    };

    try {
      if (this.isEditMode && this.avanceId) {
        await this.avanceService.updateAvance(this.avanceId, avanceData);
        this.alertService.success(this.translate.instant('AVANCES.SUCCESS_UPDATE'));
      } else {
        await this.avanceService.addAvance(avanceData);
        this.alertService.success(this.translate.instant('AVANCES.SUCCESS_ADD'));
      }
      this.goBack(); // Navigate back to the list
    } catch (error) {
      console.error('Erreur sauvegarde avance:', error);
      this.alertService.error();
    } finally {
      this.loading = false;
      this.alertService.close(); // Close loading indicator
    }
  }

   markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      formGroup.get(key)?.markAsTouched();
    });
  }


  goBack(): void {
    this.location.back();
  }
}
EOF

# 2. Nouveau: src/app/avances/avance-form.component.html
cat > /tmp/avance-form.component.html << 'EOF'
<div class="form-container">
  <div class="form-header">
    <button class="btn-back" (click)="goBack()">
      <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
      </svg>
      {{ 'SAILORS.BACK' | translate }}
    </button>
    <h1 class="form-title">{{ pageTitle | translate }}</h1>
  </div>

  <form [formGroup]="form" (ngSubmit)="onSubmit()" class="form">
    <div class="form-grid">

      <!-- Champ Marin -->
      <div class="form-group">
        <label class="form-label" for="marinId">{{ 'SAILORS.TITLE' | translate }} *</label>
        <select id="marinId" formControlName="marinId" class="form-input"
                [class.error]="form.get('marinId')?.invalid && form.get('marinId')?.touched">
          <option value="" disabled>{{ 'SAILORS.SELECT_SAILOR' | translate }}</option>
          <option *ngFor="let marin of marins$ | async" [value]="marin.id">
            {{ marin.prenom }} {{ marin.nom }} - {{ 'SAILORS.FUNCTION_TYPE.' + marin.fonction.toUpperCase() | translate }}
          </option>
        </select>
        <span class="error-message" *ngIf="form.get('marinId')?.hasError('required') && form.get('marinId')?.touched">
          {{ 'FORM.REQUIRED' | translate }}
        </span>
      </div>

      <!-- Champ Montant -->
      <div class="form-group">
        <label class="form-label" for="montant">{{ 'COMMON.AMOUNT_D_T' | translate }} *</label>
        <input id="montant" type="number" formControlName="montant" class="form-input"
               placeholder="0.00" step="0.01" min="0" autocomplete="off"
               [class.error]="form.get('montant')?.invalid && form.get('montant')?.touched"/>
        <span class="error-message" *ngIf="form.get('montant')?.hasError('required') && form.get('montant')?.touched">
            {{ 'FORM.REQUIRED' | translate }}
        </span>
         <span class="error-message" *ngIf="form.get('montant')?.hasError('min') && form.get('montant')?.touched">
             {{ 'AVANCES.AMOUNT_POSITIVE' | translate }}
        </span>
        <div class="input-helper">{{ 'COMMON.AMOUNT_IN_TND' | translate }}</div>
      </div>

      <!-- Champ Date -->
      <div class="form-group">
        <label class="form-label" for="dateAvance">{{ 'COMMON.DATE' | translate }} *</label>
        <input id="dateAvance" type="date" formControlName="dateAvance" class="form-input"
               [class.error]="form.get('dateAvance')?.invalid && form.get('dateAvance')?.touched"/>
         <span class="error-message" *ngIf="form.get('dateAvance')?.hasError('required') && form.get('dateAvance')?.touched">
             {{ 'FORM.REQUIRED' | translate }}
        </span>
      </div>

       <!-- Champ Description -->
      <div class="form-group full-width">
        <label class="form-label" for="description">{{ 'COMMON.DESCRIPTION' | translate }}</label>
        <textarea id="description" formControlName="description" class="form-input" rows="3"
                  [placeholder]="'COMMON.DESCRIPTION_OPTIONAL' | translate"></textarea>
      </div>

    </div>

    <div class="form-actions">
      <button type="button" (click)="goBack()" class="btn btn-secondary" [disabled]="loading">
        {{ 'FORM.CANCEL' | translate }}
      </button>
      <button type="submit" class="btn btn-primary" [disabled]="form.invalid || loading">
        {{ loading ? ('MESSAGES.SAVING' | translate) : ((isEditMode ? 'FORM.EDIT' : 'FORM.ADD') | translate) }}
      </button>
    </div>
  </form>
</div>
EOF

# 3. Nouveau: src/app/avances/avance-form.component.scss
cat > /tmp/avance-form.component.scss << 'EOF'
// Utiliser les mêmes styles que marin-form pour la cohérence
// (Copier le contenu de marin-form.component.scss ici)

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
  }
}

.form-grid {
  display: grid;
  // Ajuster pour moins de champs que le formulaire marin
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.form-group {
  display: flex;
  flex-direction: column;
   &.full-width {
    grid-column: 1 / -1; // Permet au textarea de prendre toute la largeur
  }
}

.form-label {
  font-weight: 600;
  color: #374151;
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
}

.form-input, select.form-input, textarea.form-input {
  padding: 0.75rem 1rem; // Padding unifié
  border: 1px solid #d1d5db;
  border-radius: 0.5rem;
  font-size: 1rem;
  transition: all 0.2s;
  width: 100%;
  background-color: #f9fafb; // Léger fond gris
  color: #1f2937;

  &:focus {
    outline: none;
    border-color: #3b82f6; // Bleu au focus
    background-color: #ffffff;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
  }

  &.error {
    border-color: #ef4444; // Rouge si erreur
     &:focus {
         box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1); // Halo rouge léger au focus si erreur
         border-color: #ef4444;
     }
  }

   // Placeholder style
  &::placeholder {
      color: #9ca3af;
      opacity: 1;
  }
}

// Styles spécifiques pour select
select.form-input {
    background-image: url('data:image/svg+xml;charset=UTF-8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" /></svg>');
    background-position: right 0.75rem center; // LTR par défaut
    background-repeat: no-repeat;
    background-size: 1.25em 1.25em;
    padding-right: 2.5rem; // Espace pour la flèche
    appearance: none; // Masquer la flèche par défaut
}
// Flèche select en RTL
:host-context(.rtl) select.form-input {
    background-position: left 0.75rem center;
    padding-right: 1rem; // Reset padding droit
    padding-left: 2.5rem; // Padding gauche pour la flèche
}

// Styles spécifiques pour textarea
textarea.form-input {
  resize: vertical;
  min-height: 90px;
}


.input-helper {
  margin-top: 0.5rem;
  font-size: 0.8rem;
  color: #6b7280;
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
  background-color: #10b981; // Vert (pour correspondre à Ajouter de Swal)
  color: white;

  &:hover:not(:disabled) {
    background-color: #059669; // Vert plus foncé
    transform: translateY(-2px);
    box-shadow: 0 4px 6px rgba(16, 185, 129, 0.3);
  }
}
// Ajustement pour le bouton "Modifier" si besoin (basé sur isEditMode?)
// .btn-primary.edit-mode { ... }

.btn-secondary {
  background-color: #6b7280; // Gris (pour Annuler/Retour)
  color: white;

  &:hover:not(:disabled) {
    background-color: #4b5563;
  }
}

/* RESPONSIVE */
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

/* RTL Support */
:host-context(.rtl) {
    .form-label {
        // text-align: right; // Est hérité, normalement pas nécessaire
    }
    .form-input, select.form-input, textarea.form-input {
        // text-align: right; // Est hérité, normalement pas nécessaire
    }
     .error-message, .input-helper {
         // text-align: right; // Est hérité
     }
    .form-actions {
        justify-content: flex-start; // Aligner les boutons à gauche en RTL
    }
    .btn-back svg {
        transform: scaleX(-1); // Inverser la flèche
    }
}
EOF

# 4. Modifié: src/app/avances/avances.component.ts
cat > /tmp/avances.component.ts << 'EOF'
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router'; // Import Router
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import Swal from 'sweetalert2';
import { AvanceService } from '../services/avance.service';
import { MarinService } from '../services/marin.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { AlertService } from '../services/alert.service';
import { Avance } from '../models/avance.model';
import { Marin } from '../models/marin.model';
import { Bateau } from '../models/bateau.model';
import { combineLatest } from 'rxjs';

@Component({
  selector: 'app-avances',
  standalone: true,
  imports: [CommonModule, TranslateModule, RouterModule],
  templateUrl: './avances.component.html',
  styleUrls: ['./avances.component.scss']
})
export class AvancesComponent implements OnInit {
  selectedBoat: Bateau | null = null;
  marins: Marin[] = [];
  avances: Avance[] = [];
  loading = true;

  constructor(
    private avanceService: AvanceService,
    private marinService: MarinService,
    private selectedBoatService: SelectedBoatService,
    private alertService: AlertService,
    private translate: TranslateService,
    private router: Router // Inject Router for navigation
  ) {}

  ngOnInit(): void {
    this.selectedBoat = this.selectedBoatService.getSelectedBoat();
    if (!this.selectedBoat) {
      this.alertService.error(this.translate.instant('BOATS.NO_BOAT_SELECTED_DETAILS'));
      this.loading = false;
      return;
    }
    this.loadData();
  }

  loadData(): void {
    if (!this.selectedBoat) return;
    this.loading = true;
    combineLatest([
      this.marinService.getMarinsByBateau(this.selectedBoat.id!),
      this.avanceService.getUnsettledAvancesByBateau(this.selectedBoat.id!)
    ]).subscribe(([marins, avances]) => {
      this.marins = marins;
      this.marins.sort((a, b) => a.nom.localeCompare(b.nom));
      this.avances = avances.sort((a, b) => {
        const dateA = a.dateAvance instanceof Date ? a.dateAvance : (a.dateAvance as any)?.toDate();
        const dateB = b.dateAvance instanceof Date ? b.dateAvance : (b.dateAvance as any)?.toDate();
        return (dateB?.getTime() || 0) - (dateA?.getTime() || 0);
      });
      this.loading = false;
    });
  }

  getMarinName(marinId: string): string {
    const marin = this.marins.find(m => m.id === marinId);
    return marin ? `${marin.prenom} ${marin.nom}` : this.translate.instant('COMMON.UNKNOWN');
  }

  getTotalAvances(): number {
    return this.avances.reduce((sum, avance) => sum + avance.montant, 0);
  }

  getAvancesByMarin(marinId: string): Avance[] {
    return this.avances.filter(a => a.marinId === marinId);
  }

  getTotalByMarin(marinId: string): number {
    return this.getAvancesByMarin(marinId).reduce((sum, avance) => sum + avance.montant, 0);
  }

  getTodayDate(): string {
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  formatDate(date: any): string {
    if (date?.toDate) return date.toDate().toISOString().split('T')[0];
    if (date instanceof Date) return date.toISOString().split('T')[0];
    return '';
  }

   formatDisplayDate(date: any): string {
    let dateObj: Date;
    if (date?.toDate) {
      dateObj = date.toDate();
    } else if (date instanceof Date) {
      dateObj = date;
    } else if (typeof date === 'string') {
        dateObj = new Date(date);
    }
     else {
      return '';
    }
    if (isNaN(dateObj.getTime())) {
        return '';
    }
    const day = String(dateObj.getDate()).padStart(2, '0');
    const month = String(dateObj.getMonth() + 1).padStart(2, '0');
    const year = dateObj.getFullYear();
    return `${day}/${month}/${year}`;
  }

  // Navigate to Add Form
  navigateToAddAvance(): void {
    this.router.navigate(['/dashboard/avances/add']);
  }

  // Navigate to Edit Form
  navigateToEditAvance(avanceId: string): void {
     if (!avanceId) return;
    this.router.navigate(['/dashboard/avances/edit', avanceId]);
  }

  // Delete Avance (Confirmation handled by alertService)
  async deleteAvance(avance: Avance): Promise<void> {
    if (!avance || !avance.id) return; // Guard clause

    const marinName = this.getMarinName(avance.marinId);
    const itemName = this.translate.instant('AVANCES.DELETE_CONFIRM_ITEM', { amount: avance.montant, name: marinName });
    const confirmed = await this.alertService.confirmDelete(itemName);

    if (confirmed) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.DELETING'));
        await this.avanceService.deleteAvance(avance.id);
        // Data reloads automatically via Firestore listener, no need to manually remove
        this.alertService.toast(this.translate.instant('AVANCES.SUCCESS_DELETE'));
      } catch (error) {
        console.error('Erreur lors de la suppression:', error);
        this.alertService.error(); // Show generic error message
      } finally {
         this.alertService.close(); // Ensure loading indicator closes
      }
    }
  }
}
EOF

# 5. Modifié: src/app/avances/avances.component.html
cat > /tmp/avances.component.html << 'EOF'
<div class="avances-container">
  <div class="header">
    <h1 class="title">{{ 'AVANCES.TITLE' | translate }}</h1>
    <!-- Modifié: Bouton navigue vers la nouvelle page formulaire -->
    <button *ngIf="!loading && marins.length > 0" class="btn btn-primary" (click)="navigateToAddAvance()">
      <svg class="icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
      </svg>
      {{ 'AVANCES.ADD' | translate }}
    </button>
  </div>

  <!-- Loading -->
  <div *ngIf="loading" class="loading-spinner">
    <div class="spinner"></div>
    <p>{{ 'MESSAGES.LOADING' | translate }}</p>
  </div>

  <!-- Pas de bateau sélectionné -->
  <div *ngIf="!loading && !selectedBoat" class="no-data">
    <svg class="no-data-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
    </svg>
    <p>{{ 'BOATS.NO_BOAT_SELECTED' | translate }}</p>
  </div>

  <!-- Pas de marins -->
  <div *ngIf="!loading && selectedBoat && marins.length === 0" class="no-data">
    <svg class="no-data-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>
    </svg>
    <p>{{ 'POINTAGE.NOCREW' | translate }}</p>
  </div>

  <!-- Liste des avances par marin -->
  <div *ngIf="!loading && selectedBoat && marins.length > 0" class="marins-list">
    <div *ngFor="let marin of marins" class="marin-card">
      <div class="marin-header">
        <div class="marin-info">
          <h3 class="marin-name">{{ marin.prenom }} {{ marin.nom }}</h3>
          <span class="fonction-badge" [ngClass]="'fonction-' + marin.fonction">
            {{ 'SAILORS.FUNCTION_TYPE.' + marin.fonction.toUpperCase() | translate }}
          </span>
        </div>
        <div class="marin-total">
          <span class="total-label">{{ 'AVANCES.TOTAL' | translate }}</span>
          <span class="total-amount">{{ getTotalByMarin(marin.id!) | number:'1.2-2' }} DT</span>
        </div>
      </div>

      <!-- Avances du marin -->
      <div class="avances-list" *ngIf="getAvancesByMarin(marin.id!).length > 0">
        <div *ngFor="let avance of getAvancesByMarin(marin.id!)" class="avance-item">
          <div class="avance-main">
            <div class="avance-details">
              <div class="avance-date-row">
                <svg class="date-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                </svg>
                <span class="avance-date">{{ formatDisplayDate(avance.dateAvance) }}</span>
              </div>
              <div class="avance-description" *ngIf="avance.description">
                <svg class="desc-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"/>
                </svg>
                <span>{{ avance.description }}</span>
              </div>
            </div>

            <div class="avance-actions">
              <span class="avance-amount">{{ avance.montant | number:'1.2-2' }} DT</span>
              <!-- Modifié: Bouton navigue vers la page de modification -->
              <button (click)="navigateToEditAvance(avance.id!)" class="btn-icon btn-warning" [title]="'BOATS.EDIT' | translate">
                <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                </svg>
              </button>
              <button (click)="deleteAvance(avance)" class="btn-icon btn-danger" [title]="'BOATS.DELETE' | translate">
                <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Pas d'avances -->
      <div class="no-avances" *ngIf="getAvancesByMarin(marin.id!).length === 0">
        <svg class="no-avances-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"/>
        </svg>
        <p>{{ 'AVANCES.NO_AVANCES' | translate }}</p>
      </div>
    </div>
  </div>

  <!-- Total général -->
  <div *ngIf="!loading && avances.length > 0" class="total-card">
    <span class="total-label-main">{{ 'AVANCES.TOTAL_GENERAL' | translate }}</span>
    <span class="total-amount-main">{{ getTotalAvances() | number:'1.2-2' }} DT</span>
  </div>
</div>
EOF

# 6. Modifié: src/app/dashboard/dashboard-routing.module.ts
cat > /tmp/dashboard-routing.module.ts << 'EOF'
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { CommonModule } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';

import { DashboardComponent } from './dashboard.component';
import { DashboardHomeComponent } from './dashboard-home/dashboard-home.component';
import { BoatSelectionGuard } from '../guards/boat-selection.guard';
import { MockDataComponent } from '../mock-data/mock-data.component';

// Importer le nouveau composant de formulaire
import { AvanceFormComponent } from '../avances/avance-form.component';
import { AvancesComponent } from '../avances/avances.component'; // Importer aussi le composant liste

const routes: Routes = [
  {
    path: '',
    component: DashboardComponent,
    children: [
      { path: '', component: DashboardHomeComponent },
      {
        path: 'bateaux',
        loadChildren: () => import('../bateaux/bateaux.module').then(m => m.BateauxModule)
      },
      {
        path: 'sorties',
        loadChildren: () => import('../sorties/sorties.module').then(m => m.SortiesModule),
        canActivate: [BoatSelectionGuard]
      },
      {
        path: 'ventes',
        loadComponent: () => import('../ventes/ventes-list.component').then(m => m.VentesListComponent),
        canActivate: [BoatSelectionGuard]
      },
      // Routes pour les avances (utilisant maintenant le composant formulaire standalone)
      {
        path: 'avances',
        canActivate: [BoatSelectionGuard],
        children: [
           { path: '', component: AvancesComponent }, // La liste reste standalone
           { path: 'add', component: AvanceFormComponent }, // Formulaire ajout (standalone)
           { path: 'edit/:id', component: AvanceFormComponent } // Formulaire modif (standalone)
        ]
      },
      {
        path: 'salaires',
        loadComponent: () => import('../salaires/salaires-list.component').then(m => m.SalairesListComponent),
        canActivate: [BoatSelectionGuard]
      },
      { path: 'mock-data', component: MockDataComponent },

      { path: '', redirectTo: '', pathMatch: 'full' }
    ]
  }
];

@NgModule({
  imports: [
    CommonModule,
    RouterModule.forChild(routes),
    TranslateModule,
    // Les composants Standalone chargés via loadComponent ou utilisés directement dans le routing
    // sont automatiquement importés par Angular si nécessaire, pas besoin de les déclarer ici.
    // AvancesComponent et AvanceFormComponent sont standalone.
  ],
  exports: [RouterModule]
})
export class DashboardRoutingModule { }
EOF

# --- Application des modifications ---

echo "Début de l'application des modifications (v8 - Refonte Formulaire Avance)..."

# Créer les nouveaux fichiers
replace_file "$AVANCES_DIR/avance-form.component.ts" "/tmp/avance-form.component.ts"
replace_file "$AVANCES_DIR/avance-form.component.html" "/tmp/avance-form.component.html"
replace_file "$AVANCES_DIR/avance-form.component.scss" "/tmp/avance-form.component.scss"

# Mettre à jour les fichiers existants
replace_file "$AVANCES_DIR/avances.component.ts" "/tmp/avances.component.ts"
replace_file "$AVANCES_DIR/avances.component.html" "/tmp/avances.component.html"
replace_file "$DASHBOARD_DIR/dashboard-routing.module.ts" "/tmp/dashboard-routing.module.ts"


# Nettoyage des fichiers temporaires
rm /tmp/avance-form.component.ts
rm /tmp/avance-form.component.html
rm /tmp/avance-form.component.scss
rm /tmp/avances.component.ts
rm /tmp/avances.component.html
rm /tmp/dashboard-routing.module.ts


echo "----------------------------------------"
echo "✅ Modifications (v8 - Refonte Formulaire Avance) appliquées avec succès !"
echo "Le formulaire d'avance est maintenant une page dédiée avec un style amélioré."
echo "Les sauvegardes des fichiers modifiés ont été créées avec le suffixe .bak_$TIMESTAMP"
echo "N'oubliez pas de redémarrer 'ng serve' pour voir les changements."
echo "----------------------------------------"

exit 0
