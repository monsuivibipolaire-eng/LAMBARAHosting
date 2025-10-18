export interface Avance {
  id?: string;
  marinId: string;
  bateauId: string;
  montant: number;
  dateAvance: Date;
  description?: string;
  createdAt?: Date;
}
