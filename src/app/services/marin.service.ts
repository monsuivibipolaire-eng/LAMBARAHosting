import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, query, where, orderBy, collectionData, docData } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Marin } from '../models/marin.model';
import { FinancialEventsService } from './financial-events.service';

@Injectable({ providedIn: 'root' })
export class MarinService {
  private collectionName = 'marins';

  constructor(
    private firestore: Firestore,
    private finEvents: FinancialEventsService
  ) {}

  getMarinsByBateau(bateauId: string): Observable<Marin[]> {
    const col = collection(this.firestore, this.collectionName);
    const q = query(col, where('bateauId','==', bateauId), orderBy('nom'));
    return collectionData(q, { idField: 'id' }) as Observable<Marin[]>;
  }

  getAllMarins(): Observable<Marin[]> {
    const col = collection(this.firestore, this.collectionName);
    const q = query(col, orderBy('nom', 'asc'));
    return collectionData(q, { idField: 'id' }) as Observable<Marin[]>;
  }

  getMarins(): Observable<Marin[]> {
    return this.getAllMarins();
  }

  getMarin(id: string): Observable<Marin | undefined> {
    const d = doc(this.firestore, this.collectionName, id);
    return docData(d, { idField: 'id' }) as Observable<Marin | undefined>;
  }

  async addMarin(marin: Omit<Marin, 'id'>): Promise<string> {
    const newMarin = {
      ...marin,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    const col = collection(this.firestore, this.collectionName);
    const ref = await addDoc(col, newMarin);
    this.finEvents.notifyFinancialChange();
    return ref.id;
  }

  async updateMarin(id: string, marin: Partial<Marin>): Promise<void> {
    const updateData = {
      ...marin,
      updatedAt: new Date()
    };
    const d = doc(this.firestore, this.collectionName, id);
    await updateDoc(d, updateData);
    this.finEvents.notifyFinancialChange();
  }

  async deleteMarin(id: string): Promise<void> {
    const d = doc(this.firestore, this.collectionName, id);
    await deleteDoc(d);
    this.finEvents.notifyFinancialChange();
  }
}
