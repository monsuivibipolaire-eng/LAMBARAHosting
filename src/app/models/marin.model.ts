export interface Marin {
  id?: string;
  coefficientSalaire: number;
  bateauId: string;
  nom: string;
  prenom: string;
  dateNaissance: Date;
  fonction: 'capitaine' | 'second' | 'mecanicien' | 'matelot';
  part: number; // Part du marin pour le calcul des salaires
  numeroPermis: string;
  telephone: string;
  email: string;
  adresse: string;
  dateEmbauche: Date;
  statut: 'actif' | 'conge' | 'inactif';
  createdAt?: Date;
  updatedAt?: Date;
}
