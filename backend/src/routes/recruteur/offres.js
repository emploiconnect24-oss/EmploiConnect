import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import { requireRecruteur } from '../../middleware/recruteurAuth.js';
import { supabase } from '../../config/supabase.js';
import { extraireMotsCles } from '../../services/ia.service.js';
import { notifNouvelleOffre } from '../../services/auto_notification.service.js';
import { notifierAlertesPourOffrePubliee } from '../../services/alerteEmploiNotify.service.js';

async function offresPublicationAutoActive() {
  const { data } = await supabase
    .from('parametres_plateforme')
    .select('valeur')
    .eq('cle', 'offres_publication_auto')
    .maybeSingle();
  return String(data?.valeur || '').toLowerCase() === 'true';
}

const router = Router();
router.use(authenticate, requireRecruteur);

router.get('/export/csv', async (req, res) => {
  try {
    const { data: rows, error } = await supabase
      .from('offres_emploi')
      .select('id, titre, statut, localisation, type_contrat, nb_vues, date_creation, date_publication, date_limite')
      .eq('entreprise_id', req.entreprise.id)
      .order('date_creation', { ascending: false });
    if (error) throw error;
    const esc = (v) => {
      const s = v == null ? '' : String(v).replace(/"/g, '""');
      return `"${s}"`;
    };
    const cols = ['id', 'titre', 'statut', 'localisation', 'type_contrat', 'nb_vues', 'date_creation', 'date_publication', 'date_limite'];
    const lines = [cols.join(',')];
    for (const r of rows || []) {
      lines.push(cols.map((h) => esc(r[h])).join(','));
    }
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="mes_offres.csv"');
    return res.send(lines.join('\n'));
  } catch (err) {
    console.error('[recruteur/offres export/csv]', err);
    return res.status(500).send('Erreur export');
  }
});

router.get('/', async (req, res) => {
  try {
    const { page = 1, limite = 20, statut, recherche } = req.query;
    const offset = (parseInt(page, 10) - 1) * parseInt(limite, 10);
    let query = supabase
      .from('offres_emploi')
      .select('*', { count: 'exact' })
      .eq('entreprise_id', req.entreprise.id)
      .order('date_creation', { ascending: false })
      .range(offset, offset + parseInt(limite, 10) - 1);
    if (statut === 'publiee' || statut === 'active') {
      query = query.in('statut', ['publiee', 'active']);
    } else if (statut === 'expiree') {
      query = query.in('statut', ['expiree', 'fermee']);
    } else if (statut) {
      query = query.eq('statut', statut);
    }
    if (recherche) query = query.ilike('titre', `%${recherche}%`);
    const { data: offres, count, error } = await query;
    if (error) throw error;
    const offresIds = (offres || []).map((o) => o.id);
    const candidaturesCount = {};
    const nonLuesCount = {};
    if (offresIds.length > 0) {
      const { data: cands } = await supabase
        .from('candidatures')
        .select('offre_id, statut')
        .in('offre_id', offresIds);

      (cands || []).forEach((c) => {
        candidaturesCount[c.offre_id] = (candidaturesCount[c.offre_id] || 0) + 1;
        if (c.statut === 'en_attente') {
          nonLuesCount[c.offre_id] = (nonLuesCount[c.offre_id] || 0) + 1;
        }
      });
    }

    const { data: tousStatuts } = await supabase
      .from('offres_emploi')
      .select('statut')
      .eq('entreprise_id', req.entreprise.id);

    const statsStatuts = {
      total: tousStatuts?.length || 0,
      publiees: tousStatuts?.filter((o) => o.statut === 'publiee' || o.statut === 'active').length || 0,
      en_attente: tousStatuts?.filter((o) => o.statut === 'en_attente').length || 0,
      refusees: tousStatuts?.filter((o) => o.statut === 'refusee' || o.statut === 'suspendue').length || 0,
      expirees: tousStatuts?.filter((o) => o.statut === 'expiree' || o.statut === 'fermee').length || 0,
      brouillons: tousStatuts?.filter((o) => o.statut === 'brouillon').length || 0,
    };

    const offresEnrichies = (offres || []).map((o) => ({
      ...o,
      nb_candidatures: candidaturesCount[o.id] || 0,
      nb_non_lues: nonLuesCount[o.id] || 0,
    }));

    return res.json({
      success: true,
      data: {
        offres: offresEnrichies,
        stats: statsStatuts,
        pagination: {
          total: count || 0,
          page: parseInt(page, 10),
          limite: parseInt(limite, 10),
          total_pages: Math.ceil((count || 0) / parseInt(limite, 10)),
        },
      },
    });
  } catch (err) {
    console.error('[recruteur/offres GET]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.post('/', async (req, res) => {
  try {
    const {
      titre, description, exigences, competences_requises, localisation, type_contrat,
      niveau_experience_requis, domaine, salaire_min, salaire_max, devise,
      nombre_postes, date_limite, publier_maintenant = true,
    } = req.body;

    if (!titre || !description || !localisation || !type_contrat) {
      return res.status(400).json({ success: false, message: 'Champs requis manquants' });
    }

    const veutPublier = publier_maintenant !== false && publier_maintenant !== 'false';
    const autoPub = veutPublier && await offresPublicationAutoActive();
    let statut;
    if (!veutPublier) statut = 'brouillon';
    else if (autoPub) statut = 'publiee';
    else statut = 'en_attente';
    console.log('[recruteur/POST offre] Statut inséré:', statut, 'autoPub=', autoPub);

    const insertRow = {
      entreprise_id: req.entreprise.id,
      titre: String(titre).trim(),
      description: String(description).trim(),
      exigences: String(exigences || '').trim(),
      competences_requises: Array.isArray(competences_requises) ? competences_requises : [],
      localisation: String(localisation).trim(),
      type_contrat: String(type_contrat).trim(),
      niveau_experience_requis: niveau_experience_requis || null,
      domaine: domaine || null,
      salaire_min: salaire_min ?? null,
      salaire_max: salaire_max ?? null,
      devise: devise || 'GNF',
      nombre_postes: nombre_postes || 1,
      date_limite: date_limite || null,
      statut,
    };
    if (statut === 'publiee') {
      insertRow.date_publication = new Date().toISOString();
    }

    const { data: inserted, error } = await supabase
      .from('offres_emploi')
      .insert(insertRow)
      .select()
      .single();
    if (error) throw error;

    setImmediate(async () => {
      try {
        const motsCles = await extraireMotsCles([titre, description, exigences].filter(Boolean).join(' '));
        if (motsCles.length) {
          const existantes = Array.isArray(inserted.competences_requises) ? inserted.competences_requises : [];
          await supabase.from('offres_emploi')
            .update({ competences_requises: [...new Set([...existantes, ...motsCles])].slice(0, 20) })
            .eq('id', inserted.id);
        }
        await notifNouvelleOffre(inserted, req.entreprise.nom_entreprise);
        if (String(inserted.statut || '').toLowerCase() === 'publiee') {
          void notifierAlertesPourOffrePubliee(inserted.id);
        }
      } catch (e) {
        console.warn('[recruteur/offres] enrichissement non bloquant:', e.message);
      }
    });

    return res.status(201).json({ success: true, data: inserted });
  } catch (err) {
    console.error('[recruteur/offres POST]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

const OFFRE_PATCHABLE = [
  'titre', 'description', 'exigences',
  'competences_requises', 'localisation', 'type_contrat',
  'niveau_experience_requis', 'domaine',
  'salaire_min', 'salaire_max', 'devise',
  'nombre_postes', 'date_limite', 'statut',
  'date_publication',
];

router.patch('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { data: offre, error: findErr } = await supabase
      .from('offres_emploi')
      .select('id, statut, entreprise_id, titre')
      .eq('id', id)
      .single();
    if (findErr || !offre) {
      return res.status(404).json({ success: false, message: 'Offre non trouvée' });
    }
    if (offre.entreprise_id !== req.entreprise.id) {
      return res.status(403).json({
        success: false,
        message: 'Vous ne pouvez modifier que vos propres offres',
      });
    }

    const updates = {};
    OFFRE_PATCHABLE.forEach((c) => {
      if (req.body[c] !== undefined) updates[c] = req.body[c];
    });
    if (updates.competences_requises === undefined && req.body.competences !== undefined) {
      updates.competences_requises = req.body.competences;
    }
    if (typeof updates.statut === 'string') {
      const s = updates.statut.toLowerCase().trim();
      if (s === 'inactive') updates.statut = 'fermee';
      if (s === 'active') updates.statut = 'publiee';
      if (s === 'attente') updates.statut = 'en_attente';
      if (s === 'suspendue') updates.statut = 'refusee';
    }
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ success: false, message: 'Aucun champ à mettre à jour' });
    }
    updates.date_modification = new Date().toISOString();

    const { data: updated, error } = await supabase
      .from('offres_emploi')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;

    const prevLive = ['publiee', 'active'].includes(String(offre.statut || '').toLowerCase());
    const nextLive = ['publiee', 'active'].includes(String(updated.statut || '').toLowerCase());
    if (!prevLive && nextLive) {
      setImmediate(() => {
        void notifierAlertesPourOffrePubliee(id);
      });
    }

    return res.json({
      success: true,
      message: 'Offre mise à jour avec succès',
      data: updated,
    });
  } catch (err) {
    console.error('[recruteur/offres PATCH]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.post('/:id/dupliquer', async (req, res) => {
  try {
    const { data: src } = await supabase
      .from('offres_emploi')
      .select('*')
      .eq('id', req.params.id)
      .eq('entreprise_id', req.entreprise.id)
      .single();
    if (!src) return res.status(404).json({ success: false, message: 'Offre non trouvée' });

    const dateLimite = new Date();
    dateLimite.setDate(dateLimite.getDate() + 30);
    const now = new Date().toISOString();

    const { data: copie, error } = await supabase
      .from('offres_emploi')
      .insert({
        entreprise_id: src.entreprise_id,
        titre: `${src.titre} (copie)`,
        description: src.description,
        exigences: src.exigences,
        competences_requises: src.competences_requises,
        localisation: src.localisation,
        type_contrat: src.type_contrat,
        niveau_experience_requis: src.niveau_experience_requis,
        domaine: src.domaine,
        salaire_min: src.salaire_min,
        salaire_max: src.salaire_max,
        devise: src.devise ?? 'GNF',
        nombre_postes: src.nombre_postes ?? 1,
        date_limite: dateLimite.toISOString(),
        statut: 'brouillon',
        nb_vues: 0,
        date_creation: now,
        date_modification: now,
      })
      .select()
      .single();
    if (error) throw error;
    return res.status(201).json({
      success: true,
      message: 'Offre dupliquée en brouillon',
      data: copie,
    });
  } catch (err) {
    console.error('[recruteur/offres/dupliquer]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.patch('/:id/cloturer', async (req, res) => {
  try {
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('id, entreprise_id')
      .eq('id', req.params.id)
      .single();
    if (!offre || offre.entreprise_id !== req.entreprise.id) {
      return res.status(404).json({ success: false, message: 'Offre non trouvée' });
    }
    await supabase
      .from('offres_emploi')
      .update({ statut: 'fermee', date_modification: new Date().toISOString() })
      .eq('id', req.params.id);
    return res.json({
      success: true,
      message: `Offre clôturée`,
    });
  } catch (err) {
    console.error('[recruteur/offres/cloturer]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('id, entreprise_id')
      .eq('id', req.params.id)
      .single();
    if (!offre || offre.entreprise_id !== req.entreprise.id) {
      return res.status(404).json({ success: false, message: 'Offre non trouvée' });
    }
    await supabase.from('offres_emploi').delete().eq('id', req.params.id);
    return res.json({ success: true, message: 'Offre supprimée' });
  } catch (err) {
    console.error('[recruteur/offres DELETE]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;

