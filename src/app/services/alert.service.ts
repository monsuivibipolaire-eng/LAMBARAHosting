import { Injectable } from '@angular/core';
import Swal from 'sweetalert2';
import { TranslateService } from '@ngx-translate/core';

@Injectable({
  providedIn: 'root'
})
export class AlertService {

  constructor(private translate: TranslateService) {}

  async success(message: string, title?: string): Promise<void> {
    await Swal.fire({
      title: title || this.translate.instant('MESSAGES.SUCCESS'),
      text: message,
      icon: 'success',
      confirmButtonColor: '#3b82f6',
      confirmButtonText: 'OK'
    });
  }

  async error(message?: string, title?: string): Promise<void> {
    await Swal.fire({
      title: title || this.translate.instant('MESSAGES.ERROR_TITLE'),
      text: message || this.translate.instant('MESSAGES.ERROR_GENERIC'),
      icon: 'error',
      confirmButtonColor: '#ef4444',
      confirmButtonText: 'OK'
    });
  }

  async warning(message: string, title?: string): Promise<void> {
    await Swal.fire({
      title: title || this.translate.instant('MESSAGES.WARNING_TITLE'),
      text: message,
      icon: 'warning',
      confirmButtonColor: '#f59e0b',
      confirmButtonText: 'OK'
    });
  }

  async confirmDelete(itemName: string): Promise<boolean> {
    const result = await Swal.fire({
      title: this.translate.instant('MESSAGES.AREYOUSURE'),
      html: `${this.translate.instant('MESSAGES.CONFIRMDELETEMESSAGE')} <b>${itemName}</b> ?<br>${this.translate.instant('MESSAGES.IRREVERSIBLE')}`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#ef4444',
      cancelButtonColor: '#6b7280',
      confirmButtonText: this.translate.instant('FORM.DELETE'),
      cancelButtonText: this.translate.instant('FORM.CANCEL')
    });
    return result.isConfirmed;
  }

  loading(message?: string): void {
    Swal.fire({
      title: message || this.translate.instant('MESSAGES.LOADING'),
      allowOutsideClick: false,
      allowEscapeKey: false,
      didOpen: () => {
        Swal.showLoading();
      }
    });
  }

  close(): void {
    Swal.close();
  }

  toast(message: string, type: 'success' | 'error' | 'warning' | 'info' = 'success'): void {
    Swal.fire({
      toast: true,
      position: 'top-end',
      icon: type,
      title: message,
      showConfirmButton: false,
      timer: 3000,
      timerProgressBar: true
    });
  }
}
