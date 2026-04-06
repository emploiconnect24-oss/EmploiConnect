/**
 * Préremplit backend/tests/recruteur.test.http avec JWT + IDs réels.
 *
 *   npm run fill:recruteur:http
 *
 * 1) Essaie l’API (POST /auth/login) si le backend tourne.
 * 2) Si connexion refusée (ECONNREFUSED) : mode secours Supabase + JWT (.env),
 *    sans serveur HTTP — vérifie le mot de passe avec bcrypt.
 *
 * Variables : TEST_API_BASE, TEST_RECRUTEUR_EMAIL, TEST_RECRUTEUR_PASSWORD, PORT
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import 'dotenv/config';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const httpPath = path.join(__dirname, '..', 'tests', 'recruteur.test.http');

const port = process.env.PORT || '3000';
const base = process.env.TEST_API_BASE || `http://localhost:${port}/api`;
const email = process.env.TEST_RECRUTEUR_EMAIL || 'entreprise@test.com';
const password = process.env.TEST_RECRUTEUR_PASSWORD || '12345678';

function networkErrorCode(err) {
  const c = err?.cause;
  if (c?.code) return c.code;
  if (Array.isArray(c?.errors) && c.errors[0]?.code) return c.errors[0].code;
  return err?.code;
}

function explainFetchFailure(err, url) {
  const code = networkErrorCode(err);
  console.error('\n[fill_recruteur_test_http] Échec réseau :', err?.message || err);
  console.error('  URL :', url);
  if (code === 'ECONNREFUSED') {
    console.error('  → Tentative mode secours : Supabase + JWT (sans npm start)…\n');
    return 'ECONNREFUSED';
  }
  if (code === 'ENOTFOUND') {
    console.error('  → Hôte introuvable (DNS). Vérifie TEST_API_BASE.\n');
    return code;
  }
  if (code === 'ETIMEDOUT' || code === 'UND_ERR_CONNECT_TIMEOUT') {
    console.error('  → Timeout.\n');
    return code;
  }
  console.error('  Code :', code || '(inconnu)', '\n');
  return code;
}

function writeHttpFile({
  baseUrl, token, offreId, candidatureId, notifId, talentUserId,
}) {
  let raw = fs.readFileSync(httpPath, 'utf8');
  raw = raw.replace(/^@base = .*$/m, `@base = ${baseUrl}`);
  raw = raw.replace(/^@emailRecruteur = .*$/m, `@emailRecruteur = ${email}`);
  raw = raw.replace(/^@passwordRecruteur = .*$/m, `@passwordRecruteur = ${password}`);
  raw = raw.replace(/^@tokenRecruteur = .*$/m, `@tokenRecruteur = ${token}`);
  raw = raw.replace(/^@offreId = .*$/m, `@offreId = ${offreId}`);
  raw = raw.replace(/^@candidatureId = .*$/m, `@candidatureId = ${candidatureId}`);
  raw = raw.replace(/^@notifId = .*$/m, `@notifId = ${notifId}`);
  raw = raw.replace(/^@destinataireId = .*$/m, `@destinataireId = ${talentUserId}`);
  raw = raw.replace(/^@talentUserId = .*$/m, `@talentUserId = ${talentUserId}`);
  fs.writeFileSync(httpPath, raw, 'utf8');
  console.log('[fill_recruteur_test_http] Fichier mis à jour:', httpPath);
  console.log(JSON.stringify({
    base: baseUrl, offreId, candidatureId, notifId, talentUserId,
  }, null, 2));
  if (candidatureId === '00000000-0000-0000-0000-000000000000') {
    console.warn(
      '[fill_recruteur_test_http] Aucune candidature trouvée pour les offres de ce recruteur — '
      + 'les requêtes GET/PATCH /recruteur/candidatures/:id échoueront tant qu’il n’y a pas de données. '
      + 'Crée une candidature (candidat) ou exécute un seed, puis relance ce script.',
    );
  }
}

async function loadIdsFromSupabase(userId) {
  const { supabase } = await import('../src/config/supabase.js');

  const { data: ent } = await supabase
    .from('entreprises')
    .select('id')
    .eq('utilisateur_id', userId)
    .maybeSingle();

  let offreId = '00000000-0000-0000-0000-000000000000';
  let candidatureId = '00000000-0000-0000-0000-000000000000';

  if (ent?.id) {
    const { data: offreRows } = await supabase
      .from('offres_emploi')
      .select('id')
      .eq('entreprise_id', ent.id)
      .order('date_creation', { ascending: false })
      .limit(1);
    if (offreRows?.[0]?.id) offreId = offreRows[0].id;

    const { data: offs } = await supabase.from('offres_emploi').select('id').eq('entreprise_id', ent.id);
    const oids = (offs || []).map((o) => o.id);
    if (oids.length) {
      const { data: candRows } = await supabase
        .from('candidatures')
        .select('id')
        .in('offre_id', oids)
        .order('date_candidature', { ascending: false })
        .limit(1);
      if (candRows?.[0]?.id) candidatureId = candRows[0].id;
    }
  }

  const { data: notifRows } = await supabase
    .from('notifications')
    .select('id')
    .eq('destinataire_id', userId)
    .order('date_creation', { ascending: false })
    .limit(1);
  const notifId = notifRows?.[0]?.id || '00000000-0000-0000-0000-000000000000';

  const { data: chercheurRows } = await supabase
    .from('chercheurs_emploi')
    .select('utilisateur_id')
    .limit(1);
  const talentUserId = chercheurRows?.[0]?.utilisateur_id || '00000000-0000-0000-0000-000000000000';

  return { offreId, candidatureId, notifId, talentUserId };
}

async function fillViaSupabaseDirect() {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    console.error('[fill_recruteur_test_http] JWT_SECRET manquant dans backend/.env (requis pour le mode sans API).');
    process.exit(1);
  }
  const expiresIn = process.env.JWT_EXPIRES_IN || '7d';
  const emailNorm = String(email).trim().toLowerCase();

  const { supabase } = await import('../src/config/supabase.js');
  const { data: user, error } = await supabase
    .from('utilisateurs')
    .select('id, email, nom, role, mot_de_passe, est_actif, est_valide')
    .eq('email', emailNorm)
    .maybeSingle();

  if (error || !user) {
    console.error('[fill_recruteur_test_http] Utilisateur introuvable:', emailNorm, error?.message);
    process.exit(1);
  }
  if (!user.est_actif) {
    console.error('[fill_recruteur_test_http] Compte désactivé.');
    process.exit(1);
  }
  if (user.role !== 'entreprise') {
    console.warn('[fill_recruteur_test_http] Attention : le compte n’est pas role=entreprise.');
  }
  const okPwd = await bcrypt.compare(password, user.mot_de_passe);
  if (!okPwd) {
    console.error('[fill_recruteur_test_http] Mot de passe incorrect.');
    process.exit(1);
  }

  const token = jwt.sign(
    { userId: user.id, email: user.email, role: user.role },
    secret,
    { expiresIn },
  );

  const ids = await loadIdsFromSupabase(user.id);
  writeHttpFile({
    baseUrl: base,
    token,
    ...ids,
  });
  console.log('[fill_recruteur_test_http] Mode : Supabase + JWT (backend HTTP non requis).');
}

async function fillViaApi() {
  const loginRes = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, mot_de_passe: password }),
  });
  const loginJson = await loginRes.json().catch(() => ({}));
  if (!loginRes.ok || !loginJson.token) {
    console.error('[fill_recruteur_test_http] Login API échoué:', loginRes.status, loginJson);
    process.exit(1);
  }
  const token = loginJson.token;
  const auth = { Authorization: `Bearer ${token}` };

  const offresRes = await fetch(`${base}/recruteur/offres?limite=1&page=1`, { headers: auth });
  const offresJson = await offresRes.json();
  const offreId = offresJson.data?.offres?.[0]?.id || '00000000-0000-0000-0000-000000000000';

  const candsRes = await fetch(`${base}/recruteur/candidatures?limite=1&page=1`, { headers: auth });
  const candsJson = await candsRes.json();
  let candidatureId = candsJson.data?.candidatures?.[0]?.id || null;

  if (!candidatureId && loginJson.user?.id) {
    const ids = await loadIdsFromSupabase(loginJson.user.id);
    candidatureId = ids.candidatureId;
  }
  if (!candidatureId) candidatureId = '00000000-0000-0000-0000-000000000000';

  const notifsRes = await fetch(`${base}/recruteur/notifications?page=1&limite=1`, { headers: auth });
  const notifsJson = await notifsRes.json();
  const notifId = notifsJson.data?.notifications?.[0]?.id || '00000000-0000-0000-0000-000000000000';

  const talentsRes = await fetch(`${base}/recruteur/talents?limite=1&page=1`, { headers: auth });
  const talentsJson = await talentsRes.json();
  const t0 = talentsJson.data?.talents?.[0];
  const talentUserId = t0?.utilisateur?.id || t0?.utilisateur_id || '00000000-0000-0000-0000-000000000000';

  writeHttpFile({
    baseUrl: base,
    token,
    offreId,
    candidatureId,
    notifId,
    talentUserId,
  });
  console.log('[fill_recruteur_test_http] Mode : API HTTP.');
}

async function main() {
  console.log('[fill_recruteur_test_http] API préférée :', base);

  try {
    await fillViaApi();
  } catch (err) {
    const code = networkErrorCode(err);
    if (code === 'ECONNREFUSED' || err?.message === 'fetch failed') {
      explainFetchFailure(err, `${base}/auth/login`);
      await fillViaSupabaseDirect();
      return;
    }
    console.error(err);
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
