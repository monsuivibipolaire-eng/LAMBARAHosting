import { Depense } from "./depense.model";
import { FactureVente } from "./facture-vente.model";

// Modèle pour sauvegarder un calcul complet
export interface CalculSalaire {
  id?: string;
  bateauId: string;
  sortiesIds: string[];
  sortiesDestinations: string[]; // Pour un affichage facile
  dateCalcul: Date;
  
  // Résumé financier
  revenuTotal: number;
  totalDepenses: number;
  beneficeNet: number;
  partProprietaire: number;
  partEquipage: number;
  deductionNuits: number;
  montantAPartager: number;
  
  // Détails par marin
  detailsMarins: DetailSalaireMarin[];

  // ✅ Transactions utilisées pour le calcul
  factures?: FactureVente[];
  depenses?: Depense[];
}

// Modèle pour les détails de chaque marin au sein d'un calcul
export interface DetailSalaireMarin {
  marinId: string;
  marinNom: string;
  part: number;
  salaireBrut: number;
  primeNuits: number;
  totalAvances: number;
  totalPaiements: number;
  resteAPayer: number;
}
