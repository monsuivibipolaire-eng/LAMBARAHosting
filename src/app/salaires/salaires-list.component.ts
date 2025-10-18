import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import Swal from 'sweetalert2';
import { take } from 'rxjs/operators';

import { SortieService } from '../services/sortie.service';
import { MarinService } from '../services/marin.service';
import { DepenseService } from '../services/depense.service';
import { AvanceService } from '../services/avance.service';
import { PaiementService } from '../services/paiement.service';
import { FactureVenteService } from '../services/facture-vente.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { AlertService } from '../services/alert.service';
import { Sortie } from '../models/sortie.model';
import { Marin } from '../models/marin.model';
import { Bateau } from '../models/bateau.model';
import { SalaireService } from '../services/salaire.service';
import { CalculSalaire } from '../models/salaire.model';

interface SalaireDetail {
  marinId: string;
  marinNom: string;
  part: number;
  salaireBrut: number;
  primeNuits: number;
  totalAvances: number;
  totalPaiements: number;
  resteAPayer: number;
}

@Component({
  selector: 'app-salaires-list',
  standalone: true,
  imports: [CommonModule, FormsModule, TranslateModule],
  templateUrl: './salaires-list.component.html',
  styleUrls: ['./salaires-list.component.scss']
})
export class SalairesListComponent implements OnInit {
  selectedBoat: Bateau | null = null;
  marins: Marin[] = [];
  selectedSortiesIds: string[] = [];
  
  activeTab: 'ouvertes' | 'historique' = 'ouvertes';
  sortiesOuvertes: Sortie[] = [];
  sortiesCalculees: Sortie[] = [];
  historiqueCalculs: { [sortieId: string]: CalculSalaire[] } = {};

  loading = true;

  constructor(
    private sortieService: SortieService,
    private marinService: MarinService,
    private depenseService: DepenseService,
    private avanceService: AvanceService,
    private paiementService: PaiementService,
    private factureService: FactureVenteService,
    private salaireService: SalaireService,
    private selectedBoatService: SelectedBoatService,
    private alertService: AlertService,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.selectedBoat = this.selectedBoatService.getSelectedBoat();
    
    if (this.selectedBoat) {
      this.loadData();
    } else {
      this.loading = false;
    }
  }

  loadData(): void {
    if (!this.selectedBoat?.id) return;
    this.loading = true;

    const boatId = this.selectedBoat.id;

    this.sortieService.getSortiesByBateau(boatId).subscribe((sorties: Sortie[]) => {
      this.sortiesOuvertes = sorties.filter(s => s.statut === 'terminee' && !s.salaireCalcule);
      
      // ✅ CORRECTION: Gère correctement la conversion de Timestamp ou Date
      this.sortiesCalculees = sorties.filter(s => s.salaireCalcule === true)
        .sort((a, b) => {
          const dateA = (a.dateRetour as any).toDate ? (a.dateRetour as any).toDate().getTime() : new Date(a.dateRetour).getTime();
          const dateB = (b.dateRetour as any).toDate ? (b.dateRetour as any).toDate().getTime() : new Date(b.dateRetour).getTime();
          return dateB - dateA;
        });
      
      this.marinService.getMarinsByBateau(boatId).subscribe((marins: Marin[]) => {
        this.marins = marins;
        this.loading = false;
      });
    });
  }

  selectTab(tabName: 'ouvertes' | 'historique'): void {
    this.activeTab = tabName;
  }

  toggleSortie(sortieId: string): void {
    const index = this.selectedSortiesIds.indexOf(sortieId);
    if (index > -1) {
      this.selectedSortiesIds.splice(index, 1);
    } else {
      this.selectedSortiesIds.push(sortieId);
    }
  }

  isSortieSelected(sortieId: string): boolean {
    return this.selectedSortiesIds.includes(sortieId);
  }

  async calculerSalaires(): Promise<void> {
    if (this.selectedSortiesIds.length === 0) {
      this.alertService.error(this.translate.instant('SALAIRES.ERROR_NO_SORTIE'));
      return;
    }

    const totalParts = this.marins.reduce((sum, marin) => sum + (marin.part || 0), 0);
    if (totalParts <= 0) {
        this.alertService.error(this.translate.instant('SALAIRES.ERROR_NO_PARTS'));
        return;
    }

    try {
      this.alertService.loading(this.translate.instant('MESSAGES.CALCULATING'));
      
      const allSorties = [...this.sortiesOuvertes, ...this.sortiesCalculees];
      const selectedSorties = allSorties.filter(s => this.selectedSortiesIds.includes(s.id!));

      const facturesPromises = this.selectedSortiesIds.map(sortieId =>
        this.factureService.getFacturesBySortie(sortieId).pipe(take(1)).toPromise()
      );
      const allFactures = await Promise.all(facturesPromises);
      const revenuTotal = allFactures.flat().reduce((sum, f) => sum + (f?.montantTotal || 0), 0);
      
      const depensesPromises = this.selectedSortiesIds.map(sortieId =>
        this.depenseService.getDepensesBySortie(sortieId).pipe(take(1)).toPromise()
      );
      const allDepenses = await Promise.all(depensesPromises);
      const totalDepenses = allDepenses.flat().reduce((sum: number, d: any) => sum + (d?.montant || 0), 0);
      
      const beneficeNet = revenuTotal - totalDepenses;
      const partProprietaire = beneficeNet * 0.5;
      const partEquipage = beneficeNet * 0.5;
      
      const totalNuits = selectedSorties.reduce((total, sortie) => total + this.calculerNombreNuits(sortie), 0);
      
      const deductionNuits = totalNuits * this.marins.length * 5;
      const montantAPartager = partEquipage - deductionNuits;

      for (const marin of this.marins) {
        const part = marin.part || 0;
        const salaireBrut = totalParts > 0 ? (montantAPartager * part) / totalParts : 0;
        const primeNuits = totalNuits * 5;

        const avances = await this.avanceService.getAvancesByMarin(marin.id!).pipe(take(1)).toPromise();
        const totalAvances = avances?.reduce((sum, a) => sum + a.montant, 0) || 0;

        const paiements = await this.paiementService.getPaiementsByMarin(marin.id!).pipe(take(1)).toPromise();
        const totalPaiements = paiements?.reduce((sum, p) => sum + p.montant, 0) || 0;
      }

      for (const sortieId of this.selectedSortiesIds) {
        await this.sortieService.updateSortie(sortieId, { salaireCalcule: true });
      }

      this.alertService.close();
      this.selectedSortiesIds = [];
      this.loadData(); 
      this.activeTab = 'historique'; 

      await Swal.fire({
        title: this.translate.instant('SALAIRES.CALCUL_SUCCESS_TITLE'),
        icon: 'success',
        confirmButtonColor: '#10b981'
      });

    } catch (error) {
      console.error('Erreur:', error);
      this.alertService.close();
      this.alertService.error();
    }
  }

  async viewCalculDetails(sortie: Sortie): Promise<void> {
    this.alertService.warning('Fonctionnalité à venir', 'Historique');
  }

  private calculerNombreNuits(sortie: Sortie): number {
    if (!sortie?.dateDepart || !sortie?.dateRetour) return 0;
    const depart = (sortie.dateDepart as any).toDate ? (sortie.dateDepart as any).toDate() : new Date(sortie.dateDepart);
    const retour = (sortie.dateRetour as any).toDate ? (sortie.dateRetour as any).toDate() : new Date(sortie.dateRetour);
    const diffTime = Math.abs(retour.getTime() - depart.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  formatDate(date: any): string {
    if (date?.toDate) return date.toDate().toLocaleDateString('fr-FR');
    if (date instanceof Date) return date.toLocaleDateString('fr-FR');
    return '';
  }
}
