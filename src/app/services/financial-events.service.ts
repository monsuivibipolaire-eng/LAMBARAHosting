import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class FinancialEventsService {
  private changeSubject = new Subject<void>();
  change$ = this.changeSubject.asObservable();

  notifyFinancialChange(): void {
    this.changeSubject.next();
  }
}
