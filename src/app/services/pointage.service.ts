import { Injectable } from '@angular/core';
import { 
  Firestore, 
  collection, 
  collectionData, 
  doc, 
  addDoc, 
  updateDoc, 
  query, 
  where, 
  CollectionReference 
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Pointage } from '../models/pointage.model';

@Injectable({
  providedIn: 'root',
})
export class PointageService {
  private pointagesCollection: CollectionReference;

  constructor(private firestore: Firestore) {
    this.pointagesCollection = collection(this.firestore, 'pointages');
  }

  getPointagesBySortie(sortieId: string): Observable<Pointage[]> {
    const q = query(this.pointagesCollection, where('sortieId', '==', sortieId));
    return collectionData(q, { idField: 'id' }) as Observable<Pointage[]>;
  }

  async addPointage(pointage: Omit<Pointage, 'id'>): Promise<any> {
    return await addDoc(this.pointagesCollection, {
      ...pointage,
      createdAt: new Date(),
      updatedAt: new Date()
    });
  }

  async updatePointage(id: string, pointage: Partial<Pointage>): Promise<void> {
    const pointageDoc = doc(this.firestore, `pointages/${id}`);
    return await updateDoc(pointageDoc, {
      ...pointage,
      updatedAt: new Date()
    });
  }
}
