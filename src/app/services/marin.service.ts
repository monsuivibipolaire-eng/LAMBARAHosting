import { Injectable } from '@angular/core';
import { Firestore, collection, collectionData, doc, docData, addDoc, updateDoc, deleteDoc, query, where, orderBy, CollectionReference } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Marin } from '../models/marin.model';

@Injectable({
  providedIn: 'root'
})
export class MarinService {
  private marinsCollection: CollectionReference;

  constructor(private firestore: Firestore) {
    this.marinsCollection = collection(this.firestore, 'marins');
  }

  getMarinsByBateau(bateauId: string): Observable<Marin[]> {
    const marinsQuery = query(
      this.marinsCollection,
      where('bateauId', '==', bateauId),
      orderBy('nom', 'asc')
    );
    return collectionData(marinsQuery, { idField: 'id' }) as Observable<Marin[]>;
  }

  getAllMarins(): Observable<Marin[]> {
    const marinsQuery = query(this.marinsCollection, orderBy('nom', 'asc'));
    return collectionData(marinsQuery, { idField: 'id' }) as Observable<Marin[]>;
  }

  getMarin(id: string): Observable<Marin> {
    const marinDoc = doc(this.firestore, `marins/${id}`);
    return docData(marinDoc, { idField: 'id' }) as Observable<Marin>;
  }

  async addMarin(marin: Marin): Promise<any> {
    const newMarin = {
      ...marin,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    return await addDoc(this.marinsCollection, newMarin);
  }

  async updateMarin(id: string, marin: Partial<Marin>): Promise<void> {
    const marinDoc = doc(this.firestore, `marins/${id}`);
    const updateData = {
      ...marin,
      updatedAt: new Date()
    };
    return await updateDoc(marinDoc, updateData);
  }

  async deleteMarin(id: string): Promise<void> {
    const marinDoc = doc(this.firestore, `marins/${id}`);
    return await deleteDoc(marinDoc);
  }
}
