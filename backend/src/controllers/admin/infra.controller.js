/**
 * Infra / Supabase — lecture seule pour l’admin (clés critiques restent dans .env).
 */
import { supabase, BUCKET_CV, BUCKET_ADMIN_AVATARS } from '../../config/supabase.js';

function maskSupabaseUrl(url) {
  const s = String(url || '').trim();
  if (!s) return 'Non configurée';
  try {
    const u = new URL(s);
    const host = u.host;
    const tail = host.length > 8 ? host.slice(-8) : host;
    return `${u.protocol}//***${tail}`;
  } catch {
    return '••••••••';
  }
}

function collectBucketNames() {
  const bannieres = process.env.SUPABASE_BANNIERES_BUCKET?.trim() || 'bannieres';
  const ill =
    process.env.SUPABASE_ILLUSTRATIONS_BUCKET?.trim()
    || process.env.SUPABASE_BANNIERES_BUCKET?.trim()
    || 'bannieres';
  return [...new Set([bannieres, BUCKET_CV, BUCKET_ADMIN_AVATARS, 'logos', ill])];
}

/** GET /api/admin/infra/test — super admin uniquement */
export async function getInfraTest(_req, res) {
  try {
    const { error } = await supabase.from('parametres_plateforme').select('cle').limit(1);
    if (error) throw error;

    const buckets = {};
    for (const name of collectBucketNames()) {
      const { data, error: bErr } = await supabase.storage.getBucket(name);
      if (bErr) {
        buckets[name] = { exists: false, public: false };
      } else {
        buckets[name] = { exists: true, public: !!data?.public };
      }
    }

    let serverPortBdd = '';
    const { data: spRow } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'server_port')
      .maybeSingle();
    if (spRow?.valeur != null) serverPortBdd = String(spRow.valeur);

    const rawUrl = process.env.SUPABASE_URL || '';

    return res.json({
      success: true,
      message: 'Supabase opérationnel',
      data: {
        supabase_url: maskSupabaseUrl(rawUrl),
        service_role_configured: !!process.env.SUPABASE_SERVICE_ROLE_KEY?.trim(),
        jwt_configured: !!process.env.JWT_SECRET?.trim(),
        port_env: String(process.env.PORT || '').trim(),
        server_port_bdd: serverPortBdd,
        buckets,
      },
    });
  } catch (err) {
    return res.json({
      success: false,
      message: err.message || 'Erreur',
    });
  }
}
