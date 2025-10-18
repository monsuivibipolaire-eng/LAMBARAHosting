import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import Swal from 'sweetalert2';

import { SalaireService } from '../../services/salaire.service';
import { MarinService } from '../../services/marin.service';
import { SortieService } from '../../services/sortie.service';
import { AvanceService } from '../../services/avance.service';
import { DepenseService } from '../../services/depense.service'; // ✅ CORRECTION: DepenseService au lieu de ExpenseService
import { AlertService } from '../../services/alert.service';

import { CalculSalaire, DetailSalaireMarin } from '../../models/salaire.model';
import { Marin } from '../../models/marin.model';
import { Sortie } from '../../models/sortie.model';
import { Depense } from '../../models/depense.model'; // ✅ AJOUT: Import du modèle Depense

import { combineLatest } from 'rxjs';
import { take } from 'rxjs/operators';

@Component({
  selector: 'app-salaires',
  standalone: true,
  imports: [CommonModule, TranslateModule, RouterModule],
  templateUrl: './salaires.component.html',
  styleUrls: ['./salaires.component.scss']
})
export class SalairesComponent implements OnInit {
  sortieId!: string;
  sortie?: Sortie;
  marins: Marin[] = [];
  coefficients: { [marinId: string]: number } = {};
  calcul?: CalculSalaire;
  loading = true;

  constructor(
    private route: ActivatedRoute,
    private salaireService: SalaireService,
    private marinService: MarinService,
    private sortieService: SortieService,
    private avanceService: AvanceService,
    private depenseService: DepenseService, // ✅ CORRECTION: DepenseService
    private alertService: AlertService,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.sortieId = this.route.snapshot.paramMap.get('id')!;
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.sortieService.getSortie(this.sortieId).pipe(take(1)).subscribe(async sortie => {
      if (sortie && sortie.bateauId) {
        this.sortie = sortie;
        
        this.marinService.getMarinsByBateau(sortie.bateauId).pipe(take(1)).subscribe(async marins => {
          this.marins = marins;
          
          for (const marin of marins) {
            this.coefficients[marin.id!] = await this.salaireService.getCoefficient(marin.id!);
          }
          
          this.loading = false;
        });
      } else {
        this.loading = false;
      }
    });
  }

  async configureCoefficients(): Promise<void> {
    const marinsHtml = this.marins.map(marin => `
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; padding: 0.75rem; background: #f9fafb; border-radius: 0.5rem;">
        <span style="font-weight: 600;">${marin.prenom} ${marin.nom}</span>
        <input id="coeff-${marin.id}" type="number" value="${this.coefficients[marin.id!] || 0}" min="0" max="100" step="1" 
               style="width: 80px; padding: 0.5rem; border: 2px solid #e5e7eb; border-radius: 0.375rem; text-align: center;">
      </div>
    `).join('');

    const { value: confirmed } = await Swal.fire({
      title: 'Configuration des coefficients',
      html: `
        <div style="text-align: left; max-height: 400px; overflow-y: auto;">
          <p style="color: #6b7280; margin-bottom: 1rem;">Définissez le pourcentage de la part équipage pour chaque marin (total doit = 100%)</p>
          ${marinsHtml}
          <div style="margin-top: 1rem; padding: 1rem; background: #dbeafe; border-radius: 0.5rem;">
            <strong>Total: <span id="total-coeff">0</span>%</strong>
          </div>
        </div>
        <script>
          function updateTotal() {
            let total = 0;
            ${this.marins.map(m => `total += parseFloat(document.getElementById('coeff-${m.id}').value) || 0;`).join('')}
            document.getElementById('total-coeff').textContent = total.toFixed(0);
          }
          ${this.marins.map(m => `document.getElementById('coeff-${m.id}').addEventListener('input', updateTotal);`).join('')}
          updateTotal();
        </script>
      `,
      width: '600px',
      showCancelButton: true,
      confirmButtonText: 'Enregistrer',
      cancelButtonText: 'Annuler',
      confirmButtonColor: '#10b981',
      preConfirm: () => {
        const coeffs: { [key: string]: number } = {};
        let total = 0;
        
        for (const marin of this.marins) {
          const value = parseFloat((document.getElementById(`coeff-${marin.id}`) as HTMLInputElement).value) || 0;
          coeffs[marin.id!] = value;
          total += value;
        }
        
        if (Math.abs(total - 100) > 0.01) {
          Swal.showValidationMessage(`Le total doit être égal à 100% (actuellement: ${total.toFixed(0)}%)`);
          return false;
        }
        
        return coeffs;
      }
    });

    if (confirmed) {
      try {
        this.alertService.loading('Enregistrement...');
        
        for (const marinId in confirmed) {
          await this.salaireService.saveCoefficient(marinId, confirmed[marinId]);
          this.coefficients[marinId] = confirmed[marinId];
        }
        
        this.alertService.close();
        this.alertService.success('Coefficients enregistrés avec succès!');
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.error('Erreur lors de l\'enregistrement');
      }
    }
  }

  async calculerSalaires(): Promise<void> {
    if (!this.sortie) return;

    try {
      this.alertService.loading('Calcul des salaires en cours...');

      // 1. Récupérer le revenu total
      const revenuTotal = await this.getRevenuTotal();

      // 2. Récupérer les dépenses - ✅ CORRECTION: typage correct
      const depenses = await this.depenseService.getDepensesBySortie(this.sortieId).pipe(take(1)).toPromise();
      const totalDepenses = depenses?.reduce((sum: number, d: Depense) => sum + d.montant, 0) || 0;

      // 3. Calculer les parts
      const beneficeNet = revenuTotal - totalDepenses;
      const partProprietaire = beneficeNet * 0.5;
      const partEquipage = beneficeNet * 0.5;

      // 4. Calculer le nombre de nuits
      const nbNuits = this.calculerNombreNuits();
      const nbMarins = this.marins.length;
      const deductionNuits = nbNuits * nbMarins * 5;

      // 5. Montant à partager
      const montantAPartager = partEquipage - deductionNuits;

      // 6. Calculer pour chaque marin
      const detailsMarins: DetailSalaireMarin[] = [];

      for (const marin of this.marins) {
        const coefficient = this.coefficients[marin.id!] || 0;
        const salaireBase = (montantAPartager * coefficient) / 100;
        const primeNuits = nbNuits * 5;
        
        // Récupérer les avances
        const avances = await this.avanceService.getAvancesByMarin(marin.id!).pipe(take(1)).toPromise();
        const totalAvances = avances?.reduce((sum, a) => sum + a.montant, 0) || 0;
        
        const salaireNet = salaireBase + primeNuits - totalAvances;

        detailsMarins.push({
          marinId: marin.id!,
          marinNom: `${marin.prenom} ${marin.nom}`,
          coefficient,
          salaireBase,
          primenuits: primeNuits,
          avances: totalAvances,
          salaireNet
        });
      }

      // 7. Créer le calcul
      this.calcul = {
        sortieId: this.sortieId,
        dateCalcul: new Date(),
        revenuTotal,
        totalDepenses,
        partProprietaire,
        partEquipage,
        nbNuits,
        nbMarins,
        deductionNuits,
        montantAPartager,
        detailsMarins
      };

      // 8. Sauvegarder
      await this.salaireService.saveCalculSalaire(this.calcul);

      this.alertService.close();
      this.alertService.success('Salaires calculés avec succès!');

    } catch (error) {
      console.error('Erreur:', error);
      this.alertService.close();
      this.alertService.error('Erreur lors du calcul');
    }
  }

  private async getRevenuTotal(): Promise<number> {
    const { value } = await Swal.fire({
      title: 'Revenu total de la sortie',
      input: 'number',
      inputLabel: 'Montant en DT',
      inputPlaceholder: '0.00',
      showCancelButton: true,
      confirmButtonText: 'Continuer',
      cancelButtonText: 'Annuler'
    });

    return parseFloat(value) || 0;
  }

  private calculerNombreNuits(): number {
    if (!this.sortie?.dateDepart || !this.sortie?.dateRetour) return 0;

    const depart = this.sortie.dateDepart instanceof Date 
      ? this.sortie.dateDepart 
      : (this.sortie.dateDepart as any).toDate();
    
    const retour = this.sortie.dateRetour instanceof Date 
      ? this.sortie.dateRetour 
      : (this.sortie.dateRetour as any).toDate();

    const diffTime = Math.abs(retour.getTime() - depart.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    return diffDays;
  }

  getMarinName(marinId: string): string {
    const marin = this.marins.find(m => m.id === marinId);
    return marin ? `${marin.prenom} ${marin.nom}` : '';
  }
}
