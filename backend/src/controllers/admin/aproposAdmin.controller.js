import { supabase } from '../../config/supabase.js';

/**
 * PUT /api/admin/apropos/:id
 * Body: { titre?, contenu?, icone?, est_actif?, ordre?, meta_donnees? }
 */
export async function putAproposSection(req, res) {
  try {
    const { id } = req.params;
    const {
      titre, contenu, icone, est_actif, ordre, meta_donnees,
    } = req.body || {};

    const patch = {};
    if (titre !== undefined) patch.titre = titre;
    if (contenu !== undefined) patch.contenu = contenu;
    if (icone !== undefined) patch.icone = icone;
    if (est_actif !== undefined) patch.est_actif = Boolean(est_actif);
    if (ordre !== undefined && ordre !== null) patch.ordre = Number(ordre);
    if (meta_donnees !== undefined) patch.meta_donnees = meta_donnees;

    if (Object.keys(patch).length === 0) {
      return res.status(400).json({ success: false, message: 'Aucun champ à mettre à jour' });
    }

    const { data, error } = await supabase
      .from('page_a_propos')
      .update(patch)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[PUT /admin/apropos/:id]', error.message);
      return res.status(500).json({ success: false, message: error.message });
    }
    if (!data) {
      return res.status(404).json({ success: false, message: 'Section introuvable' });
    }
    return res.json({ success: true, data });
  } catch (err) {
    console.error('[PUT /admin/apropos/:id]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}
