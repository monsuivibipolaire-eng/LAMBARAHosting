import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, query, where, collectionData, docData } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Avance } from '../models/avance.model';
import { FinancialEventsService } from './financial-events.service';

@Injectable({ providedIn: 'root' })
export class AvanceService {
  private collectionName = 'avances';

  constructor(
    private firestore: Firestore,
    private finEvents: FinancialEventsService
  ) {}

  // ✅ NOUVELLE FONCTION: Ne retourne que les avances non encore incluses dans un calcul de salaire
  getUnsettledAvancesByBateau(bateauId: string): Observable<Avance[]> {
    const col = collection(this.firestore, this.collectionName);
    const q = query(col, where('bateauId', '==', bateauId), where('calculSalaireId', '==', null));
    return collectionData(q, { idField: 'id' }) as Observable<Avance[]>;
  }

  getAvancesByMarin(marinId: string): Observable<Avance[]> {
    const col = collection(this.firestore, this.collectionName);
    const q = query(col, where('marinId','==', marinId));
    return collectionData(q, { idField: 'id' }) as Observable<Avance[]>;
  }

  getAvancesByBateau(bateauId: string): Observable<Avance[]> {
    const col = collection(this.firestore, this.collectionName);
    const q = query(col, where('bateauId', '==', bateauId));
    return collectionData(q, { idField: 'id' }) as Observable<Avance[]>;
  }

  getAvance(id: string): Observable<Avance | undefined> {
    const d = doc(this.firestore, this.collectionName, id);
    return docData(d, { idField: 'id' }) as Observable<Avance | undefined>;
  }

  async addAvance(avance: Omit<Avance,'id'>): Promise<string> {
    const col = collection(this.firestore, this.collectionName);
    // On s'assure que les nouvelles avances sont bien "non réglées"
    const newAvance = { ...avance, calculSalaireId: null };
    const ref = await addDoc(col, newAvance);
    this.finEvents.notifyFinancialChange();
    return ref.id;
  }

  async updateAvance(id: string, avance: Partial<Avance>): Promise<void> {
    const d = doc(this.firestore, this.collectionName, id);
    await updateDoc(d, avance);
    this.finEvents.notifyFinancialChange();
  }

  async deleteAvance(id: string): Promise<void> {
    const d = doc(this.firestore, this.collectionName, id);
    await deleteDoc(d);
    this.finEvents.notifyFinancialChange();
  }
}
