import { Injectable } from '@angular/core';
import { Firestore, collection, collectionData, doc, addDoc, updateDoc, query, where } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Partage } from '../models/partage.model';

@Injectable({ providedIn: 'root' })
export class PartageService {
  constructor(private firestore: Firestore) {}

  getPartageBySortie(sortieId: string): Observable<Partage[]> {
    const partagesCollection = collection(this.firestore, 'partages');
    const partageQuery = query(partagesCollection, where('sortieId', '==', sortieId));
    return collectionData(partageQuery, { idField: 'id' }) as Observable<Partage[]>;
  }

  async addPartage(partage: Partage): Promise<any> {
    const partagesCollection = collection(this.firestore, 'partages');
    return await addDoc(partagesCollection, { ...partage, createdAt: new Date(), updatedAt: new Date() });
  }

  async updatePartage(id: string, partage: Partial<Partage>): Promise<void> {
    const partageDoc = doc(this.firestore, 'partages/' + id);
    await updateDoc(partageDoc, { ...partage, updatedAt: new Date() });
  }
}
