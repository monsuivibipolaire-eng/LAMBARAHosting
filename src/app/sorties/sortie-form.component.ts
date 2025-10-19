import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { TranslateService } from '@ngx-translate/core';
import { SortieService } from '../services/sortie.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { AlertService } from '../services/alert.service';
import { Sortie } from '../models/sortie.model';
import { Bateau } from '../models/bateau.model';

@Component({
  selector: 'app-sortie-form',
  standalone: false,
  templateUrl: './sortie-form.component.html',
  styleUrls: ['./sortie-form.component.scss']
})
export class SortieFormComponent implements OnInit {
  sortie: any = {};
  isEditMode = false;
  sortieId?: string;
  selectedBoat: Bateau | null = null;
  loading = false;

  constructor(
    private sortieService: SortieService,
    private selectedBoatService: SelectedBoatService,
    private alertService: AlertService,
    private router: Router,
    private route: ActivatedRoute,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.selectedBoat = this.selectedBoatService.getSelectedBoat();
    
    if (!this.selectedBoat) {
      this.alertService.error(this.translate.instant('BOATS.NO_BOAT_SELECTED'));
      this.router.navigate(['/dashboard/bateaux']);
      return;
    }

    this.sortieId = this.route.snapshot.paramMap.get('id') || undefined;
    
    if (this.sortieId) {
      this.isEditMode = true;
      this.loading = true;
      this.sortieService.getSortie(this.sortieId).subscribe(sortie => {
        if (sortie) {
          this.sortie = {
            destination: sortie.destination,
            dateDepart: this.formatDate(sortie.dateDepart),
            dateRetour: sortie.dateRetour ? this.formatDate(sortie.dateRetour) : '',
            statut: sortie.statut,
            notes: sortie.notes || ''
          };
        } else {
          this.alertService.error(this.translate.instant('TRIPS.NOT_FOUND'));
          this.router.navigate(['/dashboard/sorties']);
        }
        this.loading = false;
      });
    }
  }

  formatDate(date: any): string {
    if (!date) return '';
    if (date.toDate && typeof date.toDate === 'function') {
      return date.toDate().toISOString().split('T')[0];
    }
    if (date instanceof Date) {
      return date.toISOString().split('T')[0];
    }
    if (typeof date === 'string') {
      return new Date(date).toISOString().split('T')[0];
    }
    return '';
  }

  async onSubmit(): Promise<void> {
    if (!this.selectedBoat) {
      this.alertService.error(this.translate.instant('BOATS.NO_BOAT_SELECTED'));
      return;
    }

    if (!this.sortie.destination || !this.sortie.dateDepart) {
      this.alertService.error(this.translate.instant('FORM.REQUIRED_FIELDS'));
      return;
    }

    try {
      this.loading = true;
      this.alertService.loading(this.translate.instant('MESSAGES.SAVING'));

      const sortieData: any = {
        bateauId: this.selectedBoat.id!,
        destination: this.sortie.destination,
        dateDepart: new Date(this.sortie.dateDepart),
        statut: this.sortie.statut || 'en_cours'
      };

      if (this.sortie.dateRetour) {
        sortieData.dateRetour = new Date(this.sortie.dateRetour);
      }

      if (this.sortie.notes && this.sortie.notes.trim()) {
        sortieData.notes = this.sortie.notes.trim();
      }

      if (this.isEditMode && this.sortieId) {
        sortieData.updatedAt = new Date();
        await this.sortieService.updateSortie(this.sortieId, sortieData);
        this.alertService.success(this.translate.instant('TRIPS.SUCCESS_UPDATE'));
      } else {
        sortieData.createdAt = new Date();
        await this.sortieService.addSortie(sortieData);
        this.alertService.success(this.translate.instant('TRIPS.SUCCESS_ADD'));
      }

      this.router.navigate(['/dashboard/sorties']);
    } catch (error) {
      console.error('Erreur:', error);
      this.alertService.error();
    } finally {
      this.loading = false;
    }
  }

  cancel(): void {
    this.router.navigate(['/dashboard/sorties']);
  }
}
