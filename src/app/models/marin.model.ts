export interface Marin {
  id?: string;
  bateauId: string;
  nom: string;
  prenom: string;
  dateNaissance: Date;
  fonction: 'capitaine' | 'second' | 'mecanicien' | 'matelot';
  numeroPermis: string;
  telephone: string;
  email: string;
  adresse: string;
  dateEmbauche: Date;
  statut: 'actif' | 'conge' | 'inactif';
  createdAt?: Date;
  updatedAt?: Date;
}
