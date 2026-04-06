import { supabase } from '../config/supabase.js';

let maintenanceCache = null;
let maintenanceCacheTime = 0;

export async function checkMaintenance(req, res, next) {
  if (
    req.path.startsWith('/api/admin')
    || req.path === '/api/health'
    || req.path.startsWith('/api/auth')
  ) {
    return next();
  }

  try {
    const now = Date.now();
    if (!maintenanceCache || (now - maintenanceCacheTime) > 60 * 1000) {
      const { data } = await supabase
        .from('parametres_plateforme')
        .select('cle, valeur')
        .in('cle', ['mode_maintenance', 'message_maintenance']);

      maintenanceCache = {};
      (data || []).forEach((p) => {
        maintenanceCache[p.cle] = p.valeur;
      });
      maintenanceCacheTime = now;
    }

    const raw = String(maintenanceCache?.mode_maintenance ?? '').toLowerCase();
    const isOn = raw === 'true' || raw === '1';
    if (isOn) {
      return res.status(503).json({
        success: false,
        maintenance: true,
        message: maintenanceCache?.message_maintenance
          || 'La plateforme est en cours de maintenance. Revenez bientot.',
      });
    }
  } catch (_) {
    // En cas d'erreur DB, ne pas bloquer toute l'application.
  }

  return next();
}

