export interface Avance {
  sortieId?: string;
  id?: string;
  marinId: string;
  bateauId: string;
  montant: number;
  dateAvance: Date;
  description?: string;
  createdAt?: Date;
  calculSalaireId?: string; // Champ pour lier l'avance à un calcul de salaire
}
