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
  sortiesCalculees: Sortie[] = [];
  historiqueCalculs: { [sortieId: string]: CalculSalaire[] } = {};

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

    this.sortieService.getSortiesByBateau(boatId).subscribe((sorties: Sortie[]) => {
      this.sortiesOuvertes = sorties.filter(s => s.statut === 'terminee' && !s.salaireCalcule);
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
      const allSorties = [...this.sortiesOuvertes, ...this.sortiesCalculees];
      const selectedSorties = allSorties.filter(s => this.selectedSortiesIds.includes(s.id!));

      const facturesPromises = this.selectedSortiesIds.map(id => this.factureService.getFacturesBySortie(id).pipe(take(1)).toPromise());
      const allFactures = await Promise.all(facturesPromises);
      const revenuTotal = allFactures.flat().reduce((sum, f) => sum + (f?.montant || 0), 0);
      
      const depensesPromises = this.selectedSortiesIds.map(id => this.depenseService.getDepensesBySortie(id).pipe(take(1)).toPromise());
      const allDepenses = await Promise.all(depensesPromises);
      const totalDepenses = allDepenses.flat().reduce((sum, d: any) => sum + (d?.montant || 0), 0);
      
      const beneficeNet = revenuTotal - totalDepenses;
      const partProprietaire = beneficeNet * 0.5;
      const partEquipage = beneficeNet * 0.5;
      const totalNuits = selectedSorties.reduce((total, s) => total + this.calculerNombreNuits(s), 0);
      const deductionNuits = totalNuits * this.marins.length * 5;
      const montantAPartager = partEquipage - deductionNuits;

      let detailsMarins: DetailSalaireMarin[] = [];
      for (const marin of this.marins) {
        const part = marin.part || 0;
        const salaireBrut = totalParts > 0 ? (montantAPartager * part) / totalParts : 0;
        const primeNuits = totalNuits * 5;
        const avances = await this.avanceService.getAvancesByMarin(marin.id!).pipe(take(1)).toPromise();
        const totalAvances = avances?.reduce((sum, a) => sum + a.montant, 0) || 0;
        const paiements = await this.paiementService.getPaiementsByMarin(marin.id!).pipe(take(1)).toPromise();
        const totalPaiements = paiements?.reduce((sum, p) => sum + p.montant, 0) || 0;
        const resteAPayer = salaireBrut + primeNuits - totalAvances - totalPaiements;
        detailsMarins.push({ marinId: marin.id!, marinNom: `${marin.prenom} ${marin.nom}`, part, salaireBrut, primeNuits, totalAvances, totalPaiements, resteAPayer });
      }

      const calculData: Omit<CalculSalaire, 'id'> = {
        bateauId: this.selectedBoat!.id!,
        sortiesIds: this.selectedSortiesIds,
        sortiesDestinations: selectedSorties.map(s => s.destination),
        dateCalcul: new Date(),
        revenuTotal, totalDepenses, beneficeNet, partProprietaire, partEquipage, deductionNuits, montantAPartager, detailsMarins,
        factures: allFactures.flat() as FactureVente[],
        depenses: allDepenses.flat() as Depense[]
      };
      await this.salaireService.saveCalculSalaire(calculData);

      for (const sortieId of this.selectedSortiesIds) {
        await this.sortieService.updateSortie(sortieId, { salaireCalcule: true });
      }

      this.alertService.close();
      this.dernierCalcul = calculData as CalculSalaire;
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

  async viewCalculDetails(sortie: Sortie): Promise<void> {
    this.alertService.loading(this.translate.instant('MESSAGES.LOADING_DETAILS'));
    if (this.historiqueCalculs[sortie.id!]) {
      this.displayCalculInView(this.historiqueCalculs[sortie.id!][0]);
      return;
    }
    this.salaireService.getCalculsBySortieId(sortie.id!).pipe(take(1)).subscribe({
        next: async (calculs) => {
            if (calculs && calculs.length > 0) {
                this.historiqueCalculs[sortie.id!] = calculs;
                this.displayCalculInView(calculs[0]);
            } else {
                this.alertService.close();
                const res = await Swal.fire({
                    title: this.translate.instant('SALAIRES.HISTORY.NO_DATA_FOUND_TITLE'), text: this.translate.instant('SALAIRES.HISTORY.NO_DATA_FOUND_TEXT'),
                    icon: 'info', showCancelButton: true, confirmButtonText: this.translate.instant('SALAIRES.HISTORY.RECALCULATE_BTN'),
                    cancelButtonText: this.translate.instant('FORM.CANCEL'), confirmButtonColor: '#10b981'
                });
                if (res.isConfirmed) { await this.reopenSortieForRecalculation(sortie); }
            }
        },
        error: (err) => { console.error(err); this.alertService.error(); }
    });
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

  private displayCalculInView(calcul: CalculSalaire): void {
    this.dernierCalcul = calcul;
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

  // ✅ NOUVELLE MÉTHODE POUR ENREGISTRER UN PAIEMENT
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
        // ✅ CORRECTION: Permettre le paiement exact du solde
        if (amount > detail.resteAPayer + 0.005) return this.translate.instant('SALAIRES.PAYMENTMODAL.ERROREXCEED');
        return null;
      }
    });

    if (montant) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.SAVING'));
        const montantPaye = parseFloat(montant);

      // 1. Enregistrer le paiement dans la collection "paiements"
      await this.paiementService.addPaiement({
        marinId: detail.marinId,
        montant: montantPaye,
        datePaiement: new Date(),
        sortiesIds: this.dernierCalcul!.sortiesIds
      });

      // 2. Mettre à jour l'état local
      detail.totalPaiements += montantPaye;
      detail.resteAPayer -= montantPaye;

      // 3. ✅ NOUVEAU: Sauvegarder dans Firestore (calculs_salaire)
      if (this.dernierCalcul && this.dernierCalcul.id) {
        await this.salaireService.updateCalculSalaire(this.dernierCalcul.id, {
          detailsMarins: this.dernierCalcul.detailsMarins
        });
      }

        // Mettre à jour l'état local pour un rafraîchissement instantané
        detail.totalPaiements += montantPaye;
        detail.resteAPayer -= montantPaye;

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
