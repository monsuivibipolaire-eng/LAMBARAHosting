export interface Facture {
  id?: string;
  sortieId: string;
  numeroFacture: string;
  dateFacture: Date;
  client: string;
  montantTotal: number;
  detailsPoissons: DetailPoisson[];
  paye: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface DetailPoisson {
  typePoisson: string;
  quantite: number;
  prixUnitaire: number;
  montantTotal: number;
}
