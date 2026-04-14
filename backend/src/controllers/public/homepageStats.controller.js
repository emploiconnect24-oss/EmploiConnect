/**
 * GET /api/stats/homepage — agrégats publics pour la section stats de l’accueil (cache 5 min).
 *
 * - candidats   : lignes `chercheurs_emploi` (profils candidats)
 * - entreprises : comptes `utilisateurs` rôle entreprise et validés (`est_valide`)
 * - offres       : `offres_emploi` visibles (`active` ou `publiee`)
 * - candidatures : total `candidatures` (indicateur d’activité)
 */
import { supabase } from '../../config/supabase.js';
import { logError } from '../../utils/logger.js';

let _cache = null;
let _cacheTime = 0;
const CACHE_TTL = 5 * 60 * 1000;

function num(v) {
  if (v == null) return 0;
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  const n = parseInt(String(v), 10);
  return Number.isFinite(n) ? n : 0;
}

async function countExact(builder) {
  const { count, error } = await builder;
  if (error) {
    logError('[getHomepageStats] count', error);
    return 0;
  }
  return num(count);
}

export async function getHomepageStats(req, res) {
  try {
    if (_cache && Date.now() - _cacheTime < CACHE_TTL) {
      return res.json({ success: true, data: _cache });
    }

    const [
      nbCandidats,
      nbEntreprises,
      nbOffres,
      nbCandidatures,
    ] = await Promise.all([
      countExact(
        supabase.from('chercheurs_emploi').select('*', { count: 'exact', head: true }),
      ),
      countExact(
        supabase
          .from('utilisateurs')
          .select('*', { count: 'exact', head: true })
          .eq('role', 'entreprise')
          .eq('est_valide', true),
      ),
      countExact(
        supabase
          .from('offres_emploi')
          .select('*', { count: 'exact', head: true })
          .in('statut', ['active', 'publiee']),
      ),
      countExact(
        supabase.from('candidatures').select('*', { count: 'exact', head: true }),
      ),
    ]);

    const stats = {
      entreprises: nbEntreprises,
      candidats: nbCandidats,
      offres: nbOffres,
      candidatures: nbCandidatures,
      satisfaction: 98,
    };

    _cache = stats;
    _cacheTime = Date.now();
    return res.json({ success: true, data: stats });
  } catch (err) {
    logError('[getHomepageStats]', err);
    const empty = {
      entreprises: 0,
      candidats: 0,
      offres: 0,
      candidatures: 0,
      satisfaction: 98,
    };
    return res.json({ success: true, data: empty });
  }
}
