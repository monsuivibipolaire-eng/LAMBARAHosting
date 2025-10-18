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
      this.alertService.error('Veuillez d\'abord sélectionner un bateau');
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
    return marin ? `${marin.prenom} ${marin.nom}` : 'Inconnu';
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

  // ✅ FONCTION POUR FORMATER LA DATE D'AFFICHAGE (JJ/MM/AAAA)
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
      acc[marin.id!] = `${marin.prenom} ${marin.nom} (${this.translate.instant(`SAILORS.${marin.fonction.toUpperCase()}`)})`;
      return acc;
    }, {} as any);

    const translations = {
      title: this.translate.instant('AVANCES.ADD'),
      sailor: this.translate.instant('SAILORS.TITLE'),
      selectSailor: this.translate.instant('SAILORS.SELECT_FUNCTION'),
      amount: this.translate.instant('EXPENSES.AMOUNT'),
      date: this.translate.instant('EXPENSES.DATE'),
      description: this.translate.instant('EXPENSES.DESCRIPTION'),
      add: this.translate.instant('FORM.ADD'),
      cancel: this.translate.instant('FORM.CANCEL'),
      requiredFields: this.translate.instant('FORM.REQUIRED_FIELDS'),
      amountPositive: this.translate.instant('AVANCES.AMOUNT_POSITIVE')
    };

    const todayDate = this.getTodayDate();

    const { value: formValues } = await Swal.fire({
      title: `<div style="display: flex; align-items: center; justify-content: center; gap: 1rem; color: #1f2937;">
                <svg style="width: 36px; height: 36px; color: #10b981;" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                <span style="font-weight: 700; font-size: 1.5rem;">${translations.title}</span>
              </div>`,
      html: `
        <style>
          .avance-form { text-align: left; padding: 0.5rem 0.5rem 0; }
          .form-group { margin-bottom: 1.25rem; }
          .form-label { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.625rem; font-weight: 600; color: #374151; font-size: 0.9rem; }
          .form-label svg { width: 18px; height: 18px; color: #3b82f6; }
          .required-star { color: #ef4444; font-weight: 700; }
          .custom-select, .custom-input { width: 100%; padding: 0.75rem 0.875rem; border: 2px solid #e5e7eb; border-radius: 0.5rem; font-size: 0.95rem; transition: all 0.3s; background: white; color: #1f2937; }
          .custom-select:focus, .custom-input:focus { outline: none; border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1); }
          .custom-textarea { width: 100%; padding: 0.75rem 0.875rem; border: 2px solid #e5e7eb; border-radius: 0.5rem; font-size: 0.95rem; resize: vertical; min-height: 80px; transition: all 0.3s; font-family: inherit; }
          .custom-textarea:focus { outline: none; border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1); }
          .input-helper { display: flex; align-items: center; gap: 0.4rem; margin-top: 0.4rem; font-size: 0.8rem; color: #6b7280; }
          .input-helper svg { width: 14px; height: 14px; color: #9ca3af; }
        </style>
        <div class="avance-form">
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
              ${translations.sailor} <span class="required-star">*</span>
            </label>
            <select id="swal-marin" class="custom-select">
              <option value="">${translations.selectSailor}</option>
              ${Object.keys(marinsOptions).map(id => `<option value="${id}">${marinsOptions[id]}</option>`).join('')}
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
              ${translations.amount} (DT) <span class="required-star">*</span>
            </label>
            <input id="swal-montant" type="number" class="custom-input" placeholder="0.00" step="0.01" min="0">
            <div class="input-helper">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
              <span>Montant en dinars tunisiens</span>
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
              ${translations.date} <span class="required-star">*</span>
            </label>
            <input id="swal-date" type="date" class="custom-input" value="${todayDate}">
          </div>
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"/></svg>
              ${translations.description}
            </label>
            <textarea id="swal-description" class="custom-textarea" placeholder="${translations.description}"></textarea>
          </div>
        </div>
      `,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: translations.add,
      cancelButtonText: translations.cancel,
      confirmButtonColor: '#10b981',
      cancelButtonColor: '#6b7280',
      width: '600px',
      padding: '1.5rem 2rem 2rem',
      preConfirm: () => {
        const marinId = (document.getElementById('swal-marin') as HTMLSelectElement).value;
        const montant = parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value);
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;
        const description = (document.getElementById('swal-description') as HTMLTextAreaElement).value;

        if (!marinId || !montant || !date) {
          Swal.showValidationMessage(translations.requiredFields);
          return false;
        }

        if (montant <= 0) {
          Swal.showValidationMessage(translations.amountPositive);
          return false;
        }

        return { marinId, montant, date, description };
      }
    });

    if (formValues) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.SAVING'));

        const newAvance: any = {
          marinId: formValues.marinId,
          bateauId: this.selectedBoat.id!,
          montant: formValues.montant,
          dateAvance: new Date(formValues.date)
        };

        if (formValues.description && formValues.description.trim() !== '') {
          newAvance.description = formValues.description.trim();
        }

        await this.avanceService.addAvance(newAvance);
        
        this.alertService.close();
        await this.alertService.success(this.translate.instant('AVANCES.SUCCESS_ADD'));
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.close();
        this.alertService.error(this.translate.instant('MESSAGES.ERROR'));
      }
    }
  }

  async editAvance(avance: Avance): Promise<void> {
    const translations = {
      title: this.translate.instant('AVANCES.EDIT'),
      amount: this.translate.instant('EXPENSES.AMOUNT'),
      date: this.translate.instant('EXPENSES.DATE'),
      description: this.translate.instant('EXPENSES.DESCRIPTION'),
      edit: this.translate.instant('FORM.EDIT'),
      cancel: this.translate.instant('FORM.CANCEL')
    };

    const { value: formValues } = await Swal.fire({
      title: translations.title,
      html: `
        <style>
          .avance-form { text-align: left; padding: 0.5rem 0.5rem 0; }
          .form-group { margin-bottom: 1.25rem; }
          .form-label { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.625rem; font-weight: 600; color: #374151; font-size: 0.9rem; }
          .custom-input, .custom-textarea { width: 100%; padding: 0.75rem 0.875rem; border: 2px solid #e5e7eb; border-radius: 0.5rem; font-size: 0.95rem; transition: all 0.3s; }
          .custom-input:focus, .custom-textarea:focus { outline: none; border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1); }
          .custom-textarea { resize: vertical; min-height: 80px; font-family: inherit; }
        </style>
        <div class="avance-form">
          <div class="form-group">
            <label class="form-label">${translations.amount} (DT)</label>
            <input id="swal-montant" type="number" class="custom-input" value="${avance.montant}" step="0.01" min="0">
          </div>
          <div class="form-group">
            <label class="form-label">${translations.date}</label>
            <input id="swal-date" type="date" class="custom-input" value="${this.formatDate(avance.dateAvance)}">
          </div>
          <div class="form-group">
            <label class="form-label">${translations.description}</label>
            <textarea id="swal-description" class="custom-textarea">${avance.description || ''}</textarea>
          </div>
        </div>
      `,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: translations.edit,
      cancelButtonText: translations.cancel,
      confirmButtonColor: '#f59e0b',
      width: '600px',
      padding: '1.5rem 2rem 2rem',
      preConfirm: () => {
        const montant = parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value);
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;
        const description = (document.getElementById('swal-description') as HTMLTextAreaElement).value;
        return { montant, date, description };
      }
    });

    if (formValues) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.SAVING'));
        
        const updateData: any = {
          montant: formValues.montant,
          dateAvance: new Date(formValues.date)
        };

        if (formValues.description && formValues.description.trim() !== '') {
          updateData.description = formValues.description.trim();
        } else {
          updateData.description = '';
        }

        await this.avanceService.updateAvance(avance.id!, updateData);
        
        this.alertService.close();
        await this.alertService.success(this.translate.instant('AVANCES.SUCCESS_UPDATE'));
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.close();
        this.alertService.error(this.translate.instant('MESSAGES.ERROR'));
      }
    }
  }

  async deleteAvance(avance: Avance): Promise<void> {
    const marinName = this.getMarinName(avance.marinId);
    const confirmed = await this.alertService.confirmDelete(
      `l'avance de ${avance.montant} DT pour ${marinName}`
    );

    if (confirmed) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.LOADING'));
        await this.avanceService.deleteAvance(avance.id!);
        this.alertService.close();
        this.alertService.toast(this.translate.instant('AVANCES.SUCCESS_DELETE'), 'success');
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.close();
        this.alertService.error(this.translate.instant('MESSAGES.ERROR'));
      }
    }
  }
}
