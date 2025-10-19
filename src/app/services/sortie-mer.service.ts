import { Injectable } from '@angular/core';
import { Firestore, collection, query, where, orderBy, collectionData } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { SortieMer } from '../models/sortie-mer.model';

@Injectable({ providedIn: 'root' })
export class SortieMerService {
  private collectionName = 'sorties-mer';

  constructor(private firestore: Firestore) {}

  getSortiesByBateau(bateauId: string): Observable<SortieMer[]> {
    const col = collection(this.firestore, this.collectionName);
    const q = query(col, where('bateauId', '==', bateauId), orderBy('dateFin', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<SortieMer[]>;
  }
}
