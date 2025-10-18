import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { BateauService } from '../services/bateau.service';
import { AlertService } from '../services/alert.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { Bateau } from '../models/bateau.model';
import { Observable } from 'rxjs';

@Component({
  standalone: false,
  selector: 'app-bateaux-list',
  templateUrl: './bateaux-list.component.html',
  styleUrls: ['./bateaux-list.component.scss']
})
export class BateauxListComponent implements OnInit {
  bateaux!: Observable<Bateau[]>;
  searchTerm = '';
  selectedBoat: Bateau | null = null;

  constructor(
    private bateauService: BateauService,
    private alertService: AlertService,
    private router: Router,
    private selectedBoatService: SelectedBoatService
  ) {}

  ngOnInit(): void {
    this.loadBateaux();
    
    // Récupérer le bateau sélectionné
    this.selectedBoatService.selectedBoat$.subscribe(boat => {
      this.selectedBoat = boat;
    });
  }

  loadBateaux(): void {
    this.bateaux = this.bateauService.getBateaux();
  }

  selectBoat(bateau: Bateau): void {
    this.selectedBoatService.selectBoat(bateau);
    this.alertService.toast(`Bateau "${bateau.nom}" sélectionné`, 'success');
  }

  clearSelection(): void {
    this.selectedBoatService.clearSelection();
    this.alertService.toast('Sélection annulée', 'info');
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
    const confirmed = await this.alertService.confirmDelete(`le bateau "${bateau.nom}"`);
    if (confirmed) {
      try {
        this.alertService.loading('Suppression en cours...');
        await this.bateauService.deleteBateau(bateau.id!);
        
        // Si le bateau supprimé était sélectionné, désélectionner
        if (this.isSelected(bateau)) {
          this.clearSelection();
        }
        
        this.alertService.close();
        this.alertService.toast('Bateau supprimé avec succès', 'success');
      } catch (error) {
        console.error('Erreur lors de la suppression', error);
        this.alertService.close();
        this.alertService.error('Erreur lors de la suppression du bateau');
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
