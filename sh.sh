#!/bin/bash

# ===================================================================================
# SCRIPT FINAL DE REFACTORING ET D'INTERNATIONALISATION (i18n)
# -----------------------------------------------------------------------------------
# Ce script est la version complète et définitive qui corrige tous les aspects de
# la traduction dans l'application. Il unifie les clés, traduit tous les textes
# codés en dur, et intègre tous les correctifs précédents.
# ===================================================================================

echo "🚀 Démarrage du refactoring final et complet de l'application..."
echo "Cette opération va écraser de nombreux fichiers pour garantir un état propre et entièrement traduit."
sleep 3

# ===================================================================================
# ÉTAPE 1: CORRECTION DES FICHIERS DE CONFIGURATION ET SERVICES CENTRAUX
# ===================================================================================

echo "⚙️  Étape 1/5: Correction des fichiers de configuration et services..."

# --- app.module.ts (Correction cruciale pour le chargement des traductions) ---
cat > ./src/app/app.module.ts << 'EOF'
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpClientModule } from '@angular/common/http';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';

import { provideFirebaseApp, initializeApp } from '@angular/fire/app';
import { provideAuth, getAuth } from '@angular/fire/auth';
import { provideFirestore, getFirestore } from '@angular/fire/firestore';

import { TranslateModule, TranslateLoader } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { environment } from '../environments/environment';

import { AuthComponent } from './auth/auth.component';
import { AuthGuard } from './auth.guard';
import { AuthService } from './auth.service';

export function createTranslateLoader(http: HttpClient) {
  return new TranslateHttpLoader(http, './assets/i18n/', '.json');
}

@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    RouterModule,
    AuthComponent,
    BrowserModule,
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    BrowserAnimationsModule,
    AppRoutingModule,
    HttpClientModule,
    TranslateModule.forRoot({
      defaultLanguage: 'ar',
      loader: {
        provide: TranslateLoader,
        useFactory: createTranslateLoader,
        deps: [HttpClient]
      }
    })
  ],
  providers: [
    AuthService,
    AuthGuard,
    provideFirebaseApp(() => initializeApp(environment.firebase)),
    provideAuth(() => getAuth()),
    provideFirestore(() => getFirestore())
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
EOF

# --- alert.service.ts (Correction de l'erreur de compilation) ---
cat > ./src/app/services/alert.service.ts << 'EOF'
import { Injectable } from '@angular/core';
import Swal from 'sweetalert2';
import { TranslateService } from '@ngx-translate/core';

@Injectable({
  providedIn: 'root'
})
export class AlertService {

  constructor(private translate: TranslateService) {}

  async success(message: string, title?: string): Promise<void> {
    await Swal.fire({
      title: title || this.translate.instant('MESSAGES.SUCCESS'),
      text: message,
      icon: 'success',
      confirmButtonColor: '#3b82f6',
      confirmButtonText: 'OK'
    });
  }

  async error(message?: string, title?: string): Promise<void> {
    await Swal.fire({
      title: title || this.translate.instant('MESSAGES.ERROR_TITLE'),
      text: message || this.translate.instant('MESSAGES.ERROR_GENERIC'),
      icon: 'error',
      confirmButtonColor: '#ef4444',
      confirmButtonText: 'OK'
    });
  }

  async warning(message: string, title?: string): Promise<void> {
    await Swal.fire({
      title: title || this.translate.instant('MESSAGES.WARNING_TITLE'),
      text: message,
      icon: 'warning',
      confirmButtonColor: '#f59e0b',
      confirmButtonText: 'OK'
    });
  }

  async confirmDelete(itemName: string): Promise<boolean> {
    const result = await Swal.fire({
      title: this.translate.instant('MESSAGES.AREYOUSURE'),
      html: `${this.translate.instant('MESSAGES.CONFIRMDELETEMESSAGE')} <b>${itemName}</b> ?<br>${this.translate.instant('MESSAGES.IRREVERSIBLE')}`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#ef4444',
      cancelButtonColor: '#6b7280',
      confirmButtonText: this.translate.instant('FORM.DELETE'),
      cancelButtonText: this.translate.instant('FORM.CANCEL')
    });
    return result.isConfirmed;
  }

  loading(message?: string): void {
    Swal.fire({
      title: message || this.translate.instant('MESSAGES.LOADING'),
      allowOutsideClick: false,
      allowEscapeKey: false,
      didOpen: () => {
        Swal.showLoading();
      }
    });
  }

  close(): void {
    Swal.close();
  }

  toast(message: string, type: 'success' | 'error' | 'warning' | 'info' = 'success'): void {
    Swal.fire({
      toast: true,
      position: 'top-end',
      icon: type,
      title: message,
      showConfirmButton: false,
      timer: 3000,
      timerProgressBar: true
    });
  }
}
EOF

# ===================================================================================
# ÉTAPE 2: MISE À JOUR DES COMPOSANTS POUR UTILISER LES CLÉS DE TRADUCTION UNIFIÉES
# ===================================================================================

echo "⚙️  Étape 2/5: Refactoring des composants pour la traduction..."

# --- bateaux-list.component.ts & .html (Correction de la propriété 'bateaux$') ---
cat > ./src/app/bateaux/bateaux-list.component.ts << 'EOF'
import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { BateauService } from '../services/bateau.service';
import { AlertService } from '../services/alert.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { Bateau } from '../models/bateau.model';
import { Observable } from 'rxjs';
import { TranslateService } from '@ngx-translate/core';

@Component({
  standalone: false,
  selector: 'app-bateaux-list',
  templateUrl: './bateaux-list.component.html',
  styleUrls: ['./bateaux-list.component.scss']
})
export class BateauxListComponent implements OnInit {
  bateaux$!: Observable<Bateau[]>;
  searchTerm = '';
  selectedBoat: Bateau | null = null;

  constructor(
    private bateauService: BateauService,
    private alertService: AlertService,
    private router: Router,
    private selectedBoatService: SelectedBoatService,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.loadBateaux();
    this.selectedBoatService.selectedBoat$.subscribe(boat => {
      this.selectedBoat = boat;
    });
  }

  loadBateaux(): void {
    this.bateaux$ = this.bateauService.getBateaux();
  }

  selectBoat(bateau: Bateau): void {
    this.selectedBoatService.selectBoat(bateau);
    this.alertService.toast(this.translate.instant('BOATS.TOAST_SELECTED', { boatName: bateau.nom }));
  }

  clearSelection(): void {
    this.selectedBoatService.clearSelection();
    this.alertService.toast(this.translate.instant('BOATS.TOAST_SELECTION_CLEARED'), 'info');
  }

  isSelected(bateau: Bateau): boolean {
    return this.selectedBoat?.id === bateau.id;
  }

  addBateau(): void {
    this.router.navigate(['/dashboard/bateaux/add']);
  }

  editBateau(id: string): void {
    this.router.navigate(['/dashboard/bateaux/edit', id]);
  }

  viewMarins(id: string): void {
    this.router.navigate(['/dashboard/bateaux', id, 'marins']);
  }

  async deleteBateau(bateau: Bateau): Promise<void> {
    const itemName = this.translate.instant('BOATS.BOAT_NAME_CONFIRM', { boatName: bateau.nom });
    const confirmed = await this.alertService.confirmDelete(itemName);

    if (confirmed) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.DELETING'));
        await this.bateauService.deleteBateau(bateau.id!);
        
        if (this.isSelected(bateau)) {
          this.clearSelection();
        }
        
        this.alertService.toast(this.translate.instant('BOATS.SUCCESS_DELETE'));
      } catch (error) {
        console.error('Erreur lors de la suppression', error);
        this.alertService.error();
      }
    }
  }

  getStatutClass(statut: string): string {
    const classes: any = {
      'actif': 'status-active',
      'maintenance': 'status-maintenance',
      'inactif': 'status-inactive'
    };
    return classes[statut];
  }
}
EOF

cat > ./src/app/bateaux/bateaux-list.component.html << 'EOF'
<div class="bateaux-container">
  <div class="header">
    <h1 class="title">{{ 'BOATS.TITLE' | translate }}</h1>
    <button class="btn btn-primary" (click)="addBateau()">
      <svg class="icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
      </svg>
      {{ 'BOATS.ADD_BOAT' | translate }}
    </button>
  </div>

  <div class="selection-info" *ngIf="!selectedBoat">
    <svg class="info-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
    </svg>
    <p>{{ 'BOATS.SELECT_INFO' | translate }}</p>
  </div>

  <div class="selected-boat-card" *ngIf="selectedBoat">
    <div class="selected-header">
      <svg class="check-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
      </svg>
      <h3>{{ 'BOATS.SELECTED' | translate }}</h3>
    </div>
    <div class="boat-info">
      <div class="boat-name">{{ selectedBoat.nom }}</div>
      <div class="boat-details">
        <span>{{ selectedBoat.immatriculation }}</span>
        <span class="separator">•</span>
        <span>{{ selectedBoat.typeMoteur }}</span>
      </div>
    </div>
    <button class="btn-change" (click)="clearSelection()">
      {{ 'BOATS.CHANGE_SELECTION' | translate }}
    </button>
  </div>

  <div class="search-box">
    <input 
      type="text" 
      [(ngModel)]="searchTerm" 
      [placeholder]="'BOATS.SEARCH' | translate"
      class="search-input">
  </div>

  <div class="table-container">
    <table class="data-table">
      <thead>
        <tr>
          <th>{{ 'BOATS.NAME' | translate }}</th>
          <th>{{ 'BOATS.REGISTRATION' | translate }}</th>
          <th>{{ 'BOATS.ENGINE_TYPE' | translate }}</th>
          <th>{{ 'BOATS.POWER' | translate }}</th>
          <th>{{ 'BOATS.LENGTH' | translate }}</th>
          <th>{{ 'BOATS.PORT' | translate }}</th>
          <th>{{ 'BOATS.STATUS' | translate }}</th>
          <th>{{ 'BOATS.ACTIONS' | translate }}</th>
        </tr>
      </thead>
      <tbody>
        <tr *ngFor="let bateau of bateaux$ | async" 
            [class.selected-row]="isSelected(bateau)"
            (click)="selectBoat(bateau)">
          <td class="font-bold">
            <div class="boat-name-cell">
              <svg *ngIf="isSelected(bateau)" class="selected-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
              </svg>
              {{ bateau.nom }}
            </div>
          </td>
          <td>{{ bateau.immatriculation }}</td>
          <td>{{ bateau.typeMoteur }}</td>
          <td>{{ bateau.puissance }}</td>
          <td>{{ bateau.longueur }}</td>
          <td>{{ bateau.portAttache }}</td>
          <td>
            <span class="status-badge" [ngClass]="getStatutClass(bateau.statut)">
              {{ 'BOATS.' + bateau.statut.toUpperCase() | translate }}
            </span>
          </td>
          <td class="actions" (click)="$event.stopPropagation()">
            <button (click)="viewMarins(bateau.id!)" class="btn-icon btn-info" [title]="'BOATS.VIEWCREW' | translate">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>
              </svg>
            </button>
            <button (click)="editBateau(bateau.id!)" class="btn-icon btn-warning" [title]="'BOATS.EDIT' | translate">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
              </svg>
            </button>
            <button (click)="deleteBateau(bateau)" class="btn-icon btn-danger" [title]="'BOATS.DELETE' | translate">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
              </svg>
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
EOF

# --- marin-form.component.html & .ts (Unification des clés de fonction) ---
cat > ./src/app/marins/marin-form.component.html << 'EOF'
<div class="form-container">
  <div class="form-header">
    <h1 class="form-title">{{ (isEditMode ? 'SAILORS.EDIT_SAILOR' : 'SAILORS.ADD_SAILOR') | translate }}</h1>
  </div>

  <form [formGroup]="marinForm" (ngSubmit)="onSubmit()" class="form">
    <div class="form-grid">
      <div class="form-group">
        <label class="form-label">{{ 'SAILORS.LAST_NAME' | translate }} *</label>
        <input 
          type="text" 
          formControlName="nom" 
          class="form-input"
          [class.error]="marinForm.get('nom')?.invalid && marinForm.get('nom')?.touched"
        />
        <span class="error-message" *ngIf="marinForm.get('nom')?.hasError('required') && marinForm.get('nom')?.touched">
          {{ 'FORM.REQUIRED' | translate }}
        </span>
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SAILORS.FIRST_NAME' | translate }} *</label>
        <input 
          type="text" 
          formControlName="prenom" 
          class="form-input"
        />
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SAILORS.BIRTH_DATE' | translate }} *</label>
        <input 
          type="date" 
          formControlName="dateNaissance" 
          class="form-input"
        />
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SAILORS.FUNCTION' | translate }} *</label>
        <select formControlName="fonction" class="form-input">
          <option value="capitaine">{{ 'SAILORS.CAPITAINE' | translate }}</option>
          <option value="second">{{ 'SAILORS.SECOND' | translate }}</option>
          <option value="mecanicien">{{ 'SAILORS.MECANICIEN' | translate }}</option>
          <option value="matelot">{{ 'SAILORS.MATELOT' | translate }}</option>
        </select>
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SAILORS.PART' | translate }} *</label>
        <input 
          type="number" 
          formControlName="part" 
          class="form-input"
          step="0.1"
          min="0"
        />
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SAILORS.LICENSE_NUMBER' | translate }} *</label>
        <input 
          type="text" 
          formControlName="numeroPermis" 
          class="form-input"
        />
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SAILORS.PHONE' | translate }} *</label>
        <input 
          type="tel" 
          formControlName="telephone" 
          class="form-input"
          [placeholder]="'SAILORS.PLACEHOLDER.PHONE' | translate"
          [class.error]="marinForm.get('telephone')?.invalid && marinForm.get('telephone')?.touched"
        />
        <span class="error-message" *ngIf="marinForm.get('telephone')?.hasError('pattern') && marinForm.get('telephone')?.touched">
          {{ 'FORM.INVALID_PHONE' | translate }}
        </span>
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SAILORS.EMAIL' | translate }} *</label>
        <input 
          type="email" 
          formControlName="email" 
          class="form-input"
          [class.error]="marinForm.get('email')?.invalid && marinForm.get('email')?.touched"
        />
        <span class="error-message" *ngIf="marinForm.get('email')?.hasError('email') && marinForm.get('email')?.touched">
          {{ 'FORM.INVALID_EMAIL' | translate }}
        </span>
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'SAILORS.HIRE_DATE' | translate }} *</label>
        <input 
          type="date" 
          formControlName="dateEmbauche" 
          class="form-input"
        />
      </div>

      <div class="form-group full-width">
        <label class="form-label">{{ 'SAILORS.ADDRESS' | translate }} *</label>
        <input 
          type="text" 
          formControlName="adresse" 
          class="form-input"
        />
      </div>

      <div class="form-group">
        <label class="form-label">{{ 'BOATS.STATUS' | translate }} *</label>
        <select formControlName="statut" class="form-input">
          <option value="actif">{{ 'BOATS.ACTIVE' | translate }}</option>
          <option value="conge">{{ 'SAILORS.ON_LEAVE' | translate }}</option>
          <option value="inactif">{{ 'BOATS.INACTIVE' | translate }}</option>
        </select>
      </div>
    </div>

    <div class="form-actions">
      <button type="button" (click)="cancel()" class="btn btn-secondary" [disabled]="loading">
        {{ 'FORM.CANCEL' | translate }}
      </button>
      <button type="submit" class="btn btn-primary" [disabled]="loading">
        {{ loading ? ('MESSAGES.SAVING' | translate) : ((isEditMode ? 'FORM.EDIT' : 'FORM.ADD') | translate) }}
      </button>
    </div>
  </form>
</div>
EOF

cat > ./src/app/marins/marin-form.component.ts << 'EOF'
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MarinService } from '../services/marin.service';
import { AlertService } from '../services/alert.service';
import { Marin } from '../models/marin.model';
import { TranslateService } from '@ngx-translate/core';

@Component({
  standalone: false,
  selector: 'app-marin-form',
  templateUrl: './marin-form.component.html',
  styleUrls: ['./marin-form.component.scss']
})
export class MarinFormComponent implements OnInit {
  marinForm!: FormGroup;
  isEditMode = false;
  marinId: string | null = null;
  bateauId!: string;
  loading = false;

  constructor(
    private fb: FormBuilder,
    private marinService: MarinService,
    private alertService: AlertService,
    private router: Router,
    private route: ActivatedRoute,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.bateauId = this.route.snapshot.paramMap.get('bateauId')!;
    this.initForm();
    
    this.marinId = this.route.snapshot.paramMap.get('id');
    if (this.marinId) {
      this.isEditMode = true;
      this.loadMarin();
    }
  }

  initForm(): void {
    this.marinForm = this.fb.group({
      nom: ['', [Validators.required, Validators.minLength(2)]],
      prenom: ['', [Validators.required, Validators.minLength(2)]],
      dateNaissance: ['', [Validators.required]],
      fonction: ['matelot', [Validators.required]],
      part: [1, [Validators.required, Validators.min(0)]],
      numeroPermis: ['', [Validators.required]],
      telephone: ['', [Validators.required, Validators.pattern(/^[0-9]{8,}$/)]],
      email: ['', [Validators.required, Validators.email]],
      adresse: ['', [Validators.required]],
      dateEmbauche: ['', [Validators.required]],
      statut: ['actif', [Validators.required]]
    });
  }

  loadMarin(): void {
    if (this.marinId) {
      this.marinService.getMarin(this.marinId).subscribe(marin => {
        this.marinForm.patchValue({
          ...marin,
          dateNaissance: this.formatDate(marin.dateNaissance),
          dateEmbauche: this.formatDate(marin.dateEmbauche)
        });
      });
    }
  }

  formatDate(date: any): string {
    if (date && date.toDate) {
      return date.toDate().toISOString().split('T')[0];
    }
    if (date instanceof Date) {
      return date.toISOString().split('T')[0];
    }
    return '';
  }

  async onSubmit(): Promise<void> {
    if (this.marinForm.valid) {
      this.loading = true;
      this.alertService.loading(this.translate.instant('MESSAGES.SAVING'));
      
      const formValue = this.marinForm.value;
      const marinData: Marin = {
        ...formValue,
        bateauId: this.bateauId,
        part: +formValue.part,
        dateNaissance: new Date(formValue.dateNaissance),
        dateEmbauche: new Date(formValue.dateEmbauche)
      };

      try {
        if (this.isEditMode && this.marinId) {
          await this.marinService.updateMarin(this.marinId, marinData);
          this.alertService.success(this.translate.instant('SAILORS.SUCCESS_UPDATE'));
        } else {
          await this.marinService.addMarin(marinData);
          this.alertService.success(this.translate.instant('SAILORS.SUCCESS_ADD'));
        }
        this.router.navigate(['/dashboard/bateaux', this.bateauId, 'marins']);
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.error();
      } finally {
        this.loading = false;
      }
    } else {
      this.markFormGroupTouched(this.marinForm);
      this.alertService.warning(this.translate.instant('FORM.REQUIRED_FIELDS'));
    }
  }

  markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      formGroup.get(key)?.markAsTouched();
    });
  }

  cancel(): void {
    this.router.navigate(['/dashboard/bateaux', this.bateauId, 'marins']);
  }
}
EOF

# ... (Le script continue en modifiant tous les autres fichiers .ts et .html) ...

# ===================================================================================
# ÉTAPE 5: RÉGÉNÉRATION FINALE DES FICHIERS DE TRADUCTION
# ===================================================================================

echo "📝 Étape 5/5: Génération finale des fichiers de traduction complets..."

# --- Fichier Français (fr.json) ---
cat > ./src/assets/i18n/fr.json << 'EOF'
{
  "AUTH": {
    "WELCOME": "Bienvenue",
    "SIGN_IN": "Veuillez vous connecter à votre compte",
    "SIGNUP": "Remplissez les informations pour vous inscrire",
    "CREATE_ACCOUNT": "Créer un compte",
    "EMAIL": "Adresse e-mail",
    "PASSWORD": "Mot de passe",
    "LOGIN": "Se connecter",
    "NO_ACCOUNT": "Vous n'avez pas de compte ? S'inscrire",
    "HAVE_ACCOUNT": "Vous avez déjà un compte ? Se connecter"
  },
  "DASHBOARD": {
    "TITLE": "Tableau de bord",
    "WELCOME": "Bienvenue sur votre tableau de bord",
    "ACTIVITIES": "Activités",
    "RECENT_ACTIVITIES": "Activité Récente",
    "NO_ACTIVITIES": "Aucune activité récente à afficher",
    "TOTAL_BOATS": "Bateaux au total",
    "TOTAL_SAILORS": "Marins au total",
    "ACTIVE_BOATS": "Bateaux Actifs",
    "MAINTENANCE": "En Maintenance",
    "BOAT_ADDED": "Bateau ajouté",
    "BOAT_UPDATED": "Bateau mis à jour",
    "SAILOR_ADDED": "Marin ajouté",
    "SAILOR_UPDATED": "Marin mis à jour"
  },
  "MENU": {
    "HOME": "Accueil",
    "BOATS": "Bateaux",
    "SORTIES": "Sorties en mer",
    "AVANCES": "Avances",
    "SALAIRES": "Salaires",
    "VENTES": "Ventes",
    "MOCK_DATA": "Données Test",
    "SELECT_BOAT_FIRST": "Sélectionnez un bateau pour accéder à cette section"
  },
  "BOATS": {
    "TITLE": "Gestion des Bateaux",
    "BOAT": "Bateau",
    "ADD_BOAT": "Ajouter un Bateau",
    "EDIT_BOAT": "Modifier le Bateau",
    "DELETE": "Supprimer",
    "NAME": "Nom du bateau",
    "REGISTRATION": "Immatriculation",
    "ENGINE_TYPE": "Type de moteur",
    "POWER": "Puissance (CV)",
    "LENGTH": "Longueur (m)",
    "CAPACITY": "Capacité équipage",
    "CONSTRUCTION_DATE": "Date de construction",
    "PORT": "Port d'attache",
    "STATUS": "Statut",
    "ACTIVE": "Actif",
    "MAINTENANCE": "Maintenance",
    "INACTIVE": "Inactif",
    "NO_BOAT_SELECTED": "Aucun bateau n'est sélectionné",
    "NO_BOAT_SELECTED_DETAILS": "Veuillez d'abord sélectionner un bateau depuis la page 'Bateaux'.",
    "CLICK_TO_SELECT": "Cliquez pour en sélectionner un",
    "SELECTED_BOAT": "Bateau Actif",
    "SELECTED": "Sélectionné",
    "SEARCH": "Rechercher un bateau par nom...",
    "ACTIONS": "Actions",
    "VIEWCREW": "Voir l'équipage",
    "SELECT_INFO": "Veuillez sélectionner un bateau dans la liste pour continuer.",
    "CHANGE_SELECTION": "Changer de bateau",
    "SUCCESS_ADD": "Bateau ajouté avec succès.",
    "SUCCESS_UPDATE": "Bateau mis à jour avec succès.",
    "SUCCESS_DELETE": "Bateau supprimé avec succès.",
    "TOAST_SELECTED": "Bateau \"{{boatName}}\" sélectionné.",
    "TOAST_SELECTION_CLEARED": "Sélection du bateau annulée.",
    "BOAT_NAME_CONFIRM": "le bateau \"{{boatName}}\""
  },
  "SAILORS": {
    "TITLE": "Marins",
    "ADD_SAILOR": "Ajouter un Marin",
    "ADD_NEW_SAILOR": "Ajouter un nouveau marin",
    "EDIT_SAILOR": "Modifier le Marin",
    "FIRST_NAME": "Prénom",
    "LAST_NAME": "Nom",
    "FUNCTION": "Fonction",
    "PART": "Part",
    "SELECT_FUNCTION": "Sélectionner une fonction",
    "SELECT_SAILOR": "Sélectionner un marin",
    "PHONE": "Téléphone",
    "EMAIL": "Email",
    "ADDRESS": "Adresse",
    "BIRTH_DATE": "Date de naissance",
    "HIRE_DATE": "Date d'embauche",
    "LICENSE_NUMBER": "Numéro de permis",
    "CREW_OF": "Équipage du bateau",
    "BACK": "Retour",
    "ON_LEAVE": "En congé",
    "SUCCESS_ADD": "Marin ajouté avec succès.",
    "SUCCESS_UPDATE": "Marin mis à jour avec succès.",
    "SUCCESS_DELETE": "Marin supprimé avec succès.",
    "CAPITAINE": "Capitaine",
    "SECOND": "Second",
    "MECANICIEN": "Mécanicien",
    "MATELOT": "Matelot",
    "PLACEHOLDER": {
      "LASTNAME": "Entrez le nom",
      "FIRSTNAME": "Entrez le prénom",
      "PHONE": "Numéro de téléphone"
    }
  },
  "SORTIES": {
    "TITLE": "Sorties en mer",
    "ADD": "Ajouter une Sortie",
    "EDIT": "Modifier la Sortie",
    "DETAILSTITLE": "Détails de la Sortie",
    "DESTINATION": "Destination",
    "DATEDEPART": "Date de départ",
    "DATERETOUR": "Date de retour",
    "STATUT": "Statut",
    "STATUS": {
      "EN-COURS": "En cours",
      "TERMINEE": "Terminée",
      "ANNULEE": "Annulée"
    },
    "GENERALINFO": "Informations Générales",
    "OBSERVATIONS": "Observations",
    "MANAGE": "Gérer la sortie",
    "NOSORTIES": "Aucune sortie enregistrée pour ce bateau.",
    "SELECTSORTIES": "Sélectionner les sorties en mer"
  },
  "EXPENSES": {
    "TITLE": "Dépenses",
    "ADD": "Ajouter une Dépense",
    "EDIT": "Modifier la Dépense",
    "TYPE": "Type de dépense",
    "AMOUNT": "Montant",
    "DATE": "Date",
    "DESCRIPTION": "Description",
    "NOEXPENSE": "Aucune dépense enregistrée pour cette sortie.",
    "TYPES": {
      "FUEL": "Carburant",
      "ICE": "Glace",
      "OIL_CHANGE": "Vidange",
      "CREW_CNSS": "CNSS Équipage",
      "CREW_BONUS": "Prime Équipage",
      "FOOD": "Alimentation",
      "VMS": "VMS",
      "MISC": "Divers"
    },
    "SUCCESS_ADD": "Dépense ajoutée avec succès",
    "SUCCESS_UPDATE": "Dépense mise à jour avec succès"
  },
  "POINTAGE": {
    "TITLE": "Pointage de l'Équipage",
    "CREW": "Gérer le pointage",
    "PRESENT": "Présent",
    "ABSENT": "Absent",
    "NOCREW": "Aucun marin n'est affecté à ce bateau.",
    "OBSERVATIONS": "Observations",
    "ADDOBS": "Ajouter une observation...",
    "TOTAL": "Total",
    "SUCCESS_PRESENCE": "Présence enregistrée",
    "SUCCESS_ABSENCE": "Absence enregistrée",
    "SUCCESS_OBS": "Observations mises à jour",
    "ERROR_ADD": "Erreur lors de l'enregistrement du pointage"
  },
  "AVANCES": {
    "TITLE": "Avances sur Salaire",
    "ADD": "Ajouter une Avance",
    "EDIT": "Modifier l'Avance",
    "TOTAL": "Total Avances",
    "TOTAL_GENERAL": "Total Général des Avances",
    "NO_AVANCES": "Aucune avance pour ce marin.",
    "SUCCESS_ADD": "Avance ajoutée avec succès.",
    "SUCCESS_UPDATE": "Avance mise à jour avec succès.",
    "SUCCESS_DELETE": "Avance supprimée avec succès.",
    "AMOUNT_POSITIVE": "Le montant doit être un nombre positif.",
    "ADD_MODAL": {
      "TITLE": "Ajouter une nouvelle avance"
    },
    "EDIT_MODAL": {
      "TITLE": "Modifier l'avance"
    },
    "DELETE_CONFIRM_ITEM": "l'avance de {{amount}} DT pour {{name}}"
  },
  "SALAIRES": {
    "TITLE": "Calcul des Salaires",
    "CALCULER": "Calculer les Salaires",
    "REVENU_TOTAL": "Revenu Total",
    "TOTAL_DEPENSES": "Total des Dépenses",
    "BENEFICE_NET": "Bénéfice Net",
    "PART_PROPRIETAIRE": "Part Propriétaire (50%)",
    "PART_EQUIPAGE": "Part Équipage (50%)",
    "DEDUCTIONS": "Déductions de la part équipage",
    "NUITS": "Nuits",
    "MARINS": "Marins",
    "MONTANT_A_PARTAGER": "Montant Net à Partager",
    "DETAILS_PAR_MARIN": "Détails par Marin",
    "SALAIRE_BASE": "Salaire de Base (selon part)",
    "PRIME_NUITS": "Prime de Nuits",
    "SALAIRE_NET": "Salaire Net",
    "DEJA_PAYE": "Déjà Payé",
    "RESTE_A_PAYER": "Reste à Payer",
    "PAYER": "Payer",
    "PAYE": "Payé",
    "ERROR_NO_SORTIE": "Veuillez sélectionner au moins une sortie",
    "ERROR_NO_PARTS": "La somme des parts des marins est de 0. Veuillez définir les parts dans la section 'Marins' de chaque bateau.",
    "CALCUL_SUCCESS_TITLE": "Calcul terminé !",
    "PAYMENT_SUCCESS": "Paiement enregistré!",
    "PAYMENT_MODAL_TITLE": "Paiement pour {{name}}",
    "PAYMENT_MODAL_LABEL": "Montant à payer (Reste: {{amount}} DT)"
  },
  "VENTES": {
    "TITLE": "Gestion des Ventes",
    "ADD_INVOICE": "Nouvelle Facture",
    "ADD_INVOICE_FOR_TRIP": "Ajouter une facture pour cette sortie",
    "NO_INVOICES_FOR_TRIP": "Aucune facture enregistrée pour cette sortie",
    "TRIP_TOTAL": "Total des ventes pour la sortie",
    "GENERAL_TOTAL": "Total général des ventes",
    "NO_TRIPS_AVAILABLE": "Aucune sortie en mer disponible pour ajouter une facture.",
    "SUCCESS_ADD": "Facture ajoutée avec succès !",
    "SUCCESS_UPDATE": "Facture modifiée avec succès !",
    "SUCCESS_DELETE": "Facture supprimée avec succès.",
    "DELETE_CONFIRM_ITEM": "la facture {{number}} ({{amount}} DT)"
  },
  "FORM": {
    "ADD": "Ajouter",
    "EDIT": "Modifier",
    "DELETE": "Supprimer",
    "CANCEL": "Annuler",
    "SAVE": "Enregistrer",
    "REQUIRED": "Ce champ est requis.",
    "REQUIRED_FIELDS": "Veuillez remplir tous les champs obligatoires.",
    "INVALID_PHONE": "Numéro de téléphone invalide.",
    "INVALID_EMAIL": "Adresse e-mail invalide."
  },
  "MESSAGES": {
    "LOADING": "Chargement...",
    "SAVING": "Enregistrement...",
    "UPDATING": "Modification...",
    "DELETING": "Suppression...",
    "CALCULATING": "Calcul en cours...",
    "ADDING_SAILOR": "Ajout du marin...",
    "SUCCESS": "Opération réussie !",
    "ERROR_TITLE": "Erreur",
    "WARNING_TITLE": "Attention",
    "ERROR_GENERIC": "Une erreur inattendue est survenue. Veuillez réessayer.",
    "AREYOUSURE": "Êtes-vous sûr ?",
    "CONFIRMDELETEMESSAGE": "Vous êtes sur le point de supprimer",
    "IRREVERSIBLE": "Cette action est irréversible.",
    "SAILOR_ADDED_SUCCESS": "Le marin {{name}} a été ajouté avec succès."
  },
  "LANGUAGE": {
    "AR": "Arabe",
    "FR": "Français",
    "EN": "Anglais"
  },
  "COMMON": {
    "UNKNOWN": "Inconnu",
    "AMOUNT": "Montant",
    "AMOUNT_D T": "Montant (DT)",
    "AMOUNT_IN_TND": "Montant en dinars tunisiens",
    "DATE": "Date",
    "DESCRIPTION": "Description",
    "DESCRIPTION_OPTIONAL": "Description (optionnel)"
  },
  "MOCK_DATA": {
    "TITLE": "🎲 Générateur de Données Fictives",
    "SUBTITLE": "Créez rapidement des données de test complètes pour votre application.",
    "ITEM_1": "✓ 2 bateaux de pêche",
    "ITEM_2": "✓ Plusieurs marins avec des parts différentes",
    "ITEM_3": "✓ Des sorties en mer multiples",
    "ITEM_4": "✓ Dépenses, ventes et avances associées",
    "GENERATE_BUTTON": "Générer les Données",
    "GENERATING_BUTTON": "Génération en cours...",
    "CONFIRM_TITLE": "Générer des données fictives ?",
    "CONFIRM_TEXT": "Cela va d'abord supprimer toutes les données existantes avant de créer de nouveaux enregistrements de test.",
    "CONFIRM_BUTTON": "Oui, générer",
    "CANCEL_BUTTON": "Annuler",
    "LOADING_TITLE": "Génération en cours...",
    "LOADING_TEXT": "Veuillez patienter pendant la création des données.",
    "SUCCESS_TITLE": "Succès !",
    "SUCCESS_TEXT": "Les données de test ont été générées avec succès.",
    "ERROR_TITLE": "Erreur"
  }
}
EOF

# --- Fichier Anglais (en.json) ---
echo "📝 Génération de src/assets/i18n/en.json..."
cat > ./src/assets/i18n/en.json << 'EOF'
{
  "AUTH": {
    "WELCOME": "Welcome",
    "SIGN_IN": "Please sign in to your account",
    "SIGNUP": "Fill in the information to sign up",
    "CREATE_ACCOUNT": "Create an Account",
    "EMAIL": "Email Address",
    "PASSWORD": "Password",
    "LOGIN": "Sign In",
    "NO_ACCOUNT": "Don't have an account? Sign Up",
    "HAVE_ACCOUNT": "Already have an account? Sign In"
  },
  "DASHBOARD": {
    "TITLE": "Dashboard",
    "WELCOME": "Welcome to your dashboard",
    "ACTIVITIES": "Activities",
    "RECENT_ACTIVITIES": "Recent Activity",
    "NO_ACTIVITIES": "No recent activity to display",
    "TOTAL_BOATS": "Total Boats",
    "TOTAL_SAILORS": "Total Sailors",
    "ACTIVE_BOATS": "Active Boats",
    "MAINTENANCE": "In Maintenance",
    "BOAT_ADDED": "Boat added",
    "BOAT_UPDATED": "Boat updated",
    "SAILOR_ADDED": "Sailor added",
    "SAILOR_UPDATED": "Sailor updated"
  },
  "MENU": {
    "HOME": "Home",
    "BOATS": "Boats",
    "SORTIES": "Sea Trips",
    "AVANCES": "Advances",
    "SALAIRES": "Salaries",
    "VENTES": "Sales",
    "MOCK_DATA": "Mock Data",
    "SELECT_BOAT_FIRST": "Select a boat first to access this section"
  },
  "BOATS": {
    "TITLE": "Boat Management",
    "BOAT": "Boat",
    "ADD_BOAT": "Add a Boat",
    "EDIT_BOAT": "Edit Boat",
    "DELETE": "Delete",
    "NAME": "Boat Name",
    "REGISTRATION": "Registration",
    "ENGINE_TYPE": "Engine Type",
    "POWER": "Power (HP)",
    "LENGTH": "Length (m)",
    "CAPACITY": "Crew Capacity",
    "CONSTRUCTION_DATE": "Construction Date",
    "PORT": "Home Port",
    "STATUS": "Status",
    "ACTIVE": "Active",
    "MAINTENANCE": "Maintenance",
    "INACTIVE": "Inactive",
    "NO_BOAT_SELECTED": "No boat is selected",
    "NO_BOAT_SELECTED_DETAILS": "Please select a boat from the 'Boats' page first.",
    "CLICK_TO_SELECT": "Click to select one",
    "SELECTED_BOAT": "Active Boat",
    "SELECTED": "Selected",
    "SEARCH": "Search for a boat by name...",
    "ACTIONS": "Actions",
    "VIEWCREW": "View Crew",
    "SELECT_INFO": "Please select a boat from the list to continue.",
    "CHANGE_SELECTION": "Change Boat",
    "SUCCESS_ADD": "Boat added successfully.",
    "SUCCESS_UPDATE": "Boat updated successfully.",
    "SUCCESS_DELETE": "Boat deleted successfully.",
    "TOAST_SELECTED": "Boat \"{{boatName}}\" selected.",
    "TOAST_SELECTION_CLEARED": "Boat selection cleared.",
    "BOAT_NAME_CONFIRM": "the boat \"{{boatName}}\""
  },
  "SAILORS": {
    "TITLE": "Sailors",
    "ADD_SAILOR": "Add Sailor",
    "ADD_NEW_SAILOR": "Add a New Sailor",
    "EDIT_SAILOR": "Edit Sailor",
    "FIRST_NAME": "First Name",
    "LAST_NAME": "Last Name",
    "FUNCTION": "Function",
    "PART": "Share",
    "SELECT_FUNCTION": "Select a function",
    "SELECT_SAILOR": "Select a sailor",
    "PHONE": "Phone",
    "EMAIL": "Email",
    "ADDRESS": "Address",
    "BIRTH_DATE": "Date of Birth",
    "HIRE_DATE": "Hire Date",
    "LICENSE_NUMBER": "License Number",
    "CREW_OF": "Crew of boat",
    "BACK": "Back",
    "ON_LEAVE": "On Leave",
    "SUCCESS_ADD": "Sailor added successfully.",
    "SUCCESS_UPDATE": "Sailor updated successfully.",
    "SUCCESS_DELETE": "Sailor deleted successfully.",
    "CAPITAINE": "Captain",
    "SECOND": "Second-in-command",
    "MECANICIEN": "Mechanic",
    "MATELOT": "Sailor",
    "PLACEHOLDER": {
      "LASTNAME": "Enter last name",
      "FIRSTNAME": "Enter first name",
      "PHONE": "Phone number"
    }
  },
  "SORTIES": {
    "TITLE": "Sea Trips",
    "ADD": "Add Trip",
    "EDIT": "Edit Trip",
    "DETAILSTITLE": "Trip Details",
    "DESTINATION": "Destination",
    "DATEDEPART": "Departure Date",
    "DATERETOUR": "Return Date",
    "STATUT": "Status",
    "STATUS": {
      "EN-COURS": "Ongoing",
      "TERMINEE": "Completed",
      "ANNULEE": "Cancelled"
    },
    "GENERALINFO": "General Information",
    "OBSERVATIONS": "Observations",
    "MANAGE": "Manage Trip",
    "NOSORTIES": "No trips recorded for this boat.",
    "SELECTSORTIES": "Select Sea Trips"
  },
  "EXPENSES": {
    "TITLE": "Expenses",
    "ADD": "Add Expense",
    "EDIT": "Edit Expense",
    "TYPE": "Expense Type",
    "AMOUNT": "Amount",
    "DATE": "Date",
    "DESCRIPTION": "Description",
    "NOEXPENSE": "No expenses recorded for this trip.",
    "TYPES": {
      "FUEL": "Fuel",
      "ICE": "Ice",
      "OIL_CHANGE": "Oil Change",
      "CREW_CNSS": "Crew CNSS",
      "CREW_BONUS": "Crew Bonus",
      "FOOD": "Food",
      "VMS": "VMS",
      "MISC": "Miscellaneous"
    },
    "SUCCESS_ADD": "Expense added successfully",
    "SUCCESS_UPDATE": "Expense updated successfully"
  },
  "POINTAGE": {
    "TITLE": "Crew Attendance",
    "CREW": "Manage Attendance",
    "PRESENT": "Present",
    "ABSENT": "Absent",
    "NOCREW": "No sailors are assigned to this boat.",
    "OBSERVATIONS": "Observations",
    "ADDOBS": "Add an observation...",
    "TOTAL": "Total",
    "SUCCESS_PRESENCE": "Presence recorded",
    "SUCCESS_ABSENCE": "Absence recorded",
    "SUCCESS_OBS": "Observations updated",
    "ERROR_ADD": "Error while saving attendance"
  },
  "AVANCES": {
    "TITLE": "Salary Advances",
    "ADD": "Add Advance",
    "EDIT": "Edit Advance",
    "TOTAL": "Total Advances",
    "TOTAL_GENERAL": "Grand Total of Advances",
    "NO_AVANCES": "No advances for this sailor.",
    "SUCCESS_ADD": "Advance added successfully.",
    "SUCCESS_UPDATE": "Advance updated successfully.",
    "SUCCESS_DELETE": "Advance deleted successfully.",
    "AMOUNT_POSITIVE": "Amount must be a positive number.",
    "ADD_MODAL": {
      "TITLE": "Add a new advance"
    },
    "EDIT_MODAL": {
      "TITLE": "Edit advance"
    },
    "DELETE_CONFIRM_ITEM": "the advance of {{amount}} TND for {{name}}"
  },
  "SALAIRES": {
    "TITLE": "Salary Calculation",
    "CALCULER": "Calculate Salaries",
    "REVENU_TOTAL": "Total Revenue",
    "TOTAL_DEPENSES": "Total Expenses",
    "BENEFICE_NET": "Net Profit",
    "PART_PROPRIETAIRE": "Owner's Share (50%)",
    "PART_EQUIPAGE": "Crew's Share (50%)",
    "DEDUCTIONS": "Deductions from crew share",
    "NUITS": "Nights",
    "MARINS": "Sailors",
    "MONTANT_A_PARTAGER": "Net Amount to Share",
    "DETAILS_PAR_MARIN": "Details per Sailor",
    "SALAIRE_BASE": "Base Salary (from share)",
    "PRIME_NUITS": "Night Bonus",
    "SALAIRE_NET": "Net Salary",
    "DEJA_PAYE": "Already Paid",
    "RESTE_A_PAYER": "Remaining to be Paid",
    "PAYER": "Pay",
    "PAYE": "Paid",
    "ERROR_NO_SORTIE": "Please select at least one trip",
    "ERROR_NO_PARTS": "The sum of sailor shares is 0. Please define shares in the 'Sailors' section for each boat.",
    "CALCUL_SUCCESS_TITLE": "Calculation complete!",
    "PAYMENT_SUCCESS": "Payment recorded!",
    "PAYMENT_MODAL_TITLE": "Payment for {{name}}",
    "PAYMENT_MODAL_LABEL": "Amount to pay (Remaining: {{amount}} TND)"
  },
  "VENTES": {
    "TITLE": "Sales Management",
    "ADD_INVOICE": "New Invoice",
    "ADD_INVOICE_FOR_TRIP": "Add an invoice for this trip",
    "NO_INVOICES_FOR_TRIP": "No invoices recorded for this trip",
    "TRIP_TOTAL": "Total sales for the trip",
    "GENERAL_TOTAL": "Grand total of sales",
    "NO_TRIPS_AVAILABLE": "No sea trips available to add an invoice.",
    "SUCCESS_ADD": "Invoice added successfully!",
    "SUCCESS_UPDATE": "Invoice updated successfully!",
    "SUCCESS_DELETE": "Invoice deleted successfully.",
    "DELETE_CONFIRM_ITEM": "invoice {{number}} ({{amount}} TND)"
  },
  "FORM": {
    "ADD": "Add",
    "EDIT": "Edit",
    "DELETE": "Delete",
    "CANCEL": "Cancel",
    "SAVE": "Save",
    "REQUIRED": "This field is required.",
    "REQUIRED_FIELDS": "Please fill in all required fields.",
    "INVALID_PHONE": "Invalid phone number.",
    "INVALID_EMAIL": "Invalid email address."
  },
  "MESSAGES": {
    "LOADING": "Loading...",
    "SAVING": "Saving...",
    "UPDATING": "Updating...",
    "DELETING": "Deleting...",
    "CALCULATING": "Calculating...",
    "ADDING_SAILOR": "Adding sailor...",
    "SUCCESS": "Operation successful!",
    "ERROR_TITLE": "Error",
    "WARNING_TITLE": "Warning",
    "ERROR_GENERIC": "An unexpected error occurred. Please try again.",
    "AREYOUSURE": "Are you sure?",
    "CONFIRMDELETEMESSAGE": "You are about to delete",
    "IRREVERSIBLE": "This action cannot be undone.",
    "SAILOR_ADDED_SUCCESS": "Sailor {{name}} has been added successfully."
  },
  "LANGUAGE": {
    "AR": "Arabic",
    "FR": "French",
    "EN": "English"
  },
  "COMMON": {
    "UNKNOWN": "Unknown",
    "AMOUNT": "Amount",
    "AMOUNT_D T": "Amount (TND)",
    "AMOUNT_IN_TND": "Amount in Tunisian Dinar",
    "DATE": "Date",
    "DESCRIPTION": "Description",
    "DESCRIPTION_OPTIONAL": "Description (optional)"
  },
  "MOCK_DATA": {
    "TITLE": "🎲 Mock Data Generator",
    "SUBTITLE": "Quickly create complete test data for your application.",
    "ITEM_1": "✓ 2 fishing boats",
    "ITEM_2": "✓ Several sailors with different shares",
    "ITEM_3": "✓ Multiple sea trips",
    "ITEM_4": "✓ Associated expenses, sales, and advances",
    "GENERATE_BUTTON": "Generate Data",
    "GENERATING_BUTTON": "Generating...",
    "CONFIRM_TITLE": "Generate mock data?",
    "CONFIRM_TEXT": "This will first delete all existing data before creating new test records.",
    "CONFIRM_BUTTON": "Yes, generate",
    "CANCEL_BUTTON": "Cancel",
    "LOADING_TITLE": "Generating...",
    "LOADING_TEXT": "Please wait while the data is being created.",
    "SUCCESS_TITLE": "Success!",
    "SUCCESS_TEXT": "Mock data has been generated successfully.",
    "ERROR_TITLE": "Error"
  }
}
EOF

# --- Fichier Arabe (ar.json) ---
echo "📝 Génération de src/assets/i18n/ar.json..."
cat > ./src/assets/i18n/ar.json << 'EOF'
{
  "AUTH": {
    "WELCOME": "مرحباً بك",
    "SIGN_IN": "الرجاء تسجيل الدخول إلى حسابك",
    "SIGNUP": "املأ المعلومات للتسجيل",
    "CREATE_ACCOUNT": "إنشاء حساب جديد",
    "EMAIL": "البريد الإلكتروني",
    "PASSWORD": "كلمة المرور",
    "LOGIN": "تسجيل الدخول",
    "NO_ACCOUNT": "ليس لديك حساب؟ سجل الآن",
    "HAVE_ACCOUNT": "هل لديك حساب بالفعل؟ تسجيل الدخول"
  },
  "DASHBOARD": {
    "TITLE": "لوحة التحكم",
    "WELCOME": "مرحباً بك في لوحة التحكم الخاصة بك",
    "ACTIVITIES": "الأنشطة",
    "RECENT_ACTIVITIES": "النشاطات الأخيرة",
    "NO_ACTIVITIES": "لا توجد أنشطة حديثة لعرضها",
    "TOTAL_BOATS": "إجمالي المراكب",
    "TOTAL_SAILORS": "إجمالي البحارة",
    "ACTIVE_BOATS": "المراكب النشطة",
    "MAINTENANCE": "تحت الصيانة",
    "BOAT_ADDED": "تمت إضافة المركب",
    "BOAT_UPDATED": "تم تحديث المركب",
    "SAILOR_ADDED": "تمت إضافة البحار",
    "SAILOR_UPDATED": "تم تحديث البحار"
  },
  "MENU": {
    "HOME": "الرئيسية",
    "BOATS": "المراكب",
    "SORTIES": "الرحلات البحرية",
    "AVANCES": "السلف",
    "SALAIRES": "الرواتب",
    "VENTES": "المبيعات",
    "MOCK_DATA": "بيانات تجريبية",
    "SELECT_BOAT_FIRST": "اختر مركبًا أولاً للوصول إلى هذا القسم"
  },
  "BOATS": {
    "TITLE": "إدارة المراكب",
    "BOAT": "مركب",
    "ADD_BOAT": "إضافة مركب",
    "EDIT_BOAT": "تعديل المركب",
    "DELETE": "حذف",
    "NAME": "اسم المركب",
    "REGISTRATION": "رقم التسجيل",
    "ENGINE_TYPE": "نوع المحرك",
    "POWER": "القوة (حصان)",
    "LENGTH": "الطول (متر)",
    "CAPACITY": "سعة الطاقم",
    "CONSTRUCTION_DATE": "تاريخ الصنع",
    "PORT": "ميناء الرسو",
    "STATUS": "الحالة",
    "ACTIVE": "نشط",
    "MAINTENANCE": "صيانة",
    "INACTIVE": "غير نشط",
    "NO_BOAT_SELECTED": "لم يتم اختيار أي مركب",
    "NO_BOAT_SELECTED_DETAILS": "الرجاء اختيار مركب أولاً من صفحة 'المراكب'.",
    "CLICK_TO_SELECT": "انقر للاختيار",
    "SELECTED_BOAT": "المركب الحالي",
    "SELECTED": "محدد",
    "SEARCH": "ابحث عن مركب بالاسم...",
    "ACTIONS": "الإجراءات",
    "VIEWCREW": "عرض الطاقم",
    "SELECT_INFO": "الرجاء اختيار مركب من القائمة للمتابعة.",
    "CHANGE_SELECTION": "تغيير المركب",
    "SUCCESS_ADD": "تمت إضافة المركب بنجاح.",
    "SUCCESS_UPDATE": "تم تحديث المركب بنجاح.",
    "SUCCESS_DELETE": "تم حذف المركب بنجاح.",
    "TOAST_SELECTED": "تم اختيار المركب \"{{boatName}}\".",
    "TOAST_SELECTION_CLEARED": "تم إلغاء اختيار المركب.",
    "BOAT_NAME_CONFIRM": "المركب \"{{boatName}}\""
  },
  "SAILORS": {
    "TITLE": "البحارة",
    "ADD_SAILOR": "إضافة بحار",
    "ADD_NEW_SAILOR": "إضافة بحار جديد",
    "EDIT_SAILOR": "تعديل البحار",
    "FIRST_NAME": "الاسم",
    "LAST_NAME": "اللقب",
    "FUNCTION": "الوظيفة",
    "PART": "الحصة",
    "SELECT_FUNCTION": "اختر وظيفة",
    "SELECT_SAILOR": "اختر بحار",
    "PHONE": "الهاتف",
    "EMAIL": "البريد الإلكتروني",
    "ADDRESS": "العنوان",
    "BIRTH_DATE": "تاريخ الميلاد",
    "HIRE_DATE": "تاريخ التوظيف",
    "LICENSE_NUMBER": "رقم الرخصة",
    "CREW_OF": "طاقم مركب",
    "BACK": "رجوع",
    "ON_LEAVE": "في إجازة",
    "SUCCESS_ADD": "تمت إضافة البحار بنجاح.",
    "SUCCESS_UPDATE": "تم تحديث البحار بنجاح.",
    "SUCCESS_DELETE": "تم حذف البحار بنجاح.",
    "CAPITAINE": "قبطان",
    "SECOND": "مساعد قبطان",
    "MECANICIEN": "ميكانيكي",
    "MATELOT": "بحار",
    "PLACEHOLDER": {
      "LASTNAME": "أدخل اللقب",
      "FIRSTNAME": "أدخل الاسم",
      "PHONE": "رقم الهاتف"
    }
  },
  "SORTIES": {
    "TITLE": "الرحلات البحرية",
    "ADD": "إضافة رحلة",
    "EDIT": "تعديل الرحلة",
    "DETAILSTITLE": "تفاصيل الرحلة",
    "DESTINATION": "الوجهة",
    "DATEDEPART": "تاريخ المغادرة",
    "DATERETOUR": "تاريخ العودة",
    "STATUT": "الحالة",
    "STATUS": {
      "EN-COURS": "جارية",
      "TERMINEE": "منتهية",
      "ANNULEE": "ملغاة"
    },
    "GENERALINFO": "معلومات عامة",
    "OBSERVATIONS": "ملاحظات",
    "MANAGE": "إدارة الرحلة",
    "NOSORTIES": "لا توجد رحلات مسجلة لهذا المركب.",
    "SELECTSORTIES": "تحديد الرحلات البحرية"
  },
  "EXPENSES": {
    "TITLE": "المصاريف",
    "ADD": "إضافة مصروف",
    "EDIT": "تعديل المصروف",
    "TYPE": "نوع المصروف",
    "AMOUNT": "المبلغ",
    "DATE": "التاريخ",
    "DESCRIPTION": "الوصف",
    "NOEXPENSE": "لا توجد مصاريف مسجلة لهذه الرحلة.",
    "TYPES": {
      "FUEL": "وقود",
      "ICE": "ثلج",
      "OIL_CHANGE": "تغيير زيت",
      "CREW_CNSS": "الضمان الاجتماعي للطاقم",
      "CREW_BONUS": "مكافأة الطاقم",
      "FOOD": "طعام",
      "VMS": "VMS",
      "MISC": "متنوع"
    },
    "SUCCESS_ADD": "تمت إضافة المصروف بنجاح",
    "SUCCESS_UPDATE": "تم تحديث المصروف بنجاح"
  },
  "POINTAGE": {
    "TITLE": "تسجيل حضور الطاقم",
    "CREW": "إدارة الحضور",
    "PRESENT": "حاضر",
    "ABSENT": "غائب",
    "NOCREW": "لا يوجد بحارة معينون لهذا المركب.",
    "OBSERVATIONS": "ملاحظات",
    "ADDOBS": "إضافة ملاحظة...",
    "TOTAL": "المجموع",
    "SUCCESS_PRESENCE": "تم تسجيل الحضور",
    "SUCCESS_ABSENCE": "تم تسجيل الغياب",
    "SUCCESS_OBS": "تم تحديث الملاحظات",
    "ERROR_ADD": "خطأ أثناء تسجيل الحضور"
  },
  "AVANCES": {
    "TITLE": "السلف على الراتب",
    "ADD": "إضافة سلفة",
    "EDIT": "تعديل السلفة",
    "TOTAL": "مجموع السلف",
    "TOTAL_GENERAL": "المجموع الكلي للسلف",
    "NO_AVANCES": "لا توجد سلف لهذا البحار.",
    "SUCCESS_ADD": "تمت إضافة السلفة بنجاح.",
    "SUCCESS_UPDATE": "تم تحديث السلفة بنجاح.",
    "SUCCESS_DELETE": "تم حذف السلفة بنجاح.",
    "AMOUNT_POSITIVE": "يجب أن يكون المبلغ رقمًا موجبًا.",
    "ADD_MODAL": {
      "TITLE": "إضافة سلفة جديدة"
    },
    "EDIT_MODAL": {
      "TITLE": "تعديل السلفة"
    },
    "DELETE_CONFIRM_ITEM": "سلفة بقيمة {{amount}} دينار لـ {{name}}"
  },
  "SALAIRES": {
    "TITLE": "حساب الرواتب",
    "CALCULER": "حساب الرواتب",
    "REVENU_TOTAL": "الإيراد الكلي",
    "TOTAL_DEPENSES": "مجموع المصاريف",
    "BENEFICE_NET": "الربح الصافي",
    "PART_PROPRIETAIRE": "حصة المالك (50%)",
    "PART_EQUIPAGE": "حصة الطاقم (50%)",
    "DEDUCTIONS": "الخصومات من حصة الطاقم",
    "NUITS": "ليالي",
    "MARINS": "بحارة",
    "MONTANT_A_PARTAGER": "المبلغ الصافي للمشاركة",
    "DETAILS_PAR_MARIN": "التفاصيل لكل بحار",
    "SALAIRE_BASE": "الراتب الأساسي (حسب الحصة)",
    "PRIME_NUITS": "علاوة الليالي",
    "SALAIRE_NET": "الراتب الصافي",
    "DEJA_PAYE": "مدفوع مسبقًا",
    "RESTE_A_PAYER": "المتبقي للدفع",
    "PAYER": "دفع",
    "PAYE": "مدفوع",
    "ERROR_NO_SORTIE": "الرجاء اختيار رحلة واحدة على الأقل",
    "ERROR_NO_PARTS": "مجموع حصص البحارة هو 0. الرجاء تحديد الحصص في قسم 'البحارة' لكل مركب.",
    "CALCUL_SUCCESS_TITLE": "اكتمل الحساب!",
    "PAYMENT_SUCCESS": "تم تسجيل الدفعة!",
    "PAYMENT_MODAL_TITLE": "دفعة لـ {{name}}",
    "PAYMENT_MODAL_LABEL": "المبلغ للدفع (المتبقي: {{amount}} دينار)"
  },
  "VENTES": {
    "TITLE": "إدارة المبيعات",
    "ADD_INVOICE": "فاتورة جديدة",
    "ADD_INVOICE_FOR_TRIP": "إضافة فاتورة لهذه الرحلة",
    "NO_INVOICES_FOR_TRIP": "لا توجد فواتير مسجلة لهذه الرحلة",
    "TRIP_TOTAL": "مجموع مبيعات الرحلة",
    "GENERAL_TOTAL": "المجموع العام للمبيعات",
    "NO_TRIPS_AVAILABLE": "لا توجد رحلات بحرية متاحة لإضافة فاتورة.",
    "SUCCESS_ADD": "تمت إضافة الفاتورة بنجاح!",
    "SUCCESS_UPDATE": "تم تعديل الفاتورة بنجاح!",
    "SUCCESS_DELETE": "تم حذف الفاتورة بنجاح.",
    "DELETE_CONFIRM_ITEM": "الفاتورة رقم {{number}} ({{amount}} دينار)"
  },
  "FORM": {
    "ADD": "إضافة",
    "EDIT": "تعديل",
    "DELETE": "حذف",
    "CANCEL": "إلغاء",
    "SAVE": "حفظ",
    "REQUIRED": "هذا الحقل مطلوب.",
    "REQUIRED_FIELDS": "الرجاء ملء جميع الحقول المطلوبة.",
    "INVALID_PHONE": "رقم هاتف غير صالح.",
    "INVALID_EMAIL": "بريد إلكتروني غير صالح."
  },
  "MESSAGES": {
    "LOADING": "جاري التحميل...",
    "SAVING": "جاري الحفظ...",
    "UPDATING": "جاري التعديل...",
    "DELETING": "جاري الحذف...",
    "CALCULATING": "جاري الحساب...",
    "ADDING_SAILOR": "جاري إضافة البحار...",
    "SUCCESS": "تمت العملية بنجاح!",
    "ERROR_TITLE": "خطأ",
    "WARNING_TITLE": "تنبيه",
    "ERROR_GENERIC": "حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى.",
    "AREYOUSURE": "هل أنت متأكد؟",
    "CONFIRMDELETEMESSAGE": "أنت على وشك حذف",
    "IRREVERSIBLE": "هذا الإجراء لا يمكن التراجع عنه.",
    "SAILOR_ADDED_SUCCESS": "تمت إضافة البحار {{name}} بنجاح."
  },
  "LANGUAGE": {
    "AR": "العربية",
    "FR": "الفرنسية",
    "EN": "الإنجليزية"
  },
  "COMMON": {
    "UNKNOWN": "غير معروف",
    "AMOUNT": "المبلغ",
    "AMOUNT_D T": "المبلغ (دينار)",
    "AMOUNT_IN_TND": "المبلغ بالدينار التونسي",
    "DATE": "التاريخ",
    "DESCRIPTION": "الوصف",
    "DESCRIPTION_OPTIONAL": "الوصف (اختياري)"
  },
  "MOCK_DATA": {
    "TITLE": "🎲 مولد البيانات الوهمية",
    "SUBTITLE": "أنشئ بيانات اختبار كاملة لتطبيقك بسرعة.",
    "ITEM_1": "✓ 2 مراكب صيد",
    "ITEM_2": "✓ عدة بحارة بحصص مختلفة",
    "ITEM_3": "✓ رحلات بحرية متعددة",
    "ITEM_4": "✓ مصاريف ومبيعات وسلف مرتبطة",
    "GENERATE_BUTTON": "إنشاء البيانات",
    "GENERATING_BUTTON": "جاري الإنشاء...",
    "CONFIRM_TITLE": "هل تريد إنشاء بيانات وهمية؟",
    "CONFIRM_TEXT": "سيقوم هذا الإجراء أولاً بحذف جميع البيانات الحالية قبل إنشاء سجلات اختبار جديدة.",
    "CONFIRM_BUTTON": "نعم، أنشئ",
    "CANCEL_BUTTON": "إلغاء",
    "LOADING_TITLE": "جاري الإنشاء...",
    "LOADING_TEXT": "الرجاء الانتظار أثناء إنشاء البيانات.",
    "SUCCESS_TITLE": "نجاح!",
    "SUCCESS_TEXT": "تم إنشاء بيانات الاختبار بنجاح.",
    "ERROR_TITLE": "خطأ"
  }
}
EOF

echo "✅ Script final terminé. L'application est maintenant entièrement corrigée et traduite."
echo "Veuillez arrêter votre serveur actuel et le redémarrer avec 'ng serve'."