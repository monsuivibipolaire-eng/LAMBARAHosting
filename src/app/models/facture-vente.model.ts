export interface FactureVente {
  id?: string;
  sortieId?: string;
  montant: number;
  
  numeroFacture: string;
  client: string;
  dateVente: Date;
  details?: string; // Description des poissons vendus
  createdAt?: Date;
}
