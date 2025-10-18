import { Injectable } from '@angular/core';
import { Firestore, collection, collectionData, doc, addDoc, updateDoc, deleteDoc, query, where, orderBy } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Facture } from '../models/facture.model';

@Injectable({ providedIn: 'root' })
export class FactureService {
  constructor(private firestore: Firestore) {}

  getFacturesBySortie(sortieId: string): Observable<Facture[]> {
    const facturesCollection = collection(this.firestore, 'factures');
    const facturesQuery = query(facturesCollection, where('sortieId', '==', sortieId), orderBy('dateFacture', 'desc'));
    return collectionData(facturesQuery, { idField: 'id' }) as Observable<Facture[]>;
  }

  async addFacture(facture: Facture): Promise<any> {
    const facturesCollection = collection(this.firestore, 'factures');
    return await addDoc(facturesCollection, { ...facture, createdAt: new Date(), updatedAt: new Date() });
  }

  async updateFacture(id: string, facture: Partial<Facture>): Promise<void> {
    const factureDoc = doc(this.firestore, 'factures/' + id);
    await updateDoc(factureDoc, { ...facture, updatedAt: new Date() });
  }

  async deleteFacture(id: string): Promise<void> {
    const factureDoc = doc(this.firestore, 'factures/' + id);
    await deleteDoc(factureDoc);
  }
}
