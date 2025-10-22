#!/bin/bash

# Ce script applique les modifications au composant Avances et aux fichiers i18n.
# Il crée des sauvegardes des fichiers originaux avant de les écraser.

# Variables
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SRC_DIR="src"

# Fonction pour sauvegarder et remplacer un fichier
replace_file() {
  local file_path="$1"
  local new_content_file="$2"
  local backup_path="${file_path}.bak_${TIMESTAMP}"

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
    echo "Attention : Le fichier '$file_path' n'existe pas. Création du fichier..."
    mkdir -p "$(dirname "$file_path")" # Crée le dossier parent si nécessaire
    cat "$new_content_file" > "$file_path"
     if [ $? -ne 0 ]; then
      echo "Erreur : Échec de la création de '$file_path'."
      exit 1
    fi
    echo "  -> '$file_path' créé."
  fi
}

# --- Définition du nouveau contenu ---

# 1. src/app/avances/avances.component.ts
cat > /tmp/avances.component.ts << 'EOF'
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
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
  styleUrls: ['./avances.component.scss'] // Assurez-vous que le SCSS est lié
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
    private translate: TranslateService
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
      // ✅ On récupère toujours les avances NON réglées
      this.avanceService.getUnsettledAvancesByBateau(this.selectedBoat.id!)
    ]).subscribe(([marins, avances]) => {
      this.marins = marins;
      // Trier les marins par nom pour l'affichage
      this.marins.sort((a, b) => a.nom.localeCompare(b.nom));
      // Trier les avances par date (plus récentes en premier) pour chaque marin
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
    // Vérifier si la date est valide
    if (isNaN(dateObj.getTime())) {
        return '';
    }
    const day = String(dateObj.getDate()).padStart(2, '0');
    const month = String(dateObj.getMonth() + 1).padStart(2, '0');
    const year = dateObj.getFullYear();
    return `${day}/${month}/${year}`;
  }


  // ✅ AMÉLIORATION: Méthode entièrement revue pour un meilleur design et traductions
  async addAvance(): Promise<void> {
    if (!this.selectedBoat) return;

    const marinsOptions = this.marins.reduce((acc, marin) => {
      // La traduction est maintenant correcte grâce aux clés ajoutées
      const fonction = this.translate.instant('SAILORS.FUNCTION_TYPE.' + marin.fonction.toUpperCase());
      acc[marin.id!] = `${marin.prenom} ${marin.nom} - ${fonction}`;
      return acc;
    }, {} as { [key: string]: string });

    // Objet pour regrouper les traductions nécessaires
    const t = {
      title: this.translate.instant('AVANCES.ADD_MODAL.TITLE'),
      sailor: this.translate.instant('SAILORS.TITLE'),
      selectSailor: this.translate.instant('SAILORS.SELECT_SAILOR'),
      amount: this.translate.instant('COMMON.AMOUNT_D_T'),
      amountPlaceholder: this.translate.instant('COMMON.AMOUNT_IN_TND'),
      date: this.translate.instant('COMMON.DATE'),
      description: this.translate.instant('COMMON.DESCRIPTION'),
      descriptionPlaceholder: this.translate.instant('COMMON.DESCRIPTION_OPTIONAL'),
      add: this.translate.instant('FORM.ADD'),
      cancel: this.translate.instant('FORM.CANCEL'),
      requiredFields: this.translate.instant('FORM.REQUIRED_FIELDS'),
      amountPositive: this.translate.instant('AVANCES.AMOUNT_POSITIVE')
    };

    const { value: formValues } = await Swal.fire({
      title: `<div style="text-align: center;">
                <div style="font-size: 1.5rem; font-weight: 700; color: #1f2937; margin-bottom: 0.5rem;">
                  ${t.title}
                </div>
              </div>`,
      html: `
        <div class="swal-custom-form">
          <div class="form-group">
            <label class="form-label">${t.sailor} <span class="required-star">*</span></label>
            <select id="swal-marin" class="custom-select">
              <option value="">${t.selectSailor}</option>
              ${Object.keys(marinsOptions).map(id => `<option value="${id}">${marinsOptions[id]}</option>`).join('')}
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">${t.amount} <span class="required-star">*</span></label>
            <input id="swal-montant" type="number" class="custom-input" placeholder="0.00" step="0.01" min="0" autocomplete="off" />
            <div class="input-helper">${t.amountPlaceholder}</div>
          </div>
          <div class="form-group">
            <label class="form-label">${t.date} <span class="required-star">*</span></label>
            <input id="swal-date" type="date" class="custom-input" value="${this.getTodayDate()}" />
          </div>
          <div class="form-group">
            <label class="form-label">${t.description}</label>
            <textarea id="swal-description" class="custom-textarea" placeholder="${t.descriptionPlaceholder}"></textarea>
          </div>
        </div>
      `,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: t.add,
      cancelButtonText: t.cancel,
      confirmButtonColor: '#10b981', // Vert pour ajouter
      cancelButtonColor: '#6b7280', // Gris pour annuler
      customClass: {
        popup: 'swal-wide-popup' // Classe pour potentiellement élargir le popup si besoin
      },
      preConfirm: () => {
        const marinId = (document.getElementById('swal-marin') as HTMLSelectElement).value;
        const montantStr = (document.getElementById('swal-montant') as HTMLInputElement).value;
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;
        const montant = parseFloat(montantStr);

        if (!marinId || !montantStr || !date) {
          Swal.showValidationMessage(t.requiredFields);
          return false;
        }
        if (isNaN(montant) || montant <= 0) {
          Swal.showValidationMessage(t.amountPositive);
          return false;
        }
        return {
          marinId,
          montant,
          date,
          description: (document.getElementById('swal-description') as HTMLTextAreaElement).value
        };
      }
    });

    if (formValues) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.SAVING'));
        const newAvance: Omit<Avance, 'id'> = {
          marinId: formValues.marinId,
          bateauId: this.selectedBoat!.id!,
          montant: formValues.montant,
          dateAvance: new Date(formValues.date),
          createdAt: new Date(),
          calculSalaireId: null // Explicitement null pour les nouvelles avances
        };
        // Ajouter la description seulement si elle n'est pas vide
        if (formValues.description && formValues.description.trim() !== '') {
          newAvance.description = formValues.description.trim();
        }
        await this.avanceService.addAvance(newAvance);
        // Pas besoin de recharger ici, le listener s'en charge
        this.alertService.success(this.translate.instant('AVANCES.SUCCESS_ADD'));
      } catch (error) {
        console.error("Erreur lors de l'ajout de l'avance:", error);
        this.alertService.error(); // Message d'erreur générique
      }
    }
  }


  async editAvance(avance: Avance): Promise<void> {
    const t = {
      title: this.translate.instant('AVANCES.EDIT_MODAL.TITLE'),
      amount: this.translate.instant('COMMON.AMOUNT_D_T'),
      date: this.translate.instant('COMMON.DATE'),
      description: this.translate.instant('COMMON.DESCRIPTION'),
      edit: this.translate.instant('FORM.EDIT'),
      cancel: this.translate.instant('FORM.CANCEL'),
      amountPositive: this.translate.instant('AVANCES.AMOUNT_POSITIVE'),
      requiredFields: this.translate.instant('FORM.REQUIRED_FIELDS')
    };

    const { value: formValues } = await Swal.fire({
      title: `<div style="text-align: center;">
                <div style="font-size: 1.5rem; font-weight: 700; color: #1f2937; margin-bottom: 0.5rem;">
                  ${t.title}
                </div>
              </div>`,
      html: `
        <div class="swal-custom-form">
          <div class="form-group">
            <label class="form-label">${t.amount} <span class="required-star">*</span></label>
            <input id="swal-montant" type="number" class="custom-input" value="${avance.montant}" step="0.01" min="0">
          </div>
          <div class="form-group">
            <label class="form-label">${t.date} <span class="required-star">*</span></label>
            <input id="swal-date" type="date" class="custom-input" value="${this.formatDate(avance.dateAvance)}">
          </div>
          <div class="form-group">
            <label class="form-label">${t.description}</label>
            <textarea id="swal-description" class="custom-textarea">${avance.description || ''}</textarea>
          </div>
        </div>`,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: t.edit,
      cancelButtonText: t.cancel,
      confirmButtonColor: '#f59e0b', // Orange pour modifier
      cancelButtonColor: '#6b7280',
      customClass: {
        popup: 'swal-wide-popup'
      },
      preConfirm: () => {
        const montantStr = (document.getElementById('swal-montant') as HTMLInputElement).value;
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;
        const montant = parseFloat(montantStr);

        if (!montantStr || !date) {
            Swal.showValidationMessage(t.requiredFields);
            return false;
        }
        if (isNaN(montant) || montant <= 0) {
            Swal.showValidationMessage(t.amountPositive);
            return false;
        }
        return {
            montant,
            date,
            description: (document.getElementById('swal-description') as HTMLTextAreaElement).value
        };
      }
    });

    if (formValues) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.UPDATING'));
        const updateData: Partial<Avance> = {
          montant: formValues.montant,
          dateAvance: new Date(formValues.date)
        };
        // Mettre à jour la description (ou la vider si vide)
        updateData.description = (formValues.description && formValues.description.trim() !== '') ? formValues.description.trim() : '';

        await this.avanceService.updateAvance(avance.id!, updateData);
        // Pas besoin de recharger ici
        this.alertService.success(this.translate.instant('AVANCES.SUCCESS_UPDATE'));
      } catch (error) {
        console.error('Erreur lors de la modification:', error);
        this.alertService.error();
      }
    }
  }

  async deleteAvance(avance: Avance): Promise<void> {
    const marinName = this.getMarinName(avance.marinId);
    // Utiliser la clé de traduction dédiée
    const itemName = this.translate.instant('AVANCES.DELETE_CONFIRM_ITEM', { amount: avance.montant, name: marinName });
    const confirmed = await this.alertService.confirmDelete(itemName);
    if (confirmed) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.DELETING'));
        await this.avanceService.deleteAvance(avance.id!);
        // Pas besoin de recharger ici
        this.alertService.toast(this.translate.instant('AVANCES.SUCCESS_DELETE'));
      } catch (error) {
        console.error('Erreur lors de la suppression:', error);
        this.alertService.error();
      }
    }
  }
}
EOF

# 2. src/app/avances/avances.component.scss
cat > /tmp/avances.component.scss << 'EOF'
// Styles globaux pour les popups Swal customisées
// Ces styles sont maintenant globaux car définis dans :host::ng-deep
// Assurez-vous qu'ils ne sont pas dupliqués ailleurs ou ajustez si nécessaire
:host::ng-deep {
  .swal-wide-popup {
    width: 600px !important; // Popup un peu plus large
    font-family: inherit; // Utiliser la police du reste de l'app
  }
  .swal-custom-form {
    text-align: left;
    padding: 1rem 0;
  }
  .form-group {
    margin-bottom: 1.25rem;
  }
  .form-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.625rem;
    font-weight: 600;
    color: #374151; // Gris foncé pour labels
    font-size: 0.9rem;
  }
  .required-star {
    color: #ef4444; // Rouge pour l'étoile obligatoire
    font-weight: 700;
    margin-left: 0.25rem;
    font-size: 1rem;
    line-height: 1;
  }
  .custom-input, .custom-textarea, .custom-select {
    width: 100%;
    padding: 0.75rem 0.875rem;
    border: 2px solid #e5e7eb; // Bordure grise claire
    border-radius: 0.5rem; // Coins arrondis
    font-size: 0.95rem;
    transition: all 0.3s;
    font-family: inherit;
    background: white;
    box-sizing: border-box; // S'assurer que padding et bordure sont inclus

    &:focus {
      outline: none;
      border-color: #10b981; // Vert au focus
      box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1); // Ombre légère au focus
    }
  }
  .custom-textarea {
    resize: vertical;
    min-height: 80px;
  }
  .input-helper {
    margin-top: 0.4rem;
    font-size: 0.8rem;
    color: #6b7280; // Gris pour texte d'aide
  }

  // Styles spécifiques pour la validation SweetAlert
  .swal2-validation-message {
    background-color: #fee2e2 !important; // Fond rouge clair
    color: #b91c1c !important; // Texte rouge foncé
    font-weight: 500;
    border-left: 4px solid #ef4444 !important; // Bordure gauche rouge
  }
}

// Styles spécifiques au composant Avances
.avances-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  gap: 1rem;
  flex-wrap: wrap;
}

.title {
  font-size: 2rem;
  font-weight: 700;
  color: #1f2937;
  margin: 0;
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 0.5rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;

  .icon {
    width: 20px;
    height: 20px;
  }
}

.btn-primary {
  background-color: #3b82f6; // Bleu standard
  color: white;

  &:hover {
    background-color: #2563eb; // Bleu plus foncé au survol
    transform: translateY(-2px);
    box-shadow: 0 4px 6px rgba(59, 130, 246, 0.3);
  }
}

.loading-spinner {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem;

  .spinner {
    width: 40px;
    height: 40px;
    margin-bottom: 1rem;
    border: 4px solid #f3f4f6;
    border-top-color: #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.no-data {
  text-align: center;
  padding: 3rem;
  color: #9ca3af;

  .no-data-icon {
    width: 64px;
    height: 64px;
    margin: 0 auto 1rem;
    opacity: 0.5;
  }

  p {
    font-size: 1.1rem;
  }
}

.marins-list {
  display: grid;
  gap: 1.5rem;
}

.marin-card {
  background: white;
  border-radius: 0.75rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.marin-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  background: linear-gradient(135deg, #f9fafb 0%, #f3f4f6 100%);
  border-bottom: 2px solid #e5e7eb;
}

.marin-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.marin-name {
  font-size: 1.25rem;
  font-weight: 700;
  color: #1f2937;
  margin: 0;
}

.fonction-badge {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 0.375rem;
  font-size: 0.875rem;
  font-weight: 600;
  text-transform: capitalize;
}

// Couleurs des badges de fonction
.fonction-capitaine { background-color: #fef3c7; color: #92400e; }
.fonction-second { background-color: #e0e7ff; color: #3730a3; }
.fonction-mecanicien { background-color: #ccfbf1; color: #115e59; }
.fonction-matelot { background-color: #f3e8ff; color: #6b21a8; }

.marin-total {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  .total-label { font-size: 0.875rem; color: #6b7280; font-weight: 500; }
  .total-amount { font-size: 1.5rem; font-weight: 700; color: #059669; } // Vert pour le total
}

.avances-list {
  padding: 0; // Enlever le padding pour que les items prennent toute la largeur
}

.avance-item {
  padding: 1rem 1.5rem; // Padding horizontal augmenté
  border-bottom: 1px solid #f3f4f6;
  transition: background-color 0.2s;

  &:hover { background-color: #f9fafb; }
  &:last-child { border-bottom: none; }
}

.avance-main {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
}

.avance-details {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;

  .avance-date-row {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-weight: 600;
    color: #1f2937;
    font-size: 0.95rem;

    .date-icon { width: 18px; height: 18px; color: #3b82f6; flex-shrink: 0; }
  }

  .avance-description {
    display: flex;
    align-items: flex-start;
    gap: 0.5rem;
    font-size: 0.875rem;
    color: #6b7280;
    line-height: 1.5;
    padding-left: 1.625rem; // Aligner avec l'icône de date
    .desc-icon { width: 16px; height: 16px; color: #9ca3af; flex-shrink: 0; margin-top: 0.125rem; }
    span { flex: 1; }
  }
}

.avance-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;

  .avance-amount {
    font-size: 1.125rem;
    font-weight: 700;
    color: #059669; // Vert pour le montant
    margin-right: 0.5rem;
    white-space: nowrap;
  }
}

.btn-icon {
  padding: 0.5rem;
  border: none;
  border-radius: 0.375rem;
  cursor: pointer;
  transition: all 0.2s;
  svg { width: 18px; height: 18px; }
}

.btn-warning {
  background-color: #fef3c7;
  color: #92400e;
  &:hover { background-color: #fde68a; }
}

.btn-danger {
  background-color: #fee2e2;
  color: #991b1b;
  &:hover { background-color: #fecaca; }
}

.no-avances {
  padding: 2rem;
  text-align: center;
  color: #9ca3af;
  .no-avances-icon { width: 48px; height: 48px; margin: 0 auto 0.5rem; opacity: 0.5; }
  p { margin: 0; }
}

.total-card {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%); // Dégradé vert
  color: white;
  padding: 1.5rem 2rem;
  border-radius: 0.75rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 2rem;
  box-shadow: 0 4px 6px rgba(16, 185, 129, 0.3); // Ombre verte

  .total-label-main { font-size: 1.25rem; font-weight: 600; }
  .total-amount-main { font-size: 2rem; font-weight: 700; }
}

// Responsive
@media (max-width: 768px) {
  .avances-container { padding: 1rem; }
  .title { font-size: 1.5rem; }
  .marin-header { flex-direction: column; align-items: flex-start; gap: 1rem; }
  .avance-main { flex-direction: column; align-items: flex-start; }
  .avance-actions { width: 100%; justify-content: space-between; }
  .total-card { flex-direction: column; gap: 0.5rem; text-align: center; }
}

// RTL Support pour les popups Swal
body.rtl {
  :host::ng-deep {
    .swal-custom-form, .form-label, .input-helper {
      text-align: right;
    }
    .required-star {
        margin-left: 0;
        margin-right: 0.25rem; // Espace à droite de l'étoile
    }
    .avance-description {
        padding-left: 0;
        padding-right: 1.625rem; // Padding à droite pour RTL
        .desc-icon {
            margin-left: 0.5rem; // Marge gauche pour l'icône en RTL
            margin-right: 0;
        }
    }
  }
}
EOF

# 3. src/assets/i18n/ar.json
cat > /tmp/ar.json << 'EOF'
{
  "FACTURES": {
    "TITLE": "الفواتير",
    "NOFACTURE": "لا توجد فواتير مسجلة لهذه الرحلة.",
    "ADD": "إضافة فاتورة"
  },
  "AUTH": { "WELCOME": "مرحباً بك", "SIGN_IN": "الرجاء تسجيل الدخول إلى حسابك", "SIGNUP": "املأ المعلومات للتسجيل", "CREATE_ACCOUNT": "إنشاء حساب جديد", "EMAIL": "البريد الإلكتروني", "PASSWORD": "كلمة المرور", "LOGIN": "تسجيل الدخول", "NO_ACCOUNT": "ليس لديك حساب؟ سجل الآن", "HAVE_ACCOUNT": "هل لديك حساب بالفعل؟ تسجيل الدخول" },
  "DASHBOARD": { "TITLE": "لوحة التحكم", "WELCOME": "مرحباً بك في لوحة التحكم", "ACTIVITIES": "الأنشطة", "RECENT_ACTIVITIES": "النشاطات الأخيرة", "NO_ACTIVITIES": "لا توجد أنشطة حديثة لعرضها", "TOTAL_BOATS": "إجمالي المراكب", "TOTAL_SAILORS": "إجمالي البحارة", "ACTIVE_BOATS": "المراكب النشطة", "MAINTENANCE": "تحت الصيانة", "BOAT_ADDED": "تمت إضافة المركب", "BOAT_UPDATED": "تم تحديث المركب", "SAILOR_ADDED": "تمت إضافة البحار", "SAILOR_UPDATED": "تم تحديث البحار", "TIME_AGO": { "NOW": "الآن", "MINUTES": "قبل {{minutes}} د", "HOURS": "قبل {{hours}} س", "DAYS": "قبل {{days}} ي" } },
  "MENU": { "HOME": "الرئيسية", "BOATS": "المراكب", "SORTIES": "الرحلات البحرية", "AVANCES": "السلف", "SALAIRES": "الرواتب", "VENTES": "المبيعات", "MOCK_DATA": "بيانات تجريبية", "SELECT_BOAT_FIRST": "اختر مركبًا أولاً للوصول" },
  "BOATS": { "TITLE": "إدارة المراكب", "BOAT": "مركب", "ADD_BOAT": "إضافة مركب", "EDIT_BOAT": "تعديل المركب", "DELETE": "حذف", "NAME": "اسم المركب", "REGISTRATION": "رقم التسجيل", "ENGINE_TYPE": "نوع المحرك", "POWER": "القوة (حصان)", "LENGTH": "الطول (متر)", "CAPACITY": "سعة الطاقم", "CONSTRUCTION_DATE": "تاريخ الصنع", "PORT": "ميناء الرسو", "STATUS": "الحالة", "ACTIVE": "نشط", "MAINTENANCE": "صيانة", "INACTIVE": "غير نشط", "NO_BOAT_SELECTED": "لم يتم اختيار أي مركب", "NO_BOAT_SELECTED_DETAILS": "الرجاء اختيار مركب أولاً من صفحة 'المراكب'.", "CLICK_TO_SELECT": "انقر للاختيار", "SELECTED_BOAT": "المركب الحالي", "SELECTED": "محدد", "SEARCH": "ابحث عن مركب بالاسم...", "ACTIONS": "الإجراءات", "VIEWCREW": "عرض الطاقم", "SELECT_INFO": "الرجاء اختيار مركب من القائمة للمتابعة.", "CHANGE_SELECTION": "تغيير المركب", "SUCCESS_ADD": "تمت إضافة المركب بنجاح.", "SUCCESS_UPDATE": "تم تحديث المركب بنجاح.", "SUCCESS_DELETE": "تم حذف المركب بنجاح.", "TOAST_SELECTED": "تم اختيار المركب \"{{boatName}}\".", "TOAST_SELECTION_CLEARED": "تم إلغاء اختيار المركب.", "BOAT_NAME_CONFIRM": "المركب \"{{boatName}}\"" },
  "SAILORS": { "TITLE": "البحارة", "ADD_SAILOR": "إضافة بحار", "ADD_NEW_SAILOR": "إضافة بحار جديد", "EDIT_SAILOR": "تعديل البحار", "FIRST_NAME": "الاسم", "LAST_NAME": "اللقب", "FUNCTION": "الوظيفة", "PART": "الحصة", "SELECT_FUNCTION": "اختر وظيفة", "SELECT_SAILOR": "اختر بحار", "PHONE": "الهاتف", "EMAIL": "البريد الإلكتروني", "ADDRESS": "العنوان", "BIRTH_DATE": "تاريخ الميلاد", "HIRE_DATE": "تاريخ التوظيف", "LICENSE_NUMBER": "رقم الرخصة", "CREW_OF": "طاقم مركب", "BACK": "رجوع", "ON_LEAVE": "في إجازة", "SUCCESS_ADD": "تمت إضافة البحار بنجاح.", "SUCCESS_UPDATE": "تم تحديث البحار بنجاح.", "SUCCESS_DELETE": "تم حذف البحار بنجاح.", "CAPITAINE": "قبطان", "SECOND": "مساعد قبطان", "MECANICIEN": "ميكانيكي", "MATELOT": "بحار", "PLACEHOLDER": { "LASTNAME": "أدخل اللقب", "FIRSTNAME": "أدخل الاسم", "PHONE": "رقم الهاتف" }, "FUNCTION_TYPE": { "CAPITAINE": "قبطان", "SECOND": "مساعد قبطان", "MECANICIEN": "ميكانيكي", "MATELOT": "بحار" } },
  "SORTIES": { "TITLE": "الرحلات البحرية", "ADD": "إضافة رحلة", "EDIT": "تعديل الرحلة", "DETAILSTITLE": "تفاصيل الرحلة", "DESTINATION": "الوجهة", "DATEDEPART": "تاريخ المغادرة", "DATERETOUR": "تاريخ العودة", "STATUT": "الحالة", "STATUS": { "EN-COURS": "جارية", "TERMINEE": "منتهية", "ANNULEE": "ملغاة", "ONGOING": "جارية", "COMPLETED": "منتهية", "CANCELLED": "ملغاة" }, "GENERALINFO": "معلومات عامة", "OBSERVATIONS": "ملاحظات", "MANAGE": "إدارة الرحلة", "NOSORTIES": "لا توجد رحلات مسجلة لهذا المركب.", "SELECTSORTIES": "تحديد الرحلات البحرية", "SUCCESS_ADD": "تمت إضافة الرحلة بنجاح.", "SUCCESS_UPDATE": "تم تعديل الرحلة بنجاح.", "SUCCESS_DELETE": "تم حذف الرحلة بنجاح." },
  "EXPENSES": { "TITLE": "المصاريف", "ADD": "إضافة مصروف", "EDIT": "تعديل المصروف", "TYPE": "نوع المصروف", "AMOUNT": "المبلغ", "DATE": "التاريخ", "DESCRIPTION": "الوصف", "NOEXPENSE": "لا توجد مصاريف مسجلة لهذه الرحلة.", "TYPES": { "FUEL": "وقود", "ICE": "ثلج", "OIL_CHANGE": "تغيير زيت", "CREW_CNSS": "الضمان الاجتماعي", "CREW_BONUS": "مكافأة الطاقم", "FOOD": "طعام", "VMS": "VMS", "MISC": "متنوع" }, "SUCCESS_ADD": "تمت إضافة المصروف بنجاح", "SUCCESS_UPDATE": "تم تحديث المصروف بنجاح" },
  "POINTAGE": { "TITLE": "تسجيل حضور الطاقم", "CREW": "إدارة الحضور", "PRESENT": "حاضر", "ABSENT": "غائب", "NOCREW": "لا يوجد بحارة معينون لهذا المركب.", "OBSERVATIONS": "ملاحظات", "ADDOBS": "إضافة ملاحظة...", "TOTAL": "المجموع", "SUCCESS_PRESENCE": "تم تسجيل الحضور", "SUCCESS_ABSENCE": "تم تسجيل الغياب", "SUCCESS_OBS": "تم تحديث الملاحظات", "ERROR_ADD": "خطأ أثناء تسجيل الحضور" },
  "AVANCES": { "TITLE": "السلف على الراتب", "ADD": "إضافة سلفة", "EDIT": "تعديل السلفة", "TOTAL": "مجموع السلف", "TOTAL_GENERAL": "المجموع الكلي للسلف", "NO_AVANCES": "لا توجد سلف لهذا البحار.", "SUCCESS_ADD": "تمت إضافة السلفة بنجاح.", "SUCCESS_UPDATE": "تم تحديث السلفة بنجاح.", "SUCCESS_DELETE": "تم حذف السلفة بنجاح.", "AMOUNT_POSITIVE": "يجب أن يكون المبلغ رقمًا موجبًا.", "ADD_MODAL": { "TITLE": "إضافة سلفة جديدة" }, "EDIT_MODAL": { "TITLE": "تعديل السلفة" }, "DELETE_CONFIRM_ITEM": "سلفة بقيمة {{amount}} دينار لـ {{name}}" },
  "SALAIRES": { "AUTOCALCMESSAGE": "يتم حساب الرواتب تلقائياً عند كل تحديث للبيانات المالية", "TITLE": "حساب الرواتب", "CALCULER": "حساب الرواتب", "REVENU_TOTAL": "الإيراد الكلي", "TOTAL_DEPENSES": "مجموع المصاريف", "BENEFICE_NET": "الربح الصافي", "PART_PROPRIETAIRE": "حصة المالك (50%)", "PART_EQUIPAGE": "حصة الطاقم (50%)", "DEDUCTIONS": "الخصومات", "NUITS": "ليالي", "MARINS": "بحارة", "MONTANT_A_PARTAGER": "المبلغ الصافي للمشاركة", "DETAILS_PAR_MARIN": "التفاصيل لكل بحار", "SALAIRE_BASE": "الراتب الأساسي", "PRIME_NUITS": "علاوة الليالي", "SALAIRE_NET": "الراتب الصافي", "DEJA_PAYE": "مدفوع مسبقًا", "RESTE_A_PAYER": "المتبقي للدفع", "PAYER": "دفع", "PAYE": "مدفوع", "ERROR_NO_SORTIE": "الرجاء اختيار رحلة واحدة على الأقل", "ERROR_NO_PARTS": "مجموع حصص البحارة هو 0. الرجاء تحديد الحصص في قسم 'البحارة'.", "CALCUL_SUCCESS_TITLE": "اكتمل الحساب!", "PAYMENT_SUCCESS": "تم تسجيل الدفعة!", "PAYMENT_MODAL_TITLE": "دفعة لـ {{name}}", "PAYMENT_MODAL_LABEL": "المبلغ للدفع (المتبقي: {{amount}} دينار)", "PAYMENT_MODAL": { "ERROR_POSITIVE": "يجب أن يكون المبلغ موجباً.", "ERROR_EXCEED": "لا يمكن أن يتجاوز المبلغ الرصيد المتبقي." }, "TABS": { "OPEN_TRIPS": "الرحلات المفتوحة", "HISTORY": "السجل", "CALCULATED_TRIPS": "الرحلات المحسوبة" }, "NO_OPEN_TRIPS": "لا توجد رحلات منتهية بانتظار الحساب.", "NO_CALCULATED_TRIPS": "لم يتم إجراء أي حسابات رواتب بعد.", "HISTORY": { "MODAL_TITLE": "تفاصيل الحساب لـ : {{destinations}}", "NO_DATA_FOUND_TITLE": "التفاصيل غير موجودة", "NO_DATA_FOUND_TEXT": "لم يتم العثور على تفاصيل هذا الحساب. قد يكون حسابًا قديمًا. هل تريد وضع علامة 'مفتوح' على هذه الرحلة لإعادة حسابها؟", "RECALCULATE_BTN": "إعادة الحساب", "MOVED_FOR_RECALC": "تم نقل الرحلة إلى 'الرحلات المفتوحة' لإعادة حسابها." }, "RESULTS": { "TITLE": "نتائج الحساب", "CLOSE": "إغلاق", "FINANCIAL_SUMMARY": "ملخص مالي", "PROFIT_SHARING": "تقاسم الأرباح" }, "DETAILS_MODAL": { "REVENUE_TITLE": "تفاصيل الإيرادات", "EXPENSE_TITLE": "تفاصيل المصاريف", "INVOICE_NUM": "رقم الفاتورة", "CLIENT": "العميل" } },
  "SALAIRES_HISTORY": { "CALCULATED_ON": "تم الحساب في" },
  "VENTES": { "TITLE": "إدارة المبيعات", "ADD_INVOICE": "فاتورة جديدة", "ADD_INVOICE_FOR_TRIP": "إضافة فاتورة لهذه الرحلة", "NO_INVOICES_FOR_TRIP": "لا توجد فواتير مسجلة لهذه الرحلة", "TRIP_TOTAL": "مجموع مبيعات الرحلة", "GENERAL_TOTAL": "المجموع العام للمبيعات", "NO_TRIPS_AVAILABLE": "لا توجد رحلات بحرية متاحة.", "SUCCESS_ADD": "تمت إضافة الفاتورة بنجاح!", "SUCCESS_UPDATE": "تم تعديل الفاتورة بنجاح!", "SUCCESS_DELETE": "تم حذف الفاتورة بنجاح.", "DELETE_CONFIRM_ITEM": "الفاتورة رقم {{number}} ({{amount}} دينار)", "ADD_MODAL": { "TITLE": "فاتورة مبيعات جديدة", "SELECT_TRIP": "اختر رحلة" }, "EDIT_MODAL": { "TITLE": "تعديل الفاتورة" }, "DETAILS_MODAL": { "INVOICE_NUM": "رقم الفاتورة", "CLIENT": "العميل" } },
  "FORM": { "ADD": "إضافة", "EDIT": "تعديل", "DELETE": "حذف", "CANCEL": "إلغاء", "SAVE": "حفظ", "REQUIRED": "هذا الحقل مطلوب.", "REQUIRED_FIELDS": "الرجاء ملء جميع الحقول المطلوبة.", "INVALID_PHONE": "رقم هاتف غير صالح.", "INVALID_EMAIL": "بريد إلكتروني غير صالح." },
  "MESSAGES": { "LOADING": "جاري التحميل...", "SAVING": "جاري الحفظ...", "UPDATING": "جاري التعديل...", "DELETING": "جاري الحذف...", "CALCULATING": "جاري الحساب...", "LOADING_DETAILS": "جاري تحميل التفاصيل...", "ADDING_SAILOR": "جاري إضافة البحار...", "SUCCESS": "تمت العملية بنجاح!", "ERROR_TITLE": "خطأ", "WARNING_TITLE": "تنبيه", "ERROR_GENERIC": "حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى.", "AREYOUSURE": "هل أنت متأكد؟", "CONFIRMDELETEMESSAGE": "أنت على وشك حذف", "IRREVERSIBLE": "هذا الإجراء لا يمكن التراجع عنه.", "SAILOR_ADDED_SUCCESS": "تمت إضافة البحار {{name}} بنجاح." },
  "LANGUAGE": { "AR": "العربية", "FR": "الفرنسية", "EN": "الإنجليزية" },
  "COMMON": { "UNKNOWN": "غير معروف", "AMOUNT": "المبلغ", "AMOUNT_D_T": "المبلغ (دينار)", "AMOUNT_IN_TND": "المبلغ بالدينار التونسي", "DATE": "التاريخ", "OK": "موافق", "DESCRIPTION": "الوصف", "DETAILS": "التفاصيل", "DETAILS_OPTIONAL": "الوصف (اختياري)", "VIEW_DETAILS": "عرض التفاصيل" },
  "MOCK_DATA": { "TITLE": "🎲 مولد البيانات الوهمية", "SUBTITLE": "أنشئ بيانات اختبار كاملة لتطبيقك بسرعة.", "ITEM_1": "✓ 2 مراكب صيد", "ITEM_2": "✓ عدة بحارة بحصص مختلفة", "ITEM_3": "✓ رحلات بحرية متعددة", "ITEM_4": "✓ مصاريف ومبيعات وسلف مرتبطة", "GENERATE_BUTTON": "إنشاء البيانات", "GENERATING_BUTTON": "جاري الإنشاء...", "CONFIRM_TITLE": "هل تريد إنشاء بيانات وهمية؟", "CONFIRM_TEXT": "سيقوم هذا الإجراء أولاً بحذف جميع البيانات الحالية قبل إنشاء سجلات اختبار جديدة.", "CONFIRM_BUTTON": "نعم، أنشئ", "LOADING_TITLE": "جاري الإنشاء...", "LOADING_TEXT": "الرجاء الانتظار أثناء إنشاء البيانات.", "SUCCESS_TITLE": "نجاح!", "SUCCESS_TEXT": "تم إنشاء بيانات الاختبار بنجاح.", "ERROR_TITLE": "خطأ" }
}
EOF

# 4. src/assets/i18n/en.json
cat > /tmp/en.json << 'EOF'
{
  "FACTURES": {
    "TITLE": "Invoices",
    "NOFACTURE": "No invoices recorded for this trip.",
    "ADD": "Add Invoice"
  },
  "AUTH": { "WELCOME": "Welcome", "SIGN_IN": "Please sign in to your account", "SIGNUP": "Fill in the information to sign up", "CREATE_ACCOUNT": "Create an Account", "EMAIL": "Email Address", "PASSWORD": "Password", "LOGIN": "Sign In", "NO_ACCOUNT": "Don't have an account? Sign Up", "HAVE_ACCOUNT": "Already have an account? Sign In" },
  "DASHBOARD": { "TITLE": "Dashboard", "WELCOME": "Welcome to your dashboard", "ACTIVITIES": "Activities", "RECENT_ACTIVITIES": "Recent Activity", "NO_ACTIVITIES": "No recent activity to display", "TOTAL_BOATS": "Total Boats", "TOTAL_SAILORS": "Total Sailors", "ACTIVE_BOATS": "Active Boats", "MAINTENANCE": "In Maintenance", "BOAT_ADDED": "Boat added", "BOAT_UPDATED": "Boat updated", "SAILOR_ADDED": "Sailor added", "SAILOR_UPDATED": "Sailor updated", "TIME_AGO": { "NOW": "Just now", "MINUTES": "{{minutes}} min ago", "HOURS": "{{hours}}h ago", "DAYS": "{{days}}d ago" } },
  "MENU": { "HOME": "Home", "BOATS": "Boats", "SORTIES": "Sea Trips", "AVANCES": "Advances", "SALAIRES": "Salaries", "VENTES": "Sales", "MOCK_DATA": "Mock Data", "SELECT_BOAT_FIRST": "Select a boat first to access this section" },
  "BOATS": { "TITLE": "Boat Management", "BOAT": "Boat", "ADD_BOAT": "Add a Boat", "EDIT_BOAT": "Edit Boat", "DELETE": "Delete", "NAME": "Boat Name", "REGISTRATION": "Registration", "ENGINE_TYPE": "Engine Type", "POWER": "Power (HP)", "LENGTH": "Length (m)", "CAPACITY": "Crew Capacity", "CONSTRUCTION_DATE": "Construction Date", "PORT": "Home Port", "STATUS": "Status", "ACTIVE": "Active", "MAINTENANCE": "Maintenance", "INACTIVE": "Inactive", "NO_BOAT_SELECTED": "No boat is selected", "NO_BOAT_SELECTED_DETAILS": "Please select a boat from the 'Boats' page first.", "CLICK_TO_SELECT": "Click to select one", "SELECTED_BOAT": "Active Boat", "SELECTED": "Selected", "SEARCH": "Search for a boat by name...", "ACTIONS": "Actions", "VIEWCREW": "View Crew", "SELECT_INFO": "Please select a boat from the list to continue.", "CHANGE_SELECTION": "Change Boat", "SUCCESS_ADD": "Boat added successfully.", "SUCCESS_UPDATE": "Boat updated successfully.", "SUCCESS_DELETE": "Boat deleted successfully.", "TOAST_SELECTED": "Boat \"{{boatName}}\" selected.", "TOAST_SELECTION_CLEARED": "Boat selection cleared.", "BOAT_NAME_CONFIRM": "the boat \"{{boatName}}\"" },
  "SAILORS": { "TITLE": "Sailors", "ADD_SAILOR": "Add Sailor", "ADD_NEW_SAILOR": "Add a New Sailor", "EDIT_SAILOR": "Edit Sailor", "FIRST_NAME": "First Name", "LAST_NAME": "Last Name", "FUNCTION": "Function", "PART": "Share", "SELECT_FUNCTION": "Select a function", "SELECT_SAILOR": "Select a sailor", "PHONE": "Phone", "EMAIL": "Email", "ADDRESS": "Address", "BIRTH_DATE": "Date of Birth", "HIRE_DATE": "Hire Date", "LICENSE_NUMBER": "License Number", "CREW_OF": "Crew of boat", "BACK": "Back", "ON_LEAVE": "On Leave", "SUCCESS_ADD": "Sailor added successfully.", "SUCCESS_UPDATE": "Sailor updated successfully.", "SUCCESS_DELETE": "Sailor deleted successfully.", "CAPITAINE": "Captain", "SECOND": "Second-in-command", "MECANICIEN": "Mechanic", "MATELOT": "Sailor", "PLACEHOLDER": { "LASTNAME": "Enter last name", "FIRSTNAME": "Enter first name", "PHONE": "Phone number" }, "FUNCTION_TYPE": { "CAPITAINE": "Captain", "SECOND": "Second-in-command", "MECANICIEN": "Mechanic", "MATELOT": "Sailor" } },
  "SORTIES": { "TITLE": "Sea Trips", "ADD": "Add Trip", "EDIT": "Edit Trip", "DETAILSTITLE": "Trip Details", "DESTINATION": "Destination", "DATEDEPART": "Departure Date", "DATERETOUR": "Return Date", "STATUT": "Status", "STATUS": { "EN-COURS": "Ongoing", "TERMINEE": "Completed", "ANNULEE": "Cancelled", "ONGOING": "Ongoing", "COMPLETED": "Completed", "CANCELLED": "Cancelled" }, "GENERALINFO": "General Information", "OBSERVATIONS": "Observations", "MANAGE": "Manage Trip", "NOSORTIES": "No trips recorded for this boat.", "SELECTSORTIES": "Select Sea Trips", "SUCCESS_ADD": "Trip added successfully.", "SUCCESS_UPDATE": "Trip updated successfully.", "SUCCESS_DELETE": "Trip deleted successfully." },
  "EXPENSES": { "TITLE": "Expenses", "ADD": "Add Expense", "EDIT": "Edit Expense", "TYPE": "Expense Type", "AMOUNT": "Amount", "DATE": "Date", "DESCRIPTION": "Description", "NOEXPENSE": "No expenses recorded for this trip.", "TYPES": { "FUEL": "Fuel", "ICE": "Ice", "OIL_CHANGE": "Oil Change", "CREW_CNSS": "Crew CNSS", "CREW_BONUS": "Crew Bonus", "FOOD": "Food", "VMS": "VMS", "MISC": "Miscellaneous" }, "SUCCESS_ADD": "Expense added successfully", "SUCCESS_UPDATE": "Expense updated successfully" },
  "POINTAGE": { "TITLE": "Crew Attendance", "CREW": "Manage Attendance", "PRESENT": "Present", "ABSENT": "Absent", "NOCREW": "No sailors are assigned to this boat.", "OBSERVATIONS": "Observations", "ADDOBS": "Add an observation...", "TOTAL": "Total", "SUCCESS_PRESENCE": "Presence recorded", "SUCCESS_ABSENCE": "Absence recorded", "SUCCESS_OBS": "Observations updated", "ERROR_ADD": "Error while saving attendance" },
  "AVANCES": { "TITLE": "Salary Advances", "ADD": "Add Advance", "EDIT": "Edit Advance", "TOTAL": "Total Advances", "TOTAL_GENERAL": "Grand Total of Advances", "NO_AVANCES": "No advances for this sailor.", "SUCCESS_ADD": "Advance added successfully.", "SUCCESS_UPDATE": "Advance updated successfully.", "SUCCESS_DELETE": "Advance deleted successfully.", "AMOUNT_POSITIVE": "Amount must be a positive number.", "ADD_MODAL": { "TITLE": "Add a new advance" }, "EDIT_MODAL": { "TITLE": "Edit advance" }, "DELETE_CONFIRM_ITEM": "the advance of {{amount}} TND for {{name}}" },
  "SALAIRES": { "AUTOCALCMESSAGE": "Salary calculation is performed automatically with each financial data update", "TITLE": "Salary Calculation", "CALCULER": "Calculate Salaries", "REVENU_TOTAL": "Total Revenue", "TOTAL_DEPENSES": "Total Expenses", "BENEFICE_NET": "Net Profit", "PART_PROPRIETAIRE": "Owner's Share (50%)", "PART_EQUIPAGE": "Crew's Share (50%)", "DEDUCTIONS": "Deductions", "NUITS": "Nights", "MARINS": "Sailors", "MONTANT_A_PARTAGER": "Net Amount to Share", "DETAILS_PAR_MARIN": "Details per Sailor", "SALAIRE_BASE": "Base Salary", "PRIME_NUITS": "Night Bonus", "SALAIRE_NET": "Net Salary", "DEJA_PAYE": "Already Paid", "RESTE_A_PAYER": "Remaining to be Paid", "PAYER": "Pay", "PAYE": "Paid", "ERROR_NO_SORTIE": "Please select at least one trip", "ERROR_NO_PARTS": "The sum of sailor shares is 0. Please define shares in the 'Sailors' section.", "CALCUL_SUCCESS_TITLE": "Calculation complete!", "PAYMENT_SUCCESS": "Payment recorded!", "PAYMENT_MODAL_TITLE": "Payment for {{name}}", "PAYMENT_MODAL_LABEL": "Amount to pay (Remaining: {{amount}} TND)", "PAYMENT_MODAL": { "ERROR_POSITIVE": "Amount must be positive.", "ERROR_EXCEED": "Amount cannot exceed the remaining balance." }, "TABS": { "OPEN_TRIPS": "Open Trips", "HISTORY": "History", "CALCULATED_TRIPS": "Calculated Trips" }, "NO_OPEN_TRIPS": "No completed trips are pending calculation.", "NO_CALCULATED_TRIPS": "No salary calculations have been performed yet.", "HISTORY": { "MODAL_TITLE": "Calculation Details for: {{destinations}}", "NO_DATA_FOUND_TITLE": "Details Not Found", "NO_DATA_FOUND_TEXT": "Details for this calculation were not found. This might be an old calculation. Do you want to mark this trip as 'open' to recalculate it?", "RECALCULATE_BTN": "Recalculate", "MOVED_FOR_RECALC": "The trip has been moved to the 'Open Trips' tab for recalculation." }, "RESULTS": { "TITLE": "Calculation Results", "CLOSE": "Close", "FINANCIAL_SUMMARY": "Financial Summary", "PROFIT_SHARING": "Profit Sharing" }, "DETAILS_MODAL": { "REVENUE_TITLE": "Revenue Details", "EXPENSE_TITLE": "Expense Details", "INVOICE_NUM": "Invoice No.", "CLIENT": "Client" } },
  "SALAIRES_HISTORY": { "CALCULATED_ON": "Calculated on" },
  "VENTES": { "TITLE": "Sales Management", "ADD_INVOICE": "New Invoice", "ADD_INVOICE_FOR_TRIP": "Add an invoice for this trip", "NO_INVOICES_FOR_TRIP": "No invoices recorded for this trip", "TRIP_TOTAL": "Total sales for the trip", "GENERAL_TOTAL": "Grand total of sales", "NO_TRIPS_AVAILABLE": "No sea trips are available.", "SUCCESS_ADD": "Invoice added successfully!", "SUCCESS_UPDATE": "Invoice updated successfully!", "SUCCESS_DELETE": "Invoice deleted successfully.", "DELETE_CONFIRM_ITEM": "invoice {{number}} ({{amount}} TND)", "ADD_MODAL": { "TITLE": "New Sales Invoice", "SELECT_TRIP": "Select a trip" }, "EDIT_MODAL": { "TITLE": "Edit Invoice" }, "DETAILS_MODAL": { "INVOICE_NUM": "Invoice No.", "CLIENT": "Client" } },
  "FORM": { "ADD": "Add", "EDIT": "Edit", "DELETE": "Delete", "CANCEL": "Cancel", "SAVE": "Save", "REQUIRED": "This field is required.", "REQUIRED_FIELDS": "Please fill in all required fields.", "INVALID_PHONE": "Invalid phone number.", "INVALID_EMAIL": "Invalid email address." },
  "MESSAGES": { "LOADING": "Loading...", "SAVING": "Saving...", "UPDATING": "Updating...", "DELETING": "Deleting...", "CALCULATING": "Calculating...", "LOADING_DETAILS": "Loading details...", "ADDING_SAILOR": "Adding sailor...", "SUCCESS": "Operation successful!", "ERROR_TITLE": "Error", "WARNING_TITLE": "Warning", "ERROR_GENERIC": "An unexpected error occurred. Please try again.", "AREYOUSURE": "Are you sure?", "CONFIRMDELETEMESSAGE": "You are about to delete", "IRREVERSIBLE": "This action cannot be undone.", "SAILOR_ADDED_SUCCESS": "Sailor {{name}} has been added successfully." },
  "LANGUAGE": { "AR": "Arabic", "FR": "French", "EN": "English" },
  "COMMON": { "UNKNOWN": "Unknown", "AMOUNT": "Amount", "AMOUNT_D_T": "Amount (TND)", "AMOUNT_IN_TND": "Amount in Tunisian Dinar", "DATE": "Date", "OK": "OK", "DESCRIPTION": "Description", "DETAILS": "Details", "DETAILS_OPTIONAL": "Description (optional)", "VIEW_DETAILS": "View Details" },
  "MOCK_DATA": { "TITLE": "🎲 Mock Data Generator", "SUBTITLE": "Quickly create complete test data for your application.", "ITEM_1": "✓ 2 fishing boats", "ITEM_2": "✓ Several sailors with different shares", "ITEM_3": "✓ Multiple sea trips", "ITEM_4": "✓ Associated expenses, sales, and advances", "GENERATE_BUTTON": "Generate Data", "GENERATING_BUTTON": "Generating...", "CONFIRM_TITLE": "Generate mock data?", "CONFIRM_TEXT": "This will first delete all existing data before creating new test records.", "CONFIRM_BUTTON": "Yes, generate", "LOADING_TITLE": "Generating...", "LOADING_TEXT": "Please wait while the data is being created.", "SUCCESS_TITLE": "Success!", "SUCCESS_TEXT": "Mock data has been generated successfully.", "ERROR_TITLE": "Error" }
}
EOF

# 5. src/assets/i18n/fr.json
cat > /tmp/fr.json << 'EOF'
{
  "FACTURES": {
    "TITLE": "Factures",
    "NOFACTURE": "Aucune facture enregistrée pour cette sortie.",
    "ADD": "Ajouter une facture"
  },
  "AUTH": { "WELCOME": "Bienvenue", "SIGN_IN": "Veuillez vous connecter à votre compte", "SIGNUP": "Remplissez les informations pour vous inscrire", "CREATE_ACCOUNT": "Créer un compte", "EMAIL": "Adresse e-mail", "PASSWORD": "Mot de passe", "LOGIN": "Se connecter", "NO_ACCOUNT": "Vous n'avez pas de compte ? S'inscrire", "HAVE_ACCOUNT": "Vous avez déjà un compte ? Se connecter" },
  "DASHBOARD": { "TITLE": "Tableau de bord", "WELCOME": "Bienvenue sur votre tableau de bord", "ACTIVITIES": "Activités", "RECENT_ACTIVITIES": "Activité Récente", "NO_ACTIVITIES": "Aucune activité récente à afficher", "TOTAL_BOATS": "Bateaux au total", "TOTAL_SAILORS": "Marins au total", "ACTIVE_BOATS": "Bateaux Actifs", "MAINTENANCE": "En Maintenance", "BOAT_ADDED": "Bateau ajouté", "BOAT_UPDATED": "Bateau mis à jour", "SAILOR_ADDED": "Marin ajouté", "SAILOR_UPDATED": "Marin mis à jour", "TIME_AGO": { "NOW": "À l'instant", "MINUTES": "Il y a {{minutes}} min", "HOURS": "Il y a {{hours}}h", "DAYS": "Il y a {{days}}j" } },
  "MENU": { "HOME": "Accueil", "BOATS": "Bateaux", "SORTIES": "Sorties en mer", "AVANCES": "Avances", "SALAIRES": "Salaires", "VENTES": "Ventes", "MOCK_DATA": "Données Test", "SELECT_BOAT_FIRST": "Sélectionnez un bateau pour accéder à cette section" },
  "BOATS": { "TITLE": "Gestion des Bateaux", "BOAT": "Bateau", "ADD_BOAT": "Ajouter un Bateau", "EDIT_BOAT": "Modifier le Bateau", "DELETE": "Supprimer", "NAME": "Nom du bateau", "REGISTRATION": "Immatriculation", "ENGINE_TYPE": "Type de moteur", "POWER": "Puissance (CV)", "LENGTH": "Longueur (m)", "CAPACITY": "Capacité équipage", "CONSTRUCTION_DATE": "Date de construction", "PORT": "Port d'attache", "STATUS": "Statut", "ACTIVE": "Actif", "MAINTENANCE": "Maintenance", "INACTIVE": "Inactif", "NO_BOAT_SELECTED": "Aucun bateau n'est sélectionné", "NO_BOAT_SELECTED_DETAILS": "Veuillez d'abord sélectionner un bateau depuis la page 'Bateaux'.", "CLICK_TO_SELECT": "Cliquez pour en sélectionner un", "SELECTED_BOAT": "Bateau Actif", "SELECTED": "Sélectionné", "SEARCH": "Rechercher un bateau par nom...", "ACTIONS": "Actions", "VIEWCREW": "Voir l'équipage", "SELECT_INFO": "Veuillez sélectionner un bateau dans la liste pour continuer.", "CHANGE_SELECTION": "Changer de bateau", "SUCCESS_ADD": "Bateau ajouté avec succès.", "SUCCESS_UPDATE": "Bateau mis à jour avec succès.", "SUCCESS_DELETE": "Bateau supprimé avec succès.", "TOAST_SELECTED": "Bateau \"{{boatName}}\" sélectionné.", "TOAST_SELECTION_CLEARED": "Sélection du bateau annulée.", "BOAT_NAME_CONFIRM": "le bateau \"{{boatName}}\"" },
  "SAILORS": { "TITLE": "Marins", "ADD_SAILOR": "Ajouter un Marin", "ADD_NEW_SAILOR": "Ajouter un nouveau marin", "EDIT_SAILOR": "Modifier le Marin", "FIRST_NAME": "Prénom", "LAST_NAME": "Nom", "FUNCTION": "Fonction", "PART": "Part", "SELECT_FUNCTION": "Sélectionner une fonction", "SELECT_SAILOR": "Sélectionner un marin", "PHONE": "Téléphone", "EMAIL": "Email", "ADDRESS": "Adresse", "BIRTH_DATE": "Date de naissance", "HIRE_DATE": "Date d'embauche", "LICENSE_NUMBER": "Numéro de permis", "CREW_OF": "Équipage du bateau", "BACK": "Retour", "ON_LEAVE": "En congé", "SUCCESS_ADD": "Marin ajouté avec succès.", "SUCCESS_UPDATE": "Marin mis à jour avec succès.", "SUCCESS_DELETE": "Marin supprimé avec succès.", "CAPITAINE": "Capitaine", "SECOND": "Second", "MECANICIEN": "Mécanicien", "MATELOT": "Matelot", "PLACEHOLDER": { "LASTNAME": "Entrez le nom", "FIRSTNAME": "Entrez le prénom", "PHONE": "Numéro de téléphone" }, "FUNCTION_TYPE": { "CAPITAINE": "Capitaine", "SECOND": "Second", "MECANICIEN": "Mécanicien", "MATELOT": "Matelot" } },
  "SORTIES": { "TITLE": "Sorties en mer", "ADD": "Ajouter une Sortie", "EDIT": "Modifier la Sortie", "DETAILSTITLE": "Détails de la Sortie", "DESTINATION": "Destination", "DATEDEPART": "Date de départ", "DATERETOUR": "Date de retour", "STATUT": "Statut", "STATUS": { "EN-COURS": "En cours", "TERMINEE": "Terminée", "ANNULEE": "Annulée", "ONGOING": "En cours", "COMPLETED": "Terminée", "CANCELLED": "Annulée" }, "GENERALINFO": "Informations Générales", "OBSERVATIONS": "Observations", "MANAGE": "Gérer la sortie", "NOSORTIES": "Aucune sortie enregistrée pour ce bateau.", "SELECTSORTIES": "Sélectionner les sorties en mer", "SUCCESS_ADD": "Sortie ajoutée avec succès.", "SUCCESS_UPDATE": "Sortie modifiée avec succès.", "SUCCESS_DELETE": "Sortie supprimée avec succès." },
  "EXPENSES": { "TITLE": "Dépenses", "ADD": "Ajouter une Dépense", "EDIT": "Modifier la Dépense", "TYPE": "Type de dépense", "AMOUNT": "Montant", "DATE": "Date", "DESCRIPTION": "Description", "NOEXPENSE": "Aucune dépense enregistrée pour cette sortie.", "TYPES": { "FUEL": "Carburant", "ICE": "Glace", "OIL_CHANGE": "Vidange", "CREW_CNSS": "CNSS Équipage", "CREW_BONUS": "Prime Équipage", "FOOD": "Alimentation", "VMS": "VMS", "MISC": "Divers" }, "SUCCESS_ADD": "Dépense ajoutée avec succès", "SUCCESS_UPDATE": "Dépense mise à jour avec succès" },
  "POINTAGE": { "TITLE": "Pointage de l'Équipage", "CREW": "Gérer le pointage", "PRESENT": "Présent", "ABSENT": "Absent", "NOCREW": "Aucun marin n'est affecté à ce bateau.", "OBSERVATIONS": "Observations", "ADDOBS": "Ajouter une observation...", "TOTAL": "Total", "SUCCESS_PRESENCE": "Présence enregistrée", "SUCCESS_ABSENCE": "Absence enregistrée", "SUCCESS_OBS": "Observations mises à jour", "ERROR_ADD": "Erreur lors de l'enregistrement du pointage" },
  "AVANCES": { "TITLE": "Avances sur Salaire", "ADD": "Ajouter une Avance", "EDIT": "Modifier l'Avance", "TOTAL": "Total Avances", "TOTAL_GENERAL": "Total Général des Avances", "NO_AVANCES": "Aucune avance pour ce marin.", "SUCCESS_ADD": "Avance ajoutée avec succès.", "SUCCESS_UPDATE": "Avance mise à jour avec succès.", "SUCCESS_DELETE": "Avance supprimée avec succès.", "AMOUNT_POSITIVE": "Le montant doit être un nombre positif.", "ADD_MODAL": { "TITLE": "Ajouter une nouvelle avance" }, "EDIT_MODAL": { "TITLE": "Modifier l'avance" }, "DELETE_CONFIRM_ITEM": "l'avance de {{amount}} DT pour {{name}}" },
  "SALAIRES": { "AUTOCALCMESSAGE": "Le calcul des salaires se fait automatiquement à chaque mise à jour des données financières", "TITLE": "Calcul des Salaires", "CALCULER": "Calculer les Salaires", "REVENU_TOTAL": "Revenu Total", "TOTAL_DEPENSES": "Total des Dépenses", "BENEFICE_NET": "Bénéfice Net", "PART_PROPRIETAIRE": "Part Propriétaire (50%)", "PART_EQUIPAGE": "Part Équipage (50%)", "DEDUCTIONS": "Déductions", "NUITS": "Nuits", "MARINS": "Marins", "MONTANT_A_PARTAGER": "Montant Net à Partager", "DETAILS_PAR_MARIN": "Détails par Marin", "SALAIRE_BASE": "Salaire de Base", "PRIME_NUITS": "Prime de Nuits", "SALAIRE_NET": "Salaire Net", "DEJA_PAYE": "Déjà Payé", "RESTE_A_PAYER": "Reste à Payer", "PAYER": "Payer", "PAYE": "Payé", "ERROR_NO_SORTIE": "Veuillez sélectionner au moins une sortie", "ERROR_NO_PARTS": "La somme des parts des marins est de 0. Veuillez définir les parts dans la section 'Marins'.", "CALCUL_SUCCESS_TITLE": "Calcul terminé !", "PAYMENT_SUCCESS": "Paiement enregistré!", "PAYMENT_MODAL_TITLE": "Paiement pour {{name}}", "PAYMENT_MODAL_LABEL": "Montant à payer (Reste: {{amount}} DT)", "PAYMENT_MODAL": { "ERROR_POSITIVE": "Le montant doit être positif.", "ERROR_EXCEED": "Le montant ne peut pas dépasser le reste à payer." }, "TABS": { "OPEN_TRIPS": "Voyages Ouverts", "HISTORY": "Historique", "CALCULATED_TRIPS": "Voyages Calculés" }, "NO_OPEN_TRIPS": "Aucun voyage terminé n'est en attente de calcul.", "NO_CALCULATED_TRIPS": "Aucun calcul de salaire n'a encore été effectué.", "HISTORY": { "MODAL_TITLE": "Détails du Calcul pour : {{destinations}}", "NO_DATA_FOUND_TITLE": "Détails non trouvés", "NO_DATA_FOUND_TEXT": "Les détails pour ce calcul n'ont pas été trouvés. Il s'agit peut-être d'un ancien calcul. Voulez-vous marquer ce voyage comme 'ouvert' pour le recalculer ?", "RECALCULATE_BTN": "Recalculer", "MOVED_FOR_RECALC": "Le voyage a été déplacé vers l'onglet 'Voyages Ouverts'." }, "RESULTS": { "TITLE": "Résultats du Calcul", "CLOSE": "Fermer", "FINANCIAL_SUMMARY": "Résumé Financier", "PROFIT_SHARING": "Partage des Bénéfices" }, "DETAILS_MODAL": { "REVENUE_TITLE": "Détails des Revenus", "EXPENSE_TITLE": "Détails des Dépenses", "INVOICE_NUM": "N° Facture", "CLIENT": "Client" } },
  "SALAIRES_HISTORY": { "CALCULATED_ON": "Calculé le" },
  "VENTES": { "TITLE": "Gestion des Ventes", "ADD_INVOICE": "Nouvelle Facture", "ADD_INVOICE_FOR_TRIP": "Ajouter une facture pour cette sortie", "NO_INVOICES_FOR_TRIP": "Aucune facture enregistrée pour cette sortie", "TRIP_TOTAL": "Total des ventes pour la sortie", "GENERAL_TOTAL": "Total général des ventes", "NO_TRIPS_AVAILABLE": "Aucune sortie en mer n'est disponible.", "SUCCESS_ADD": "Facture ajoutée avec succès !", "SUCCESS_UPDATE": "Facture modifiée avec succès !", "SUCCESS_DELETE": "Facture supprimée avec succès.", "DELETE_CONFIRM_ITEM": "la facture {{number}} ({{amount}} DT)", "ADD_MODAL": { "TITLE": "Nouvelle Facture de Vente", "SELECT_TRIP": "Sélectionner une sortie" }, "EDIT_MODAL": { "TITLE": "Modifier la Facture" }, "DETAILS_MODAL": { "INVOICE_NUM": "N° Facture", "CLIENT": "Client" } },
  "FORM": { "ADD": "Ajouter", "EDIT": "Modifier", "DELETE": "Supprimer", "CANCEL": "Annuler", "SAVE": "Enregistrer", "REQUIRED": "Ce champ est requis.", "REQUIRED_FIELDS": "Veuillez remplir tous les champs obligatoires.", "INVALID_PHONE": "Numéro de téléphone invalide.", "INVALID_EMAIL": "Adresse e-mail invalide." },
  "MESSAGES": { "LOADING": "Chargement...", "SAVING": "Enregistrement...", "UPDATING": "Modification...", "DELETING": "Suppression...", "CALCULATING": "Calcul en cours...", "LOADING_DETAILS": "Chargement des détails...", "ADDING_SAILOR": "Ajout du marin...", "SUCCESS": "Opération réussie !", "ERROR_TITLE": "Erreur", "WARNING_TITLE": "Attention", "ERROR_GENERIC": "Une erreur inattendue est survenue. Veuillez réessayer.", "AREYOUSURE": "Êtes-vous sûr ?", "CONFIRMDELETEMESSAGE": "Vous êtes sur le point de supprimer", "IRREVERSIBLE": "Cette action est irréversible.", "SAILOR_ADDED_SUCCESS": "Le marin {{name}} a été ajouté avec succès." },
  "LANGUAGE": { "AR": "Arabe", "FR": "Français", "EN": "Anglais" },
  "COMMON": { "UNKNOWN": "Inconnu", "AMOUNT": "Montant", "AMOUNT_D_T": "Montant (DT)", "AMOUNT_IN_TND": "Montant en dinars tunisiens", "DATE": "Date", "OK": "OK", "DESCRIPTION": "Description", "DETAILS": "Détails", "DETAILS_OPTIONAL": "Description (optionnel)", "VIEW_DETAILS": "Voir Détails" },
  "MOCK_DATA": { "TITLE": "🎲 Générateur de Données Fictives", "SUBTITLE": "Créez rapidement des données de test complètes pour votre application.", "ITEM_1": "✓ 2 bateaux de pêche", "ITEM_2": "✓ Plusieurs marins avec des parts différentes", "ITEM_3": "✓ Des sorties en mer multiples", "ITEM_4": "✓ Dépenses, ventes et avances associées", "GENERATE_BUTTON": "Générer les Données", "GENERATING_BUTTON": "Génération en cours...", "CONFIRM_TITLE": "Générer des données fictives ?", "CONFIRM_TEXT": "Cela va d'abord supprimer toutes les données existantes avant de créer de nouveaux enregistrements de test.", "CONFIRM_BUTTON": "Oui, générer", "LOADING_TITLE": "Génération en cours...", "LOADING_TEXT": "Veuillez patienter pendant la création des données.", "SUCCESS_TITLE": "Succès !", "SUCCESS_TEXT": "Les données de test ont été générées avec succès.", "ERROR_TITLE": "Erreur" }
}
EOF

# --- Application des modifications ---

echo "Début de l'application des modifications..."

replace_file "$SRC_DIR/app/avances/avances.component.ts" "/tmp/avances.component.ts"
replace_file "$SRC_DIR/app/avances/avances.component.scss" "/tmp/avances.component.scss"
replace_file "$SRC_DIR/assets/i18n/ar.json" "/tmp/ar.json"
replace_file "$SRC_DIR/assets/i18n/en.json" "/tmp/en.json"
replace_file "$SRC_DIR/assets/i18n/fr.json" "/tmp/fr.json"

# Nettoyage des fichiers temporaires
rm /tmp/avances.component.ts
rm /tmp/avances.component.scss
rm /tmp/ar.json
rm /tmp/en.json
rm /tmp/fr.json

echo "----------------------------------------"
echo "✅ Modifications appliquées avec succès !"
echo "Les sauvegardes des fichiers originaux ont été créées avec le suffixe .bak_$TIMESTAMP"
echo "----------------------------------------"

exit 0

