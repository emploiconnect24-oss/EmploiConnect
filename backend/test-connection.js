/**
 * Script de test de connexion à Supabase
 * Vérifie que le .env et la base sont correctement configurés
 */
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

console.log('=== Test de connexion Supabase (EmploiConnect) ===\n');

// 1. Vérification des variables d'environnement
console.log('1. Vérification du fichier .env...');
if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ ERREUR: Variables manquantes dans .env');
  console.error('   Requises: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}
console.log('   ✓ SUPABASE_URL:', SUPABASE_URL);
console.log('   ✓ SUPABASE_ANON_KEY: présent (', SUPABASE_ANON_KEY?.slice(0, 20) + '...)');
console.log('   ✓ SUPABASE_SERVICE_ROLE_KEY: présent\n');

// 2. Connexion avec la clé service_role (accès backend)
console.log('2. Connexion au projet Supabase...');
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// 3. Test: requête sur une table du schéma (utilisateurs)
console.log('3. Test de requête sur la table "utilisateurs"...');
const { data, error } = await supabase
  .from('utilisateurs')
  .select('id, email, role')
  .limit(1);

if (error) {
  console.error('❌ ERREUR de connexion / requête:');
  console.error('   Code:', error.code);
  console.error('   Message:', error.message);
  if (error.code === '42P01') {
    console.error('\n   → La table "utilisateurs" n\'existe pas. Exécutez le schéma SQL dans Supabase (database/supabase_schema.sql)');
  }
  process.exit(1);
}

console.log('   ✓ Connexion réussie !');
console.log('   ✓ Table "utilisateurs" accessible.');
console.log('   Nombre d\'enregistrements (échantillon):', data?.length ?? 0);
if (data?.length > 0) {
  console.log('   Exemple:', data[0]);
}

console.log('\n=== ✅ Tout est bon : la base de données est connectée correctement. ===');
