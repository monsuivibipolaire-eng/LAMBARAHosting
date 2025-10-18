import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, doc, getDoc, setDoc, collectionData, query, where } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { CoeffSalaire, CalculSalaire } from '../models/salaire.model';

@Injectable({
  providedIn: 'root'
})
export class SalaireService {
  private collectionName = 'coefficients_salaire';
  private calculsSalaireCollection = 'calculs_salaire';

  constructor(private firestore: Firestore) {}

  // Récupérer le coefficient d'un marin
  async getCoefficient(marinId: string): Promise<number> {
    const coeffDoc = doc(this.firestore, `${this.collectionName}/${marinId}`);
    const docSnap = await getDoc(coeffDoc);
    
    if (docSnap.exists()) {
      const data = docSnap.data() as CoeffSalaire;
      return data.coefficient;
    }
    return 0; // Par défaut
  }

  // Sauvegarder le coefficient d'un marin
  async saveCoefficient(marinId: string, coefficient: number): Promise<void> {
    const coeffDoc = doc(this.firestore, `${this.collectionName}/${marinId}`);
    const data: CoeffSalaire = {
      marinId,
      coefficient
    };
    return await setDoc(coeffDoc, data);
  }

  // Sauvegarder un calcul de salaire
  async saveCalculSalaire(calcul: CalculSalaire): Promise<any> {
    const calculsCollection = collection(this.firestore, this.calculsSalaireCollection);
    return await addDoc(calculsCollection, calcul);
  }

  // Récupérer les calculs de salaire d'une sortie
  getCalculsBySortie(sortieId: string): Observable<CalculSalaire[]> {
    const calculsCollection = collection(this.firestore, this.calculsSalaireCollection);
    const q = query(calculsCollection, where('sortieId', '==', sortieId));
    return collectionData(q, { idField: 'id' }) as Observable<CalculSalaire[]>;
  }
}
