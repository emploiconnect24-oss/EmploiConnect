import crypto from 'crypto';
import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import { requireRecruteur } from '../../middleware/recruteurAuth.js';
import { supabase } from '../../config/supabase.js';
import { calculerMatchingScore } from '../../services/ia.service.js';
import { sendNewMessageEmail } from '../../services/mail.service.js';

const router = Router();
router.use(authenticate, requireRecruteur);

router.get('/', async (req, res) => {
  try {
    const { recherche, niveau_etude: niveauEtude, disponibilite, ville, offre_id: offreId, page = 1, limite = 20 } = req.query;
    console.log('[recruteur/talents] Recherche:', recherche, '| offre_id:', offreId);
    let query = supabase
      .from('chercheurs_emploi')
      .select(`
        id, competences, niveau_etude, disponibilite, genre, utilisateur_id,
        utilisateur:utilisateur_id (
          id, nom, email, photo_url, adresse, est_actif, est_valide, date_creation
        )
      `, { count: 'exact' })
      .range((parseInt(page, 10) - 1) * parseInt(limite, 10), parseInt(page, 10) * parseInt(limite, 10) - 1);
    if (niveauEtude) query = query.eq('niveau_etude', niveauEtude);
    if (disponibilite) query = query.eq('disponibilite', disponibilite);
    const { data: talents, count, error } = await query;
    if (error) throw error;
    let resultats = (talents || []).filter(
      (c) => c.utilisateur?.est_actif === true && c.utilisateur?.est_valide === true,
    );
    if (recherche) {
      const r = String(recherche).toLowerCase();
      resultats = resultats.filter((t) => {
        const comps = Array.isArray(t.competences) ? t.competences : Object.values(t.competences || {});
        return t.utilisateur?.nom?.toLowerCase().includes(r)
          || comps.some((c) => String(c).toLowerCase().includes(r));
      });
    }
    if (ville) {
      resultats = resultats.filter((t) => (
        t.utilisateur?.adresse?.toLowerCase().includes(String(ville).toLowerCase())
      ));
    }

    const chercheurIds = resultats.map((t) => t.id);
    const cvMap = {};
    if (chercheurIds.length > 0) {
      const { data: cvs } = await supabase
        .from('cv')
        .select('chercheur_id, fichier_url, nom_fichier, competences_extrait, niveau_experience')
        .in('chercheur_id', chercheurIds);
      (cvs || []).forEach((cv) => { cvMap[cv.chercheur_id] = cv; });
    }

    if (offreId) {
      const { data: offre } = await supabase
        .from('offres_emploi')
        .select('id, titre, description, exigences, competences_requises, localisation, niveau_experience_requis, entreprise_id')
        .eq('id', offreId)
        .eq('entreprise_id', req.entreprise.id)
        .single();
      if (offre) {
        resultats = await Promise.all(resultats.map(async (talent) => {
          const cv = cvMap[talent.id];
          const compsProfil = Array.isArray(talent.competences) ? talent.competences : Object.values(talent.competences || {});
          const compsCv = cv?.competences_extrait?.competences || [];
          return {
            ...talent,
            cv: cv ? {
              fichier_url: cv.fichier_url,
              nom_fichier: cv.nom_fichier,
              niveau_experience: cv.niveau_experience,
              competences_extrait: cv.competences_extrait,
            } : null,
            toutes_competences: [...new Set([...compsProfil, ...compsCv])],
            score_matching: await calculerMatchingScore({ competences: [...compsProfil, ...compsCv] }, offre),
          };
        }));
        resultats.sort((a, b) => (b.score_matching || 0) - (a.score_matching || 0));
      }
    }
    console.log('[talents] Retournes:', resultats.length);
    return res.json({ success: true, data: { talents: resultats, pagination: { total: count || 0 } } });
  } catch (err) {
    console.error('[recruteur/talents]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.post('/contacter', async (req, res) => {
  try {
    const { talent_utilisateur_id: talentId, message, offre_id: offreId } = req.body || {};
    if (!talentId || !message) return res.status(400).json({ success: false, message: 'talent_utilisateur_id et message requis' });
    const conversationId = crypto.createHash('md5').update([req.user.id, talentId].sort().join('-')).digest('hex');
    const { data: newMsg } = await supabase
      .from('messages')
      .insert({
        conversation_id: conversationId,
        expediteur_id: req.user.id,
        destinataire_id: talentId,
        contenu: String(message).trim(),
        offre_id: offreId || null,
      })
      .select()
      .single();
    await supabase.from('notifications').insert({
      destinataire_id: talentId,
      type_destinataire: 'individuel',
      titre: `💼 ${req.entreprise.nom_entreprise} vous a contacté`,
      message: String(message).trim().slice(0, 100),
      type: 'message',
      lien: '/dashboard/messages',
    });
    void sendNewMessageEmail(talentId, {
      senderLabel: `${req.entreprise.nom_entreprise} vous contacte`,
      excerpt: String(message).trim(),
      lienLibelle:
          'Consultez la messagerie dans votre espace candidat pour répondre.',
    });
    return res.status(201).json({ success: true, data: newMsg });
  } catch (err) {
    console.error('[recruteur/talents/contacter]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;

