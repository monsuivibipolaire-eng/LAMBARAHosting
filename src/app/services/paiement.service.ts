import { Injectable } from '@angular/core';
import { 
  Firestore, 
  collection, 
  addDoc, 
  query, 
  where, 
  collectionData,
  orderBy
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Paiement } from '../models/paiement.model';
import { FinancialEventsService } from './financial-events.service';

@Injectable({
  providedIn: 'root'
})
export class PaiementService {
  private collectionName = 'paiements';

  constructor(
    private firestore: Firestore,
    private finEvents: FinancialEventsService
  ) {}

  getPaiementsByMarin(marinId: string): Observable<Paiement[]> {
    const col = collection(this.firestore, this.collectionName);
    const q = query(col, where('marinId', '==', marinId));
    return collectionData(q, { idField: 'id' }) as Observable<Paiement[]>;
  }

  getAllPaiements(): Observable<Paiement[]> {
    const col = collection(this.firestore, this.collectionName);
    const q = query(col, orderBy('datePaiement', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<Paiement[]>;
  }

  async addPaiement(paiement: Omit<Paiement, 'id'>): Promise<string> {
    const col = collection(this.firestore, this.collectionName);
    const paiementData = {
      ...paiement,
      createdAt: new Date()
    };
    const ref = await addDoc(col, paiementData);
    this.finEvents.notifyFinancialChange();
    return ref.id;
  }
}
