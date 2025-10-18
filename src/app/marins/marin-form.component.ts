import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MarinService } from '../services/marin.service';
import { AlertService } from '../services/alert.service';
import { Marin } from '../models/marin.model';
import { TranslateService } from '@ngx-translate/core';

@Component({
  standalone: false,
  selector: 'app-marin-form',
  templateUrl: './marin-form.component.html',
  styleUrls: ['./marin-form.component.scss']
})
export class MarinFormComponent implements OnInit {
  marinForm!: FormGroup;
  isEditMode = false;
  marinId: string | null = null;
  bateauId!: string;
  loading = false;

  constructor(
    private fb: FormBuilder,
    private marinService: MarinService,
    private alertService: AlertService,
    private router: Router,
    private route: ActivatedRoute,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.bateauId = this.route.snapshot.paramMap.get('bateauId')!;
    this.initForm();
    
    this.marinId = this.route.snapshot.paramMap.get('id');
    if (this.marinId) {
      this.isEditMode = true;
      this.loadMarin();
    }
  }

  initForm(): void {
    this.marinForm = this.fb.group({
      nom: ['', [Validators.required, Validators.minLength(2)]],
      prenom: ['', [Validators.required, Validators.minLength(2)]],
      dateNaissance: ['', [Validators.required]],
      fonction: ['matelot', [Validators.required]],
      part: [1, [Validators.required, Validators.min(0)]],
      numeroPermis: ['', [Validators.required]],
      telephone: ['', [Validators.required, Validators.pattern(/^[0-9]{8,}$/)]],
      email: ['', [Validators.required, Validators.email]],
      adresse: ['', [Validators.required]],
      dateEmbauche: ['', [Validators.required]],
      statut: ['actif', [Validators.required]]
    });
  }

  loadMarin(): void {
    if (this.marinId) {
      this.marinService.getMarin(this.marinId).subscribe(marin => {
        this.marinForm.patchValue({
          ...marin,
          dateNaissance: this.formatDate(marin.dateNaissance),
          dateEmbauche: this.formatDate(marin.dateEmbauche)
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
    if (this.marinForm.valid) {
      this.loading = true;
      this.alertService.loading(this.translate.instant('MESSAGES.SAVING'));
      
      const formValue = this.marinForm.value;
      const marinData: Marin = {
        ...formValue,
        bateauId: this.bateauId,
        part: +formValue.part,
        dateNaissance: new Date(formValue.dateNaissance),
        dateEmbauche: new Date(formValue.dateEmbauche)
      };

      try {
        if (this.isEditMode && this.marinId) {
          await this.marinService.updateMarin(this.marinId, marinData);
          this.alertService.success(this.translate.instant('SAILORS.SUCCESS_UPDATE'));
        } else {
          await this.marinService.addMarin(marinData);
          this.alertService.success(this.translate.instant('SAILORS.SUCCESS_ADD'));
        }
        this.router.navigate(['/dashboard/bateaux', this.bateauId, 'marins']);
      } catch (error) {
        console.error('Erreur:', error);
        this.alertService.error();
      } finally {
        this.loading = false;
      }
    } else {
      this.markFormGroupTouched(this.marinForm);
      this.alertService.warning(this.translate.instant('FORM.REQUIRED_FIELDS'));
    }
  }

  markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      formGroup.get(key)?.markAsTouched();
    });
  }

  cancel(): void {
    this.router.navigate(['/dashboard/bateaux', this.bateauId, 'marins']);
  }
}
