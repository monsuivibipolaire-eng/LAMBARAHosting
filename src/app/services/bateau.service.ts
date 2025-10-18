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
  orderBy,
  CollectionReference
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Bateau } from '../models/bateau.model';

@Injectable({
  providedIn: 'root'
})
export class BateauService {
  private bateauxCollection: CollectionReference;

  constructor(private firestore: Firestore) {
    this.bateauxCollection = collection(this.firestore, 'bateaux');
  }

  getBateaux(): Observable<Bateau[]> {
    const bateauxQuery = query(this.bateauxCollection, orderBy('nom', 'asc'));
    return collectionData(bateauxQuery, { idField: 'id' }) as Observable<Bateau[]>;
  }

  getBateau(id: string): Observable<Bateau> {
    const bateauDoc = doc(this.firestore, `bateaux/${id}`);
    return docData(bateauDoc, { idField: 'id' }) as Observable<Bateau>;
  }

  async addBateau(bateau: Bateau): Promise<string> {
    const newBateau = {
      ...bateau,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    const docRef = await addDoc(this.bateauxCollection, newBateau);
    // Retourner uniquement l'ID, pas le chemin complet
    return docRef.id;
  }

  async updateBateau(id: string, bateau: Partial<Bateau>): Promise<void> {
    const bateauDoc = doc(this.firestore, `bateaux/${id}`);
    const updateData = {
      ...bateau,
      updatedAt: new Date()
    };
    return await updateDoc(bateauDoc, updateData);
  }

  async deleteBateau(id: string): Promise<void> {
    const bateauDoc = doc(this.firestore, `bateaux/${id}`);
    return await deleteDoc(bateauDoc);
  }
}
