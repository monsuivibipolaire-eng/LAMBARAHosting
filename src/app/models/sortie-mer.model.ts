export interface SortieMer {
  totalVentes?: number;  // montant total des ventes pour affichage
  id?: string;
  bateauId: string;
  dateDebut: Date;
  dateFin: Date;
  statut: string;
  salaireCalcule?: boolean;
  createdAt?: Date;
  updatedAt?: Date;
  // Autres propriétés selon vos besoins
}
