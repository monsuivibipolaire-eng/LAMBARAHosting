export interface Sortie {
  id?: string;
  bateauId: string;
  dateDepart: Date;
  dateRetour?: Date;
  destination: string;
  statut: 'en_cours' | 'terminee' | 'annulee';
  salaireCalcule?: boolean;
  notes?: string;
  createdAt?: Date;
  updatedAt?: Date;
}
