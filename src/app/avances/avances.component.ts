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
