/**
 * Vérification des ID tokens Google (OAuth) — config lue depuis parametres_plateforme ou .env
 */
import { OAuth2Client } from 'google-auth-library';

function _mapRoleDefaut(raw) {
  const s = String(raw || '').trim().toLowerCase();
  if (s === 'entreprise' || s === 'recruteur') return 'entreprise';
  return 'chercheur';
}

export async function getGoogleAuthConfig(supabase) {
  try {
    const { data: rows } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'google_client_id',
        'google_client_secret',
        'google_oauth_actif',
        'google_roles_defaut',
      ]);

    const c = {};
    (rows || []).forEach((r) => {
      c[r.cle] = r.valeur;
    });

    return {
      clientId: String(c.google_client_id || process.env.GOOGLE_CLIENT_ID || '').trim(),
      clientSecret: String(c.google_client_secret || process.env.GOOGLE_CLIENT_SECRET || '').trim(),
      actif: c.google_oauth_actif !== 'false',
      roleDefaut: _mapRoleDefaut(c.google_roles_defaut),
    };
  } catch (e) {
    console.error('[googleAuth] Config error:', e.message);
    return {
      clientId: String(process.env.GOOGLE_CLIENT_ID || '').trim(),
      clientSecret: String(process.env.GOOGLE_CLIENT_SECRET || '').trim(),
      actif: true,
      roleDefaut: 'chercheur',
    };
  }
}

/**
 * @param {string} idToken
 * @param {import('@supabase/supabase-js').SupabaseClient} supabase
 */
export async function verifierTokenGoogle(idToken, supabase) {
  const config = await getGoogleAuthConfig(supabase);

  if (!config.actif) {
    throw new Error('La connexion Google est désactivée');
  }

  if (!config.clientId) {
    throw new Error('Google Client ID non configuré dans les paramètres admin');
  }

  const client = new OAuth2Client(config.clientId);

  const ticket = await client.verifyIdToken({
    idToken,
    audience: config.clientId,
  });

  const payload = ticket.getPayload();
  if (!payload?.sub || !payload.email) {
    throw new Error('Payload Google incomplet');
  }

  return {
    googleId: payload.sub,
    email: String(payload.email).trim().toLowerCase(),
    nom: payload.name || payload.email.split('@')[0],
    prenom: payload.given_name || null,
    nomFamille: payload.family_name || null,
    photo: payload.picture || null,
    emailVerifie: Boolean(payload.email_verified),
    roleDefaut: config.roleDefaut,
  };
}

/**
 * Vérifie un access_token OAuth2 (flux popup Web) puis lit le profil OpenID.
 * @param {string} accessToken
 * @param {import('@supabase/supabase-js').SupabaseClient} supabase
 */
export async function verifierAccessTokenGoogle(accessToken, supabase) {
  const config = await getGoogleAuthConfig(supabase);

  if (!config.actif) {
    throw new Error('La connexion Google est désactivée');
  }
  if (!config.clientId) {
    throw new Error('Google Client ID non configuré dans les paramètres admin');
  }

  const at = String(accessToken || '').trim();
  if (!at) {
    throw new Error('Access token Google manquant');
  }

  const tokeninfoUrl = `https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(at)}`;
  const tiRes = await fetch(tokeninfoUrl);
  const ti = await tiRes.json();
  if (!tiRes.ok || ti.error) {
    throw new Error(ti.error_description || ti.error || 'Access token Google invalide');
  }
  const expected = config.clientId.trim();
  const aud = String(ti.aud || ti.audience || '').trim();
  const azp = String(ti.azp || '').trim();
  if (aud !== expected && azp !== expected) {
    throw new Error('Access token : application (audience) incorrecte');
  }

  const uiRes = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
    headers: { Authorization: `Bearer ${at}` },
  });
  const p = await uiRes.json();
  if (!uiRes.ok || p.error) {
    throw new Error(p.error_description || p.error || 'Profil Google inaccessible');
  }
  if (!p.sub || !p.email) {
    throw new Error('Profil Google incomplet (sub ou email manquant)');
  }

  return {
    googleId: String(p.sub),
    email: String(p.email).trim().toLowerCase(),
    nom: p.name || String(p.email).split('@')[0],
    prenom: p.given_name || null,
    nomFamille: p.family_name || null,
    photo: p.picture || null,
    emailVerifie: Boolean(p.email_verified),
    roleDefaut: config.roleDefaut,
  };
}
