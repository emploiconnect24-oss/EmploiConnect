/**
 * Seed d'offres recruteur via API (flux réel).
 *
 * Usage:
 *   node scripts/seed_recruteur_offres.js
 *
 * Variables d'env requises:
 *   API_BASE_URL=http://localhost:3000/api
 *   RECRUTEUR_EMAIL=entreprise@test.com
 *   RECRUTEUR_PASSWORD=motdepasse
 *
 * Optionnelles:
 *   SEED_OFFRES_COUNT=5
 *   SEED_PREFIX=Assistant Comptable
 */

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api';
const RECRUTEUR_EMAIL = process.env.RECRUTEUR_EMAIL || '';
const RECRUTEUR_PASSWORD = process.env.RECRUTEUR_PASSWORD || '';
const SEED_OFFRES_COUNT = Number.parseInt(process.env.SEED_OFFRES_COUNT || '5', 10);
const SEED_PREFIX = process.env.SEED_PREFIX || 'Assistant Comptable';

function fail(message) {
  console.error(`\n[seed/offres] ${message}`);
  process.exit(1);
}

async function login() {
  const res = await fetch(`${API_BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: RECRUTEUR_EMAIL,
      mot_de_passe: RECRUTEUR_PASSWORD,
    }),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || !body?.token) {
    throw new Error(body?.message || `Login KO (${res.status})`);
  }
  return body.token;
}

function buildOffrePayload(index) {
  const i = index + 1;
  return {
    titre: `${SEED_PREFIX} #${Date.now()}-${i}`,
    description:
      'Intitule du poste : Assistant Comptable. Missions : saisie comptable, rapprochements bancaires, suivi factures, support reporting.',
    exigences:
      'Niveau: Licence. Experience: 1-2 ans. Competences: comptabilite generale, Excel, rigueur, organisation.',
    competences_requises: ['Comptabilite', 'Excel', 'Reporting'],
    localisation: 'Conakry',
    type_contrat: i % 2 === 0 ? 'cdi' : 'cdd',
    niveau_experience_requis: '1-2 ans',
    domaine: 'Finance',
    salaire_min: 3000000,
    salaire_max: 5000000,
    devise: 'GNF',
    nombre_postes: 1,
    // volontairement true pour alimenter "en_attente" admin
    publier_maintenant: true,
  };
}

async function createOffre(token, payload) {
  const res = await fetch(`${API_BASE_URL}/recruteur/offres`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(body?.message || `Creation KO (${res.status})`);
  }
  return body?.data || {};
}

async function main() {
  if (!RECRUTEUR_EMAIL || !RECRUTEUR_PASSWORD) {
    fail('RECRUTEUR_EMAIL / RECRUTEUR_PASSWORD manquants.');
  }
  if (!Number.isFinite(SEED_OFFRES_COUNT) || SEED_OFFRES_COUNT <= 0) {
    fail('SEED_OFFRES_COUNT doit etre un entier > 0.');
  }

  console.log(`[seed/offres] API: ${API_BASE_URL}`);
  console.log(`[seed/offres] Login recruteur: ${RECRUTEUR_EMAIL}`);
  console.log(`[seed/offres] Nombre d'offres a creer: ${SEED_OFFRES_COUNT}`);

  const token = await login();
  console.log('[seed/offres] Login OK');

  const created = [];
  for (let i = 0; i < SEED_OFFRES_COUNT; i += 1) {
    const payload = buildOffrePayload(i);
    const offre = await createOffre(token, payload);
    created.push(offre);
    console.log(
      `[seed/offres] ${i + 1}/${SEED_OFFRES_COUNT} creee: ${offre?.titre || payload.titre} | statut=${offre?.statut || 'n/a'}`,
    );
  }

  console.log('\n[seed/offres] Termine.');
  console.log(`[seed/offres] Offres creees: ${created.length}`);
  console.log('[seed/offres] Attendu cote admin: compteur "offres en attente" augmente + notifications.');
}

main().catch((err) => fail(err?.message || String(err)));
