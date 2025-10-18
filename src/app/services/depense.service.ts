import { Injectable } from '@angular/core';
import {
  Firestore,
  collection,
  collectionData,
  doc,
  docData,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  CollectionReference,
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Depense } from '../models/depense.model';

@Injectable({
  providedIn: 'root',
})
export class DepenseService {
  private depensesCollection: CollectionReference;

  constructor(private firestore: Firestore) {
    this.depensesCollection = collection(this.firestore, 'depenses');
  }

  getDepensesBySortie(sortieId: string): Observable<Depense[]> {
    const q = query(
      this.depensesCollection,
      where('sortieId', '==', sortieId),
      orderBy('date', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Depense[]>;
  }

  getDepense(id: string): Observable<Depense | undefined> {
    const depenseDoc = doc(this.firestore, `depenses/${id}`);
    return docData(depenseDoc, { idField: 'id' }) as Observable<Depense | undefined>;
  }

  async addDepense(depense: Depense): Promise<any> {
    const newDepense = { ...depense, createdAt: new Date(), updatedAt: new Date() };
    return await addDoc(this.depensesCollection, newDepense);
  }

  async updateDepense(id: string, depense: Partial<Depense>): Promise<void> {
    const depenseDoc = doc(this.firestore, `depenses/${id}`);
    const updateData = { ...depense, updatedAt: new Date() };
    return await updateDoc(depenseDoc, updateData);
  }

  async deleteDepense(id: string): Promise<void> {
    const depenseDoc = doc(this.firestore, `depenses/${id}`);
    return await deleteDoc(depenseDoc);
  }
}
