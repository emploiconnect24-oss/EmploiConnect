import { supabase } from '../config/supabase.js';
import { logError } from '../utils/logger.js';

let securityParamsCache = null;
let cacheTimestamp = 0;

async function loadSecurityParams() {
  const { data, error } = await supabase
    .from('parametres_plateforme')
    .select('cle, valeur')
    .eq('categorie', 'securite');

  if (error) throw error;
  const params = {};
  (data || []).forEach((p) => {
    params[p.cle] = p.valeur;
  });
  return params;
}

export async function getSecurityParamsCached({ ttlMs = 5 * 60 * 1000 } = {}) {
  const now = Date.now();
  if (securityParamsCache && now - cacheTimestamp < ttlMs) return securityParamsCache;
  try {
    securityParamsCache = await loadSecurityParams();
    cacheTimestamp = now;
  } catch (e) {
    // Ne pas bloquer si la lecture des paramètres échoue
    logError('getSecurityParamsCached - erreur', e);
  }
  return securityParamsCache || {};
}

function getClientIp(req) {
  const xf = req.headers['x-forwarded-for'];
  if (typeof xf === 'string' && xf.trim()) {
    return xf.split(',')[0].trim();
  }
  return (
    req.ip ||
    req.connection?.remoteAddress ||
    req.socket?.remoteAddress ||
    null
  );
}

export async function checkBlockedIP(req, res, next) {
  try {
    const params = await getSecurityParamsCached();
    let ipsBloquees = [];
    try {
      ipsBloquees = JSON.parse(params.ips_bloquees || '[]');
    } catch (_) {
      ipsBloquees = [];
    }
    const clientIP = getClientIp(req);
    if (clientIP && Array.isArray(ipsBloquees)) {
      const blocked = ipsBloquees.some((ip) => String(clientIP).includes(String(ip)));
      if (blocked) {
        return res.status(403).json({
          success: false,
          message: 'Accès refusé depuis cette adresse IP',
        });
      }
    }
    return next();
  } catch (_) {
    return next();
  }
}

// Login attempts limiter (in-memory) — configurable via parametres_plateforme.max_tentatives_connexion
const attemptsByIp = new Map(); // ip -> { count, firstAtMs }

export async function loginAttemptsGuard(req, res, next) {
  try {
    const params = await getSecurityParamsCached();
    const maxAttempts = Math.max(1, parseInt(params.max_tentatives_connexion || '5', 10));
    const windowMs = Number(process.env.LOGIN_RATE_LIMIT_WINDOW_MS || 15 * 60 * 1000);
    const ip = getClientIp(req) || 'unknown';

    const now = Date.now();
    const entry = attemptsByIp.get(ip);
    if (!entry || now - entry.firstAtMs > windowMs) {
      attemptsByIp.set(ip, { count: 0, firstAtMs: now });
    }

    const cur = attemptsByIp.get(ip);
    if (cur && cur.count >= maxAttempts) {
      return res.status(429).json({
        message: 'Trop de tentatives de connexion, réessayez plus tard.',
      });
    }

    // Incrémente seulement si l'auth échoue : on intercepte res.json en cas de 401/403
    const originalJson = res.json.bind(res);
    res.json = (body) => {
      if (res.statusCode === 401 || res.statusCode === 403) {
        const cur2 = attemptsByIp.get(ip);
        if (cur2) cur2.count += 1;
      } else if (res.statusCode >= 200 && res.statusCode < 300) {
        attemptsByIp.delete(ip);
      }
      return originalJson(body);
    };
    return next();
  } catch (_) {
    return next();
  }
}

