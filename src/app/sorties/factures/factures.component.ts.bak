import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import Swal from 'sweetalert2';

import { FactureVenteService } from '../../services/facture-vente.service';
import { SortieService } from '../../services/sortie.service';
import { AlertService } from '../../services/alert.service';

import { FactureVente } from '../../models/facture-vente.model';
import { Sortie } from '../../models/sortie.model';

import { take } from 'rxjs/operators';

@Component({
  selector: 'app-factures',
  standalone: true,
  imports: [CommonModule, TranslateModule, RouterModule],
  templateUrl: './factures.component.html',
  styleUrls: ['./factures.component.scss']
})
export class FacturesComponent implements OnInit {
  sortieId!: string;
  sortie?: Sortie;
  factures: FactureVente[] = [];
  loading = true;

  constructor(
    private route: ActivatedRoute,
    private factureService: FactureVenteService,
    private sortieService: SortieService,
    private alertService: AlertService,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.sortieId = this.route.snapshot.paramMap.get('id')!;
    this.loadData();
  }

  loadData(): void {
    this.sortieService.getSortie(this.sortieId).pipe(take(1)).subscribe(sortie => {
      this.sortie = sortie;
      
      this.factureService.getFacturesBySortie(this.sortieId).subscribe(factures => {
        this.factures = factures;
        this.loading = false;
      });
    });
  }

  getTotalVentes(): number {
    return this.factures.reduce((sum, f) => sum + f.montantTotal, 0);
  }

  async ajouterFacture(): Promise<void> {
    const { value: formValues } = await Swal.fire({
      title: 'Ajouter une facture de vente',
      html: `
        <div style="text-align: left; padding: 1rem;">
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">N° Facture *</label>
            <input id="swal-numero" type="text" class="swal2-input" placeholder="F-001" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">Client *</label>
            <input id="swal-client" type="text" class="swal2-input" placeholder="Nom du client" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">Date de vente *</label>
            <input id="swal-date" type="date" class="swal2-input" value="${this.getTodayDate()}" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">Montant total (DT) *</label>
            <input id="swal-montant" type="number" class="swal2-input" placeholder="0.00" step="0.01" min="0" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">Détails (poissons vendus)</label>
            <textarea id="swal-details" class="swal2-textarea" placeholder="Ex: 50 kg de dorade, 30 kg de loup..." style="width: 90%;"></textarea>
          </div>
        </div>
      `,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: 'Ajouter',
      cancelButtonText: 'Annuler',
      confirmButtonColor: '#10b981',
      width: '600px',
      preConfirm: () => {
        const numero = (document.getElementById('swal-numero') as HTMLInputElement).value;
        const client = (document.getElementById('swal-client') as HTMLInputElement).value;
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;
        const montant = parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value);
        const details = (document.getElementById('swal-details') as HTMLTextAreaElement).value;

        if (!numero || !client || !date || !montant) {
          Swal.showValidationMessage('Veuillez remplir tous les champs obligatoires');
          return false;
        }

        if (montant <= 0) {
          Swal.showValidationMessage('Le montant doit être supérieur à 0');
          return false;
        }

        return { numero, client, date, montant, details };
      }
    });

    if (formValues) {
      try {
        this.alertService.loading('Ajout de la facture...');

        const newFacture: Omit<FactureVente, 'id'> = {
          sortieId: this.sortieId,
          numeroFacture: formValues.numero,
          client: formValues.client,
          dateVente: new Date(formValues.date),
          montantTotal: formValues.montant,
          details: formValues.details || undefined
        };

        await this.factureService.addFacture(newFacture);
        
        this.alertService.close();
        this.alertService.success('Facture ajoutée avec succès!');
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.close();
        this.alertService.error('Erreur lors de l\'ajout');
      }
    }
  }

  async modifierFacture(facture: FactureVente): Promise<void> {
    const { value: formValues } = await Swal.fire({
      title: 'Modifier la facture',
      html: `
        <div style="text-align: left; padding: 1rem;">
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">N° Facture *</label>
            <input id="swal-numero" type="text" class="swal2-input" value="${facture.numeroFacture}" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">Client *</label>
            <input id="swal-client" type="text" class="swal2-input" value="${facture.client}" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">Date de vente *</label>
            <input id="swal-date" type="date" class="swal2-input" value="${this.formatDate(facture.dateVente)}" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">Montant total (DT) *</label>
            <input id="swal-montant" type="number" class="swal2-input" value="${facture.montantTotal}" step="0.01" min="0" style="width: 90%;">
          </div>
          
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">Détails</label>
            <textarea id="swal-details" class="swal2-textarea" style="width: 90%;">${facture.details || ''}</textarea>
          </div>
        </div>
      `,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: 'Modifier',
      cancelButtonText: 'Annuler',
      confirmButtonColor: '#f59e0b',
      width: '600px',
      preConfirm: () => {
        const numero = (document.getElementById('swal-numero') as HTMLInputElement).value;
        const client = (document.getElementById('swal-client') as HTMLInputElement).value;
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;
        const montant = parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value);
        const details = (document.getElementById('swal-details') as HTMLTextAreaElement).value;

        return { numero, client, date, montant, details };
      }
    });

    if (formValues) {
      try {
        this.alertService.loading('Modification...');
        
        await this.factureService.updateFacture(facture.id!, {
          numeroFacture: formValues.numero,
          client: formValues.client,
          dateVente: new Date(formValues.date),
          montantTotal: formValues.montant,
          details: formValues.details || undefined
        });
        
        this.alertService.close();
        this.alertService.success('Facture modifiée!');
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.close();
        this.alertService.error('Erreur lors de la modification');
      }
    }
  }

  async supprimerFacture(facture: FactureVente): Promise<void> {
    const confirmed = await this.alertService.confirmDelete(
      `la facture ${facture.numeroFacture} (${facture.montantTotal} DT)`
    );

    if (confirmed) {
      try {
        this.alertService.loading('Suppression...');
        await this.factureService.deleteFacture(facture.id!);
        this.alertService.close();
        this.alertService.toast('Facture supprimée', 'success');
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.close();
        this.alertService.error('Erreur lors de la suppression');
      }
    }
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
    if (date?.toDate) {
      return date.toDate().toLocaleDateString('fr-FR');
    }
    if (date instanceof Date) {
      return date.toLocaleDateString('fr-FR');
    }
    return '';
  }
}
