import { Injectable } from '@angular/core';
import { 
  Firestore, 
  collection, 
  getDocs, 
  deleteDoc,
  doc,
  addDoc
} from '@angular/fire/firestore';
import { BateauService } from './bateau.service';
import { MarinService } from './marin.service';
import { SortieService } from './sortie.service';
import { DepenseService } from './depense.service';
import { Bateau } from '../models/bateau.model';
import { Marin } from '../models/marin.model';
import { Sortie } from '../models/sortie.model';
import { FactureVente } from '../models/facture-vente.model';
import { Depense } from '../models/depense.model';

@Injectable({
  providedIn: 'root'
})
export class MockDataService {

  private typesPoissons = [
    { nom: 'Daurade royale', prixMin: 28, prixMax: 38 },
    { nom: 'Loup de mer', prixMin: 32, prixMax: 48 },
    { nom: 'Rouget barbet', prixMin: 22, prixMax: 32 },
    { nom: 'Sardine fraîche', prixMin: 6, prixMax: 12 },
    { nom: 'Thon rouge', prixMin: 55, prixMax: 85 },
    { nom: 'Mérou brun', prixMin: 38, prixMax: 55 },
    { nom: 'Saint-Pierre', prixMin: 30, prixMax: 45 },
    { nom: 'Sole commune', prixMin: 35, prixMax: 52 },
    { nom: 'Calamar', prixMin: 20, prixMax: 30 },
    { nom: 'Poulpe', prixMin: 18, prixMax: 28 },
    { nom: 'Crevettes roses', prixMin: 45, prixMax: 65 },
    { nom: 'Langoustines', prixMin: 60, prixMax: 80 },
    { nom: 'Pageot', prixMin: 25, prixMax: 35 },
    { nom: 'Sar commun', prixMin: 20, prixMax: 30 },
    { nom: 'Rascasse', prixMin: 28, prixMax: 40 },
    { nom: 'Mulet', prixMin: 15, prixMax: 25 }
  ];

  private nomsClients = [
    'Restaurant La Goulette - Tunis',
    'Poissonnerie Ben Ahmed - Sfax',
    'Restaurant Le Pirate - La Marsa',
    'Marché Central - Sfax',
    'Restaurant Dar El Jeld - Médina',
    'Grossiste Fruits de Mer - Monastir',
    'Poissonnerie du Port - Sousse',
    'Restaurant La Médina - Hammamet',
    'Hotel Hasdrubal Thalassa & Spa',
    'Carrefour Lac 2 - Tunis',
    'Restaurant Le Corail - Mahdia',
    'Poissonnerie Zitouna - Sfax',
    'Hôtel Concorde Les Berges du Lac',
    'Restaurant Chez Slah - Kerkennah',
    'Marché de Poissons - Mahdia',
    'Monoprix Sousse Centre',
    'Restaurant Fish Market - Gammarth',
    'Hôtel Mövenpick Sousse',
    'Grossiste Al Baraka - Gabès',
    'Poissonnerie El Amel - Sfax'
  ];

  constructor(
    private firestore: Firestore,
    private bateauService: BateauService,
    private marinService: MarinService,
    private sortieService: SortieService,
    private depenseService: DepenseService
  ) {}

  async generateAllMockData(): Promise<void> {
    try {
      console.log('🧹 Suppression des anciennes données...');
      await this.clearAllData();

      console.log('🚢 Génération des bateaux...');
      const bateauxIds = await this.generateBateaux();
      console.log(`✅ ${bateauxIds.length} bateaux créés`);
      
      for (const bateauId of bateauxIds) {
        console.log(`\n👥 Génération des marins pour le bateau ${bateauId}...`);
        await this.generateMarins(bateauId);
        
        console.log(`⛵ Génération des sorties pour le bateau ${bateauId}...`);
        const sortiesIds = await this.generateSorties(bateauId);
        console.log(`✅ ${sortiesIds.length} sorties créées`);
        
        for (let i = 0; i < sortiesIds.length; i++) {
          const sortieId = sortiesIds[i];
          console.log(`\n📄 Sortie ${i + 1}/${sortiesIds.length} (ID: ${sortieId})`);
          
          const nbFactures = await this.generateFacturesDetaillees(sortieId);
          console.log(`  ✅ ${nbFactures} factures créées`);
          
          await this.generateDepenses(sortieId);
          console.log(`  ✅ 6 dépenses créées`);
        }
      }
      
      console.log('\n🎉 ✅ Génération terminée!');
    } catch (error) {
      console.error('❌ Erreur:', error);
      throw error;
    }
  }

  private async clearAllData(): Promise<void> {
    const collections = ['bateaux', 'marins', 'sorties', 'factures-vente', 'depenses', 'calculs-salaire'];
    
    for (const collectionName of collections) {
      const querySnapshot = await getDocs(collection(this.firestore, collectionName));
      const deletePromises = querySnapshot.docs.map(document => 
        deleteDoc(doc(this.firestore, collectionName, document.id))
      );
      await Promise.all(deletePromises);
      console.log(`  ✓ ${collectionName}: ${querySnapshot.size} supprimés`);
    }
  }

  private async generateBateaux(): Promise<string[]> {
    const bateaux: Omit<Bateau, 'id'>[] = [
      {
        nom: 'El Amel',
        immatriculation: 'SF-2024-001',
        typeMoteur: 'Diesel Volvo Penta',
        puissance: 350,
        longueur: 18,
        capaciteEquipage: 6,
        dateConstruction: new Date('2018-03-15'),
        portAttache: 'Port de Sfax',
        statut: 'actif',
        createdAt: new Date()
      },
      {
        nom: 'La Perle Bleue',
        immatriculation: 'SF-2023-045',
        typeMoteur: 'Diesel Caterpillar',
        puissance: 420,
        longueur: 22,
        capaciteEquipage: 8,
        dateConstruction: new Date('2020-06-20'),
        portAttache: 'Port de Sfax',
        statut: 'actif',
        createdAt: new Date()
      }
    ];

    const ids: string[] = [];
    for (const bateau of bateaux) {
      const bateauId = await this.bateauService.addBateau(bateau);
      ids.push(bateauId);
    }
    return ids;
  }

  private async generateMarins(bateauId: string): Promise<string[]> {
    const prenoms = ['Ahmed', 'Mohamed', 'Ali', 'Karim', 'Mehdi', 'Youssef'];
    const noms = ['Ben Salem', 'Trabelsi', 'Gharbi', 'Hammami', 'Jomaa', 'Ksouri'];
    const fonctions: Array<'capitaine' | 'second' | 'mecanicien' | 'matelot'> = 
      ['capitaine', 'second', 'mecanicien', 'matelot', 'matelot', 'matelot'];

    const ids: string[] = [];
    for (let i = 0; i < 6; i++) {
      const marin: Omit<Marin, 'id'> = {
        bateauId,
        nom: noms[i],
        prenom: prenoms[i],
        dateNaissance: new Date(1985 + Math.floor(Math.random() * 15), Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1),
        fonction: fonctions[i],
        part: fonctions[i] === 'capitaine' ? 2 : fonctions[i] === 'second' ? 1.5 : fonctions[i] === 'mecanicien' ? 1.3 : 1,
        numeroPermis: `PM-${10000 + i}`,
        telephone: `+216 ${20 + i} ${Math.floor(Math.random() * 900000 + 100000)}`,
        email: `${prenoms[i].toLowerCase()}.${noms[i].toLowerCase().replace(' ', '')}@email.com`,
        adresse: `${Math.floor(Math.random() * 100) + 1} Avenue Habib Bourguiba, Sfax`,
        dateEmbauche: new Date(2020 + Math.floor(Math.random() * 4), Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1),
        statut: 'actif',
        createdAt: new Date()
      };
      const marinId = await this.marinService.addMarin(marin);
      ids.push(marinId);
    }
    return ids;
  }

  private async generateSorties(bateauId: string): Promise<string[]> {
    const destinations = [
      'Banc de Kerkennah (Zone Nord-Est)',
      'Golfe de Gabès (Zone Sud)',
      'Îles Kerkennah (Zone côtière)'
    ];

    const ids: string[] = [];
    const today = new Date();
    
    for (let i = 0; i < 3; i++) {
      const joursAvant = 15 + (i * 15);
      const dateDepart = new Date(today);
      dateDepart.setDate(dateDepart.getDate() - joursAvant - 3);
      
      const dateRetour = new Date(dateDepart);
      dateRetour.setDate(dateRetour.getDate() + (2 + i));

      const sortie: Omit<Sortie, 'id'> = {
        bateauId,
        dateDepart,
        dateRetour,
        destination: destinations[i],
        statut: 'terminee',
        salaireCalcule: false,
        observations: `Sortie ${i + 1} - Excellentes conditions météo`,
        createdAt: new Date()
      };
      const sortieId = await this.sortieService.addSortie(sortie);
      ids.push(sortieId);
    }
    return ids;
  }

  private async generateFacturesDetaillees(sortieId: string): Promise<number> {
    const nombreFactures = Math.floor(Math.random() * 4) + 5;
    console.log(`  📝 Génération de ${nombreFactures} factures...`);
    
    for (let i = 0; i < nombreFactures; i++) {
      const nombreTypesPoissons = Math.floor(Math.random() * 4) + 3;
      const poissonsSelectionnes = this.shuffleArray([...this.typesPoissons])
        .slice(0, nombreTypesPoissons);
      
      let montantTotalFacture = 0;
      let detailsTexte = '';
      
      for (const poisson of poissonsSelectionnes) {
        const quantite = Math.floor(Math.random() * 120) + 30;
        const prixUnitaire = Math.floor(
          (Math.random() * (poisson.prixMax - poisson.prixMin) + poisson.prixMin) * 100
        ) / 100;
        const montantTotal = Math.round(quantite * prixUnitaire * 100) / 100;
        
        detailsTexte += `${poisson.nom}: ${quantite} kg × ${prixUnitaire} DT = ${montantTotal} DT\n`;
        montantTotalFacture += montantTotal;
      }

      montantTotalFacture = Math.round(montantTotalFacture * 100) / 100;

      const numeroFacture = `FA-${new Date().getFullYear()}-${String(Math.floor(Math.random() * 9000) + 1000).padStart(4, '0')}`;
      const client = this.nomsClients[Math.floor(Math.random() * this.nomsClients.length)];
      
      const facture: Omit<FactureVente, 'id'> = {
        sortieId,
        numeroFacture,
        client,
        dateVente: new Date(),
        montantTotal: montantTotalFacture,
        details: detailsTexte.trim(),
        createdAt: new Date()
      };
      
      try {
        await addDoc(collection(this.firestore, 'factures-vente'), facture);
        console.log(`    ✓ ${numeroFacture} - ${client} - ${montantTotalFacture} DT`);
      } catch (error) {
        console.error(`    ✗ Erreur facture ${i + 1}:`, error);
      }
    }
    
    return nombreFactures;
  }

  private async generateDepenses(sortieId: string): Promise<void> {
    const depensesData: Array<{
      type: 'fuel' | 'ice' | 'oil_change' | 'crew_cnss' | 'crew_bonus' | 'food' | 'vms' | 'misc';
      montantMin: number;
      montantMax: number;
      description: string;
    }> = [
      { type: 'fuel', montantMin: 1200, montantMax: 2500, description: 'Carburant diesel' },
      { type: 'ice', montantMin: 200, montantMax: 450, description: 'Glace' },
      { type: 'food', montantMin: 350, montantMax: 600, description: 'Provisions' },
      { type: 'crew_cnss', montantMin: 500, montantMax: 800, description: 'CNSS équipage' },
      { type: 'vms', montantMin: 50, montantMax: 100, description: 'VMS' },
      { type: 'oil_change', montantMin: 300, montantMax: 500, description: 'Entretien moteur' }
    ];
    
    for (const depenseData of depensesData) {
      const montant = Math.floor(
        Math.random() * (depenseData.montantMax - depenseData.montantMin) + depenseData.montantMin
      );

      const depense: Omit<Depense, 'id'> = {
        sortieId,
        type: depenseData.type,
        montant,
        date: new Date(),
        description: depenseData.description,
        createdAt: new Date()
      };
      
      await this.depenseService.addDepense(depense);
    }
  }

  private shuffleArray<T>(array: T[]): T[] {
    const newArray = [...array];
    for (let i = newArray.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
    }
    return newArray;
  }
}
