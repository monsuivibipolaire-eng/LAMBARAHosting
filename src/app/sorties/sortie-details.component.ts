import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Observable, take } from 'rxjs';
import { Location } from '@angular/common';
import Swal from 'sweetalert2';

import { Sortie } from '../models/sortie.model';
import { SortieService } from '../services/sortie.service';
import { FactureVente } from '../models/facture-vente.model';
import { FactureVenteService } from '../services/facture-vente.service';
import { Depense } from '../models/depense.model';
import { DepenseService } from '../services/depense.service';
import { AlertService } from '../services/alert.service';

@Component({
  selector: 'app-sortie-details',
  standalone: false,
  templateUrl: './sortie-details.component.html',
  styleUrls: ['./sortie-details.component.scss']
})
export class SortieDetailsComponent implements OnInit {
  sortie!: Observable<Sortie | undefined>;
  depenses!: Observable<Depense[]>;
  factures!: Observable<FactureVente[]>;
  sortieId!: string;

  constructor(
    private route: ActivatedRoute,
    private sortieService: SortieService,
    private factureVenteService: FactureVenteService,
    private depenseService: DepenseService,
    private alertService: AlertService,
    private router: Router,
    private location: Location
  ) {}

  ngOnInit(): void {
    this.sortieId = this.route.snapshot.paramMap.get('id')!;
    if (this.sortieId) {
      this.sortie = this.sortieService.getSortie(this.sortieId);
      this.loadFactures();
      this.loadDepenses();
    }
  }

  loadFactures(): void {
    this.factures = this.factureVenteService.getFacturesBySortie(this.sortieId);
  }

  loadDepenses(): void {
    this.depenses = this.depenseService.getDepensesBySortie(this.sortieId);
  }

  goBack(): void {
    this.location.back();
  }

  formatDate(date: any): string {
    if (!date) return '-';
    const d = date.toDate ? date.toDate() : new Date(date);
    return new Intl.DateTimeFormat('fr-FR').format(d);
  }

  // --- LOGIQUE POUR LES DÉPENSES (RÉINTÉGRÉE) ---

  addDepense(): void {
    this.router.navigate(['/dashboard/sorties/details', this.sortieId, 'depenses', 'add']);
  }

  editDepense(depenseId: string): void {
    this.router.navigate(['/dashboard/sorties/details', this.sortieId, 'depenses', 'edit', depenseId]);
  }

  async deleteDepense(depense: Depense): Promise<void> {
    if (!depense.id) return;
    const confirmed = await this.alertService.confirmDelete(`la dépense de type ${depense.type}`);
    if (confirmed) {
      try {
        await this.depenseService.deleteDepense(depense.id);
        this.alertService.toast('Dépense supprimée avec succès', 'success');
      } catch (error) {
        this.alertService.error('Erreur lors de la suppression');
        console.error(error);
      }
    }
  }

  getExpenseTypeName(type: string): string {
    const types: any = {
      'fuel': 'Carburant', 'ice': 'Glace', 'oilchange': 'Vidange',
      'crewcnss': 'CNSS Équipage', 'crewbonus': 'Prime Équipage',
      'food': 'Alimentation', 'vms': 'VMS', 'misc': 'Divers'
    };
    return types[type] || type;
  }

  // --- LOGIQUE POUR LES FACTURES (AJOUTÉE PRÉCÉDEMMENT) ---

  addFacture(): void {
    this.sortie.pipe(take(1)).subscribe(sortie => {
      if (sortie) {
        this.openAddFactureModal(sortie);
      }
    });
  }
  
  private getTodayDate(): string {
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private async openAddFactureModal(sortie: Sortie): Promise<void> {
    const { value: formValues } = await Swal.fire({
      title: 'Nouvelle facture de vente',
      html: `
        <div style="text-align: left; padding: 1rem;">
          <div style="margin-bottom: 1rem;">
            <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">N° Facture *</label>
            <input id="swal-numero" type="text" class="swal2-input" placeholder="Ex: F-001" style="width: 90%;">
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
            <textarea id="swal-details" class="swal2-textarea" placeholder="Ex: 50 kg de dorade..." style="width: 90%;"></textarea>
          </div>
        </div>`,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: 'Ajouter',
      cancelButtonText: 'Annuler',
      confirmButtonColor: '#10b981',
      preConfirm: () => {
        const numero = (document.getElementById('swal-numero') as HTMLInputElement).value;
        const client = (document.getElementById('swal-client') as HTMLInputElement).value;
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;
        const montant = parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value);
        if (!numero || !client || !date || !montant) {
          Swal.showValidationMessage('Veuillez remplir tous les champs obligatoires');
          return false;
        }
        return { 
          numero, client, date, montant, 
          details: (document.getElementById('swal-details') as HTMLTextAreaElement).value 
        };
      }
    });

    if (formValues) {
      try {
        this.alertService.loading('Ajout de la facture...');
        const newFacture: Omit<FactureVente, 'id'> = {
          sortieId: sortie.id!,
          numeroFacture: formValues.numero,
          client: formValues.client,
          dateVente: new Date(formValues.date),
          montantTotal: formValues.montant,
          details: formValues.details || undefined
        };
        await this.factureVenteService.addFacture(newFacture);
        this.alertService.success('Facture ajoutée avec succès!');
        this.loadFactures();
      } catch (error) {
        this.alertService.error('Erreur lors de l\'ajout');
      }
    }
  }
}
