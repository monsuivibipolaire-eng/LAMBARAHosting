# Mock Data pour SalairesListComponent

## Prérequis
- Installez Firebase Admin: `npm install firebase-admin`
- Créez un serviceAccountKey.json (téléchargez depuis Firebase Console > Project Settings > Service Accounts)
- Placez-le dans le dossier racine ou adaptez le chemin dans seed-salaires-mock-data.js

## Exécution
1. cd scripts
2. node seed-salaires-mock-data.js

## Ce que ça fait (adapté aux modifs récentes)
- **Bateau**: 1 bateau test (ID: 'bateau-mock-1') pour SelectedBoatService
- **Marins**: 3 marins actifs assignés au bateau (pour stats et calculs)
- **Sorties de mer**: 5 sorties (collection 'sorties-mer')
  - Tri auto par dateFin desc (récentes en haut)
  - 2 en_cours (ouvertes, pas calculables)
  - 2 terminee + salaireCalcule: true (déjà calculées)
  - 1 terminee + salaireCalcule: false (déclenche auto-calcul dans triggerAutoCalcul())
- **Calculs historiques**: 2 entrées dans 'salaires' (pour SalaireService.getCalculsByBateau())
  - Tri par dateCalcul desc dans loadData()
  - Champs: dateCalcul, nombreSorties, total, marins (array noms)
- **Auto-calcul**: Au chargement, triggerAutoCalcul() sélectionne la sortie non calculée et appelle calculerSalairesPourSelection()
  - Adaptez calculerSalairesPourSelection() pour marquer salaireCalcule: true et ajouter à historique

## Nettoyage (optionnel)
Exécutez ce script pour vider:
