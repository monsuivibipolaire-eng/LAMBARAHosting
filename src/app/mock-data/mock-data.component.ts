import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MockDataService } from '../services/mock-data.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-mock-data',
  standalone: false,
  template: `
    <div class="mock-container">
      <div class="mock-card">
        <h2>🎲 Générateur de Données Fictives</h2>
        <p>Créez rapidement des données de test complètes</p>
        
        <div class="data-list">
          <div class="data-item">✓ 2 bateaux de pêche</div>
          <div class="data-item">✓ 5 marins</div>
          <div class="data-item">✓ 6 sorties en mer</div>
          <div class="data-item">✓ 12 dépenses</div>
          <div class="data-item">✓ 6 factures de vente</div>
          <div class="data-item">✓ 5 avances</div>
        </div>

        <button 
          (click)="generate()" 
          [disabled]="generating"
          class="btn-generate">
          <span *ngIf="!generating">Générer les données</span>
          <span *ngIf="generating">Génération en cours...</span>
        </button>
      </div>
    </div>
  `,
  styles: [`
    .mock-container {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 2rem;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    
    .mock-card {
      background: white;
      border-radius: 1rem;
      padding: 3rem;
      max-width: 500px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
    }
    
    h2 {
      margin: 0 0 1rem 0;
      color: #1f2937;
      font-size: 2rem;
    }
    
    p {
      color: #6b7280;
      margin: 0 0 2rem 0;
    }
    
    .data-list {
      background: #f9fafb;
      padding: 1.5rem;
      border-radius: 0.5rem;
      margin-bottom: 2rem;
    }
    
    .data-item {
      padding: 0.5rem 0;
      color: #374151;
      font-weight: 500;
    }
    
    .btn-generate {
      width: 100%;
      padding: 1rem;
      background: #667eea;
      color: white;
      border: none;
      border-radius: 0.5rem;
      font-size: 1.125rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s;
    }
    
    .btn-generate:hover:not(:disabled) {
      background: #5568d3;
      transform: translateY(-2px);
      box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
    }
    
    .btn-generate:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
  `]
})
export class MockDataComponent {
  generating = false;

  constructor(private mockService: MockDataService) {}

  async generate(): Promise<void> {
    const result = await Swal.fire({
      title: 'Générer des données fictives ?',
      text: 'Cela va créer environ 35 enregistrements de test',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Oui, générer',
      cancelButtonText: 'Annuler',
      confirmButtonColor: '#667eea'
    });

    if (result.isConfirmed) {
      try {
        this.generating = true;

        Swal.fire({
          title: 'Génération en cours...',
          text: 'Veuillez patienter',
          allowOutsideClick: false,
          didOpen: () => Swal.showLoading()
        });

        await this.mockService.generateAllMockData();

        Swal.close();

        await Swal.fire({
          title: 'Succès !',
          text: 'Les données ont été générées avec succès',
          icon: 'success',
          confirmButtonColor: '#667eea'
        });

      } catch (error) {
        console.error(error);
        Swal.fire({
          title: 'Erreur',
          text: 'Une erreur est survenue',
          icon: 'error'
        });
      } finally {
        this.generating = false;
      }
    }
  }
}
