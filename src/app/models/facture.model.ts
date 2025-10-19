export interface Facture {
  id?: string;
  sortieId: string;
  numeroFacture: string;
  dateFacture: Date;
  client: string;
  montant: number;
  detailsPoissons: DetailPoisson[];
  paye: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface DetailPoisson {
  typePoisson: string;
  quantite: number;
  prixUnitaire: number;
  montant: number;
}
