import { Injectable } from '@angular/core';
import { Firestore, collection, query, where, collectionData, addDoc, updateDoc, deleteDoc, doc, docData } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Sortie } from '../models/sortie.model';

@Injectable({
  providedIn: 'root'
})
export class SortieService {
  private sortiesCollection = collection(this.firestore, 'sorties');

  constructor(private firestore: Firestore) {}

  getSorties(): Observable<Sortie[]> {
    return collectionData(this.sortiesCollection, { idField: 'id' }) as Observable<Sortie[]>;
  }

  getSortie(id: string): Observable<Sortie> {
    const sortieDoc = doc(this.firestore, 'sorties', id);
    return docData(sortieDoc, { idField: 'id' }) as Observable<Sortie>;
  }

  getSortiesByBateau(bateauId: string): Observable<Sortie[]> {
    console.log('🔍 getSortiesByBateau appelé avec bateauId:', bateauId);
    
    const q = query(
      this.sortiesCollection,
      where('bateauId', '==', bateauId)
    );
    
    const result$ = collectionData(q, { idField: 'id' }) as Observable<Sortie[]>;
    
    result$.subscribe(sorties => {
      console.log(`📊 Sorties trouvées pour bateau ${bateauId}:`, sorties.length);
      if (sorties.length > 0) {
        console.log('📦 Première sortie:', sorties[0]);
      }
    });
    
    return result$;
  }

  async addSortie(sortie: Omit<Sortie, 'id'>): Promise<string> {
    console.log('➕ Ajout sortie:', sortie);
    const docRef = await addDoc(this.sortiesCollection, sortie);
    console.log('✅ Sortie ajoutée avec ID:', docRef.id);
    return docRef.id;
  }

  async updateSortie(id: string, sortie: Partial<Sortie>): Promise<void> {
    const sortieDoc = doc(this.firestore, 'sorties', id);
    await updateDoc(sortieDoc, sortie);
  }

  async deleteSortie(id: string): Promise<void> {
    const sortieDoc = doc(this.firestore, 'sorties', id);
    await deleteDoc(sortieDoc);
  }
}
