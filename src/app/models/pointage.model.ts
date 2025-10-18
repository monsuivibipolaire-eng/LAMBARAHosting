export interface Pointage {
  id?: string;
  sortieId: string;
  marinId: string;
  present: boolean;
  datePointage: Date;
  observations?: string;
  createdAt?: Date;
  updatedAt?: Date;
}
