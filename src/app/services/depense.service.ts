import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, query, where, collectionData, docData } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Depense } from '../models/depense.model';
import { FinancialEventsService } from './financial-events.service';

@Injectable({ providedIn: 'root' })
export class DepenseService {
  private collectionName = 'depenses';

  constructor(
    private firestore: Firestore,
    private finEvents: FinancialEventsService
  ) {}

  getDepensesBySortie(sortieId: string): Observable<Depense[]> {
    const col = collection(this.firestore, this.collectionName);
    const q = query(col, where('sortieId','==', sortieId));
    return collectionData(q, { idField: 'id' }) as Observable<Depense[]>;
  }

  getDepense(id: string): Observable<Depense | undefined> {
    const d = doc(this.firestore, this.collectionName, id);
    return docData(d, { idField: 'id' }) as Observable<Depense | undefined>;
  }

  async addDepense(depense: Omit<Depense,'id'>): Promise<string> {
    const col = collection(this.firestore, this.collectionName);
    const ref = await addDoc(col, depense);
    this.finEvents.notifyFinancialChange();
    return ref.id;
  }

  async updateDepense(id: string, depense: Partial<Depense>): Promise<void> {
    const d = doc(this.firestore, this.collectionName, id);
    await updateDoc(d, depense);
    this.finEvents.notifyFinancialChange();
  }

  async deleteDepense(id: string): Promise<void> {
    const d = doc(this.firestore, this.collectionName, id);
    await deleteDoc(d);
    this.finEvents.notifyFinancialChange();
  }
}
