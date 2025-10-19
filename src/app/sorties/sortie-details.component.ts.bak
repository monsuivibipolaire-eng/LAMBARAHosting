import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Observable } from 'rxjs';
import { Location } from '@angular/common';
import { Sortie } from '../models/sortie.model';
import { SortieService } from '../services/sortie.service';
// ✅ CORRECTION : Importer les bons modèles et services
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
  // ✅ CORRECTION : Utiliser le bon type de modèle
  factures!: Observable<FactureVente[]>;
  sortieId!: string;

  constructor(
    private route: ActivatedRoute,
    private sortieService: SortieService,
    // ✅ CORRECTION : Injecter le bon service de factures
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
    // ✅ CORRECTION : Appeler le bon service
    this.factures = this.factureVenteService.getFacturesBySortie(this.sortieId);
  }

  goBack(): void {
    this.location.back();
  }

  formatDate(date: any): string {
    if (!date) return '-';
    const d = date.toDate ? date.toDate() : new Date(date);
    return new Intl.DateTimeFormat('fr-FR').format(d);
  }

  loadDepenses(): void {
    this.depenses = this.depenseService.getDepensesBySortie(this.sortieId);
  }

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
      'fuel': 'Carburant',
      'ice': 'Glace',
      'oilchange': 'Vidange',
      'crewcnss': 'CNSS Équipage',
      'crewbonus': 'Prime Équipage',
      'food': 'Alimentation',
      'vms': 'VMS',
      'misc': 'Divers'
    };
    return types[type] || type;
  }
}
