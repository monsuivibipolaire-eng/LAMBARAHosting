export interface Paiement {
  id?: string;
  marinId: string;
  montant: number;
  datePaiement: Date;
  sortiesIds: string[]; // Liste des sorties concernées
  description?: string;
  createdAt?: Date;
}
