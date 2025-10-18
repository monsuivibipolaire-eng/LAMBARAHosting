export interface Partage {
  id?: string;
  sortieId: string;
  beneficesTotal: number;
  partProprietaires: number;
  partEquipage: number;
  repartitionEquipage: RepartitionMarin[];
  dateCalcul: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface RepartitionMarin {
  marinId: string;
  nomMarin: string;
  prenomMarin: string;
  fonction: string;
  pourcentage: number;
  montant: number;
  avances: number;
  montantNet: number;
}
