import { Injectable } from '@angular/core';
import { 
  Firestore, 
  collection, 
  addDoc, 
  collectionData, 
  query, 
  where, 
  orderBy,
  doc,
  updateDoc
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { CalculSalaire } from '../models/salaire.model';

@Injectable({
  providedIn: 'root'
})
export class SalaireService {
  private calculsSalaireCollection = 'calculs_salaire';

  constructor(private firestore: Firestore) {}

  async saveCalculSalaire(calcul: Omit<CalculSalaire, 'id'>): Promise<any> {
    const calculsCollection = collection(this.firestore, this.calculsSalaireCollection);
    return await addDoc(calculsCollection, calcul);
  }

  getCalculsBySortieId(sortieId: string): Observable<CalculSalaire[]> {
    const calculsCollection = collection(this.firestore, this.calculsSalaireCollection);
    const q = query(calculsCollection, where('sortiesIds', 'array-contains', sortieId));
    return collectionData(q, { idField: 'id' }) as Observable<CalculSalaire[]>;
  }

  getCalculsByBateau(bateauId: string): Observable<CalculSalaire[]> {
    const calculsCollection = collection(this.firestore, this.calculsSalaireCollection);
    const q = query(calculsCollection, where('bateauId', '==', bateauId), orderBy('dateCalcul', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<CalculSalaire[]>;
  }

  getAllCalculs(): Observable<CalculSalaire[]> {
    const calculsCollection = collection(this.firestore, this.calculsSalaireCollection);
    const q = query(calculsCollection, orderBy('dateCalcul', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<CalculSalaire[]>;
  }

  async updateCalculSalaire(id: string, data: Partial<CalculSalaire>): Promise<void> {
    const docRef = doc(this.firestore, this.calculsSalaireCollection, id);
    await updateDoc(docRef, { ...data });
  }
}
