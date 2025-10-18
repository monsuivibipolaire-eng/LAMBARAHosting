#!/bin/bash

# ===================================================================================
# SCRIPT POUR AJOUTER LA FONCTIONNALITÉ DE PAIEMENT DANS LES RÉSULTATS DE SALAIRE
# -----------------------------------------------------------------------------------
# Ce script ajoute un bouton "Payer" dans le tableau des résultats de calcul,
# permettant d'enregistrer des paiements partiels ou complets pour chaque marin
# et de mettre à jour leur solde instantanément.
# ===================================================================================

echo "🚀 Implémentation de la fonctionnalité de paiement des salaires..."

TS_PATH="./src/app/salaires/salaires-list.component.ts"
HTML_PATH="./src/app/salaires/salaires-list.component.html"
SCSS_PATH="./src/app/salaires/salaires-list.component.scss"
FR_JSON="./src/assets/i18n/fr.json"

# --- 1. Mettre à jour la logique du composant (.ts) ---
echo "Mise à jour de $TS_PATH..."
if [ -f "$TS_PATH" ]; then
cat > "$TS_PATH" << 'EOF'
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
      const revenuTotal = allFactures.flat().reduce((sum, f) => sum + (f?.montantTotal || 0), 0);
      
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
      const rows = this.dernierCalcul.factures.map(f => `<tr><td>${f.numeroFacture}</td><td>${f.client}</td><td>${this.formatDate(f.dateVente)}</td><td class="amount">${f.montantTotal.toFixed(2)} DT</td></tr>`).join('');
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
        if (!value) { return this.translate.instant('FORM.REQUIRED'); }
        const amount = parseFloat(value);
        if (amount <= 0) { return this.translate.instant('SALAIRES.PAYMENT_MODAL.ERROR_POSITIVE'); }
        if (amount > detail.resteAPayer) { return this.translate.instant('SALAIRES.PAYMENT_MODAL.ERROR_EXCEED'); }
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
EOF
else
  echo "❌ Erreur : Le fichier $TS_PATH n'a pas été trouvé."
fi

# --- 2. Mettre à jour le template HTML ---
echo "Mise à jour de $HTML_PATH..."
if [ -f "$HTML_PATH" ]; then
cat > "$HTML_PATH" << 'EOF'
<div class="salaires-container">
  <div class="header">
    <h1 class="title">{{ 'SALAIRES.TITLE' | translate }}</h1>
  </div>

  <div *ngIf="loading" class="loading">
    <div class="spinner"></div>
    <p>{{ 'MESSAGES.LOADING' | translate }}</p>
  </div>

  <div *ngIf="!loading && selectedBoat" class="content">
    <div class="tabs">
      <button class="tab-button" [class.active]="activeTab === 'ouvertes'" (click)="selectTab('ouvertes')">
        {{ 'SALAIRES.TABS.OPEN_TRIPS' | translate }}
        <span class="badge">{{ sortiesOuvertes.length }}</span>
      </button>
      <button class="tab-button" [class.active]="activeTab === 'historique'" (click)="selectTab('historique')">
        {{ 'SALAIRES.TABS.HISTORY' | translate }}
        <span class="badge">{{ sortiesCalculees.length }}</span>
      </button>
    </div>

    <div *ngIf="dernierCalcul" class="results-container">
      <div class="results-header">
        <h2>{{ 'SALAIRES.RESULTS.TITLE' | translate }} : {{ dernierCalcul.sortiesDestinations.join(', ') }}</h2>
        <button class="btn-close-results" (click)="dernierCalcul = null" [title]="'SALAIRES.RESULTS.CLOSE' | translate">
          <svg fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        </button>
      </div>

      <div class="accordion">
        <div class="accordion-item">
          <button class="accordion-header" (click)="toggleAccordion('summary')">
            <span>{{ 'SALAIRES.RESULTS.FINANCIAL_SUMMARY' | translate }}</span>
            <svg class="chevron" [class.rotate]="accordionState['summary']" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
          </button>
          <div class="accordion-content" [class.open]="accordionState['summary']">
            <div class="summary-grid">
              <div class="summary-item">
                <span>{{ 'SALAIRES.REVENU_TOTAL' | translate }}</span>
                <strong class="revenue">
                  {{ dernierCalcul.revenuTotal | number:'1.2-2' }} DT
                  <button (click)="showRevenueDetails()" class="details-link">({{ 'COMMON.VIEW_DETAILS' | translate }})</button>
                </strong>
              </div>
              <div class="summary-item">
                <span>{{ 'SALAIRES.TOTAL_DEPENSES' | translate }}</span>
                <strong class="expenses">
                  {{ dernierCalcul.totalDepenses | number:'1.2-2' }} DT
                  <button (click)="showExpenseDetails()" class="details-link">({{ 'COMMON.VIEW_DETAILS' | translate }})</button>
                </strong>
              </div>
              <div class="summary-item"><span>{{ 'SALAIRES.BENEFICE_NET' | translate }}</span><strong class="benefit">{{ dernierCalcul.beneficeNet | number:'1.2-2' }} DT</strong></div>
            </div>
          </div>
        </div>

        <div class="accordion-item">
          <button class="accordion-header" (click)="toggleAccordion('sharing')">
            <span>{{ 'SALAIRES.RESULTS.PROFIT_SHARING' | translate }}</span>
            <svg class="chevron" [class.rotate]="accordionState['sharing']" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
          </button>
          <div class="accordion-content" [class.open]="accordionState['sharing']">
             <div class="summary-grid">
              <div class="summary-item"><span>{{ 'SALAIRES.PART_PROPRIETAIRE' | translate }}</span><strong>{{ dernierCalcul.partProprietaire | number:'1.2-2' }} DT</strong></div>
              <div class="summary-item"><span>{{ 'SALAIRES.PART_EQUIPAGE' | translate }}</span><strong>{{ dernierCalcul.partEquipage | number:'1.2-2' }} DT</strong></div>
              <div class="summary-item"><span>- Déductions</span><strong class="expenses">{{ dernierCalcul.deductionNuits | number:'1.2-2' }} DT</strong></div>
              <div class="summary-item net-share"><span>{{ 'SALAIRES.MONTANT_A_PARTAGER' | translate }}</span><strong>{{ dernierCalcul.montantAPartager | number:'1.2-2' }} DT</strong></div>
            </div>
          </div>
        </div>

        <div class="accordion-item">
          <button class="accordion-header" (click)="toggleAccordion('details')">
            <span>{{ 'SALAIRES.DETAILS_PAR_MARIN' | translate }}</span>
            <svg class="chevron" [class.rotate]="accordionState['details']" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
          </button>
          <div class="accordion-content" [class.open]="accordionState['details']">
            <div class="table-container">
              <table class="salaires-table">
                <thead>
                  <tr>
                    <th>{{ 'SAILORS.TITLE' | translate }}</th>
                    <th>{{ 'SAILORS.PART' | translate }}</th>
                    <th>{{ 'SALAIRES.SALAIRE_BASE' | translate }}</th>
                    <th>{{ 'SALAIRES.PRIME_NUITS' | translate }}</th>
                    <th>{{ 'AVANCES.TITLE' | translate }}</th>
                    <th>{{ 'SALAIRES.DEJA_PAYE' | translate }}</th>
                    <th class="reste">{{ 'SALAIRES.RESTE_A_PAYER' | translate }}</th>
                    <th>{{ 'BOATS.ACTIONS' | translate }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr *ngFor="let detail of dernierCalcul.detailsMarins">
                    <td class="marin-name">{{ detail.marinNom }}</td>
                    <td>{{ detail.part }}</td>
                    <td>{{ detail.salaireBrut | number:'1.2-2' }} DT</td>
                    <td>{{ detail.primeNuits | number:'1.2-2' }} DT</td>
                    <td class="avances">{{ detail.totalAvances | number:'1.2-2' }} DT</td>
                    <td class="paiements">{{ detail.totalPaiements | number:'1.2-2' }} DT</td>
                    <td class="reste"><strong>{{ detail.resteAPayer | number:'1.2-2' }} DT</strong></td>
                    <td>
                      <button class="btn btn-sm btn-pay" (click)="enregistrerPaiement(detail)" [disabled]="detail.resteAPayer <= 0.01">
                        {{ detail.resteAPayer > 0.01 ? ('SALAIRES.PAYER' | translate) : ('SALAIRES.PAYE' | translate) }}
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div *ngIf="!dernierCalcul">
      <div *ngIf="activeTab === 'ouvertes'" class="tab-content">
        <div class="section-card">
          <h2>{{ 'SORTIES.SELECTSORTIES' | translate }}</h2>
          <div *ngIf="sortiesOuvertes.length > 0; else noOpenTrips" class="sorties-list">
            <div *ngFor="let sortie of sortiesOuvertes" 
                 class="sortie-item" [class.selected]="isSortieSelected(sortie.id!)" (click)="toggleSortie(sortie.id!)">
              <input type="checkbox" [checked]="isSortieSelected(sortie.id!)" (click)="$event.stopPropagation()">
              <div class="sortie-info">
                <strong>{{ sortie.destination }}</strong>
                <span>{{ formatDate(sortie.dateDepart) }} - {{ formatDate(sortie.dateRetour) }}</span>
              </div>
            </div>
          </div>
          <ng-template #noOpenTrips><div class="no-data-small"><p>{{ 'SALAIRES.NO_OPEN_TRIPS' | translate }}</p></div></ng-template>
          
          <button class="btn btn-success btn-lg" (click)="calculerSalaires()" [disabled]="selectedSortiesIds.length === 0 || marins.length === 0">
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
            {{ 'SALAIRES.CALCULER' | translate }}
          </button>
        </div>
      </div>

      <div *ngIf="activeTab === 'historique'" class="tab-content">
        <div class="section-card">
          <h2>{{ 'SALAIRES.TABS.CALCULATED_TRIPS' | translate }}</h2>
          <div *ngIf="sortiesCalculees.length > 0; else noCalculatedTrips" class="sorties-list-history">
            <div *ngFor="let sortie of sortiesCalculees" class="sortie-item-history">
              <div class="sortie-info">
                <strong>{{ sortie.destination }}</strong>
                <span>{{ formatDate(sortie.dateDepart) }} - {{ formatDate(sortie.dateRetour) }}</span>
              </div>
              <button class="btn btn-secondary btn-sm" (click)="viewCalculDetails(sortie)">{{ 'COMMON.VIEW_DETAILS' | translate }}</button>
            </div>
          </div>
          <ng-template #noCalculatedTrips><div class="no-data-small"><p>{{ 'SALAIRES.NO_CALCULATED_TRIPS' | translate }}</p></div></ng-template>
        </div>
      </div>
    </div>
  </div>
</div>
EOF
else
  echo "❌ Erreur : Le fichier $HTML_PATH n'a pas été trouvé."
fi


# --- 3. Mettre à jour le fichier SCSS ---
echo "Mise à jour de $SCSS_PATH..."
if [ -f "$SCSS_PATH" ]; then
cat >> "$SCSS_PATH" << 'EOF'

/* Styles pour le bouton Payer */
.btn-pay {
  background-color: #3b82f6;
  color: white;
  &:hover:not(:disabled) {
    background-color: #2563eb;
  }
  &:disabled {
    background-color: #d1d5db;
    cursor: not-allowed;
  }
}
EOF
else
    echo "❌ Erreur : Le fichier $SCSS_PATH n'a pas été trouvé."
fi

# --- 4. Mettre à jour le fichier de traduction ---
echo "Mise à jour de $FR_JSON..."
if [ -f "$FR_JSON" ]; then
    # Utilisation d'une commande sed compatible macOS et Linux
    sed -i.bak -e $'/^    "PAYMENT_MODAL_LABEL":/a\\\n    ,"PAYMENT_MODAL": { "ERROR_POSITIVE": "Le montant doit être positif.", "ERROR_EXCEED": "Le montant ne peut pas dépasser le reste à payer." }' "$FR_JSON"
else
    echo "❌ Erreur : Le fichier $FR_JSON n'a pas été trouvé."
fi

rm -f ./*.bak

echo "✅ Script terminé. La fonctionnalité de paiement a été ajoutée."