export interface Bateau {
  id?: string;
  nom: string;
  immatriculation: string;
  typeMoteur: string;
  puissance: number;
  longueur: number;
  capaciteEquipage: number;
  dateConstruction: Date;
  portAttache: string;
  statut: 'actif' | 'maintenance' | 'inactif';
  createdAt?: Date;
  updatedAt?: Date;
}
