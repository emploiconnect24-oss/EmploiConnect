/**
 * Factory : journalise une action admin après réponse JSON 2xx.
 */
import { supabase } from '../config/supabase.js';

const MAX_DETAILS_JSON = 12000;

function compactForAudit(value) {
  try {
    const s = JSON.stringify(value);
    if (s.length <= MAX_DETAILS_JSON) return value;
    return { _truncated: true, len: s.length, head: s.slice(0, MAX_DETAILS_JSON) };
  } catch {
    return null;
  }
}

export function auditLog(action, typeObjet = null) {
  return (req, res, next) => {
    const originalJson = res.json.bind(res);
    res.json = (body) => {
      if (res.statusCode >= 200 && res.statusCode < 300 && req.user) {
        const rawId = req.params?.id ?? body?.data?.id ?? body?.id ?? null;
        let objetId = null;
        if (typeof rawId === 'string' && /^[0-9a-f-]{36}$/i.test(rawId)) {
          objetId = rawId;
        }
        supabase
          .from('activite_admin')
          .insert({
            admin_id: req.user.id,
            action,
            type_objet: typeObjet,
            objet_id: objetId,
            details: {
              body_request: compactForAudit(req.body),
              response_preview: compactForAudit(
                body && typeof body === 'object'
                  ? { success: body.success, message: body.message }
                  : body,
              ),
              params: req.params,
              status_code: res.statusCode,
            },
            ip_address: req.ip || req.socket?.remoteAddress,
            user_agent: req.get('user-agent'),
          })
          .then(({ error }) => {
            if (error) console.error('[auditLog]', error.message);
          });
      }
      return originalJson(body);
    };
    next();
  };
}
