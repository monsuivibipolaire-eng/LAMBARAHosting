import { Component, OnInit } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { AvanceService } from '../services/avance.service';
import { AlertService } from '../services/alert.service';
import { MarinService } from '../services/marin.service';
import { SelectedBoatService } from '../services/selected-boat.service';
import { Avance } from '../models/avance.model';
import { Marin } from '../models/marin.model';
import { Bateau } from '../models/bateau.model';
import { Observable } from 'rxjs';
import { take } from 'rxjs/operators';

@Component({
  selector: 'app-avance-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, TranslateModule],
  templateUrl: './avance-form.component.html',
  styleUrls: ['./avance-form.component.scss']
})
export class AvanceFormComponent implements OnInit {
  form!: FormGroup;
  isEditMode = false;
  avanceId?: string;
  selectedBoat: Bateau | null = null;
  marins$: Observable<Marin[]> | undefined;
  loading = false;
  pageTitle = '';

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private avanceService: AvanceService,
    private alertService: AlertService,
    private marinService: MarinService,
    private selectedBoatService: SelectedBoatService,
    private location: Location,
    private translate: TranslateService
  ) {}

  ngOnInit(): void {
    this.selectedBoat = this.selectedBoatService.getSelectedBoat();
    if (!this.selectedBoat) {
      this.alertService.error(this.translate.instant('BOATS.NO_BOAT_SELECTED_DETAILS'));
      this.router.navigate(['/dashboard/bateaux']);
      return;
    }

    this.avanceId = this.route.snapshot.paramMap.get('id') ?? undefined;
    this.isEditMode = !!this.avanceId;
    this.pageTitle = this.isEditMode ? 'AVANCES.EDIT' : 'AVANCES.ADD';

    this.initForm();
    this.loadMarins();

    if (this.isEditMode && this.avanceId) {
      this.loadAvanceData();
    }
  }

  private initForm(): void {
    this.form = this.fb.group({
      marinId: ['', Validators.required],
      montant: [null, [Validators.required, Validators.min(0.01)]],
      dateAvance: [this.getTodayDate(), Validators.required],
      description: ['']
    });
  }

  private loadMarins(): void {
    if (this.selectedBoat?.id) {
      this.marins$ = this.marinService.getMarinsByBateau(this.selectedBoat.id);
    }
  }

  private loadAvanceData(): void {
    this.loading = true;
    this.avanceService.getAvance(this.avanceId!).pipe(take(1)).subscribe(avance => {
      if (avance) {
        this.form.patchValue({
          ...avance,
          dateAvance: this.formatDate(avance.dateAvance) // Format date for input
        });
      } else {
        this.alertService.error(this.translate.instant('MESSAGES.ERROR_GENERIC')); // Or a specific not found message
        this.goBack();
      }
      this.loading = false;
    }, error => {
      console.error('Error loading avance:', error);
      this.alertService.error();
      this.loading = false;
      this.goBack();
    });
  }

  getTodayDate(): string {
    return new Date().toISOString().split('T')[0];
  }

  formatDate(date: any): string {
    if (!date) return this.getTodayDate();
    const d = date.toDate ? date.toDate() : new Date(date);
    return d.toISOString().split('T')[0];
  }

  async onSubmit(): Promise<void> {
    if (this.form.invalid) {
        this.markFormGroupTouched(this.form);
        this.alertService.warning(this.translate.instant('FORM.REQUIRED_FIELDS'));
        return;
    }

    if (!this.selectedBoat) {
        this.alertService.error('Erreur: Bateau non sélectionné.'); // Should not happen normally
        return;
    }

    this.loading = true;
    this.alertService.loading(this.translate.instant('MESSAGES.SAVING'));
    const formValue = this.form.value;

    const avanceData: Omit<Avance, 'id'> = {
      bateauId: this.selectedBoat.id!,
      marinId: formValue.marinId,
      montant: formValue.montant,
      dateAvance: new Date(formValue.dateAvance),
      description: formValue.description?.trim() || undefined, // Set undefined if empty
      calculSalaireId: undefined // Ensure it's not set when adding/editing manually
    };

    try {
      if (this.isEditMode && this.avanceId) {
        await this.avanceService.updateAvance(this.avanceId, avanceData);
        this.alertService.success(this.translate.instant('AVANCES.SUCCESS_UPDATE'));
      } else {
        await this.avanceService.addAvance(avanceData);
        this.alertService.success(this.translate.instant('AVANCES.SUCCESS_ADD'));
      }
      this.goBack(); // Navigate back to the list
    } catch (error) {
      console.error('Erreur sauvegarde avance:', error);
      this.alertService.error();
    } finally {
      this.loading = false;
      this.alertService.close(); // Close loading indicator
    }
  }

   markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      formGroup.get(key)?.markAsTouched();
    });
  }


  goBack(): void {
    this.location.back();
  }
}
