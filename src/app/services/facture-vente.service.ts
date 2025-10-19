import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, query, where, collectionData, docData } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { FactureVente } from '../models/facture-vente.model';
import { FinancialEventsService } from './financial-events.service';

@Injectable({ providedIn: 'root' })
export class FactureVenteService {
  private collectionName = 'factures-vente';

  constructor(
    private firestore: Firestore,
    private finEvents: FinancialEventsService
  ) {}

  getFacturesBySortie(sortieId: string): Observable<FactureVente[]> {
    const col = collection(this.firestore, this.collectionName);
    const q = query(col, where('sortieId','==', sortieId));
    return collectionData(q, { idField: 'id' }) as Observable<FactureVente[]>;
  }

  getFacture(id: string): Observable<FactureVente | undefined> {
    const d = doc(this.firestore, this.collectionName, id);
    return docData(d, { idField: 'id' }) as Observable<FactureVente | undefined>;
  }

  async addFacture(facture: Omit<FactureVente,'id'>): Promise<string> {
    const col = collection(this.firestore, this.collectionName);
    const ref = await addDoc(col, facture);
    this.finEvents.notifyFinancialChange();
    return ref.id;
  }

  async updateFacture(id: string, facture: Partial<FactureVente>): Promise<void> {
    const d = doc(this.firestore, this.collectionName, id);
    await updateDoc(d, facture);
    this.finEvents.notifyFinancialChange();
  }

  async deleteFacture(id: string): Promise<void> {
    const d = doc(this.firestore, this.collectionName, id);
    await deleteDoc(d);
    this.finEvents.notifyFinancialChange();
  }
}
