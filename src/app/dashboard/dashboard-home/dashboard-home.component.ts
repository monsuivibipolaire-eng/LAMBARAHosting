import { Component, OnInit } from '@angular/core';
import { BateauService } from '../../services/bateau.service';
import { MarinService } from '../../services/marin.service';
import { SortieService } from '../../services/sortie.service';
import { AvanceService } from '../../services/avance.service';
import { DepenseService } from '../../services/depense.service';
import { FactureVenteService } from '../../services/facture-vente.service';
import { PaiementService } from '../../services/paiement.service';
import { SalaireService } from '../../services/salaire.service';
import { Observable, combineLatest, map } from 'rxjs';
import { Bateau } from '../../models/bateau.model';
import { Marin } from '../../models/marin.model';

interface Activity {
  type: 'boat' | 'sailor' | 'sortie' | 'avance' | 'depense' | 'facture' | 'paiement' | 'salaire';
  action: 'added' | 'updated';
  name: string;
  date: Date;
  icon: string;
  color: string;
  details?: string;
}

interface Stats {
  totalBoats: number;
  activeBoats: number;
  maintenanceBoats: number;
  totalSailors: number;
  activeSailors: number;
}

@Component({
  standalone: false,
  selector: 'app-dashboard-home',
  templateUrl: './dashboard-home.component.html',
  styleUrls: ['./dashboard-home.component.scss']
})
export class DashboardHomeComponent implements OnInit {
  stats!: Observable<Stats>;
  recentActivities: Activity[] = [];
  loading = true;

  constructor(
    private bateauService: BateauService,
    private marinService: MarinService,
    private sortieService: SortieService,
    private avanceService: AvanceService,
    private depenseService: DepenseService,
    private factureService: FactureVenteService,
    private paiementService: PaiementService,
    private salaireService: SalaireService
  ) {}

  ngOnInit(): void {
    this.loadStats();
    this.loadRecentActivities();
  }

  loadStats(): void {
    this.stats = combineLatest([
      this.bateauService.getBateaux(),
      this.marinService.getAllMarins()
    ]).pipe(
      map(([bateaux, marins]) => {
        return {
          totalBoats: bateaux.length,
          activeBoats: bateaux.filter(b => b.statut === 'actif').length,
          maintenanceBoats: bateaux.filter(b => b.statut === 'maintenance').length,
          totalSailors: marins.length,
          activeSailors: marins.filter(m => m.statut === 'actif').length
        };
      })
    );
  }

  private toDate(timestamp: any): Date {
    if (!timestamp) return new Date(0);
    if (timestamp instanceof Date) return timestamp;
    if (timestamp.toDate && typeof timestamp.toDate === 'function') return timestamp.toDate();
    if (timestamp.seconds) return new Date(timestamp.seconds * 1000);
    return new Date(timestamp);
  }

  loadRecentActivities(): void {
    combineLatest([
      this.bateauService.getBateaux(),
      this.marinService.getAllMarins(),
      this.sortieService.getAllSorties(),
      this.avanceService.getAllAvances(),
      this.depenseService.getAllDepenses(),
      this.factureService.getAllFactures(),
      this.paiementService.getAllPaiements(),
      this.salaireService.getAllCalculs()
    ]).subscribe(([bateaux, marins, sorties, avances, depenses, factures, paiements, calculs]) => {
      const activities: Activity[] = [];

      // Bateaux
      bateaux.slice(0, 5).forEach(bateau => {
        const date = this.toDate(bateau.updatedAt || bateau.createdAt);
        activities.push({
          type: 'boat',
          action: bateau.updatedAt ? 'updated' : 'added',
          name: bateau.nom,
          date: date,
          icon: '🚢',
          color: '#3b82f6'
        });
      });

      // Marins
      marins.slice(0, 5).forEach(marin => {
        const date = this.toDate(marin.updatedAt || marin.createdAt);
        activities.push({
          type: 'sailor',
          action: marin.updatedAt ? 'updated' : 'added',
          name: `${marin.prenom} ${marin.nom}`,
          date: date,
          icon: '👤',
          color: '#059669'
        });
      });

      // Sorties
      sorties.slice(0, 5).forEach(sortie => {
        const date = this.toDate(sortie.createdAt);
        activities.push({
          type: 'sortie',
          action: 'added',
          name: `Sortie vers ${sortie.destination}`,
          date: date,
          icon: '⛵',
          color: '#06b6d4'
        });
      });

      // Avances
      avances.slice(0, 5).forEach(avance => {
        const date = this.toDate(avance.createdAt || avance.dateAvance);
        activities.push({
          type: 'avance',
          action: 'added',
          name: `Avance de ${avance.montant} DT`,
          date: date,
          icon: '💰',
          color: '#f59e0b'
        });
      });

      // Dépenses
      depenses.slice(0, 5).forEach(depense => {
        const date = this.toDate(depense.createdAt || depense.date);
        activities.push({
          type: 'depense',
          action: 'added',
          name: `Dépense: ${depense.type} (${depense.montant} DT)`,
          date: date,
          icon: '💸',
          color: '#ef4444'
        });
      });

      // Factures
      factures.slice(0, 5).forEach(facture => {
        const date = this.toDate(facture.createdAt || facture.dateVente);
        activities.push({
          type: 'facture',
          action: 'added',
          name: `Vente: ${facture.numeroFacture} (${facture.montant} DT)`,
          date: date,
          icon: '📄',
          color: '#10b981'
        });
      });

      // Paiements
      paiements.slice(0, 5).forEach(paiement => {
        const date = this.toDate(paiement.createdAt || paiement.datePaiement);
        activities.push({
          type: 'paiement',
          action: 'added',
          name: `Paiement de ${paiement.montant} DT`,
          date: date,
          icon: '💳',
          color: '#8b5cf6'
        });
      });

      // Calculs de salaire
      calculs.slice(0, 5).forEach(calcul => {
        const date = this.toDate(calcul.dateCalcul);
        activities.push({
          type: 'salaire',
          action: 'added',
          name: `Calcul de salaire`,
          date: date,
          icon: '📊',
          color: '#ec4899'
        });
      });

      // Trier par date et prendre les 20 plus récentes
      this.recentActivities = activities
        .sort((a, b) => b.date.getTime() - a.date.getTime())
        .slice(0, 20);

      this.loading = false;
    });
  }

  getActionText(activity: Activity): string {
    const translations: any = {
      boat: { added: 'Bateau ajouté', updated: 'Bateau mis à jour' },
      sailor: { added: 'Marin ajouté', updated: 'Marin mis à jour' },
      sortie: { added: 'Sortie en mer ajoutée' },
      avance: { added: 'Avance enregistrée' },
      depense: { added: 'Dépense ajoutée' },
      facture: { added: 'Facture créée' },
      paiement: { added: 'Paiement effectué' },
      salaire: { added: 'Salaire calculé' }
    };
    return translations[activity.type]?.[activity.action] || 'Action';
  }

  getTimeAgo(date: Date): string {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return "À l'instant";
    if (minutes < 60) return `Il y a ${minutes} min`;
    if (hours < 24) return `Il y a ${hours}h`;
    return `Il y a ${days}j`;
  }
}
