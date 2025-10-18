export interface Sortie {
  id?: string;
  bateauId: string;
  dateDepart: Date;
  dateRetour: Date;
  destination: string;
  statut: 'en-cours' | 'terminee' | 'annulee';
  observations?: string;
  createdAt?: Date;
  updatedAt?: Date;
}
