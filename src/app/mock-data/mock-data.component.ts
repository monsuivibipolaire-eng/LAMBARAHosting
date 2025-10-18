import { Component } from '@angular/core';
import { MockDataService } from '../services/mock-data.service';
import Swal from 'sweetalert2';
import { TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'app-mock-data',
  standalone: false,
  template: `
    <div class="mock-container">
      <div class="mock-card">
        <h2>{{ 'MOCK_DATA.TITLE' | translate }}</h2>
        <p>{{ 'MOCK_DATA.SUBTITLE' | translate }}</p>
        
        <div class="data-list">
          <div class="data-item">{{ 'MOCK_DATA.ITEM_1' | translate }}</div>
          <div class="data-item">{{ 'MOCK_DATA.ITEM_2' | translate }}</div>
          <div class="data-item">{{ 'MOCK_DATA.ITEM_3' | translate }}</div>
          <div class="data-item">{{ 'MOCK_DATA.ITEM_4' | translate }}</div>
        </div>

        <button 
          (click)="generate()" 
          [disabled]="generating"
          class="btn-generate">
          <span *ngIf="!generating">{{ 'MOCK_DATA.GENERATE_BUTTON' | translate }}</span>
          <span *ngIf="generating">{{ 'MOCK_DATA.GENERATING_BUTTON' | translate }}</span>
        </button>
      </div>
    </div>
  `,
  styles: [`
    .mock-container {
      min-height: 80vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 2rem;
    }
    .mock-card {
      background: white;
      border-radius: 1rem;
      padding: 3rem;
      max-width: 500px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.1);
      text-align: center;
    }
    h2 { margin: 0 0 1rem 0; color: #1f2937; font-size: 2rem; }
    p { color: #6b7280; margin: 0 0 2rem 0; }
    .data-list { background: #f9fafb; padding: 1.5rem; border-radius: 0.5rem; margin-bottom: 2rem; text-align: left; }
    .data-item { padding: 0.5rem 0; color: #374151; font-weight: 500; }
    .btn-generate {
      width: 100%;
      padding: 1rem;
      background: #3b82f6;
      color: white;
      border: none;
      border-radius: 0.5rem;
      font-size: 1.125rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s;
    }
    .btn-generate:hover:not(:disabled) { background: #2563eb; transform: translateY(-2px); box-shadow: 0 10px 20px rgba(59, 130, 246, 0.3); }
    .btn-generate:disabled { opacity: 0.6; cursor: not-allowed; }
  `]
})
export class MockDataComponent {
  generating = false;

  constructor(
    private mockService: MockDataService,
    private translate: TranslateService
  ) {}

  async generate(): Promise<void> {
    const result = await Swal.fire({
      title: this.translate.instant('MOCK_DATA.CONFIRM_TITLE'),
      text: this.translate.instant('MOCK_DATA.CONFIRM_TEXT'),
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: this.translate.instant('MOCK_DATA.CONFIRM_BUTTON'),
      cancelButtonText: this.translate.instant('MOCK_DATA.CANCEL_BUTTON'),
      confirmButtonColor: '#3b82f6'
    });

    if (result.isConfirmed) {
      try {
        this.generating = true;
        Swal.fire({
          title: this.translate.instant('MOCK_DATA.LOADING_TITLE'),
          text: this.translate.instant('MOCK_DATA.LOADING_TEXT'),
          allowOutsideClick: false,
          didOpen: () => Swal.showLoading()
        });

        await this.mockService.generateAllMockData();

        Swal.close();

        await Swal.fire({
          title: this.translate.instant('MOCK_DATA.SUCCESS_TITLE'),
          text: this.translate.instant('MOCK_DATA.SUCCESS_TEXT'),
          icon: 'success',
          confirmButtonColor: '#10b981'
        });
      } catch (error) {
        console.error(error);
        Swal.fire({
          title: this.translate.instant('MOCK_DATA.ERROR_TITLE'),
          text: (error as Error).message,
          icon: 'error'
        });
      } finally {
        this.generating = false;
      }
    }
  }
}
