import { Injectable, inject } from '@angular/core';
import { 
  Firestore, 
  collection, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  collectionData, 
  query, 
  where 
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { FactureVente } from '../models/facture-vente.model';

@Injectable({
  providedIn: 'root'
})
export class FactureVenteService {
  private collectionName = 'factures-vente';
  private firestore = inject(Firestore);

  getFacturesBySortie(sortieId: string): Observable<FactureVente[]> {
    const facturesCollection = collection(this.firestore, this.collectionName);
    const q = query(facturesCollection, where('sortieId', '==', sortieId));
    return collectionData(q, { idField: 'id' }) as Observable<FactureVente[]>;
  }

  async addFacture(facture: Omit<FactureVente, 'id'>): Promise<any> {
    const facturesCollection = collection(this.firestore, this.collectionName);
    return await addDoc(facturesCollection, {
      ...facture,
      createdAt: new Date()
    });
  }

  async updateFacture(id: string, facture: Partial<FactureVente>): Promise<void> {
    const factureDoc = doc(this.firestore, this.collectionName, id);
    return await updateDoc(factureDoc, facture);
  }

  async deleteFacture(id: string): Promise<void> {
    const factureDoc = doc(this.firestore, this.collectionName, id);
    return await deleteDoc(factureDoc);
  }
}
