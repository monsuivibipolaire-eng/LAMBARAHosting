import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Firestore, collection, query, where, orderBy, collectionData, doc, updateDoc } from '@angular/fire/firestore';
import { Observable, combineLatest, forkJoin } from 'rxjs';
import { SelectedBoatService } from '../services/selected-boat.service';
import { MarinService } from '../services/marin.service';
import { SalaireService } from '../services/salaire.service';
import { AvanceService } from '../services/avance.service';
import { FactureVenteService } from '../services/facture-vente.service';
import { DepenseService } from '../services/depense.service';
import { FinancialEventsService } from '../services/financial-events.service';
import { SortieMer } from '../models/sortie-mer.model';
import { Marin } from '../models/marin.model';

@Component({
  selector: 'app-salaires-list',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './salaires-list.component.html',
  styleUrls: ['./salaires-list.component.scss']
})
export class SalairesListComponent implements OnInit {

  // Retourne le total des ventes d’une sortie
  getTotalVentesSortie(sortie: any): number { return sortie.totalVentes ?? 0; }


  /**
   * Helper: total des ventes pour une sortie (doit être chargé au préalable)
   */
  selectedBoat: any = null;
  sorties: SortieMer[] = [];  // Toutes les sorties (ouvertes + fermées)
  marins: Marin[] = [];
  historiqueDesCalculs: any[] = [];
  sortiesOuvertes: number = 0;
  sortiesCalculees: number = 0;
  selectedSortiesIds: string[] = [];  // Sorties sélectionnées par l'utilisateur
  resultatCalcul: any[] = [];  // Résultats détaillés par marin (avances, salaire, reste)

  constructor(
    private firestore: Firestore,
    private selectedBoatService: SelectedBoatService,
    private marinService: MarinService,
    private salaireService: SalaireService,
    private avanceService: AvanceService,
    private factureVenteService: FactureVenteService,
    private depenseService: DepenseService,
    private finEvents: FinancialEventsService
  ) {}

  ngOnInit(): void {
    this.selectedBoat = this.selectedBoatService.getSelectedBoat();
    if (this.selectedBoat && this.selectedBoat.id) {
      this.loadData();
    }

    // Recharger données à chaque changement financier
    this.finEvents.change$.subscribe(() => {
      this.selectedBoat = this.selectedBoatService.getSelectedBoat();
      if (this.selectedBoat && this.selectedBoat.id) {
        this.loadData();
      }
    });
  }

  loadData(): void {
    const bateauId = this.selectedBoat.id;
    const sortiesCollection = collection(this.firestore, 'sorties-mer');
    const sortiesQuery = query(
      sortiesCollection,
      where('bateauId', '==', bateauId),
      orderBy('dateFin', 'desc')  // Ordre descendant par date (plus récentes en premier)
    );

    const sorties$ = collectionData(sortiesQuery, { idField: 'id' }) as Observable<SortieMer[]>;
    const marins$ = this.marinService.getMarinsByBateau(bateauId);
    const calculs$ = this.salaireService.getCalculsByBateau(bateauId);

    combineLatest([sorties$, marins$, calculs$]).subscribe(([sorties, marins, calculs]) => {
      this.sorties = sorties;
      this.marins = marins || [];
      this.historiqueDesCalculs = calculs ? calculs.sort((a, b) => 
        new Date(b.dateCalcul).getTime() - new Date(a.dateCalcul).getTime()
      ) : [];

      // Stats
      this.sortiesOuvertes = sorties.filter(s => !s.salaireCalcule && s.statut === 'terminee').length;
      this.sortiesCalculees = sorties.filter(s => s.salaireCalcule === true).length;
    });
  }

  // Sélection des sorties
  isSortieSelected(sortieId: string): boolean {
    return this.selectedSortiesIds.includes(sortieId);
  }

  toggleSortieSelection(sortieId: string): void {
    const index = this.selectedSortiesIds.indexOf(sortieId);
    if (index > -1) {
      this.selectedSortiesIds.splice(index, 1);
    } else {
      this.selectedSortiesIds.push(sortieId);
    }
  }

  isAllSelected(): boolean {
    const selectables = this.sorties.filter(s => !s.salaireCalcule && s.statut === 'terminee');
    return selectables.length > 0 && selectables.every(s => this.selectedSortiesIds.includes(s.id!));
  }

  toggleSelectAll(event: any): void {
    const checked = event.target.checked;
    const selectables = this.sorties.filter(s => !s.salaireCalcule && s.statut === 'terminee');
    if (checked) {
      this.selectedSortiesIds = selectables.map(s => s.id!);
    } else {
      this.selectedSortiesIds = [];
    }
  }

  // Calculer UNE seule sortie (bouton sur la ligne)
  async calculerUneSortie(sortieId: string): Promise<void> {
    this.selectedSortiesIds = [sortieId];
    await this.calculerSalairesSelectionnes();
  }

  // Calculer TOUTES les sorties sélectionnées
  async calculerSalairesSelectionnes(): Promise<void> {
    if (this.selectedSortiesIds.length === 0) {
      alert('يرجى اختيار رحلة واحدة على الأقل');
      return;
    }

    console.log('🔄 Calcul des salaires pour', this.selectedSortiesIds.length, 'sorties...');
    
    try {
      // Charger les données financières pour chaque sortie sélectionnée
      const calculsParMarin: any = {};  // { marinId: { avances, salaire, reste } }

      // Pour chaque marin, calculer son salaire total sur les sorties sélectionnées
      for (const marin of this.marins) {
        let totalAvances = 0;
        let salaireCalcule = 0;

        for (const sortieId of this.selectedSortiesIds) {
          const sortie = this.sorties.find(s => s.id === sortieId);
          if (!sortie) continue;

          // Charger avances du marin pour cette sortie
          const avances = await this.avanceService.getAvancesByMarin(marin.id!).toPromise();
          const avancesSortie = avances?.filter(a => a.id === sortieId) || [];
          totalAvances += avancesSortie.reduce((sum, a) => sum + a.montant, 0);

          // Calculer salaire (exemple simplifié : revenus - dépenses, réparti selon coefficient)
          const ventes = await this.factureVenteService.getFacturesBySortie(sortieId).toPromise();
          const depenses = await this.depenseService.getDepensesBySortie(sortieId).toPromise();
          
          const totalVentes = ventes?.reduce((sum, v) => sum + v.montant, 0) || 0;
          const totalDepenses = depenses?.reduce((sum, d) => sum + d.montant, 0) || 0;
          const benefice = totalVentes - totalDepenses;

          // Répartir selon coefficient (somme coefficients tous marins)
          const sommeCoefficients = this.marins.reduce((sum, m) => sum + m.coefficientSalaire, 0);
          const partMarin = (benefice * marin.coefficientSalaire) / sommeCoefficients;
          salaireCalcule += partMarin;
        }

        calculsParMarin[marin.id!] = {
          nom: marin.nom,
          prenom: marin.prenom,
          fonction: marin.fonction,
          totalAvances,
          salaireCalcule,
          resteAPayer: salaireCalcule - totalAvances
        };
      }

      // Afficher résultats
      this.resultatCalcul = Object.values(calculsParMarin);
      console.log('✅ Calcul terminé:', this.resultatCalcul);

      // Marquer les sorties comme calculées
      for (const sortieId of this.selectedSortiesIds) {
        const sortieRef = doc(this.firestore, 'sorties-mer', sortieId);
        await updateDoc(sortieRef, { salaireCalcule: true });
      }

      // Sauvegarder l'historique du calcul
      await this.salaireService.saveCalculSalaire({
        bateauId: this.selectedBoat.id,
        dateCalcul: new Date(),
        nombreSorties: this.selectedSortiesIds.length,
        total: this.getTotalSalaires(),
        marins: this.resultatCalcul.map(m => m.nom + ' ' + m.prenom)
      } as any);

      // Réinitialiser sélection et recharger
      this.selectedSortiesIds = [];
      this.loadData();
      this.finEvents.notifyFinancialChange();

      alert('تم حساب الرواتب بنجاح');
    } catch (error) {
      console.error('Erreur calcul:', error);
      alert('حدث خطأ أثناء حساب الرواتب');
    }
  }

  // Totaux pour affichage
  getTotalAvances(): number {
    return this.resultatCalcul.reduce((sum, m) => sum + m.totalAvances, 0);
  }

  getTotalSalaires(): number {
    return this.resultatCalcul.reduce((sum, m) => sum + m.salaireCalcule, 0);
  }

  getTotalReste(): number {
    return this.resultatCalcul.reduce((sum, m) => sum + m.resteAPayer, 0);
  }
}

  // Méthode helper pour calculer total ventes d'une sortie (pour affichage dans template)
