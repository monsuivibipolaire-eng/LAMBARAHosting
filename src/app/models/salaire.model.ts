import { FactureVente } from './facture-vente.model';
import { Depense } from './depense.model';

export interface CalculSalaire {
  id?: string;
  bateauId: string;
  sortiesIds: string[];
  sortiesDestinations: string[];
  dateCalcul: Date;
  
  revenuTotal: number;
  totalDepenses: number;
  beneficeNet: number;
  partProprietaire: number;
  partEquipage: number;
  deductionNuits: number;
  montantAPartager: number;
  
  detailsMarins: DetailSalaireMarin[];
  
  factures?: FactureVente[];
  depenses?: Depense[];
}

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
