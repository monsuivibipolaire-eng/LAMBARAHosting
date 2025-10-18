import { Component, OnInit } from '@angular/core';
import { BateauService } from '../../services/bateau.service';
import { MarinService } from '../../services/marin.service';
import { Observable, combineLatest, map } from 'rxjs';
import { Bateau } from '../../models/bateau.model';
import { Marin } from '../../models/marin.model';

interface Activity {
  type: 'boat' | 'sailor';
  action: 'added' | 'updated';
  name: string;
  date: Date;
  icon: string;
  color: string;
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
  stats$!: Observable<Stats>;
  recentActivities: Activity[] = [];
  loading = true;

  constructor(
    private bateauService: BateauService,
    private marinService: MarinService
  ) {}

  ngOnInit(): void {
    this.loadStats();
    this.loadRecentActivities();
  }

  loadStats(): void {
    this.stats$ = combineLatest([
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

  // Fonction helper pour convertir Timestamp Firestore en Date
  private toDate(timestamp: any): Date {
    if (!timestamp) return new Date(0);
    if (timestamp instanceof Date) return timestamp;
    if (timestamp.toDate && typeof timestamp.toDate === 'function') {
      return timestamp.toDate();
    }
    if (timestamp.seconds) {
      return new Date(timestamp.seconds * 1000);
    }
    return new Date(timestamp);
  }

  loadRecentActivities(): void {
    combineLatest([
      this.bateauService.getBateaux(),
      this.marinService.getAllMarins()
    ]).subscribe(([bateaux, marins]) => {
      const activities: Activity[] = [];

      // Ajouter les bateaux récents
      bateaux
        .sort((a, b) => {
          const dateA = this.toDate(a.updatedAt || a.createdAt);
          const dateB = this.toDate(b.updatedAt || b.createdAt);
          return dateB.getTime() - dateA.getTime();
        })
        .slice(0, 5)
        .forEach(bateau => {
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

      // Ajouter les marins récents
      marins
        .sort((a, b) => {
          const dateA = this.toDate(a.updatedAt || a.createdAt);
          const dateB = this.toDate(b.updatedAt || b.createdAt);
          return dateB.getTime() - dateA.getTime();
        })
        .slice(0, 5)
        .forEach(marin => {
          const date = this.toDate(marin.updatedAt || marin.createdAt);
          activities.push({
            type: 'sailor',
            action: marin.updatedAt ? 'updated' : 'added',
            name: `${marin.prenom} ${marin.nom}`,
            date: date,
            icon: '👨‍✈️',
            color: '#059669'
          });
        });

      // Trier par date et prendre les 10 plus récentes
      this.recentActivities = activities
        .sort((a, b) => b.date.getTime() - a.date.getTime())
        .slice(0, 10);

      this.loading = false;
    });
  }

  getActionText(activity: Activity): string {
    if (activity.type === 'boat') {
      return activity.action === 'added' ? 'DASHBOARD.BOAT_ADDED' : 'DASHBOARD.BOAT_UPDATED';
    } else {
      return activity.action === 'added' ? 'DASHBOARD.SAILOR_ADDED' : 'DASHBOARD.SAILOR_UPDATED';
    }
  }

  getTimeAgo(date: Date): string {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return 'À l\'instant';
    if (minutes < 60) return `Il y a ${minutes} min`;
    if (hours < 24) return `Il y a ${hours}h`;
    return `Il y a ${days}j`;
  }
}
