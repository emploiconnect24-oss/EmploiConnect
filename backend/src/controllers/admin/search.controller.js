import { supabase } from '../../config/supabase.js';

function escapeIlike(term) {
  return String(term).replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
}

/**
 * GET /api/admin/recherche?q=
 */
export async function rechercheGlobale(req, res) {
  try {
    const q = (req.query.q || '').trim();
    if (q.length < 2) {
      return res.json({ success: true, data: { resultats: [] } });
    }

    const pattern = `%${escapeIlike(q)}%`;

    const [byNom, byEmail, offresR, entreprisesR] = await Promise.all([
      supabase.from('utilisateurs').select('id, nom, email, role, photo_url').ilike('nom', pattern).limit(5),
      supabase.from('utilisateurs').select('id, nom, email, role, photo_url').ilike('email', pattern).limit(5),
      supabase.from('offres_emploi').select('id, titre, localisation, statut').ilike('titre', pattern).limit(5),
      supabase
        .from('entreprises')
        .select('id, nom_entreprise, logo_url, utilisateur_id')
        .ilike('nom_entreprise', pattern)
        .limit(5),
    ]);

    if (byNom.error) throw byNom.error;
    if (byEmail.error) throw byEmail.error;
    if (offresR.error) throw offresR.error;
    if (entreprisesR.error) throw entreprisesR.error;

    const userMap = new Map();
    for (const u of [...(byNom.data || []), ...(byEmail.data || [])]) {
      if (!userMap.has(u.id)) userMap.set(u.id, u);
    }
    const usersMerged = [...userMap.values()].slice(0, 5);

    const resultats = [
      ...usersMerged.map((u) => ({
        type: 'utilisateur',
        id: u.id,
        titre: u.nom,
        sous_titre: `${u.email} · ${u.role}`,
        photo: u.photo_url,
        lien: `/admin/utilisateurs/${u.id}`,
      })),
      ...(offresR.data || []).map((o) => ({
        type: 'offre',
        id: o.id,
        titre: o.titre,
        sous_titre: `${o.localisation ?? '—'} · ${o.statut}`,
        lien: `/admin/offres/${o.id}`,
      })),
      ...(entreprisesR.data || []).map((e) => ({
        type: 'entreprise',
        id: e.id,
        utilisateur_id: e.utilisateur_id,
        titre: e.nom_entreprise,
        sous_titre: 'Entreprise',
        photo: e.logo_url,
        lien: `/admin/entreprises/${e.utilisateur_id}`,
      })),
    ];

    return res.json({ success: true, data: { resultats } });
  } catch (err) {
    console.error('[rechercheGlobale]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
