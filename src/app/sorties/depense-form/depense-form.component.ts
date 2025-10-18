import { Component, OnInit } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';
import { DepenseService } from '../../services/depense.service';
import { AlertService } from '../../services/alert.service';
import { Depense } from '../../models/depense.model';

@Component({
  selector: 'app-depense-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, TranslateModule],
  templateUrl: './depense-form.component.html',
  styleUrls: ['./depense-form.component.scss'],
})
export class DepenseFormComponent implements OnInit {
  form!: FormGroup;
  isEditMode = false;
  sortieId!: string;
  depenseId?: string;
  loading = false;
  // Utilise les clés MAJUSCULES qui existent dans les fichiers JSON
  expenseKeys: string[] = ['FUEL', 'ICE', 'OIL_CHANGE', 'CREW_CNSS', 'CREW_BONUS', 'FOOD', 'VMS', 'MISC'];

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private depenseService: DepenseService,
    private alertService: AlertService,
    private location: Location
  ) {}

  ngOnInit(): void {
    this.sortieId = this.route.snapshot.paramMap.get('id')!;
    this.depenseId = this.route.snapshot.paramMap.get('depenseId') || undefined;
    this.isEditMode = !!this.depenseId;

    this.initForm();

    if (this.isEditMode && this.depenseId) {
      this.loading = true;
      this.depenseService.getDepense(this.depenseId).subscribe((depense) => {
        if (depense) {
          this.form.patchValue({
            ...depense,
            date: this.formatDate(depense.date),
          });
        }
        this.loading = false;
      });
    }
  }

  private initForm(): void {
    this.form = this.fb.group({
      type: ['fuel', Validators.required], // Valeur par défaut en minuscule
      montant: [null, [Validators.required, Validators.min(0.01)]],
      date: [new Date().toISOString().substring(0, 10), Validators.required],
      description: [''],
    });
  }
  
  private formatDate(date: any): string {
    if (!date) return new Date().toISOString().substring(0, 10);
    const d = date.toDate ? date.toDate() : new Date(date);
    return d.toISOString().split('T')[0];
  }

  async onSubmit(): Promise<void> {
    if (this.form.invalid) {
      this.alertService.warning('Veuillez remplir tous les champs obligatoires.', 'Formulaire incomplet');
      return;
    }

    this.loading = true;
    const formValue = this.form.value;
    const depenseData: Omit<Depense, 'id'> = {
      ...formValue,
      sortieId: this.sortieId,
      date: new Date(formValue.date),
    };

    try {
      if (this.isEditMode && this.depenseId) {
        await this.depenseService.updateDepense(this.depenseId, depenseData);
        await this.alertService.toast('EXPENSES.SUCCESS_UPDATE', 'success');
      } else {
        await this.depenseService.addDepense(depenseData as Depense);
        await this.alertService.toast('EXPENSES.SUCCESS_ADD', 'success');
      }
      this.router.navigate(['/dashboard/sorties/details', this.sortieId]);
    } catch (error) {
      console.error('Erreur lors de la sauvegarde de la dépense', error);
      this.alertService.error('Une erreur est survenue.', 'Erreur');
    } finally {
      this.loading = false;
    }
  }

  cancel(): void {
    this.location.back();
  }
}
