import { Injectable } from '@angular/core';
import { Firestore, collection, query, where, collectionData, addDoc, updateDoc, deleteDoc, doc, docData } from '@angular/fire/firestore';
import { Observable, of, combineLatest } from 'rxjs';
// ✅ CORRECTION : Ajout de l'opérateur `tap` pour les logs
import { switchMap, map, tap } from 'rxjs/operators';

import { Sortie } from '../models/sortie.model';
import { Depense } from '../models/depense.model';
import { FactureVente } from '../models/facture-vente.model';

import { DepenseService } from './depense.service';
import { FactureVenteService } from './facture-vente.service';

export interface SortieDetails extends Sortie {
  depenses: Depense[];
  factures: FactureVente[];
  totalDepenses: number;
  totalFactures: number;
}

@Injectable({
  providedIn: 'root'
})
export class SortieService {
  private sortiesCollection = collection(this.firestore, 'sorties');

  constructor(
    private firestore: Firestore,
    private depenseService: DepenseService,
    private factureVenteService: FactureVenteService
  ) {}

  getSorties(): Observable<Sortie[]> {
    return collectionData(this.sortiesCollection, { idField: 'id' }) as Observable<Sortie[]>;
  }

  getSortie(id: string): Observable<Sortie> {
    const sortieDoc = doc(this.firestore, 'sorties', id);
    return docData(sortieDoc, { idField: 'id' }) as Observable<Sortie>;
  }

  // ✅ CORRECTION : La fonction contient maintenant des logs détaillés
  getSortiesByBateau(bateauId: string): Observable<SortieDetails[]> {
    console.log('🔍 getSortiesByBateau (version enrichie) appelée avec bateauId:', bateauId);
    
    const q = query(
      this.sortiesCollection,
      where('bateauId', '==', bateauId)
    );
    
    const sorties$ = collectionData(q, { idField: 'id' }) as Observable<Sortie[]>;
    
    return sorties$.pipe(
      tap(sorties => {
        // ✅ LOG : Affiche les sorties initiales trouvées
        console.log(`- ${sorties.length} sortie(s) trouvée(s) pour le bateau ${bateauId}.`, sorties);
        if (sorties.length > 0) {
            console.log("- Lancement de la récupération des détails (dépenses et factures) pour chaque sortie...");
        }
      }),
      switchMap(sorties => {
        if (sorties.length === 0) {
          return of([]);
        }

        const sortieDetailsObservables = sorties.map(sortie => {
          const depenses$ = this.depenseService.getDepensesBySortie(sortie.id!);
          const factures$ = this.factureVenteService.getFacturesBySortie(sortie.id!);

          return combineLatest([depenses$, factures$]).pipe(
            map(([depenses, factures]) => {
              const totalDepenses = depenses.reduce((sum, item) => sum + item.montant, 0);
              const totalFactures = factures.reduce((sum, item) => sum + item.montantTotal, 0);
              
              const sortieDetails: SortieDetails = {
                ...sortie,
                depenses,
                factures,
                totalDepenses,
                totalFactures
              };

              // ✅ LOG : Affiche l'objet complet pour chaque sortie
              console.log(`📦 Détails combinés pour la sortie "${sortie.destination}":`, sortieDetails);

              return sortieDetails;
            })
          );
        });

        return combineLatest(sortieDetailsObservables);
      }),
      tap(finalResult => {
        // ✅ LOG : Affiche le tableau final qui sera envoyé au composant
        console.log('✅✅✅ Tableau final de SortieDetails retourné:', finalResult);
      })
    );
  }

  async addSortie(sortie: Omit<Sortie, 'id'>): Promise<string> {
    const docRef = await addDoc(this.sortiesCollection, sortie);
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