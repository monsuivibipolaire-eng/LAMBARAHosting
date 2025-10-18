export interface Depense {
  id?: string;
  sortieId: string;
  type: 'fuel' | 'ice' | 'oil_change' | 'crew_cnss' | 'crew_bonus' | 'food' | 'vms' | 'misc';
  montant: number;
  date: Date;
  description?: string;
  createdAt?: Date;
  updatedAt?: Date;
}
