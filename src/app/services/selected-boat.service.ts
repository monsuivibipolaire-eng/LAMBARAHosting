import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { Bateau } from '../models/bateau.model';

@Injectable({
  providedIn: 'root'
})
export class SelectedBoatService {
  private selectedBoatSubject = new BehaviorSubject<Bateau | null>(null);
  public selectedBoat$: Observable<Bateau | null> = this.selectedBoatSubject.asObservable();

  constructor() {
    // Charger le bateau depuis le localStorage au démarrage
    const savedBoat = localStorage.getItem('selectedBoat');
    if (savedBoat) {
      try {
        this.selectedBoatSubject.next(JSON.parse(savedBoat));
      } catch (e) {
        console.error('Erreur lors du chargement du bateau sélectionné', e);
      }
    }
  }

  selectBoat(boat: Bateau): void {
    this.selectedBoatSubject.next(boat);
    localStorage.setItem('selectedBoat', JSON.stringify(boat));
  }

  getSelectedBoat(): Bateau | null {
    return this.selectedBoatSubject.value;
  }

  clearSelection(): void {
    this.selectedBoatSubject.next(null);
    localStorage.removeItem('selectedBoat');
  }

  hasSelectedBoat(): boolean {
    return this.selectedBoatSubject.value !== null;
  }
}
