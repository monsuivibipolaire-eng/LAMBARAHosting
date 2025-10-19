import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import Swal from 'sweetalert2';

import { PointageService } from '../../services/pointage.service';
import { MarinService } from '../../services/marin.service';
import { SortieService } from '../../services/sortie.service';
import { AlertService } from '../../services/alert.service';

import { Pointage } from '../../models/pointage.model';
import { Marin } from '../../models/marin.model';
import { Sortie } from '../../models/sortie.model';

import { switchMap, take } from 'rxjs/operators';
import { of, combineLatest } from 'rxjs';

@Component({
  selector: 'app-pointage',
  standalone: true,
  imports: [CommonModule, TranslateModule, RouterModule, FormsModule],
  templateUrl: './pointage.component.html',
  styleUrls: ['./pointage.component.scss']
})
export class PointageComponent implements OnInit {
  sortieId!: string;
  sortie?: Sortie;
  marins: Marin[] = [];
  pointages: Pointage[] = [];
  loading = true;
  errorMessage = '';

  constructor(
    private route: ActivatedRoute,
    private marinService: MarinService,
    private pointageService: PointageService,
    private sortieService: SortieService,
    private alertService: AlertService,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.sortieId = this.route.snapshot.paramMap.get('id')!;
    this.loadData();
  }

  loadData(): void {
    this.sortieService.getSortie(this.sortieId)
      .pipe(
        take(1),
        switchMap((sortie) => {
          if (!sortie || !sortie.bateauId) {
            this.errorMessage = sortie ? 'Aucun bateau associé à cette sortie' : 'Sortie introuvable';
            return of([[], []] as [Marin[], Pointage[]]);
          }
          this.sortie = sortie;
          return combineLatest([
            this.marinService.getMarinsByBateau(sortie.bateauId),
            this.pointageService.getPointagesBySortie(this.sortieId)
          ]);
        })
      )
      .subscribe({
        next: ([marins, pointages]) => {
          this.marins = marins;
          this.pointages = pointages;
          if (marins.length === 0) {
            this.errorMessage = 'Aucun marin affecté à ce bateau';
          }
          this.loading = false;
        },
        error: (error) => {
          console.error('❌ Erreur chargement:', error);
          this.errorMessage = 'Erreur lors du chargement des données';
          this.alertService.error('Erreur lors du chargement des données');
          this.loading = false;
        }
      });
  }

  async addNewMarin(): Promise<void> {
    if (!this.sortie?.bateauId) {
      this.alertService.error('Aucun bateau associé à cette sortie');
      return;
    }

    const translations = {
      title: this.translate.instant('SAILORS.ADD_NEW_SAILOR'),
      lastname: this.translate.instant('SAILORS.LASTNAME'),
      firstname: this.translate.instant('SAILORS.FIRSTNAME'),
      function: this.translate.instant('SAILORS.FUNCTION'),
      part: this.translate.instant('SAILORS.PART'), // ✅ Traduction ajoutée
      selectFunction: this.translate.instant('SAILORS.SELECT_FUNCTION'),
      phone: this.translate.instant('SAILORS.PHONE'),
      birthdate: this.translate.instant('SAILORS.BIRTHDATE'),
      captain: this.translate.instant('SAILORS.CAPITAINE'),
      second: this.translate.instant('SAILORS.SECOND'),
      mechanic: this.translate.instant('SAILORS.MECANICIEN'),
      sailor: this.translate.instant('SAILORS.MATELOT'),
      add: this.translate.instant('FORM.ADD'),
      cancel: this.translate.instant('FORM.CANCEL'),
      requiredFields: this.translate.instant('FORM.REQUIRED_FIELDS'),
      placeholderLastname: this.translate.instant('SAILORS.PLACEHOLDER.LASTNAME'),
      placeholderFirstname: this.translate.instant('SAILORS.PLACEHOLDER.FIRSTNAME'),
      placeholderPhone: this.translate.instant('SAILORS.PLACEHOLDER.PHONE')
    };

    const { value: formValues } = await Swal.fire({
      title: translations.title,
      html: `
        <div style="text-align: left; padding: 1rem;">
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">${translations.lastname} *</label>
            <input id="swal-nom" class="swal2-input" placeholder="${translations.placeholderLastname}" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">${translations.firstname} *</label>
            <input id="swal-prenom" class="swal2-input" placeholder="${translations.placeholderFirstname}" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">${translations.function} *</label>
            <select id="swal-fonction" class="swal2-input" style="width: 90%;">
              <option value="">${translations.selectFunction}</option>
              <option value="capitaine">${translations.captain}</option>
              <option value="second">${translations.second}</option>
              <option value="mecanicien">${translations.mechanic}</option>
              <option value="matelot">${translations.sailor}</option>
            </select>
          </div>

          <!-- ✅ CHAMP AJOUTÉ POUR LA PART -->
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">${translations.part} *</label>
            <input id="swal-part" type="number" value="1" step="0.1" min="0" class="swal2-input" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">${translations.phone}</label>
            <input id="swal-phone" class="swal2-input" placeholder="${translations.placeholderPhone}" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">${translations.birthdate} *</label>
            <input id="swal-birthdate" type="date" class="swal2-input" style="width: 90%;">
          </div>
        </div>
      `,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: translations.add,
      cancelButtonText: translations.cancel,
      confirmButtonColor: '#3b82f6',
      cancelButtonColor: '#6b7280',
      width: '600px',
      preConfirm: () => {
        const nom = (document.getElementById('swal-nom') as HTMLInputElement).value;
        const prenom = (document.getElementById('swal-prenom') as HTMLInputElement).value;
        const fonction = (document.getElementById('swal-fonction') as HTMLSelectElement).value;
        const part = parseFloat((document.getElementById('swal-part') as HTMLInputElement).value);
        const phone = (document.getElementById('swal-phone') as HTMLInputElement).value;
        const birthdate = (document.getElementById('swal-birthdate') as HTMLInputElement).value;

        if (!nom || !prenom || !fonction || !birthdate || isNaN(part)) {
          Swal.showValidationMessage(translations.requiredFields);
          return false;
        }

        return { nom, prenom, fonction, part, phone, birthdate };
      }
    });

    if (formValues) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.ADDING_SAILOR'));

        // ✅ CORRECTION: Ajout de la propriété 'part'
        const newMarin: Omit<Marin, 'id'> = {
          nom: formValues.nom,
          prenom: formValues.prenom,
          fonction: formValues.fonction as 'capitaine' | 'second' | 'mecanicien' | 'matelot',
          part: formValues.part,
          telephone: formValues.phone || '',
          dateNaissance: new Date(formValues.birthdate),
          bateauId: this.sortie!.bateauId,
          email: `${formValues.prenom}.${formValues.nom}@email.com`.toLowerCase(),
          numeroPermis: 'N/A',
    coefficientSalaire: 1.0,
          dateEmbauche: new Date(),
          adresse: 'N/A',
          statut: 'actif'
        };

        await this.marinService.addMarin(newMarin);
        
        this.alertService.close();
        const successMsg = this.translate.instant('MESSAGES.SAILOR_ADDED_SUCCESS', {
          name: `${formValues.prenom} ${formValues.nom}`
        });
        await this.alertService.success(successMsg);
        
        this.loadData();
      } catch (error) {
        console.error('Erreur lors de l\'ajout du marin:', error);
        this.alertService.close();
        this.alertService.error('Erreur lors de l\'ajout du marin');
      }
    }
  }

  get nombrePresents(): number {
    return this.pointages.filter(p => p.present === true).length;
  }

  get nombreAbsents(): number {
    return this.marins.length - this.nombrePresents;
  }

  isPresent(marinId: string): boolean {
    const p = this.pointages.find(pointage => pointage.marinId === marinId);
    return p ? p.present : false;
  }

  async togglePresence(marinId: string, event: Event): Promise<void> {
    const isChecked = (event.target as HTMLInputElement).checked;
    const existingPointage = this.pointages.find(p => p.marinId === marinId);

    try {
      if (existingPointage && existingPointage.id) {
        await this.pointageService.updatePointage(existingPointage.id, {
          present: isChecked,
          datePointage: new Date()
        });
        existingPointage.present = isChecked;
      } else {
        const newPointageData: Omit<Pointage, 'id'> = {
          sortieId: this.sortieId,
          marinId: marinId,
          present: isChecked,
          datePointage: new Date()
        };
        const result = await this.pointageService.addPointage(newPointageData);
        this.pointages.push({ id: result.id, ...newPointageData });
      }
      this.alertService.toast(
        isChecked ? 'Présence enregistrée' : 'Absence enregistrée',
        'success'
      );
    } catch (error) {
      console.error('❌ Erreur lors du pointage:', error);
      this.alertService.error('Erreur lors de l\'enregistrement du pointage');
    }
  }

  getObservations(marinId: string): string {
    const p = this.pointages.find(pointage => pointage.marinId === marinId);
    return p?.observations || '';
  }

  async updateObservations(marinId: string, observations: string): Promise<void> {
    const existingPointage = this.pointages.find(p => p.marinId === marinId);
    
    if (existingPointage && existingPointage.id) {
      if (existingPointage.observations === observations) return;
      try {
        await this.pointageService.updatePointage(existingPointage.id, { observations });
        existingPointage.observations = observations;
        this.alertService.toast('Observations mises à jour', 'success');
      } catch (error) {
        console.error('Erreur mise à jour observations:', error);
        this.alertService.error('Erreur lors de la mise à jour');
      }
    }
  }
}
