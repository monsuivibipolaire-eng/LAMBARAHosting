import { Injectable } from '@angular/core';
import {
  Firestore,
  collection,
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  query,
  where,
  collectionData,
  docData,
  orderBy
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Sortie } from '../models/sortie.model';
import { FinancialEventsService } from './financial-events.service';

@Injectable({
  providedIn: 'root'
})
export class SortieService {
  private sortiesCollection = collection(this.firestore, 'sorties');

  constructor(
    private firestore: Firestore,
    private finEvents: FinancialEventsService
  ) {}

  getSorties(): Observable<Sortie[]> {
    return collectionData(this.sortiesCollection, { idField: 'id' }) as Observable<Sortie[]>;
  }

  getAllSorties(): Observable<Sortie[]> {
    const q = query(this.sortiesCollection, orderBy('dateDepart', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<Sortie[]>;
  }

  getSortiesByBateau(bateauId: string): Observable<Sortie[]> {
    const q = query(this.sortiesCollection, where('bateauId', '==', bateauId));
    return collectionData(q, { idField: 'id' }) as Observable<Sortie[]>;
  }

  getSortie(id: string): Observable<Sortie | undefined> {
    const d = doc(this.firestore, 'sorties', id);
    return docData(d, { idField: 'id' }) as Observable<Sortie | undefined>;
  }

  async addSortie(sortie: Omit<Sortie, 'id'>): Promise<string> {
    const ref = await addDoc(this.sortiesCollection, sortie);
    this.finEvents.notifyFinancialChange();
    return ref.id;
  }

  async updateSortie(id: string, sortie: Partial<Sortie>): Promise<void> {
    const d = doc(this.firestore, 'sorties', id);
    await updateDoc(d, { ...sortie });
    this.finEvents.notifyFinancialChange();
  }

  async deleteSortie(id: string): Promise<void> {
    const d = doc(this.firestore, 'sorties', id);
    await deleteDoc(d);
    this.finEvents.notifyFinancialChange();
  }
}
