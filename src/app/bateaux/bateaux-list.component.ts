import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { BateauService } from '../services/bateau.service';
import { AlertService } from '../services/alert.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { Bateau } from '../models/bateau.model';
import { Observable } from 'rxjs';
import { TranslateService } from '@ngx-translate/core';

@Component({
  standalone: false,
  selector: 'app-bateaux-list',
  templateUrl: './bateaux-list.component.html',
  styleUrls: ['./bateaux-list.component.scss']
})
export class BateauxListComponent implements OnInit {
  bateaux$!: Observable<Bateau[]>;
  searchTerm = '';
  selectedBoat: Bateau | null = null;

  constructor(
    private bateauService: BateauService,
    private alertService: AlertService,
    private router: Router,
    private selectedBoatService: SelectedBoatService,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.loadBateaux();
    this.selectedBoatService.selectedBoat$.subscribe(boat => {
      this.selectedBoat = boat;
    });
  }

  loadBateaux(): void {
    this.bateaux$ = this.bateauService.getBateaux();
  }

  selectBoat(bateau: Bateau): void {
    this.selectedBoatService.selectBoat(bateau);
    this.alertService.toast(this.translate.instant('BOATS.TOAST_SELECTED', { boatName: bateau.nom }));
  }

  clearSelection(): void {
    this.selectedBoatService.clearSelection();
    this.alertService.toast(this.translate.instant('BOATS.TOAST_SELECTION_CLEARED'), 'info');
  }

  isSelected(bateau: Bateau): boolean {
    return this.selectedBoat?.id === bateau.id;
  }

  addBateau(): void {
    this.router.navigate(['/dashboard/bateaux/add']);
  }

  editBateau(id: string): void {
    this.router.navigate(['/dashboard/bateaux/edit', id]);
  }

  viewMarins(id: string): void {
    this.router.navigate(['/dashboard/bateaux', id, 'marins']);
  }

  async deleteBateau(bateau: Bateau): Promise<void> {
    const itemName = this.translate.instant('BOATS.BOAT_NAME_CONFIRM', { boatName: bateau.nom });
    const confirmed = await this.alertService.confirmDelete(itemName);

    if (confirmed) {
      try {
        this.alertService.loading(this.translate.instant('MESSAGES.DELETING'));
        await this.bateauService.deleteBateau(bateau.id!);
        
        if (this.isSelected(bateau)) {
          this.clearSelection();
        }
        
        this.alertService.toast(this.translate.instant('BOATS.SUCCESS_DELETE'));
      } catch (error) {
        console.error('Erreur lors de la suppression', error);
        this.alertService.error();
      }
    }
  }

  getStatutClass(statut: string): string {
    const classes: any = {
      'actif': 'status-active',
      'maintenance': 'status-maintenance',
      'inactif': 'status-inactive'
    };
    return classes[statut];
  }
}
