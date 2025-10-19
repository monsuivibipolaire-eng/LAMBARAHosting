const admin = require('firebase-admin');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialiser Firebase Admin (remplacez par vos credentials)
const serviceAccount = require('../path/to/your/serviceAccountKey.json');  // Adapter chemin
initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = getFirestore();

// Mock data adaptés aux modifications:
// - 1 bateau de test
// - 3 marins
// - 5 sorties de mer (tri dateFin desc: récentes en premier)
//   - 2 ouvertes (statut non 'terminee')
//   - 2 terminées calculées (salaireCalcule: true)
//   - 1 terminée non calculée (pour tester auto-calcul)
// - 2 calculs historiques (dateCalcul, total, etc.) pour SalaireService

async function seedMockData() {
  const bateauId = 'bateau-mock-1';
  const now = new Date();
  const dates = [
    new Date(now.getFullYear(), now.getMonth(), now.getDate() - 5),  // Plus ancien
    new Date(now.getFullYear(), now.getMonth(), now.getDate() - 3),
    new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1),
    new Date(now.getFullYear(), now.getMonth(), now.getDate()),
    new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1)   // Plus récent
  ];

  // 1. Bateau de test
  await db.collection('bateaux').doc(bateauId).set({
    nom: 'Bateau Test Auto-Calcul',
    immatriculation: 'MOCK-123',
    createdAt: now.toISOString()
  });
  console.log('✅ Bateau mock créé:', bateauId);

  // 2. Marins (assignés au bateau)
  const marinsData = [
    { nom: 'Ahmed', prenom: 'Ali', dateNaissance: new Date(1990, 0, 1), dateEmbauche: new Date(2020, 0, 1), fonction: 'Capitaine', coefficientSalaire: 1.5, bateauId, statut: 'actif' },
    { nom: 'Fatma', prenom: 'Belaid', dateNaissance: new Date(1995, 5, 15), dateEmbauche: new Date(2022, 3, 10), fonction: 'Matelot', coefficientSalaire: 1.0, bateauId, statut: 'actif' },
    { nom: 'Karim', prenom: 'Ben', dateNaissance: new Date(1985, 11, 20), dateEmbauche: new Date(2018, 7, 5), fonction: 'Mécanicien', coefficientSalaire: 1.2, bateauId, statut: 'actif' }
  ];
  for (const marin of marinsData) {
    await db.collection('marins').add(marin);
  }
  console.log('✅ 3 marins mock créés pour bateau', bateauId);

  // 3. Sorties de mer (5 totales, triées dateFin desc dans loadData)
  const sortiesData = [
    // Sortie 1: Récente, terminée et calculée (affichée en premier après tri)
    { bateauId, dateDebut: dates[4], dateFin: dates[4], statut: 'terminee', salaireCalcule: true, createdAt: dates[4].toISOString() },
    // Sortie 2: Récente, ouverte (non terminée, pas calculée)
    { bateauId, dateDebut: dates[3], dateFin: dates[3], statut: 'en_cours', salaireCalcule: false, createdAt: dates[3].toISOString() },
    // Sortie 3: Moyenne, terminée non calculée (déclenche auto-calcul)
    { bateauId, dateDebut: dates[2], dateFin: dates[2], statut: 'terminee', salaireCalcule: false, createdAt: dates[2].toISOString() },
    // Sortie 4: Ancienne, terminée calculée
    { bateauId, dateDebut: dates[1], dateFin: dates[1], statut: 'terminee', salaireCalcule: true, createdAt: dates[1].toISOString() },
    // Sortie 5: Plus ancienne, ouverte
    { bateauId, dateDebut: dates[0], dateFin: dates[0], statut: 'en_cours', salaireCalcule: false, createdAt: dates[0].toISOString() }
  ];
  const sortieRefs = [];
  for (const sortie of sortiesData) {
    const ref = await db.collection('sorties-mer').add(sortie);
    sortieRefs.push(ref.id);
  }
  console.log('✅ 5 sorties mock créées (2 ouvertes, 2 calculées, 1 pour auto-calcul)');

  // 4. Historique des calculs (2 entrées dans 'salaires' ou 'calculs-salaires')
  const calculsData = [
    // Calcul récent (correspond à une sortie calculée)
    { bateauId, dateCalcul: dates[4], nombreSorties: 1, total: 1500, marins: marinsData.map(m => m.nom + ' ' + m.prenom), createdAt: dates[4].toISOString() },
    // Calcul ancien
    { bateauId, dateCalcul: dates[1], nombreSorties: 2, total: 2800, marins: marinsData.slice(0, 2).map(m => m.nom + ' ' + m.prenom), createdAt: dates[1].toISOString() }
  ];
  for (const calcul of calculsData) {
    await db.collection('salaires').add(calcul);  // Adapter à votre collection (salaires ou calculs-salaires)
  }
  console.log('✅ 2 calculs historiques mock créés (triés par dateCalcul desc)');

  console.log('🎉 Mock data seedé! Testez SalairesListComponent:');
  console.log('   - Stats: 5 totales, 2 calculées, 1 ouverte (pour auto), 3 marins');
  console.log('   - Liste sorties: 5 items triés récent → ancien');
  console.log('   - Historique: 2 calculs (récent en premier)');
  console.log('   - Auto-calcul: déclenche pour la sortie non calculée (ID parmi sortieRefs)');
}

seedMockData().catch(console.error).then(() => process.exit(0));
