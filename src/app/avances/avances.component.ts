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
    combineLatest([
      this.marinService.getMarinsByBateau(this.selectedBoat.id!),
      this.avanceService.getAvancesByBateau(this.selectedBoat.id!)
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

  async addAvance(): Promise<void> {
  if (!this.selectedBoat) return;

  const marinsOptions = this.marins.reduce((acc, marin) => {
    acc[marin.id!] = `${marin.prenom} ${marin.nom} - ${this.translate.instant('SAILORS.FUNCTION_TYPE.' + marin.fonction.toUpperCase())}`;
    return acc;
  }, {} as any);

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
    title: `<i class="swal-icon-money"></i> ${t.title}`,
    html: `
      <div class="swal-form">
        <div class="form-group">
          <label class="form-label"><i class="swal-icon-user"></i> ${t.sailor} <span class="required-star">*</span></label>
          <select id="swal-marin" class="swal2-input">
            <option value="">${t.selectSailor}</option>
            ${Object.keys(marinsOptions).map(id => `<option value="${id}">${marinsOptions[id]}</option>`).join('')}
          </select>
        </div>
        <div class="form-group">
          <label class="form-label"><i class="swal-icon-cash"></i> ${t.amount} <span class="required-star">*</span></label>
          <input id="swal-montant" type="number" class="swal2-input" placeholder="0.00" step="0.01" min="0" />
          <div class="input-helper">${t.amountPlaceholder}</div>
        </div>
        <div class="form-group">
          <label class="form-label"><i class="swal-icon-calendar"></i> ${t.date} <span class="required-star">*</span></label>
          <input id="swal-date" type="date" class="swal2-input" value="${this.getTodayDate()}" />
        </div>
        <div class="form-group">
          <label class="form-label"><i class="swal-icon-details"></i> ${t.description}</label>
          <textarea id="swal-description" class="swal2-textarea" placeholder="${t.descriptionPlaceholder}"></textarea>
        </div>
      </div>
    `,
    focusConfirm: false,
    showCancelButton: true,
    confirmButtonText: t.add,
    cancelButtonText: t.cancel,
    confirmButtonColor: '#10b981',
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
      
      const newAvance: any = {
        marinId: formValues.marinId,
        bateauId: this.selectedBoat.id!,
        montant: formValues.montant,
        dateAvance: new Date(formValues.date),
        createdAt: new Date() // ✅ AJOUT: Date de création
      };

      if (formValues.description && formValues.description.trim() !== '') {
        newAvance.description = formValues.description.trim();
      }

      // ✅ CORRECTION: Attendre l'enregistrement
      await this.avanceService.addAvance(newAvance);
      
      this.alertService.success(this.translate.instant('AVANCES.SUCCESS_ADD'));
    } catch (error) {
      console.error('Erreur lors de l\'ajout de l\'avance:', error);
      this.alertService.error();
    }
  }
}


  async editAvance(avance: Avance): Promise<void> {
    const t = {
        title: this.translate.instant('AVANCES.EDIT_MODAL.TITLE'),
        amount: this.translate.instant('COMMON.AMOUNT_D T'),
        date: this.translate.instant('COMMON.DATE'),
        description: this.translate.instant('COMMON.DESCRIPTION'),
        edit: this.translate.instant('FORM.EDIT'),
        cancel: this.translate.instant('FORM.CANCEL')
    };

    const { value: formValues } = await Swal.fire({
      title: t.title,
      html: `
        <div class="swal-form">
          <div class="form-group">
            <label class="form-label">${t.amount}</label>
            <input id="swal-montant" type="number" class="swal2-input" value="${avance.montant}" step="0.01" min="0">
          </div>
          <div class="form-group">
            <label class="form-label">${t.date}</label>
            <input id="swal-date" type="date" class="swal2-input" value="${this.formatDate(avance.dateAvance)}">
          </div>
          <div class="form-group">
            <label class="form-label">${t.description}</label>
            <textarea id="swal-description" class="swal2-textarea">${avance.description || ''}</textarea>
          </div>
        </div>`,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: t.edit,
      cancelButtonText: t.cancel,
      confirmButtonColor: '#f59e0b',
      preConfirm: () => ({
        montant: parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value),
        date: (document.getElementById('swal-date') as HTMLInputElement).value,
        description: (document.getElementById('swal-description') as HTMLTextAreaElement).value
      })
    });

    if (formValues) {
      try {
        this.alertService.loading();
        const updateData: any = {
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
