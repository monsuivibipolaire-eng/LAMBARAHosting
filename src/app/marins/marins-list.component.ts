import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { MarinService } from '../services/marin.service';
import { BateauService } from '../services/bateau.service';
import { AlertService } from '../services/alert.service';
import { Marin } from '../models/marin.model';
import { Bateau } from '../models/bateau.model';
import { Observable } from 'rxjs';
import { TranslateService } from '@ngx-translate/core';

@Component({
  standalone: false,
  selector: 'app-marins-list',
  templateUrl: './marins-list.component.html',
  styleUrls: ['./marins-list.component.scss']
})
export class MarinsListComponent implements OnInit {
  marins$!: Observable<Marin[]>;
  bateau$!: Observable<Bateau>;
  bateauId!: string;

  constructor(
    private marinService: MarinService,
    private bateauService: BateauService,
    private alertService: AlertService,
    private route: ActivatedRoute,
    private router: Router,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.bateauId = this.route.snapshot.paramMap.get('bateauId')!;
    this.loadMarins();
    this.loadBateau();
  }

  loadMarins(): void {
    this.marins$ = this.marinService.getMarinsByBateau(this.bateauId);
  }

  loadBateau(): void {
    this.bateau$ = this.bateauService.getBateau(this.bateauId);
  }

  addMarin(): void {
    this.router.navigate(['/dashboard/bateaux', this.bateauId, 'marins', 'add']);
  }

  editMarin(id: string): void {
    this.router.navigate(['/dashboard/bateaux', this.bateauId, 'marins', 'edit', id]);
  }

  async deleteMarin(marin: Marin): Promise<void> {
    const confirmed = await this.alertService.confirmDelete(`${marin.prenom} ${marin.nom}`);
    if (confirmed) {
      try {
        this.alertService.loading();
        await this.marinService.deleteMarin(marin.id!);
        this.alertService.toast(this.translate.instant('SAILORS.SUCCESS_DELETE'));
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.error();
      }
    }
  }

  goBack(): void {
    this.router.navigate(['/dashboard/bateaux']);
  }

  getStatutClass(statut: string): string {
    const classes: any = {
      'actif': 'status-active',
      'conge': 'status-leave',
      'inactif': 'status-inactive'
    };
    return classes[statut] || '';
  }

  getFonctionClass(fonction: string): string {
    const classes: any = {
      'capitaine': 'fonction-capitaine',
      'second': 'fonction-second',
      'mecanicien': 'fonction-mecanicien',
      'matelot': 'fonction-matelot'
    };
    return classes[fonction] || '';
  }

  formatDate(date: any): Date | null {
    if (date && date.toDate) {
      return date.toDate();
    }
    return date;
  }
}
