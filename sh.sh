#!/bin/bash
set -e

echo "🔄 Restauration de marin-form.component.ts depuis backup..."

FILE="src/app/marins/marin-form.component.ts"

# Restaurer depuis le backup le plus ancien (avant corruptions)
OLDEST_BACKUP=$(ls -t "${FILE}.bak_"* 2>/dev/null | tail -1)

if [ -n "$OLDEST_BACKUP" ]; then
    echo "📦 Restauration depuis: $OLDEST_BACKUP"
    cp "$OLDEST_BACKUP" "$FILE"
    echo "✅ Fichier restauré!"
else
    echo "❌ Aucun backup trouvé. Recréation du fichier..."
    
    # Si pas de backup, recréer le fichier de base
    cat > "$FILE" << 'EOF'
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MarinService } from '../services/marin.service';
import { Marin } from '../models/marin.model';

@Component({
  selector: 'app-marin-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './marin-form.component.html',
  styleUrls: ['./marin-form.component.scss']
})
export class MarinFormComponent implements OnInit {
  marinForm: FormGroup;
  marinId: string | null = null;
  bateauId: string = '';
  isEditMode = false;

  constructor(
    private fb: FormBuilder,
    private marinService: MarinService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.marinForm = this.fb.group({
      nom: ['', Validators.required],
      prenom: ['', Validators.required],
      dateNaissance: ['', Validators.required],
      dateEmbauche: ['', Validators.required],
      fonction: ['', Validators.required],
      coefficientSalaire: [1, [Validators.required, Validators.min(0.1)]],
      telephone: [''],
      adresse: [''],
      statut: ['actif', Validators.required]
    });
  }

  ngOnInit(): void {
    this.route.queryParams.subscribe(params => {
      this.bateauId = params['bateauId'] || '';
      this.marinId = params['id'] || null;

      if (this.marinId) {
        this.isEditMode = true;
        this.loadMarin();
      }
    });
  }

  loadMarin(): void {
    if (this.marinId) {
      this.marinService.getMarin(this.marinId).subscribe(marin => {
        if (marin) {
          this.marinForm.patchValue({
            nom: marin.nom,
            prenom: marin.prenom,
            dateNaissance: this.formatDate(marin.dateNaissance),
            dateEmbauche: this.formatDate(marin.dateEmbauche),
            fonction: marin.fonction,
            coefficientSalaire: marin.coefficientSalaire,
            telephone: marin.telephone || '',
            adresse: marin.adresse || '',
            statut: marin.statut
          });
        }
      });
    }
  }

  formatDate(date: any): string {
    if (date && typeof date.toDate === 'function') {
      return date.toDate().toISOString().split('T')[0];
    }
    if (date instanceof Date) {
      return date.toISOString().split('T')[0];
    }
    return '';
  }

  async onSubmit(): Promise<void> {
    if (this.marinForm.valid) {
      try {
        const marinData = {
          ...this.marinForm.value,
          bateauId: this.bateauId,
          dateNaissance: new Date(this.marinForm.value.dateNaissance),
          dateEmbauche: new Date(this.marinForm.value.dateEmbauche)
        };

        if (this.isEditMode && this.marinId) {
          await this.marinService.updateMarin(this.marinId, marinData);
          alert('Marin modifié avec succès');
        } else {
          await this.marinService.addMarin(marinData);
          alert('Marin ajouté avec succès');
        }

        this.router.navigate(['/dashboard/marins'], {
          queryParams: { bateauId: this.bateauId }
        });
      } catch (error) {
        console.error('Erreur:', error);
        alert('Erreur lors de l\'enregistrement');
      }
    }
  }

  cancel(): void {
    this.router.navigate(['/dashboard/marins'], {
      queryParams: { bateauId: this.bateauId }
    });
  }
}
EOF
    echo "✅ Fichier recréé depuis zéro"
fi

echo ""
echo "🎉 Fichier restauré/recréé avec succès!"
echo "➡️ Recompilez: ng serve"
