import { Injectable } from '@angular/core';
import { Firestore, collection, getDocs, deleteDoc, doc } from '@angular/fire/firestore';
import { BateauService } from './bateau.service';
import { MarinService } from './marin.service';
import { SortieService } from './sortie.service';
import { DepenseService } from './depense.service';
import { FactureVenteService } from './facture-vente.service';
import { AvanceService } from './avance.service';
import { PaiementService } from './paiement.service';

@Injectable({
  providedIn: 'root'
})
export class MockDataService {
  
  constructor(
    private firestore: Firestore,
    private bateauService: BateauService,
    private marinService: MarinService,
    private sortieService: SortieService,
    private depenseService: DepenseService,
    private factureService: FactureVenteService,
    private avanceService: AvanceService,
    private paiementService: PaiementService
  ) {}

  async clearAllData(): Promise<void> {
    console.log('🗑️ Suppression de toutes les données...');
    const collections = ['paiements', 'avances', 'factures', 'depenses', 'sorties', 'marins', 'bateaux'];
    
    for (const collectionName of collections) {
      const collectionRef = collection(this.firestore, collectionName);
      const snapshot = await getDocs(collectionRef);
      const deletePromises = snapshot.docs.map(document => 
        deleteDoc(doc(this.firestore, collectionName, document.id))
      );
      await Promise.all(deletePromises);
      console.log(`✅ ${collectionName}: ${snapshot.size} supprimés`);
    }
  }

  async generateAllMockData(): Promise<void> {
    await this.clearAllData();
    console.log('🎲 Génération des données fictives...');

    const bateauIds = await this.generateBateaux();
    const marinsData = await this.generateMarins(bateauIds);
    const sortieIds = await this.generateSorties(bateauIds);
    await this.generateDepenses(sortieIds);
    await this.generateFactures(sortieIds);
    await this.generateAvances(marinsData);
    await this.generatePaiements(marinsData);

    console.log('✅ Données générées avec succès!');
  }

  private async generateBateaux(): Promise<string[]> {
    const bateaux = [
      {
        nom: 'Le Poséidon',
        immatriculation: 'TN-SF-001',
        puissance: 350,
        typeMoteur: 'Diesel Volvo Penta',
        longueur: 18.5,
        capaciteEquipage: 12,
        dateConstruction: new Date('2015-06-15'),
        portAttache: 'Port de Sfax',
        statut: 'actif' as const
      },
      {
        nom: 'Neptune III',
        immatriculation: 'TN-SF-002',
        puissance: 420,
        typeMoteur: 'Diesel Caterpillar',
        longueur: 22.0,
        capaciteEquipage: 15,
        dateConstruction: new Date('2018-03-20'),
        portAttache: 'Port de Sfax',
        statut: 'actif' as const
      }
    ];

    const ids: string[] = [];
    for (const bateau of bateaux) {
      const id = await this.bateauService.addBateau(bateau);
      ids.push(id);
      console.log(`✅ Bateau: ${bateau.nom} (ID: ${id})`);
    }
    return ids;
  }

  private async generateMarins(bateauIds: string[]): Promise<{ bateauId: string, marinIds: string[] }[]> {
    const marinsParBateau = [
      [ // équipage du Poséidon
        { prenom: 'Mohamed', nom: 'Ben Ali', fonction: 'capitaine' as const },
        { prenom: 'Ahmed', nom: 'Trabelsi', fonction: 'mecanicien' as const },
        { prenom: 'Karim', nom: 'Hamdi', fonction: 'matelot' as const }
      ],
      [ // équipage du Neptune III
        { prenom: 'Hichem', nom: 'Jebali', fonction: 'capitaine' as const },
        { prenom: 'Nabil', nom: 'Bouazizi', fonction: 'mecanicien' as const },
        { prenom: 'Riadh', nom: 'Mansour', fonction: 'matelot' as const }
      ]
    ];

    const result: { bateauId: string, marinIds: string[] }[] = [];

    for (let i = 0; i < bateauIds.length; i++) {
      const bateauId = bateauIds[i];
      const marins = marinsParBateau[i];
      const marinIds: string[] = [];

      for (const marin of marins) {
        const id = await this.marinService.addMarin({
          prenom: marin.prenom,
          nom: marin.nom,
          fonction: marin.fonction,
          bateauId: bateauId,
          telephone: `+216 98 ${Math.floor(Math.random() * 1000000).toString().padStart(6, '0')}`,
          email: `${marin.prenom.toLowerCase()}.${marin.nom.toLowerCase()}@example.com`,
          adresse: 'Avenue Habib Bourguiba, Sfax',
          dateNaissance: new Date(1980, 5, 15),
          dateEmbauche: new Date(2018, 0, 1),
          numeroPermis: `PM-${Math.random().toString(36).substr(2, 9).toUpperCase()}`,
          statut: 'actif' as const
        });
        marinIds.push(id);
        console.log(`✅ Marin: ${marin.prenom} ${marin.nom} (${marin.fonction}) pour bateau ${bateauId}`);
      }
      
      result.push({ bateauId, marinIds });
    }

    return result;
  }

  private async generateSorties(bateauIds: string[]): Promise<string[]> {
    const sortieIds: string[] = [];
    const destinations = ['Lampedusa', 'Kerkennah', 'Djerba', 'Gabès', 'Zarzis'];
    const now = new Date();

    for (const bateauId of bateauIds) {
      // 5 sorties par bateau
      for (let i = 0; i < 5; i++) {
        const daysAgo = (i + 1) * 7;
        const dateDepart = new Date(now.getTime() - (daysAgo * 24 * 60 * 60 * 1000));
        const dureeJours = 4;
        const dateRetour = new Date(dateDepart.getTime() + (dureeJours * 24 * 60 * 60 * 1000));
        
        let statut: 'en-cours' | 'terminee' | 'annulee';
        if (i === 0) {
          statut = 'en-cours';
        } else {
          statut = 'terminee';
        }

        const id = await this.sortieService.addSortie({
          bateauId: bateauId,
          destination: destinations[i],
          dateDepart,
          dateRetour,
          statut
        });

        sortieIds.push(id);
        console.log(`✅ Sortie: ${destinations[i]} pour bateau ${bateauId} (ID: ${id})`);
      }
    }

    return sortieIds;
  }

  private async generateDepenses(sortieIds: string[]): Promise<void> {
    // Types valides selon le modèle Depense
    const types: Array<'fuel' | 'ice' | 'food' | 'oil_change' | 'crew_cnss' | 'crew_bonus' | 'vms' | 'misc'> = [
      'fuel',
      'ice', 
      'food',
      'oil_change',
      'crew_cnss'
    ];
    
    for (const sortieId of sortieIds) {
      // 2 dépenses par sortie
      for (let i = 0; i < 2; i++) {
        const type = types[Math.floor(Math.random() * types.length)];
        const montant = 100 + Math.random() * 400;
        const daysAgo = Math.floor(Math.random() * 10);
        const date = new Date(Date.now() - (daysAgo * 24 * 60 * 60 * 1000));

        await this.depenseService.addDepense({
          sortieId: sortieId,
          type,
          montant: Math.round(montant * 100) / 100,
          date,
          description: `Dépense de ${type.replace('_', ' ')}`
        });
      }
    }
    console.log('✅ Dépenses créées');
  }

  private async generateFactures(sortieIds: string[]): Promise<void> {
    for (const sortieId of sortieIds) {
      const montant = 2000 + Math.random() * 3000;
      const daysAgo = Math.floor(Math.random() * 10);
      const date = new Date(Date.now() - (daysAgo * 24 * 60 * 60 * 1000));

      await this.factureService.addFacture({
        sortieId: sortieId,
        numeroFacture: `F-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`,
        client: 'Marché Central',
        dateVente: date,
        montantTotal: Math.round(montant * 100) / 100,
        details: 'Vente de poissons'
      });
    }
    console.log('✅ Factures créées');
  }

  private async generateAvances(marinsData: { bateauId: string, marinIds: string[] }[]): Promise<void> {
    for (const { bateauId, marinIds } of marinsData) {
      for (const marinId of marinIds) {
        // 2 avances par marin
        for (let i = 0; i < 2; i++) {
          const montant = 200 + i * 100;
          const daysAgo = (i + 1) * 15;
          const date = new Date(Date.now() - (daysAgo * 24 * 60 * 1000));

          await this.avanceService.addAvance({
            bateauId: bateauId,
            marinId: marinId,
            montant,
            dateAvance: date,
            description: `Avance ${i + 1}`
          });
        }
      }
    }
    console.log('✅ Avances créées');
  }

  private async generatePaiements(marinsData: { bateauId: string, marinIds: string[] }[]): Promise<void> {
    for (const { marinIds } of marinsData) {
      for (const marinId of marinIds) {
        // 1 paiement par marin
        const montant = 500;
        const date = new Date(Date.now() - (30 * 24 * 60 * 60 * 1000));

        await this.paiementService.addPaiement({
          marinId,
          montant,
          datePaiement: date,
          sortiesIds: []
        });
      }
    }
    console.log('✅ Paiements créés');
  }
}
