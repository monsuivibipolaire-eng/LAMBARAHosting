import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import Swal from 'sweetalert2';

import { SortieService } from '../services/sortie.service';
import { FactureVenteService } from '../services/facture-vente.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { AlertService } from '../services/alert.service';

import { Sortie } from '../models/sortie.model';
import { Bateau } from '../models/bateau.model';
import { FactureVente } from '../models/facture-vente.model';

import { combineLatest } from 'rxjs';

interface SortieWithFactures {
  sortie: Sortie;
  factures: FactureVente[];
  totalVentes: number;
}

@Component({
  selector: 'app-ventes-list',
  standalone: true,
  imports: [CommonModule, TranslateModule],
  templateUrl: './ventes-list.component.html',
  styleUrls: ['./ventes-list.component.scss']
})
export class VentesListComponent implements OnInit {
  selectedBoat: Bateau | null = null;
  sortiesWithFactures: SortieWithFactures[] = [];
  loading = true;

  constructor(
    private sortieService: SortieService,
    private factureService: FactureVenteService,
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
    if (!this.selectedBoat) return;

    this.sortieService.getSortiesByBateau(this.selectedBoat.id!).subscribe((sorties: Sortie[]) => {
      const facturesObservables = sorties.map(sortie =>
        this.factureService.getFacturesBySortie(sortie.id!)
      );

      combineLatest(facturesObservables).subscribe((allFactures: FactureVente[][]) => {
        this.sortiesWithFactures = sorties.map((sortie, index) => {
          const factures = allFactures[index];
          const totalVentes = factures.reduce((sum, f) => sum + f.montant, 0);
          
          return {
            sortie,
            factures,
            totalVentes
          };
        });

        this.loading = false;
      });
    });
  }

  getTotalGeneral(): number {
    return this.sortiesWithFactures.reduce((sum, s) => sum + s.totalVentes, 0);
  }

  // ✅ NOUVELLE MÉTHODE: Ajouter facture avec sélection de sortie
  async ajouterFactureGlobale(): Promise<void> {
    if (this.sortiesWithFactures.length === 0) {
      this.alertService.error('Aucune sortie en mer disponible');
      return;
    }

    // Créer les options de sorties
    const sortiesOptions = this.sortiesWithFactures.reduce((acc, item) => {
      const dateDepart = this.formatDisplayDate(item.sortie.dateDepart);
      const dateRetour = this.formatDisplayDate(item.sortie.dateRetour);
      acc[item.sortie.id!] = `${item.sortie.destination} (${dateDepart} - ${dateRetour})`;
      return acc;
    }, {} as any);

    const { value: formValues } = await Swal.fire({
      title: `<div style="text-align: center;">
                <div style="font-size: 1.5rem; font-weight: 700; color: #1f2937; margin-bottom: 0.5rem;">
                  Nouvelle facture de vente
                </div>
              </div>`,
      html: `
        <style>
          .facture-form {
            text-align: left;
            padding: 1rem 0;
          }
          .form-group {
            margin-bottom: 1.25rem;
          }
          .form-label {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 0.625rem;
            font-weight: 600;
            color: #374151;
            font-size: 0.9rem;
          }
          .form-label svg {
            width: 18px;
            height: 18px;
            color: #10b981;
          }
          .required-star {
            color: #ef4444;
            font-weight: 700;
          }
          .custom-input, .custom-textarea, .custom-select {
            width: 100%;
            padding: 0.75rem 0.875rem;
            border: 2px solid #e5e7eb;
            border-radius: 0.5rem;
            font-size: 0.95rem;
            transition: all 0.3s;
            font-family: inherit;
            background: white;
          }
          .custom-input:focus, .custom-textarea:focus, .custom-select:focus {
            outline: none;
            border-color: #10b981;
            box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
          }
          .custom-textarea {
            resize: vertical;
            min-height: 80px;
          }
          .input-helper {
            display: flex;
            align-items: center;
            gap: 0.4rem;
            margin-top: 0.4rem;
            font-size: 0.8rem;
            color: #6b7280;
          }
        </style>
        <div class="facture-form">
          <!-- ✅ SÉLECTION DE SORTIE -->
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
              </svg>
              Sortie en mer <span class="required-star">*</span>
            </label>
            <select id="swal-sortie" class="custom-select">
              <option value="">Sélectionner une sortie</option>
              ${Object.keys(sortiesOptions).map(id => 
                `<option value="${id}">${sortiesOptions[id]}</option>`
              ).join('')}
            </select>
          </div>

          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14"/>
              </svg>
              N° Facture <span class="required-star">*</span>
            </label>
            <input id="swal-numero" type="text" class="custom-input" placeholder="Ex: F-001" autocomplete="off">
            <div class="input-helper">Numéro unique de la facture</div>
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
              </svg>
              Client <span class="required-star">*</span>
            </label>
            <input id="swal-client" type="text" class="custom-input" placeholder="Nom du client" autocomplete="off">
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
              </svg>
              Date de vente <span class="required-star">*</span>
            </label>
            <input id="swal-date" type="date" class="custom-input" value="${this.getTodayDate()}">
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              Montant total (DT) <span class="required-star">*</span>
            </label>
            <input id="swal-montant" type="number" class="custom-input" placeholder="0.00" step="0.01" min="0" autocomplete="off">
            <div class="input-helper">Montant en dinars tunisiens</div>
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"/>
              </svg>
              Détails (poissons vendus)
            </label>
            <textarea id="swal-details" class="custom-textarea" placeholder="Ex: 50 kg de dorade, 30 kg de loup, 20 kg de rouget..."></textarea>
          </div>
        </div>
      `,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: 'Ajouter la facture',
      cancelButtonText: 'Annuler',
      confirmButtonColor: '#10b981',
      cancelButtonColor: '#6b7280',
      width: '650px',
      preConfirm: () => {
        const sortieId = (document.getElementById('swal-sortie') as HTMLSelectElement).value;
        const numero = (document.getElementById('swal-numero') as HTMLInputElement).value.trim();
        const client = (document.getElementById('swal-client') as HTMLInputElement).value.trim();
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;
        const montant = parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value);
        const details = (document.getElementById('swal-details') as HTMLTextAreaElement).value.trim();

        if (!sortieId) {
          Swal.showValidationMessage('Veuillez sélectionner une sortie en mer');
          return false;
        }

        if (!numero || !client || !date || !montant) {
          Swal.showValidationMessage('Veuillez remplir tous les champs obligatoires');
          return false;
        }

        if (montant <= 0) {
          Swal.showValidationMessage('Le montant doit être supérieur à 0');
          return false;
        }

        return { sortieId, numero, client, date, montant, details };
      }
    });

    if (formValues) {
      try {
        this.alertService.loading('Ajout de la facture...');

        const newFacture: Omit<FactureVente, 'id'> = {
          sortieId: formValues.sortieId,
          numeroFacture: formValues.numero,
          client: formValues.client,
          dateVente: new Date(formValues.date),
          montant: formValues.montant,
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

  // Méthode existante pour ajouter avec sortie présélectionnée
  async ajouterFacture(sortie: Sortie): Promise<void> {
    const { value: formValues } = await Swal.fire({
      title: `<div style="text-align: center;">
                <div style="font-size: 1.5rem; font-weight: 700; color: #1f2937; margin-bottom: 0.5rem;">
                  Nouvelle facture de vente
                </div>
                <div style="font-size: 0.875rem; color: #6b7280;">
                  ${sortie.destination}
                </div>
              </div>`,
      html: `
        <style>
          .facture-form {
            text-align: left;
            padding: 1rem 0;
          }
          .form-group {
            margin-bottom: 1.25rem;
          }
          .form-label {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 0.625rem;
            font-weight: 600;
            color: #374151;
            font-size: 0.9rem;
          }
          .form-label svg {
            width: 18px;
            height: 18px;
            color: #10b981;
          }
          .required-star {
            color: #ef4444;
            font-weight: 700;
          }
          .custom-input, .custom-textarea {
            width: 100%;
            padding: 0.75rem 0.875rem;
            border: 2px solid #e5e7eb;
            border-radius: 0.5rem;
            font-size: 0.95rem;
            transition: all 0.3s;
            font-family: inherit;
          }
          .custom-input:focus, .custom-textarea:focus {
            outline: none;
            border-color: #10b981;
            box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
          }
          .custom-textarea {
            resize: vertical;
            min-height: 80px;
          }
          .input-helper {
            display: flex;
            align-items: center;
            gap: 0.4rem;
            margin-top: 0.4rem;
            font-size: 0.8rem;
            color: #6b7280;
          }
        </style>
        <div class="facture-form">
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14"/>
              </svg>
              N° Facture <span class="required-star">*</span>
            </label>
            <input id="swal-numero" type="text" class="custom-input" placeholder="Ex: F-001" autocomplete="off">
            <div class="input-helper">Numéro unique de la facture</div>
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
              </svg>
              Client <span class="required-star">*</span>
            </label>
            <input id="swal-client" type="text" class="custom-input" placeholder="Nom du client" autocomplete="off">
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
              </svg>
              Date de vente <span class="required-star">*</span>
            </label>
            <input id="swal-date" type="date" class="custom-input" value="${this.getTodayDate()}">
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              Montant total (DT) <span class="required-star">*</span>
            </label>
            <input id="swal-montant" type="number" class="custom-input" placeholder="0.00" step="0.01" min="0" autocomplete="off">
            <div class="input-helper">Montant en dinars tunisiens</div>
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"/>
              </svg>
              Détails (poissons vendus)
            </label>
            <textarea id="swal-details" class="custom-textarea" placeholder="Ex: 50 kg de dorade, 30 kg de loup, 20 kg de rouget..."></textarea>
          </div>
        </div>
      `,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: 'Ajouter la facture',
      cancelButtonText: 'Annuler',
      confirmButtonColor: '#10b981',
      cancelButtonColor: '#6b7280',
      width: '600px',
      preConfirm: () => {
        const numero = (document.getElementById('swal-numero') as HTMLInputElement).value.trim();
        const client = (document.getElementById('swal-client') as HTMLInputElement).value.trim();
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;
        const montant = parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value);
        const details = (document.getElementById('swal-details') as HTMLTextAreaElement).value.trim();

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
          sortieId: sortie.id!,
          numeroFacture: formValues.numero,
          client: formValues.client,
          dateVente: new Date(formValues.date),
          montant: formValues.montant,
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
        <style>
          .facture-form { text-align: left; padding: 1rem 0; }
          .form-group { margin-bottom: 1.25rem; }
          .form-label { display: block; margin-bottom: 0.625rem; font-weight: 600; color: #374151; font-size: 0.9rem; }
          .custom-input, .custom-textarea { width: 100%; padding: 0.75rem 0.875rem; border: 2px solid #e5e7eb; border-radius: 0.5rem; font-size: 0.95rem; transition: all 0.3s; font-family: inherit; }
          .custom-input:focus, .custom-textarea:focus { outline: none; border-color: #f59e0b; box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1); }
          .custom-textarea { resize: vertical; min-height: 80px; }
        </style>
        <div class="facture-form">
          <div class="form-group">
            <label class="form-label">N° Facture</label>
            <input id="swal-numero" type="text" class="custom-input" value="${facture.numeroFacture}">
          </div>
          <div class="form-group">
            <label class="form-label">Client</label>
            <input id="swal-client" type="text" class="custom-input" value="${facture.client}">
          </div>
          <div class="form-group">
            <label class="form-label">Date de vente</label>
            <input id="swal-date" type="date" class="custom-input" value="${this.formatDate(facture.dateVente)}">
          </div>
          <div class="form-group">
            <label class="form-label">Montant total (DT)</label>
            <input id="swal-montant" type="number" class="custom-input" value="${facture.montant}" step="0.01" min="0">
          </div>
          <div class="form-group">
            <label class="form-label">Détails</label>
            <textarea id="swal-details" class="custom-textarea">${facture.details || ''}</textarea>
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
        const numero = (document.getElementById('swal-numero') as HTMLInputElement).value.trim();
        const client = (document.getElementById('swal-client') as HTMLInputElement).value.trim();
        const date = (document.getElementById('swal-date') as HTMLInputElement).value;
        const montant = parseFloat((document.getElementById('swal-montant') as HTMLInputElement).value);
        const details = (document.getElementById('swal-details') as HTMLTextAreaElement).value.trim();

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
          montant: formValues.montant,
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
      `la facture ${facture.numeroFacture} (${facture.montant} DT)`
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
