import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { BateauService } from '../services/bateau.service';
import { AlertService } from '../services/alert.service';
import { Bateau } from '../models/bateau.model';
import { TranslateService } from '@ngx-translate/core';

@Component({
  standalone: false,
  selector: 'app-bateau-form',
  templateUrl: './bateau-form.component.html',
  styleUrls: ['./bateau-form.component.scss']
})
export class BateauFormComponent implements OnInit {
  bateauForm!: FormGroup;
  isEditMode = false;
  bateauId: string | null = null;
  loading = false;

  constructor(
    private fb: FormBuilder,
    private bateauService: BateauService,
    private alertService: AlertService,
    private router: Router,
    private route: ActivatedRoute,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.bateauId = this.route.snapshot.paramMap.get('id');
    if (this.bateauId) {
      this.isEditMode = true;
      this.loadBateau();
    }
  }

  initForm(): void {
    this.bateauForm = this.fb.group({
      nom: ['', [Validators.required, Validators.minLength(2)]],
      immatriculation: ['', [Validators.required]],
      typeMoteur: ['', [Validators.required]],
      puissance: [0, [Validators.required, Validators.min(1)]],
      longueur: [0, [Validators.required, Validators.min(1)]],
      capaciteEquipage: [0, [Validators.required, Validators.min(1)]],
      dateConstruction: ['', [Validators.required]],
      portAttache: ['', [Validators.required]],
      statut: ['actif', [Validators.required]]
    });
  }

  loadBateau(): void {
    if (this.bateauId) {
      this.bateauService.getBateau(this.bateauId).subscribe(bateau => {
        this.bateauForm.patchValue({
          ...bateau,
          dateConstruction: this.formatDate(bateau.dateConstruction)
        });
      });
    }
  }

  formatDate(date: any): string {
    if (date && date.toDate) {
      return date.toDate().toISOString().split('T')[0];
    }
    if (date instanceof Date) {
      return date.toISOString().split('T')[0];
    }
    return '';
  }

  async onSubmit(): Promise<void> {
    if (this.bateauForm.valid) {
      this.loading = true;
      this.alertService.loading();
      
      const formValue = this.bateauForm.value;
      const bateauData: Bateau = {
        ...formValue,
        dateConstruction: new Date(formValue.dateConstruction)
      };

      try {
        if (this.isEditMode && this.bateauId) {
          await this.bateauService.updateBateau(this.bateauId, bateauData);
          await this.alertService.success(this.translate.instant('BOATS.SUCCESS_UPDATE'));
        } else {
          await this.bateauService.addBateau(bateauData);
          await this.alertService.success(this.translate.instant('BOATS.SUCCESS_ADD'));
        }
        this.router.navigate(['/dashboard/bateaux']);
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.error();
      } finally {
        this.loading = false;
      }
    } else {
      this.markFormGroupTouched(this.bateauForm);
      this.alertService.warning(this.translate.instant('FORM.REQUIRED_FIELDS'));
    }
  }

  markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      formGroup.get(key)?.markAsTouched();
    });
  }

  cancel(): void {
    this.router.navigate(['/dashboard/bateaux']);
  }
}
