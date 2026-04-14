import { supabase } from '../config/supabase.js';

let _configCache = null;
let _cacheExpiry = 0;

function _asBool(v, defaultValue = false) {
  if (v === true || v === false) return v;
  const s = String(v ?? '').trim().toLowerCase();
  if (!s) return defaultValue;
  return s === 'true' || s === '1' || s === 'yes';
}

export async function getGoogleOAuthConfig() {
  if (_configCache && Date.now() < _cacheExpiry) {
    return _configCache;
  }

  const { data } = await supabase
    .from('parametres_plateforme')
    .select('cle, valeur')
    .in('cle', [
      'google_client_id',
      'google_client_secret',
      'google_oauth_actif',
      'google_redirect_uri',
      'google_roles_defaut',
      'google_domaines_autorises',
      'google_projet_id',
    ]);

  const c = {};
  (data || []).forEach((p) => {
    c[p.cle] = p.valeur;
  });

  const redirectFromEnv = String(process.env.GOOGLE_REDIRECT_URI || '').trim();
  const publicApi = String(process.env.PUBLIC_API_URL || 'http://localhost:3000').trim().replace(/\/$/, '');

  _configCache = {
    clientId: String(c.google_client_id || process.env.GOOGLE_CLIENT_ID || '').trim(),
    clientSecret: String(c.google_client_secret || process.env.GOOGLE_CLIENT_SECRET || '').trim(),
    actif: _asBool(c.google_oauth_actif, false),
    redirectUri: String(c.google_redirect_uri || redirectFromEnv || `${publicApi}/api/auth/google/callback`).trim(),
    rolesDefaut: String(c.google_roles_defaut || 'chercheur').trim().toLowerCase() === 'entreprise'
      ? 'entreprise'
      : 'chercheur',
    domainesAutorises: String(c.google_domaines_autorises || '')
      .split(',')
      .map((d) => d.trim().toLowerCase())
      .filter(Boolean),
    projetId: String(c.google_projet_id || '').trim(),
  };

  _configCache.estConfigure = Boolean(_configCache.clientId && _configCache.clientSecret);
  _cacheExpiry = Date.now() + 5 * 60 * 1000;
  return _configCache;
}

export function invaliderCache() {
  _configCache = null;
  _cacheExpiry = 0;
}

export async function testerConfiguration() {
  const config = await getGoogleOAuthConfig();
  const etapes = [];

  const formatOk = config.clientId.includes('.apps.googleusercontent.com');
  etapes.push({
    ok: formatOk,
    message: formatOk
      ? 'Client ID valide'
      : 'Client ID invalide (doit finir par .apps.googleusercontent.com)',
  });

  const secretOk = config.clientSecret.length > 10;
  etapes.push({
    ok: secretOk,
    message: secretOk ? 'Client Secret configure' : 'Client Secret manquant',
  });

  etapes.push({
    ok: config.actif,
    message: config.actif ? 'Google OAuth active' : 'Google OAuth desactive',
  });

  etapes.push({
    ok: true,
    message: `URI de redirection: ${config.redirectUri}`,
  });

  return {
    success: formatOk && secretOk,
    etapes,
    redirect_uri_suggere: config.redirectUri,
    message: formatOk && secretOk ? 'Configuration valide' : 'Configuration incomplete',
  };
}
