import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import { requireRecruteur } from '../../middleware/recruteurAuth.js';
import { supabase } from '../../config/supabase.js';
import { notifyChercheurCandidatureStatutChanged } from '../../services/candidatureSignalementNotify.service.js';
import { createCvSignedUrl } from '../../helpers/cvSignedUrl.js';

const router = Router();
router.use(authenticate, requireRecruteur);

const NIL_UUID = '00000000-0000-0000-0000-000000000000';
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const KANBAN_MAX = 2000;

function labelStatut(s) {
  const map = {
    en_attente: 'En attente',
    en_cours: 'En examen',
    entretien: 'Entretien',
    acceptee: 'Acceptée',
    refusee: 'Refusée',
  };
  return map[s] || s || '';
}

function labelNiveau(n) {
  const map = {
    bac: 'Bac',
    bac2: 'Bac+2',
    licence: 'Licence (Bac+3)',
    master: 'Master (Bac+5)',
    doctorat: 'Doctorat',
  };
  return map[n] || n || 'Non précisé';
}

function labelDispo(d) {
  const map = {
    immediat: 'Disponible immédiatement',
    '1_mois': 'Dans 1 mois',
    '3_mois': 'Dans 3 mois',
  };
  return map[d] || d || 'Non précisé';
}

function escCsv(v) {
  if (v == null || v === undefined) return '""';
  const s = String(v).replace(/"/g, '""');
  return `"${s}"`;
}

function badCandidatureId(id) {
  if (id == null || id === '') return true;
  const s = String(id).trim();
  if (s === NIL_UUID) return true;
  return !UUID_RE.test(s);
}

router.get('/', async (req, res) => {
  try {
    const { offre_id: offreId, statut, recherche, vue = 'liste', page = 1, limite = 50 } = req.query;
    const entrepriseId = req.entreprise.id;
    const { data: mesOffres, error: offresErr } = await supabase
      .from('offres_emploi')
      .select('id, titre')
      .eq('entreprise_id', entrepriseId);
    if (offresErr) throw offresErr;

    const ids = (mesOffres || []).map((o) => o.id);

    if (!ids.length) {
      return res.json({
        success: true,
        data: {
          candidatures: [],
          stats: {
            total: 0,
            en_attente: 0,
            en_cours: 0,
            entretien: 0,
            acceptees: 0,
            refusees: 0,
          },
          kanban: null,
        },
      });
    }

    let idsFiltres = ids;
    if (offreId) {
      if (!ids.includes(offreId)) {
        return res.status(403).json({
          success: false,
          message: 'Cette offre ne vous appartient pas',
        });
      }
      idsFiltres = [offreId];
    }

    const isKanban = String(vue).toLowerCase() === 'kanban';
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limiteNum = isKanban
      ? KANBAN_MAX
      : Math.min(200, Math.max(1, parseInt(limite, 10) || 50));
    const from = isKanban ? 0 : (pageNum - 1) * limiteNum;
    const to = isKanban ? KANBAN_MAX - 1 : from + limiteNum - 1;

    let q = supabase
      .from('candidatures')
      .select(`id, statut, score_compatibilite, date_candidature, date_modification, offre_id,
        lettre_motivation,
        chercheur:chercheur_id (
          id,
          utilisateur:utilisateur_id (id, nom, email, photo_url, telephone, adresse),
          competences, niveau_etude, disponibilite
        ),
        offre:offre_id (id, titre, localisation, type_contrat),
        cv:cv_id (id, fichier_url, nom_fichier, competences_extrait)
      `, { count: 'exact' })
      .in('offre_id', idsFiltres)
      .order('date_candidature', { ascending: false })
      .range(from, to);
    if (statut) q = q.eq('statut', statut);
    const { data, count, error } = await q;
    if (error) throw error;
    let candidatures = data || [];
    if (recherche) {
      const r = String(recherche).toLowerCase();
      candidatures = candidatures.filter((c) => (
        c.chercheur?.utilisateur?.nom?.toLowerCase().includes(r)
        || c.chercheur?.utilisateur?.email?.toLowerCase().includes(r)
      ));
    }

    const { data: tousStatuts } = await supabase
      .from('candidatures')
      .select('statut')
      .in('offre_id', idsFiltres);
    const stats = {
      total: tousStatuts?.length || 0,
      en_attente: tousStatuts?.filter((c) => c.statut === 'en_attente').length || 0,
      en_cours: tousStatuts?.filter((c) => c.statut === 'en_cours').length || 0,
      entretien: tousStatuts?.filter((c) => c.statut === 'entretien').length || 0,
      acceptees: tousStatuts?.filter((c) => c.statut === 'acceptee').length || 0,
      refusees: tousStatuts?.filter((c) => c.statut === 'refusee').length || 0,
    };
    const kanban = vue === 'kanban' ? {
      en_attente: candidatures.filter((c) => c.statut === 'en_attente'),
      en_cours: candidatures.filter((c) => c.statut === 'en_cours'),
      entretien: candidatures.filter((c) => c.statut === 'entretien'),
      acceptees: candidatures.filter((c) => c.statut === 'acceptee'),
      refusees: candidatures.filter((c) => c.statut === 'refusee'),
    } : null;
    return res.json({
      success: true,
      data: {
        candidatures,
        stats,
        kanban,
        pagination: {
          total: count || 0,
          page: pageNum,
          limite: limiteNum,
          total_pages: isKanban ? 1 : Math.ceil((count || 0) / limiteNum),
        },
      },
    });
  } catch (err) {
    console.error('[recruteur/candidatures GET]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.get('/export/csv', async (req, res) => {
  try {
    const { offre_id: offreId, statut } = req.query;
    const entrepriseId = req.entreprise.id;
    const nomEnt = (req.entreprise.nom_entreprise || 'entreprise').replace(/[/\\?%*:|"<>]/g, '-');

    const { data: mesOffres, error: offErr } = await supabase
      .from('offres_emploi')
      .select('id, titre')
      .eq('entreprise_id', entrepriseId);
    if (offErr) throw offErr;

    const mesOffresIds = (mesOffres || []).map((o) => o.id);
    if (!mesOffresIds.length) {
      const headers = [
        'ID Candidature',
        'Nom Candidat',
        'Email',
        'Téléphone',
        'Poste candidaté',
        'Statut',
        'Score IA (%)',
        'Niveau d\'étude',
        'Disponibilité',
        'Date candidature',
      ].join(',');
      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader(
        'Content-Disposition',
        `attachment; filename="candidatures_${nomEnt}_${new Date().toISOString().split('T')[0]}.csv"`,
      );
      return res.send(`\uFEFF${headers}`);
    }

    let filtreIds = mesOffresIds;
    if (offreId && mesOffresIds.includes(offreId)) {
      filtreIds = [offreId];
    }

    let query = supabase
      .from('candidatures')
      .select(`
        id, statut, score_compatibilite, date_candidature,
        lettre_motivation,
        chercheur:chercheur_id (
          utilisateur:utilisateur_id (
            nom, email, telephone, adresse
          ),
          niveau_etude, disponibilite
        ),
        offre:offre_id ( titre ),
        cv:cv_id ( nom_fichier )
      `)
      .in('offre_id', filtreIds)
      .order('date_candidature', { ascending: false });

    if (statut && String(statut) !== 'all') {
      query = query.eq('statut', statut);
    }

    const { data, error } = await query;
    if (error) throw error;

    const headers = [
      'ID Candidature',
      'Nom Candidat',
      'Email',
      'Téléphone',
      'Poste candidaté',
      'Statut',
      'Score IA (%)',
      'Niveau d\'étude',
      'Disponibilité',
      'Date candidature',
    ].join(',');

    const rows = (data || []).map((c) => {
      const ch = c.chercheur || {};
      const u = ch.utilisateur || {};
      const score = c.score_compatibilite != null ? String(c.score_compatibilite) : '';
      const dateStr = c.date_candidature ? String(c.date_candidature).split('T')[0] : '';
      return [
        escCsv(c.id),
        escCsv(u.nom || ''),
        escCsv(u.email || ''),
        escCsv(u.telephone || ''),
        escCsv(c.offre?.titre || ''),
        escCsv(labelStatut(c.statut)),
        score,
        escCsv(labelNiveau(ch.niveau_etude)),
        escCsv(labelDispo(ch.disponibilite)),
        escCsv(dateStr),
      ].join(',');
    });

    const csv = ['\uFEFF' + headers, ...rows].join('\n');
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="candidatures_${nomEnt}_${new Date().toISOString().split('T')[0]}.csv"`,
    );
    return res.send(csv);
  } catch (err) {
    console.error('[export candidatures csv]', err.message);
    return res.status(500).json({ success: false, message: err.message || 'Erreur export CSV' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    if (badCandidatureId(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: 'ID candidature invalide. Exécutez GET /recruteur/candidatures et utilisez un id de la liste (pas 00000000-...).',
      });
    }

    // 1) Base candidature (robuste aux variations de schéma)
    // Certaines bases n'ont pas encore raison_refus / date_entretien → fallback.
    let base = null;
    let baseErr = null;
    {
      const r1 = await supabase
        .from('candidatures')
        .select('id, statut, score_compatibilite, date_candidature, date_modification, lettre_motivation, raison_refus, date_entretien, lien_visio, type_entretien, lieu_entretien, notes_entretien, offre_id, chercheur_id, cv_id')
        .eq('id', req.params.id)
        .maybeSingle();
      base = r1.data;
      baseErr = r1.error;
      if (baseErr && baseErr.code === '42703') {
        const r2 = await supabase
          .from('candidatures')
          .select('id, statut, score_compatibilite, date_candidature, date_modification, lettre_motivation, offre_id, chercheur_id, cv_id')
          .eq('id', req.params.id)
          .maybeSingle();
        base = r2.data;
        baseErr = r2.error;
      }
    }

    if (baseErr) throw baseErr;
    if (!base) return res.status(404).json({ success: false, message: 'Candidature non trouvée' });

    // 2) Vérifier appartenance à l’entreprise du recruteur
    const { data: offreCheck, error: offreErr } = await supabase
      .from('offres_emploi')
      .select('id, titre, localisation, type_contrat, entreprise_id')
      .eq('id', base.offre_id)
      .maybeSingle();
    if (offreErr) throw offreErr;
    if (!offreCheck || offreCheck.entreprise_id !== req.entreprise.id) {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }

    // 3) Charger profil candidat + CV (meilleur effort, sans faire échouer l’écran)
    let chercheur = null;
    let cv = null;

    if (base.chercheur_id) {
      let ch = null;
      let chErr = null;
      {
        const r1 = await supabase
          .from('chercheurs')
          .select(`
            id,
            competences, niveau_etude, disponibilite,
            utilisateur:utilisateur_id (id, nom, email, photo_url, telephone, adresse)
          `)
          .eq('id', base.chercheur_id)
          .maybeSingle();
        ch = r1.data;
        chErr = r1.error;
      }
      // Certaines bases utilisent encore chercheurs_emploi.
      if (chErr && (chErr.code === 'PGRST205' || /chercheurs/i.test(String(chErr.message || '')))) {
        const r2 = await supabase
          .from('chercheurs_emploi')
          .select(`
            id,
            competences, niveau_etude, disponibilite,
            utilisateur:utilisateur_id (id, nom, email, photo_url, telephone, adresse)
          `)
          .eq('id', base.chercheur_id)
          .maybeSingle();
        ch = r2.data;
        chErr = r2.error;
      }
      if (chErr) {
        console.error('[recruteur/candidatures/:id] chercheur:', chErr);
      } else {
        chercheur = ch;
      }
    }

    if (base.cv_id) {
      const { data: cvRow, error: cvErr } = await supabase
        .from('cv')
        .select('id, fichier_url, nom_fichier, competences_extrait, niveau_experience')
        .eq('id', base.cv_id)
        .maybeSingle();
      if (cvErr) {
        console.error('[recruteur/candidatures/:id] cv:', cvErr);
      } else {
        cv = cvRow;
      }
    }

    let cvOut = cv;
    if (cv && cv.fichier_url) {
      const { signedUrl, error: signErr } = await createCvSignedUrl(cv.fichier_url);
      if (signErr) {
        console.error('[recruteur/candidatures/:id] signed_url:', signErr.message || signErr);
      }
      cvOut = { ...cv, signed_url: signedUrl };
    }

    return res.json({
      success: true,
      data: {
        ...base,
        offre: offreCheck,
        chercheur,
        cv: cvOut,
      },
    });
  } catch (err) {
    console.error('[recruteur/candidatures/:id]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.patch('/:id', async (req, res) => {
  try {
    if (badCandidatureId(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: 'ID candidature invalide. Exécutez GET /recruteur/candidatures et utilisez un id de la liste (pas 00000000-...).',
      });
    }
    const {
      action,
      date_entretien: dateEntretien,
      raison_refus: raisonRefus,
      lien_visio: lienVisio,
      type_entretien: typeEntretien,
      lieu_entretien: lieuEntretien,
      notes_entretien: notesEntretien,
    } = req.body;
    const { data: cand, error: fetchErr } = await supabase
      .from('candidatures')
      .select('id, offre_id, chercheur_id, statut')
      .eq('id', req.params.id)
      .maybeSingle();
    if (fetchErr || !cand) return res.status(404).json({ success: false, message: 'Candidature non trouvée' });
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('entreprise_id, titre, entreprises ( nom_entreprise )')
      .eq('id', cand.offre_id)
      .single();
    if (!offre || offre.entreprise_id !== req.entreprise.id) return res.status(403).json({ success: false, message: 'Accès refusé' });
    const entEmbed = offre.entreprises;
    const entRow = Array.isArray(entEmbed) ? entEmbed[0] : entEmbed;
    const entrepriseNom = entRow?.nom_entreprise ?? null;

    const update = {};
    if (action === 'mettre_en_examen') update.statut = 'en_cours';
    else if (action === 'planifier_entretien') {
      update.statut = 'entretien';
      update.date_entretien = dateEntretien || null;
      if (lienVisio !== undefined) update.lien_visio = String(lienVisio ?? '').trim() || null;
      if (typeEntretien !== undefined) update.type_entretien = String(typeEntretien ?? '').trim() || null;
      if (lieuEntretien !== undefined) update.lieu_entretien = String(lieuEntretien ?? '').trim() || null;
      if (notesEntretien !== undefined) update.notes_entretien = String(notesEntretien ?? '').trim() || null;
    } else if (action === 'accepter') update.statut = 'acceptee';
    else if (action === 'refuser') {
      update.statut = 'refusee';
      update.raison_refus = raisonRefus || null;
    } else return res.status(400).json({ success: false, message: 'Action invalide' });

    const { data: saved, error } = await supabase.from('candidatures').update(update).eq('id', req.params.id).select().single();
    if (error) throw error;
    if (saved?.statut && saved.statut !== cand.statut) {
      void notifyChercheurCandidatureStatutChanged(cand.chercheur_id, {
        offreTitre: offre.titre,
        statut: saved.statut,
        raisonRefus: saved.raison_refus ?? null,
        dateEntretien: saved.date_entretien ?? null,
        lienVisio: saved.lien_visio ?? null,
        typeEntretien: saved.type_entretien ?? null,
        lieuEntretien: saved.lieu_entretien ?? null,
        notesEntretien: saved.notes_entretien ?? null,
        candidatureId: req.params.id,
        entrepriseNom,
      });
    }
    return res.json({ success: true, data: saved });
  } catch (err) {
    console.error('[recruteur/candidatures PATCH]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;

