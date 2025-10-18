import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { SelectedBoatService } from '../services/selected-boat.service';
import { SortieService } from '../services/sortie.service';
import { AlertService } from '../services/alert.service';
import { Bateau } from '../models/bateau.model';

@Component({
  standalone: false,
  selector: 'app-sortie-form',
  templateUrl: './sortie-form.component.html',
  styleUrls: ['./sortie-form.component.scss']
})
export class SortieFormComponent implements OnInit {
  form!: FormGroup;
  isEditMode = false;
  id?: string;
  loading = false;
  selectedBoat: Bateau | null = null;

  constructor(
    private fb: FormBuilder,
    private sortieService: SortieService,
    private alertService: AlertService,
    private route: ActivatedRoute,
    private router: Router,
    private selectedBoatService: SelectedBoatService
  ) {}

  ngOnInit(): void {
    this.id = this.route.snapshot.paramMap.get('id') ?? undefined;
    this.isEditMode = !!this.id;
    
    // Récupérer le bateau sélectionné
    this.selectedBoat = this.selectedBoatService.getSelectedBoat();
    
    if (!this.selectedBoat && !this.isEditMode) {
      this.alertService.error('Veuillez d\'abord sélectionner un bateau');
      this.router.navigate(['/dashboard/bateaux']);
      return;
    }
    
    this.form = this.fb.group({
      bateauId: [this.selectedBoat?.id || '', Validators.required],
      destination: ['', Validators.required],
      dateDepart: ['', Validators.required],
      dateRetour: ['', Validators.required],
      statut: ['en-cours', Validators.required],
      observations: ['']
    });

    // Désactiver le champ bateau (il est automatiquement sélectionné)
    this.form.get('bateauId')?.disable();

    if (this.isEditMode) {
      this.loadSortie();
    }
  }

  loadSortie(): void {
    this.sortieService.getSortie(this.id!).subscribe(sortie => {
      this.form.patchValue({
        ...sortie,
        dateDepart: this.formatDate(sortie.dateDepart),
        dateRetour: this.formatDate(sortie.dateRetour)
      });
    });
  }

  formatDate(date: any): string {
    if (date?.toDate) {
      return date.toDate().toISOString().split('T')[0];
    }
    if (date instanceof Date) {
      return date.toISOString().split('T')[0];
    }
    return '';
  }

  async onSubmit(): Promise<void> {
    if (this.form.valid) {
      this.loading = true;
      this.alertService.loading('Enregistrement en cours...');

      const data = {
        ...this.form.getRawValue(),  // getRawValue() pour inclure les champs désactivés
        dateDepart: new Date(this.form.value.dateDepart),
        dateRetour: new Date(this.form.value.dateRetour)
      };

      try {
        if (this.isEditMode) {
          await this.sortieService.updateSortie(this.id!, data);
          this.alertService.close();
          await this.alertService.success('La sortie a été modifiée avec succès', 'Modification réussie!');
        } else {
          await this.sortieService.addSortie(data);
          this.alertService.close();
          await this.alertService.success('La sortie a été ajoutée avec succès', 'Ajout réussi!');
        }
        this.router.navigate(['/dashboard/sorties']);
      } catch (error) {
        this.alertService.close();
        this.alertService.error('Erreur lors de l\'enregistrement');
      } finally {
        this.loading = false;
      }
    } else {
      this.markFormGroupTouched(this.form);
      this.alertService.warning('Veuillez remplir tous les champs requis', 'Formulaire incomplet');
    }
  }

  markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      formGroup.get(key)?.markAsTouched();
    });
  }

  cancel(): void {
    this.router.navigate(['/dashboard/sorties']);
  }
}
