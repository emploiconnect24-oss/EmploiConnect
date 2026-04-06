import { Router } from 'express';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { supabase } from '../../config/supabase.js';
import { ROLES } from '../../config/constants.js';

const router = Router();
router.use(authenticate, requireRole(ROLES.CHERCHEUR), attachProfileIds);

function isMissingAlertesTable(err) {
  return err?.code === 'PGRST205'
    && typeof err?.message === 'string'
    && err.message.includes("Could not find the table 'public.alertes_emploi'");
}

router.get('/', async (req, res) => {
  try {
    if (!req.chercheurId) return res.status(400).json({ success: false, message: 'Profil chercheur introuvable' });
    const { data, error } = await supabase
      .from('alertes_emploi')
      .select('*')
      .eq('chercheur_id', req.chercheurId)
      .order('date_creation', { ascending: false });
    if (error) {
      if (isMissingAlertesTable(error)) {
        return res.json({
          success: true,
          data: [],
          warning: 'alertes_emploi_table_missing',
          message: 'La table alertes_emploi est absente. Appliquez la migration SQL 019.',
        });
      }
      throw error;
    }
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    console.error('[candidat/alertes GET /]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.post('/', async (req, res) => {
  try {
    if (!req.chercheurId) return res.status(400).json({ success: false, message: 'Profil chercheur introuvable' });
    const {
      nom,
      mots_cles: motsCles,
      secteur,
      ville,
      localisation,
      type_contrat: typeContrat,
      domaine,
      salaire_min: salaireMin,
      types_contrat: typesContrat,
      frequence,
      est_active: estActive,
    } = req.body || {};

    const motsStr = motsCles != null ? String(motsCles).trim() : '';
    let nomFinal = nom != null ? String(nom).trim() : '';
    if (!nomFinal && motsStr) {
      nomFinal = motsStr.split(/[,;]/)[0].trim().slice(0, 100);
    }
    if (!nomFinal) {
      return res.status(400).json({
        success: false,
        message: 'Nom de l\'alerte requis (ou renseignez des mots-clés).',
      });
    }
    nomFinal = nomFinal.slice(0, 100);

    const payload = {
      chercheur_id: req.chercheurId,
      nom: nomFinal,
      mots_cles: motsStr || null,
      secteur: secteur ?? null,
      ville: ville ?? null,
      localisation: localisation ?? ville ?? null,
      type_contrat: typeContrat ?? null,
      domaine: domaine ?? secteur ?? null,
      salaire_min: salaireMin ?? null,
      types_contrat: Array.isArray(typesContrat) ? typesContrat : [],
      frequence: frequence || 'Immédiatement',
      est_active: estActive !== false,
    };

    const { data, error } = await supabase
      .from('alertes_emploi')
      .insert(payload)
      .select('*')
      .single();
    if (error) {
      if (isMissingAlertesTable(error)) {
        return res.status(503).json({
          success: false,
          message: 'Alertes indisponibles: table alertes_emploi absente. Appliquez la migration SQL 019.',
          code: 'alertes_emploi_table_missing',
        });
      }
      throw error;
    }
    return res.status(201).json({ success: true, data });
  } catch (err) {
    console.error('[candidat/alertes POST /]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.patch('/:id', async (req, res) => {
  try {
    if (!req.chercheurId) return res.status(400).json({ success: false, message: 'Profil chercheur introuvable' });
    const allowed = [
      'nom', 'mots_cles', 'secteur', 'ville', 'localisation',
      'type_contrat', 'domaine', 'salaire_min', 'types_contrat',
      'frequence', 'est_active', 'derniere_notif',
    ];
    const update = {};
    for (const f of allowed) {
      if (req.body?.[f] !== undefined) update[f] = req.body[f];
    }
    update.date_modification = new Date().toISOString();

    const { data, error } = await supabase
      .from('alertes_emploi')
      .update(update)
      .eq('id', req.params.id)
      .eq('chercheur_id', req.chercheurId)
      .select('*')
      .maybeSingle();
    if (error) throw error;
    if (!data) return res.status(404).json({ success: false, message: 'Alerte introuvable' });
    return res.json({ success: true, data });
  } catch (err) {
    console.error('[candidat/alertes PATCH /:id]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    if (!req.chercheurId) return res.status(400).json({ success: false, message: 'Profil chercheur introuvable' });
    const { data, error } = await supabase
      .from('alertes_emploi')
      .delete()
      .eq('id', req.params.id)
      .eq('chercheur_id', req.chercheurId)
      .select('id');
    if (error) throw error;
    if (!data?.length) return res.status(404).json({ success: false, message: 'Alerte introuvable' });
    return res.json({ success: true });
  } catch (err) {
    console.error('[candidat/alertes DELETE /:id]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;

