import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import { SortieService } from '../services/sortie.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { AlertService } from '../services/alert.service';
import { Sortie } from '../models/sortie.model';
import { Bateau } from '../models/bateau.model';

@Component({
  selector: 'app-sorties-list',
  templateUrl: './sorties-list.component.html',
  styleUrls: ['./sorties-list.component.scss'],
  standalone: false
})
export class SortiesListComponent implements OnInit {
  sorties$!: Observable<Sortie[]>;  // ⬅️ Renommé avec $
  selectedBoat: Bateau | null = null;

  constructor(
    private sortieService: SortieService,
    private selectedBoatService: SelectedBoatService,
    private alertService: AlertService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.selectedBoat = this.selectedBoatService.getSelectedBoat();
    
    if (this.selectedBoat?.id) {
      this.sorties$ = this.sortieService.getSortiesByBateau(this.selectedBoat.id);
      console.log('🚢 Chargement des sorties pour:', this.selectedBoat.nom);
    } else {
      console.warn('⚠️ Aucun bateau sélectionné');
      this.alertService.warning('Veuillez d\'abord sélectionner un bateau');
      this.router.navigate(['/dashboard/bateaux']);
    }
  }

  formatDate(date: any): string {
    if (!date) return '';
    if (date.toDate) return date.toDate().toLocaleDateString('fr-FR');
    if (date instanceof Date) return date.toLocaleDateString('fr-FR');
    return String(date);
  }

  getStatutClass(statut: string): string {
    return `status-${statut}`;
  }

  addSortie(): void {
    this.router.navigate(['/dashboard/sorties/add']);
  }

  editSortie(id: string): void {
    this.router.navigate(['/dashboard/sorties/edit', id]);
  }

  async deleteSortie(sortie: Sortie): Promise<void> {
    const confirmed = await this.alertService.confirmDelete(`la sortie ${sortie.destination}`);
    if (confirmed && sortie.id) {
      try {
        await this.sortieService.deleteSortie(sortie.id);
        this.alertService.toast('Sortie supprimée avec succès', 'success');
      } catch (error) {
        this.alertService.error('Erreur lors de la suppression');
      }
    }
  }

  viewDetails(id: string): void {
    this.router.navigate(['/dashboard/sorties/details', id]);
  }
}
