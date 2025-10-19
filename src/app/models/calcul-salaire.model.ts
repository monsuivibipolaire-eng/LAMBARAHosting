export interface CalculSalaire {
  nombreSorties?: number;  id?: string;
  bateauId: string;
  dateCalcul: Date;
  marins: any[];
  totalRevenu: number;
  totalDepenses: number;
  salaires: any[];
  createdAt?: Date;
  // Autres propriétés
}
