import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';
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

interface SalaireDetail {
  marinId: string;
  marinNom: string;
  coefficient: number;
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
  sorties: Sortie[] = [];
  marins: Marin[] = [];
  selectedSortiesIds: string[] = [];
  coefficients: { [marinId: string]: number } = {};
  
  revenuTotal = 0;
  totalDepenses = 0;
  beneficeNet = 0;
  partProprietaire = 0;
  partEquipage = 0;
  totalNuits = 0;
  deductionNuits = 0;
  montantAPartager = 0;
  salairesDetails: SalaireDetail[] = [];
  calculated = false;
  loading = true;

  constructor(
    private sortieService: SortieService,
    private marinService: MarinService,
    private depenseService: DepenseService,
    private avanceService: AvanceService,
    private paiementService: PaiementService,
    private factureService: FactureVenteService,
    private selectedBoatService: SelectedBoatService,
    private alertService: AlertService
  ) {}

  ngOnInit(): void {
    this.selectedBoat = this.selectedBoatService.getSelectedBoat();
    console.log('🚢 Bateau sélectionné:', this.selectedBoat);
    
    if (this.selectedBoat) {
      this.loadData();
    } else {
      this.loading = false;
      console.warn('⚠️ Aucun bateau sélectionné');
    }
  }

  loadData(): void {
    if (!this.selectedBoat?.id) {
      console.error('❌ ID du bateau manquant');
      return;
    }

    console.log('📡 Chargement des sorties pour le bateau:', this.selectedBoat.id);

    this.sortieService.getSortiesByBateau(this.selectedBoat.id).subscribe((sorties: Sortie[]) => {
      console.log('📦 Toutes les sorties reçues:', sorties.length);
      console.log('📊 Détails des sorties:', sorties);
      
      // Afficher TOUTES les sorties (pas seulement terminées)
      this.sorties = sorties;
      
      console.log(`✅ ${this.sorties.length} sorties chargées (tous statuts)`);
      
      if (this.sorties.length === 0) {
        console.warn('⚠️ AUCUNE SORTIE TROUVÉE pour ce bateau!');
        console.warn('💡 Vérifiez que les données mock ont bien des sorties liées à ce bateau');
      }
    }, error => {
      console.error('❌ Erreur lors du chargement des sorties:', error);
    });

    this.marinService.getMarinsByBateau(this.selectedBoat.id).subscribe((marins: Marin[]) => {
      this.marins = marins;
      console.log('👥 Marins chargés:', marins.length);
      
      marins.forEach(marin => {
        this.coefficients[marin.id!] = 0;
      });
      
      this.loading = false;
    });
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

  async configureCoefficients(): Promise<void> {
    if (this.marins.length === 0) {
      this.alertService.error('Aucun marin disponible');
      return;
    }

    let html = '<div style="text-align: left; padding: 1rem;">';
    this.marins.forEach(marin => {
      html += `
        <div style="margin-bottom: 1rem;">
          <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">
            ${marin.prenom} ${marin.nom} (${marin.fonction})
          </label>
          <input 
            id="coeff-${marin.id}" 
            type="number" 
            value="${this.coefficients[marin.id!] || 0}" 
            min="0" 
            max="100"
            style="width: 100%; padding: 0.5rem; border: 1px solid #ddd; border-radius: 0.25rem;"
          />
        </div>
      `;
    });
    html += '</div>';

    const result = await Swal.fire({
      title: 'Configuration des coefficients',
      html,
      showCancelButton: true,
      confirmButtonText: 'Enregistrer',
      cancelButtonText: 'Annuler',
      confirmButtonColor: '#10b981',
      width: '600px'
    });

    if (result.isConfirmed) {
      this.marins.forEach(marin => {
        const input = document.getElementById(`coeff-${marin.id}`) as HTMLInputElement;
        if (input) {
          this.coefficients[marin.id!] = parseFloat(input.value) || 0;
        }
      });
      this.alertService.success('Coefficients enregistrés!');
    }
  }

  async calculerSalaires(): Promise<void> {
    if (this.selectedSortiesIds.length === 0) {
      this.alertService.error('Veuillez sélectionner au moins une sortie');
      return;
    }

    try {
      this.alertService.loading('Calcul en cours...');

      const facturesPromises = this.selectedSortiesIds.map(sortieId =>
        this.factureService.getFacturesBySortie(sortieId).pipe(take(1)).toPromise()
      );
      const allFactures = await Promise.all(facturesPromises);
      this.revenuTotal = allFactures.flat().reduce((sum, f) => sum + (f?.montantTotal || 0), 0);

      const depensesPromises = this.selectedSortiesIds.map(sortieId =>
        this.depenseService.getDepensesBySortie(sortieId).pipe(take(1)).toPromise()
      );
      const allDepenses = await Promise.all(depensesPromises);
      this.totalDepenses = allDepenses.flat().reduce((sum: number, d: any) => sum + (d?.montant || 0), 0);

      this.beneficeNet = this.revenuTotal - this.totalDepenses;
      this.partProprietaire = this.beneficeNet * 0.5;
      this.partEquipage = this.beneficeNet * 0.5;

      this.totalNuits = this.selectedSortiesIds.reduce((total, sortieId) => {
        const sortie = this.sorties.find(s => s.id === sortieId);
        return total + this.calculerNombreNuits(sortie!);
      }, 0);
      this.deductionNuits = this.totalNuits * this.marins.length * 5;
      this.montantAPartager = this.partEquipage - this.deductionNuits;

      this.salairesDetails = [];
      for (const marin of this.marins) {
        const coefficient = this.coefficients[marin.id!] || 0;
        const salaireBrut = (this.montantAPartager * coefficient) / 100;
        const primeNuits = this.totalNuits * 5;

        const avances = await this.avanceService.getAvancesByMarin(marin.id!).pipe(take(1)).toPromise();
        const totalAvances = avances?.reduce((sum, a) => sum + a.montant, 0) || 0;

        const paiements = await this.paiementService.getPaiementsByMarin(marin.id!).pipe(take(1)).toPromise();
        const totalPaiements = paiements?.reduce((sum, p) => sum + p.montant, 0) || 0;

        const resteAPayer = salaireBrut + primeNuits - totalAvances - totalPaiements;

        this.salairesDetails.push({
          marinId: marin.id!,
          marinNom: `${marin.prenom} ${marin.nom}`,
          coefficient,
          salaireBrut,
          primeNuits,
          totalAvances,
          totalPaiements,
          resteAPayer
        });
      }

      this.calculated = true;
      this.alertService.close();

      await Swal.fire({
        title: 'Calcul terminé !',
        html: `
          <div style="text-align: left; padding: 1rem;">
            <p><strong>Revenu total:</strong> ${this.revenuTotal.toFixed(2)} DT</p>
            <p><strong>Total dépenses:</strong> ${this.totalDepenses.toFixed(2)} DT</p>
            <p><strong>Bénéfice net:</strong> ${this.beneficeNet.toFixed(2)} DT</p>
            <p><strong>Part propriétaire (50%):</strong> ${this.partProprietaire.toFixed(2)} DT</p>
            <p><strong>Part équipage (50%):</strong> ${this.partEquipage.toFixed(2)} DT</p>
          </div>
        `,
        icon: 'success',
        confirmButtonColor: '#10b981'
      });
    } catch (error) {
      console.error('Erreur:', error);
      this.alertService.close();
      this.alertService.error('Erreur lors du calcul');
    }
  }

  async enregistrerPaiement(detail: SalaireDetail): Promise<void> {
    const { value: montant } = await Swal.fire({
      title: `Paiement pour ${detail.marinNom}`,
      input: 'number',
      inputLabel: `Montant à payer (Reste: ${detail.resteAPayer.toFixed(2)} DT)`,
      inputValue: detail.resteAPayer,
      showCancelButton: true,
      confirmButtonText: 'Enregistrer',
      cancelButtonText: 'Annuler',
      confirmButtonColor: '#10b981',
      inputValidator: (value) => {
        const amount = parseFloat(value);
        if (!value || amount <= 0) return 'Veuillez entrer un montant valide';
        if (amount > detail.resteAPayer) return 'Le montant ne peut pas dépasser le reste à payer';
        return null;
      }
    });

    if (montant) {
      try {
        this.alertService.loading('Enregistrement du paiement...');
        await this.paiementService.addPaiement({
          marinId: detail.marinId,
          montant: parseFloat(montant),
          datePaiement: new Date(),
          sortiesIds: this.selectedSortiesIds
        });
        this.alertService.close();
        this.alertService.success('Paiement enregistré!');
        await this.calculerSalaires();
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.close();
        this.alertService.error('Erreur lors de l\'enregistrement');
      }
    }
  }

  private calculerNombreNuits(sortie: Sortie): number {
    if (!sortie?.dateDepart || !sortie?.dateRetour) return 0;
    const depart = sortie.dateDepart instanceof Date ? sortie.dateDepart : (sortie.dateDepart as any).toDate();
    const retour = sortie.dateRetour instanceof Date ? sortie.dateRetour : (sortie.dateRetour as any).toDate();
    const diffTime = Math.abs(retour.getTime() - depart.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  formatDate(date: any): string {
    if (date?.toDate) return date.toDate().toLocaleDateString('fr-FR');
    if (date instanceof Date) return date.toLocaleDateString('fr-FR');
    return '';
  }
}
