export interface Sortie {
  id?: string;
  bateauId: string;
  dateDepart: Date;
  dateRetour: Date;
  destination: string;
  statut: 'en-cours' | 'terminee' | 'annulee';
  salaireCalcule?: boolean; // ✅ Propriété ajoutée pour le suivi des calculs
  observations?: string;
  createdAt?: Date;
  updatedAt?: Date;
}
