import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, collectionData, query, where } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Paiement } from '../models/paiement.model';

@Injectable({
  providedIn: 'root'
})
export class PaiementService {
  private collectionName = 'paiements';

  constructor(private firestore: Firestore) {}

  getPaiementsByMarin(marinId: string): Observable<Paiement[]> {
    const paymentsCollection = collection(this.firestore, this.collectionName);
    const q = query(paymentsCollection, where('marinId', '==', marinId));
    return collectionData(q, { idField: 'id' }) as Observable<Paiement[]>;
  }

  async addPaiement(paiement: Omit<Paiement, 'id'>): Promise<any> {
    const paymentsCollection = collection(this.firestore, this.collectionName);
    return await addDoc(paymentsCollection, {
      ...paiement,
      createdAt: new Date()
    });
  }
}
