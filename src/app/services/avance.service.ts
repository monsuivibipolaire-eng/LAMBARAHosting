import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, collectionData, query, where } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Avance } from '../models/avance.model';

@Injectable({
  providedIn: 'root'
})
export class AvanceService {
  private collectionName = 'avances';

  constructor(private firestore: Firestore) {}

  getAvancesByMarin(marinId: string): Observable<Avance[]> {
    const avancesCollection = collection(this.firestore, this.collectionName);
    const q = query(avancesCollection, where('marinId', '==', marinId));
    return collectionData(q, { idField: 'id' }) as Observable<Avance[]>;
  }

  getAvancesByBateau(bateauId: string): Observable<Avance[]> {
    const avancesCollection = collection(this.firestore, this.collectionName);
    const q = query(avancesCollection, where('bateauId', '==', bateauId));
    return collectionData(q, { idField: 'id' }) as Observable<Avance[]>;
  }

  async addAvance(avance: Omit<Avance, 'id'>): Promise<any> {
    const avancesCollection = collection(this.firestore, this.collectionName);
    
    // ✅ FILTRER LES VALEURS UNDEFINED
    const dataToSave: any = {
      marinId: avance.marinId,
      bateauId: avance.bateauId,
      montant: avance.montant,
      dateAvance: avance.dateAvance,
      createdAt: new Date()
    };

    // Ajouter description seulement si elle existe
    if (avance.description && avance.description.trim() !== '') {
      dataToSave.description = avance.description;
    }

    return await addDoc(avancesCollection, dataToSave);
  }

  async updateAvance(id: string, avance: Partial<Avance>): Promise<void> {
    const avanceDoc = doc(this.firestore, `${this.collectionName}/${id}`);
    
    // ✅ FILTRER LES VALEURS UNDEFINED
    const dataToUpdate: any = {};
    
    if (avance.montant !== undefined) {
      dataToUpdate.montant = avance.montant;
    }
    
    if (avance.dateAvance !== undefined) {
      dataToUpdate.dateAvance = avance.dateAvance;
    }
    
    if (avance.description !== undefined) {
      if (avance.description && avance.description.trim() !== '') {
        dataToUpdate.description = avance.description;
      } else {
        // Si description est vide, la supprimer du document
        dataToUpdate.description = '';
      }
    }

    return await updateDoc(avanceDoc, dataToUpdate);
  }

  async deleteAvance(id: string): Promise<void> {
    const avanceDoc = doc(this.firestore, `${this.collectionName}/${id}`);
    return await deleteDoc(avanceDoc);
  }
}
