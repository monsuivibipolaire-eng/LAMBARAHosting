#!/bin/bash

# ==============================================================================
#  Script pour améliorer le design de la popup "Ajouter une sلفة"
#  et corriger les traductions manquantes.
# ==============================================================================

# --- Fichiers à modifier ---
AVANCES_TS="src/app/avances/avances.component.ts"
AVANCES_SCSS="src/app/avances/avances.component.scss"
I18N_AR="src/assets/i18n/ar.json"
I18N_EN="src/assets/i18n/en.json"
I18N_FR="src/assets/i18n/fr.json"

# --- Vérification des fichiers ---
for file in $AVANCES_TS $AVANCES_SCSS $I18N_AR $I18N_EN $I18N_FR; do
    if [ ! -f "$file" ]; then
        echo "❌ Erreur : Fichier manquant -> $file"
        exit 1
    fi
done

echo "🔧 Début de l'amélioration de la popup d'ajout d'avance..."

# --- 1. Remplacement du fichier TypeScript (avances.component.ts) ---
echo "🔄 1/3 - Mise à jour de la méthode 'addAvance' avec le nouveau design..."
cp "$AVANCES_TS" "$AVANCES_TS.bak"
cat > "$AVANCES_TS" << 'EOF'
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
    this.loading = true; // S'assurer que le loading est bien actif
    combineLatest([
      this.marinService.getMarinsByBateau(this.selectedBoat.id!),
      this.avanceService.getUnsettledAvancesByBateau(this.selectedBoat.id!)
    ]).subscribe(([marins, avances]) => {
      this.marins = marins;
      this.avances = avances;
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
    } else {
      return '';
    }
    const day = String(dateObj.getDate()).padStart(2, '0');
    const month = String(dateObj.getMonth() + 1).padStart(2, '0');
    const year = dateObj.getFullYear();
    return `${day}/${month}/${year}`;
  }

  // ✅ AMÉLIORATION: Méthode entièrement revue pour un meilleur design
  async addAvance(): Promise<void> {
    if (!this.selectedBoat) return;

    const marinsOptions = this.marins.reduce((acc, marin) => {
      // La traduction est maintenant correcte grâce aux clés ajoutées
      const fonction = this.translate.instant('SAILORS.FUNCTION_TYPE.' + marin.fonction.toUpperCase());
      acc[marin.id!] = `${marin.prenom} ${marin.nom} - ${fonction}`;
      return acc;
    }, {} as { [key: string]: string });

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
      title: t.title,
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
            <input id="swal-montant" type="number" class="custom-input" placeholder="0.00" step="0.01" min="0" />
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
      confirmButtonColor: '#10b981',
      customClass: {
        popup: 'swal-wide-popup'
      },
      preConfirm: () => {
        const marinId = (document.getElementById('swal-marin') as HTMLSelectElement).value;
        const montant = parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value);
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;

        if (!marinId || !montant || !date) {
          Swal.showValidationMessage(t.requiredFields);
          return false;
        }
        if (montant <= 0) {
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
          createdAt: new Date()
        };
        if (formValues.description && formValues.description.trim() !== '') {
          newAvance.description = formValues.description.trim();
        }
        await this.avanceService.addAvance(newAvance);
        this.alertService.success(this.translate.instant('AVANCES.SUCCESS_ADD'));
      } catch (error) {
        console.error("Erreur lors de l'ajout de l'avance:", error);
        this.alertService.error();
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
        cancel: this.translate.instant('FORM.CANCEL')
    };

    const { value: formValues } = await Swal.fire({
      title: t.title,
      html: `
        <div class="swal-custom-form">
          <div class="form-group">
            <label class="form-label">${t.amount}</label>
            <input id="swal-montant" type="number" class="custom-input" value="${avance.montant}" step="0.01" min="0">
          </div>
          <div class="form-group">
            <label class="form-label">${t.date}</label>
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
      confirmButtonColor: '#f59e0b',
      customClass: {
        popup: 'swal-wide-popup'
      },
      preConfirm: () => ({
        montant: parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value),
        date: (document.getElementById('swal-date') as HTMLInputElement).value,
        description: (document.getElementById('swal-description') as HTMLTextAreaElement).value
      })
    });

    if (formValues) {
      try {
        this.alertService.loading();
        const updateData: Partial<Avance> = {
          montant: formValues.montant,
          dateAvance: new Date(formValues.date)
        };
        updateData.description = (formValues.description && formValues.description.trim() !== '') ? formValues.description.trim() : '';
        await this.avanceService.updateAvance(avance.id!, updateData);
        this.alertService.success(this.translate.instant('AVANCES.SUCCESS_UPDATE'));
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.error();
      }
    }
  }

  async deleteAvance(avance: Avance): Promise<void> {
    const marinName = this.getMarinName(avance.marinId);
    const itemName = this.translate.instant('AVANCES.DELETE_CONFIRM_ITEM', { amount: avance.montant, name: marinName });
    const confirmed = await this.alertService.confirmDelete(itemName);
    if (confirmed) {
      try {
        this.alertService.loading();
        await this.avanceService.deleteAvance(avance.id!);
        this.alertService.toast(this.translate.instant('AVANCES.SUCCESS_DELETE'));
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.error();
      }
    }
  }
}
EOF

# --- 2. Remplacement du fichier SCSS (avances.component.scss) ---
echo "🔄 2/3 - Ajout des styles pour la nouvelle popup..."
cp "$AVANCES_SCSS" "$AVANCES_SCSS.bak"
cat > "$AVANCES_SCSS" << 'EOF'
// Styles globaux pour les popups Swal customisées
:host::ng-deep {
  .swal-wide-popup {
    width: 600px !important;
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
    color: #374151;
    font-size: 0.9rem;
  }
  .required-star {
    color: #ef4444;
    font-weight: 700;
  }
  .custom-input, .custom-textarea, .custom-select {
    width: 100%;
    padding: 0.75rem 0.875rem;
    border: 2px solid #e5e7eb;
    border-radius: 0.5rem;
    font-size: 0.95rem;
    transition: all 0.3s;
    font-family: inherit;
    background: white;
  }
  .custom-input:focus, .custom-textarea:focus, .custom-select:focus {
    outline: none;
    border-color: #10b981;
    box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
  }
  .custom-textarea {
    resize: vertical;
    min-height: 80px;
  }
  .input-helper {
    margin-top: 0.4rem;
    font-size: 0.8rem;
    color: #6b7280;
  }
}


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
  background-color: #3b82f6;
  color: white;

  &:hover {
    background-color: #2563eb;
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

.fonction-capitaine { background-color: #fef3c7; color: #92400e; }
.fonction-second { background-color: #e0e7ff; color: #3730a3; }
.fonction-mecanicien { background-color: #ccfbf1; color: #115e59; }
.fonction-matelot { background-color: #f3e8ff; color: #6b21a8; }

.marin-total {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  .total-label { font-size: 0.875rem; color: #6b7280; font-weight: 500; }
  .total-amount { font-size: 1.5rem; font-weight: 700; color: #059669; }
}

.avances-list {
  padding: 1rem;
}

.avance-item {
  padding: 1rem;
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
    padding-left: 1.625rem;
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
    color: #059669;
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
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: white;
  padding: 1.5rem 2rem;
  border-radius: 0.75rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 2rem;
  box-shadow: 0 4px 6px rgba(16, 185, 129, 0.3);

  .total-label-main { font-size: 1.25rem; font-weight: 600; }
  .total-amount-main { font-size: 2rem; font-weight: 700; }
}

@media (max-width: 768px) {
  .avances-container { padding: 1rem; }
  .title { font-size: 1.5rem; }
  .marin-header { flex-direction: column; align-items: flex-start; gap: 1rem; }
  .avance-main { flex-direction: column; align-items: flex-start; }
  .avance-actions { width: 100%; justify-content: space-between; }
  .total-card { flex-direction: column; gap: 0.5rem; text-align: center; }
}
EOF

# --- 3. Ajout des clés de traduction ---
echo "🔄 3/3 - Ajout des clés de traduction manquantes pour les fonctions..."

# fr.json
sed -i'' '/"PLACEHOLDER": {/i \
    "FUNCTION_TYPE": {\
      "CAPITAINE": "Capitaine",\
      "SECOND": "Second",\
      "MECANICIEN": "Mécanicien",\
      "MATELOT": "Matelot"\
    },
' "$I18N_FR"

# en.json
sed -i'' '/"PLACEHOLDER": {/i \
    "FUNCTION_TYPE": {\
      "CAPITAINE": "Captain",\
      "SECOND": "Second",\
      "MECANICIEN": "Mechanic",\
      "MATELOT": "Sailor"\
    },
' "$I18N_EN"

# ar.json
sed -i'' '/"PLACEHOLDER": {/i \
    "FUNCTION_TYPE": {\
      "CAPITAINE": "قبطان",\
      "SECOND": "مساعد قبطان",\
      "MECANICIEN": "ميكانيكي",\
      "MATELOT": "بحار"\
    },
' "$I18N_AR"

# --- Nettoyage et confirmation ---
rm -f "$AVANCES_TS.bak" "$AVANCES_SCSS.bak"
echo "✅ Modifications terminées avec succès !"
echo "Le design de la popup a été amélioré et les traductions sont maintenant correctes."