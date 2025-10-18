export interface FactureVente {
  id?: string;
  sortieId: string;
  numeroFacture: string;
  client: string;
  dateVente: Date;
  montantTotal: number;
  details?: string; // Description des poissons vendus
  createdAt?: Date;
}
