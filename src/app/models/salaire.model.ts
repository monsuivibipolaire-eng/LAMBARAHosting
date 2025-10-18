export interface CoeffSalaire {
  marinId: string;
  coefficient: number; // Pourcentage du partage équipage (ex: 20 pour 20%)
}

export interface CalculSalaire {
  sortieId: string;
  dateCalcul: Date;
  
  // Revenus
  revenuTotal: number;
  
  // Dépenses
  totalDepenses: number;
  
  // Part propriétaire et équipage
  partProprietaire: number; // 50%
  partEquipage: number; // 50%
  
  // Déduction nuits (5 DT par nuit par marin)
  nbNuits: number;
  nbMarins: number;
  deductionNuits: number;
  
  // Montant à partager entre équipage
  montantAPartager: number;
  
  // Détails par marin
  detailsMarins: DetailSalaireMarin[];
}

export interface DetailSalaireMarin {
  marinId: string;
  marinNom: string;
  coefficient: number;
  salaireBase: number; // Part selon coefficient
  primenuits: number; // 5 DT × nombre de nuits
  avances: number;
  salaireNet: number; // salaireBase + primeNuits - avances
}
