import { supabase } from '../../config/supabase.js';

function csvCell(v) {
  const s = v == null ? '' : String(v);
  if (/[",\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

export async function getCandidatures(req, res) {
  try {
    const {
      page = 1,
      limite = 20,
      statut,
      offre_id,
      entreprise_id,
      chercheur_id,
      date_debut,
      date_fin,
      chercheur_nom,
      entreprise_nom,
      ordre = 'date_candidature',
      direction = 'desc',
    } = req.query;

    const offset = (parseInt(page, 10) - 1) * parseInt(limite, 10);

    let chercheurIdsFilter = null;
    if (chercheur_nom && String(chercheur_nom).trim()) {
      const term = `%${String(chercheur_nom).trim().replace(/%/g, '\\%')}%`;
      const { data: users } = await supabase.from('utilisateurs').select('id').ilike('nom', term);
      const uids = (users || []).map((u) => u.id);
      if (uids.length === 0) {
        return res.json({
          success: true,
          data: {
            candidatures: [],
            stats: await candidaturesStats(),
            pagination: {
              total: 0,
              page: parseInt(page, 10),
              limite: parseInt(limite, 10),
              total_pages: 0,
            },
          },
        });
      }
      const { data: chs } = await supabase.from('chercheurs_emploi').select('id').in('utilisateur_id', uids);
      chercheurIdsFilter = (chs || []).map((c) => c.id);
      if (chercheurIdsFilter.length === 0) {
        return res.json({
          success: true,
          data: {
            candidatures: [],
            stats: await candidaturesStats(),
            pagination: {
              total: 0,
              page: parseInt(page, 10),
              limite: parseInt(limite, 10),
              total_pages: 0,
            },
          },
        });
      }
    }

    let offreIdsFilter = null;
    if (entreprise_nom && String(entreprise_nom).trim()) {
      const term = `%${String(entreprise_nom).trim().replace(/%/g, '\\%')}%`;
      const { data: ents } = await supabase.from('entreprises').select('id').ilike('nom_entreprise', term);
      const eids = (ents || []).map((e) => e.id);
      if (eids.length === 0) {
        return res.json({
          success: true,
          data: {
            candidatures: [],
            stats: await candidaturesStats(),
            pagination: {
              total: 0,
              page: parseInt(page, 10),
              limite: parseInt(limite, 10),
              total_pages: 0,
            },
          },
        });
      }
      const { data: offs } = await supabase.from('offres_emploi').select('id').in('entreprise_id', eids);
      offreIdsFilter = (offs || []).map((o) => o.id);
      if (offreIdsFilter.length === 0) {
        return res.json({
          success: true,
          data: {
            candidatures: [],
            stats: await candidaturesStats(),
            pagination: {
              total: 0,
              page: parseInt(page, 10),
              limite: parseInt(limite, 10),
              total_pages: 0,
            },
          },
        });
      }
    }

    let query = supabase
      .from('candidatures')
      .select(
        `
        id, statut, score_compatibilite,
        date_candidature, date_modification,
        chercheur_id, offre_id,
        chercheurs_emploi (
          id,
          utilisateurs ( nom, email, photo_url )
        ),
        offres_emploi (
          id, titre, localisation, type_contrat, entreprise_id,
          entreprises ( nom_entreprise, logo_url )
        )
      `,
        { count: 'exact' },
      )
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite, 10) - 1);

    if (statut) query = query.eq('statut', statut);
    if (offre_id) query = query.eq('offre_id', offre_id);
    if (chercheur_id) query = query.eq('chercheur_id', chercheur_id);
    if (date_debut) query = query.gte('date_candidature', date_debut);
    if (date_fin) query = query.lte('date_candidature', date_fin);
    if (chercheurIdsFilter) query = query.in('chercheur_id', chercheurIdsFilter);
    if (offreIdsFilter) query = query.in('offre_id', offreIdsFilter);

    if (entreprise_id) {
      const { data: offs } = await supabase.from('offres_emploi').select('id').eq('entreprise_id', entreprise_id);
      const oids = (offs || []).map((o) => o.id);
      if (oids.length === 0) {
        return res.json({
          success: true,
          data: {
            candidatures: [],
            stats: await candidaturesStats(),
            pagination: {
              total: 0,
              page: parseInt(page, 10),
              limite: parseInt(limite, 10),
              total_pages: 0,
            },
          },
        });
      }
      query = query.in('offre_id', oids);
    }

    const { data, count, error } = await query;
    if (error) throw error;

    return res.json({
      success: true,
      data: {
        candidatures: data || [],
        stats: await candidaturesStats(),
        pagination: {
          total: count || 0,
          page: parseInt(page, 10),
          limite: parseInt(limite, 10),
          total_pages: Math.ceil((count || 0) / parseInt(limite, 10)),
        },
      },
    });
  } catch (err) {
    console.error('[getCandidatures]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function getCandidatureById(req, res) {
  try {
    const { id } = req.params;
    if (!id) {
      return res.status(400).json({ success: false, message: 'Identifiant requis' });
    }

    const { data, error } = await supabase
      .from('candidatures')
      .select(
        `
        id, statut, score_compatibilite,
        date_candidature, date_modification,
        lettre_motivation, raison_refus,
        chercheur_id, offre_id,
        chercheurs_emploi (
          id,
          utilisateur_id,
          utilisateurs ( id, nom, email, photo_url )
        ),
        offres_emploi (
          id, titre, localisation, type_contrat, entreprise_id,
          entreprises ( nom_entreprise, logo_url )
        )
      `,
      )
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    if (!data) {
      return res.status(404).json({ success: false, message: 'Candidature non trouvée' });
    }

    return res.json({ success: true, data });
  } catch (err) {
    console.error('[getCandidatureById]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

async function candidaturesStats() {
  const { data: statsData } = await supabase.from('candidatures').select('statut');
  return {
    total: statsData?.length || 0,
    en_attente: statsData?.filter((c) => c.statut === 'en_attente').length || 0,
    en_cours: statsData?.filter((c) => c.statut === 'en_cours').length || 0,
    entretien: statsData?.filter((c) => c.statut === 'entretien').length || 0,
    acceptees: statsData?.filter((c) => c.statut === 'acceptee').length || 0,
    refusees: statsData?.filter((c) => c.statut === 'refusee').length || 0,
    annulees: statsData?.filter((c) => c.statut === 'annulee').length || 0,
  };
}

export async function exportCandidatures(req, res) {
  try {
    const { data, error } = await supabase
      .from('candidatures')
      .select(
        `
        statut, score_compatibilite, date_candidature,
        chercheurs_emploi ( utilisateurs ( nom, email ) ),
        offres_emploi ( titre, entreprises ( nom_entreprise ) )
      `,
      )
      .order('date_candidature', { ascending: false });

    if (error) throw error;

    const lines = ['Candidat,Email,Poste,Entreprise,Statut,Score IA,Date'];
    for (const c of data || []) {
      const ch = c.chercheurs_emploi;
      const chRow = Array.isArray(ch) ? ch[0] : ch;
      const u = chRow?.utilisateurs;
      const uRow = Array.isArray(u) ? u[0] : u;
      const nom = uRow?.nom ?? '';
      const email = uRow?.email ?? '';
      const off = c.offres_emploi;
      const oRow = Array.isArray(off) ? off[0] : off;
      const titre = oRow?.titre ?? '';
      const ent = oRow?.entreprises;
      const eRow = Array.isArray(ent) ? ent[0] : ent;
      const entNom = eRow?.nom_entreprise ?? '';
      const score = c.score_compatibilite ?? '';
      const dateStr = c.date_candidature?.split('T')[0] || '';
      lines.push(
        [
          csvCell(nom),
          csvCell(email),
          csvCell(titre),
          csvCell(entNom),
          csvCell(c.statut),
          csvCell(score),
          csvCell(dateStr),
        ].join(','),
      );
    }

    const csv = lines.join('\n');
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="candidatures_emploiconnect.csv"');
    return res.send(`\uFEFF${csv}`);
  } catch (err) {
    console.error('[exportCandidatures]', err);
    res.status(500).json({ success: false, message: 'Erreur export' });
  }
}
