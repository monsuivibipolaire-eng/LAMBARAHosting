import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import Swal from 'sweetalert2';
import { take } from 'rxjs/operators';
import { combineLatest } from 'rxjs';

import { SortieService, SortieDetails } from '../services/sortie.service';
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
import { CalculSalaire, DetailSalaireMarin } from '../models/salaire.model';
import { FactureVente } from '../models/facture-vente.model';
import { Depense } from '../models/depense.model';

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
  historiqueCalculs: CalculSalaire[] = [];
  
  // ✅ NOUVEAU: Stocke la liste complète de toutes les sorties pour le bateau
  private allBoatSorties: SortieDetails[] = [];

  dernierCalcul: CalculSalaire | null = null;
  accordionState: { [key: string]: boolean } = { summary: true, sharing: true, details: true };
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
    if (this.selectedBoat) { this.loadData(); } else { this.loading = false; }
  }

  loadData(): void {
    if (!this.selectedBoat?.id) return;
    this.loading = true;
    const boatId = this.selectedBoat.id;

    combineLatest([
      this.sortieService.getSortiesByBateau(boatId),
      this.marinService.getMarinsByBateau(boatId),
      this.salaireService.getCalculsByBateau(boatId)
    ]).subscribe(([sorties, marins, calculs]) => {
      // ✅ NOUVEAU: On stocke toutes les sorties ici
      this.allBoatSorties = sorties;
      
      this.sortiesOuvertes = sorties.filter(s => s.statut === 'terminee' && !s.salaireCalcule);
      this.marins = marins;
      
      this.historiqueCalculs = calculs.sort((a, b) =>  
        ((b.dateCalcul as any).toDate ? (b.dateCalcul as any).toDate() : new Date(b.dateCalcul)).getTime() - 
        ((a.dateCalcul as any).toDate ? (a.dateCalcul as any).toDate() : new Date(a.dateCalcul)).getTime()
      );

      this.loading = false;
    });
  }

  selectTab(tabName: 'ouvertes' | 'historique'): void {
    this.activeTab = tabName;
    this.dernierCalcul = null;
  }

  toggleSortie(sortieId: string): void {
    this.dernierCalcul = null;
    const index = this.selectedSortiesIds.indexOf(sortieId);
    if (index > -1) { this.selectedSortiesIds.splice(index, 1); } else { this.selectedSortiesIds.push(sortieId); }
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
      
      // ✅ CORRIGÉ: On filtre la liste complète et typée des sorties
      const selectedSorties = this.allBoatSorties.filter(s => this.selectedSortiesIds.includes(s.id!));

      const facturesPromises = this.selectedSortiesIds.map(id => this.factureService.getFacturesBySortie(id).pipe(take(1)).toPromise());
      const allFactures = await Promise.all(facturesPromises);
      const revenuTotal = allFactures.flat().reduce((sum, f) => sum + (f?.montant || 0), 0);
      
      const depensesPromises = this.selectedSortiesIds.map(id => this.depenseService.getDepensesBySortie(id).pipe(take(1)).toPromise());
      const allDepenses = await Promise.all(depensesPromises);
      const totalDepenses = allDepenses.flat().reduce((sum, d: any) => sum + (d?.montant || 0), 0);
      const beneficeNet = revenuTotal - totalDepenses;
      const partProprietaire = beneficeNet * 0.5;
      const partEquipage = beneficeNet * 0.5;
      
      // ✅ CORRIGÉ: Le reduce fonctionne car selectedSorties est maintenant de type Sortie[]
      const totalNuits = selectedSorties.reduce((total: number, s: Sortie) => total + this.calculerNombreNuits(s), 0);
      const deductionNuits = totalNuits * this.marins.length * 5;
      const montantAPartager = partEquipage - deductionNuits;

      const allPreviousCalculs = await this.salaireService.getCalculsByBateau(this.selectedBoat!.id!).pipe(take(1)).toPromise();

      let detailsMarins: DetailSalaireMarin[] = [];
      for (const marin of this.marins) {
        const part = marin.part || 0;
        const salaireBrut = totalParts > 0 ? (montantAPartager * part) / totalParts : 0;
        // ✅ CORRIGÉ: L'opération fonctionne car totalNuits est bien un 'number'
        const primeNuits = totalNuits * 5;
        
        let lastCalculDate = new Date(0);
        if (allPreviousCalculs) {
          const marinsPreviousCalculs = allPreviousCalculs.filter(c => 
            c.detailsMarins.some(d => d.marinId === marin.id!)
          );
          if (marinsPreviousCalculs.length > 0) {
            marinsPreviousCalculs.sort((a, b) => 
              ((b.dateCalcul as any).toDate ? (b.dateCalcul as any).toDate() : new Date(b.dateCalcul)).getTime() - 
              ((a.dateCalcul as any).toDate ? (a.dateCalcul as any).toDate() : new Date(a.dateCalcul)).getTime()
            );
            lastCalculDate = (marinsPreviousCalculs[0].dateCalcul as any).toDate ? (marinsPreviousCalculs[0].dateCalcul as any).toDate() : new Date(marinsPreviousCalculs[0].dateCalcul);
          }
        }
        
        const allAvances = await this.avanceService.getAvancesByMarin(marin.id!).pipe(take(1)).toPromise();
        const unsettledAvances = allAvances?.filter(avance => {
          const avanceDate = (avance.dateAvance as any).toDate ? (avance.dateAvance as any).toDate() : new Date(avance.dateAvance);
          return avanceDate > lastCalculDate;
        }) || [];

        const totalAvances = unsettledAvances.reduce((sum, a) => sum + a.montant, 0) || 0;
        const totalPaiements = 0; 
        const resteAPayer = salaireBrut + primeNuits - totalAvances; 

        detailsMarins.push({ marinId: marin.id!, marinNom: `${marin.prenom} ${marin.nom}`, part, salaireBrut, primeNuits, totalAvances, totalPaiements, resteAPayer });
      }

      const calculData: Omit<CalculSalaire, 'id'> = {
        bateauId: this.selectedBoat!.id!,
        sortiesIds: this.selectedSortiesIds,
        // ✅ CORRIGÉ: Le map fonctionne car selectedSorties est bien de type Sortie[]
        sortiesDestinations: selectedSorties.map((s: Sortie) => s.destination),
        dateCalcul: new Date(),
        revenuTotal, totalDepenses, beneficeNet, partProprietaire, partEquipage, deductionNuits, montantAPartager, detailsMarins,
        factures: allFactures.flat() as FactureVente[],
        depenses: allDepenses.flat() as Depense[]
      };
      
      const docRef = await this.salaireService.saveCalculSalaire(calculData);

      for (const sortieId of this.selectedSortiesIds) {
        await this.sortieService.updateSortie(sortieId, { salaireCalcule: true });
      }

      this.alertService.close();
      this.dernierCalcul = { ...calculData, id: docRef.id } as CalculSalaire;
      this.accordionState = { summary: true, sharing: true, details: true };
      this.selectedSortiesIds = [];
      this.loadData();
      this.alertService.toast(this.translate.instant('SALAIRES.CALCUL_SUCCESS_TITLE'), 'success');
    } catch (error) {
      console.error('Erreur:', error);
      this.alertService.close();
      this.alertService.error();
    }
  }
  
  async reopenSortieForRecalculation(sortie: Sortie): Promise<void> {
    try {
        this.alertService.loading(this.translate.instant('MESSAGES.UPDATING'));
        await this.sortieService.updateSortie(sortie.id!, { salaireCalcule: false });
        this.loadData();
        this.activeTab = 'ouvertes';
        this.alertService.success(this.translate.instant('SALAIRES.HISTORY.MOVED_FOR_RECALC'));
    } catch (error) { console.error(error); this.alertService.error(); }
  }

  public async displayCorrectedCalcul(calcul: CalculSalaire): Promise<void> {
    this.alertService.loading(this.translate.instant('MESSAGES.LOADING_DETAILS'));
    const correctedCalcul = JSON.parse(JSON.stringify(calcul));
    const calculSortiesIds = correctedCalcul.sortiesIds || [];

    for (const detail of correctedCalcul.detailsMarins) {
        const allPaiements = await this.paiementService.getPaiementsByMarin(detail.marinId).pipe(take(1)).toPromise() || [];
        
        const paiementsPourCettePeriode = allPaiements.filter(p =>
            p.sortiesIds && p.sortiesIds.some(id => calculSortiesIds.includes(id))
        );

        const totalPaiementsPourCettePeriode = paiementsPourCettePeriode.reduce((sum, p) => sum + p.montant, 0);

        detail.totalPaiements = totalPaiementsPourCettePeriode;

        const salaireTotal = detail.salaireBrut + detail.primeNuits;
        detail.resteAPayer = salaireTotal - detail.totalAvances - detail.totalPaiements;
    }

    this.dernierCalcul = correctedCalcul;
    this.accordionState = { summary: true, sharing: true, details: true };
    this.activeTab = 'historique';
    this.alertService.close();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  showRevenueDetails(): void {
      if (!this.dernierCalcul || !this.dernierCalcul.factures) return;
      const t = { title: this.translate.instant('SALAIRES.DETAILS_MODAL.REVENUE_TITLE'), invoiceNum: this.translate.instant('SALAIRES.DETAILS_MODAL.INVOICE_NUM'), client: this.translate.instant('SALAIRES.DETAILS_MODAL.CLIENT'), date: this.translate.instant('COMMON.DATE'), amount: this.translate.instant('COMMON.AMOUNT') };
      const rows = this.dernierCalcul.factures.map(f => `<tr><td>${f.numeroFacture}</td><td>${f.client}</td><td>${this.formatDate(f.dateVente)}</td><td class="amount">${f.montant.toFixed(2)} DT</td></tr>`).join('');
      const html = `<div class="details-modal-content"><table class="details-table"><thead><tr><th>${t.invoiceNum}</th><th>${t.client}</th><th>${t.date}</th><th class="amount">${t.amount}</th></tr></thead><tbody>${rows}</tbody></table></div>`;
      Swal.fire({ title: t.title, html: html, width: '800px', showCloseButton: true, showConfirmButton: false });
  }

  showExpenseDetails(): void {
      if (!this.dernierCalcul || !this.dernierCalcul.depenses) return;
      const t = { title: this.translate.instant('SALAIRES.DETAILS_MODAL.EXPENSE_TITLE'), type: this.translate.instant('EXPENSES.TYPE'), date: this.translate.instant('COMMON.DATE'), description: this.translate.instant('COMMON.DESCRIPTION'), amount: this.translate.instant('COMMON.AMOUNT') };
      const rows = this.dernierCalcul.depenses.map(d => `<tr><td>${this.translate.instant('EXPENSES.TYPES.' + d.type.toUpperCase())}</td><td>${this.formatDate(d.date)}</td><td>${d.description || '-'}</td><td class="amount">${d.montant.toFixed(2)} DT</td></tr>`).join('');
      const html = `<div class="details-modal-content"><table class="details-table"><thead><tr><th>${t.type}</th><th>${t.date}</th><th>${t.description}</th><th class="amount">${t.amount}</th></tr></thead><tbody>${rows}</tbody></table></div>`;
      Swal.fire({ title: t.title, html: html, width: '800px', showCloseButton: true, showConfirmButton: false });
  }

 async enregistrerPaiement(detail: DetailSalaireMarin): Promise<void> {
  const { value: montant } = await Swal.fire({
    title: this.translate.instant('SALAIRES.PAYMENT_MODAL_TITLE', { name: detail.marinNom }),
    input: 'number',
    inputLabel: this.translate.instant('SALAIRES.PAYMENT_MODAL_LABEL', { amount: detail.resteAPayer.toFixed(2) }),
    inputValue: detail.resteAPayer > 0 ? detail.resteAPayer.toFixed(2) : 0,
    showCancelButton: true,
    confirmButtonText: this.translate.instant('FORM.SAVE'),
    cancelButtonText: this.translate.instant('FORM.CANCEL'),
    confirmButtonColor: '#10b981',
    inputValidator: (value) => {
      if (!value) return this.translate.instant('FORM.REQUIRED');
      const amount = parseFloat(value);
      if (amount <= 0) return this.translate.instant('SALAIRES.PAYMENTMODAL.ERRORPOSITIVE');
      if (amount > detail.resteAPayer + 0.01) return this.translate.instant('SALAIRES.PAYMENTMODAL.ERROREXCEED');
      return null;
    }
  });

  if (montant) {
    try {
      this.alertService.loading(this.translate.instant('MESSAGES.SAVING'));
      const montantPaye = parseFloat(montant);

      await this.paiementService.addPaiement({
        marinId: detail.marinId,
        montant: montantPaye,
        datePaiement: new Date(),
        sortiesIds: this.dernierCalcul!.sortiesIds
      });
      
      detail.totalPaiements += montantPaye;
      
      const salaireTotal = detail.salaireBrut + detail.primeNuits;
      detail.resteAPayer = salaireTotal - detail.totalAvances - detail.totalPaiements;
      
      if (Math.abs(detail.resteAPayer) < 0.01) {
        detail.resteAPayer = 0;
      }

      if (this.dernierCalcul && this.dernierCalcul.id) {
        await this.salaireService.updateCalculSalaire(this.dernierCalcul.id, {
          detailsMarins: this.dernierCalcul.detailsMarins
        });
      }

      this.alertService.success(this.translate.instant('SALAIRES.PAYMENT_SUCCESS'));
    } catch (error) {
      console.error('Erreur:', error);
      this.alertService.error();
    }
  }
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

  toggleAccordion(panel: string): void {
    this.accordionState[panel] = !this.accordionState[panel];
  }
}
