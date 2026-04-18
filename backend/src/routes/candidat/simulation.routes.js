import { Router } from 'express';
import { supabase } from '../../config/supabase.js';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { ROLES } from '../../config/constants.js';
import {
  genererPremierMessage,
  genererProchainMessage,
  genererRapportFinal,
} from '../../services/simulationEntretien.service.js';

const router = Router();

router.use(authenticate);
router.use(requireRole(ROLES.CHERCHEUR));

async function chargerProfilSimulation(candidatId, posteVise, domaine) {
  const selectLarge = `
    titre_profil, titre_poste, competences, niveau_etudes,
    experience_annees, experiences, domaine_activite,
    langues, objectif_professionnel, cv_analyse,
    about, utilisateur:utilisateurs(nom, email)
  `;
  const { data: profilLarge, error: errLarge } = await supabase
    .from('chercheurs_emploi')
    .select(selectLarge)
    .or(`utilisateur_id.eq.${candidatId},id.eq.${candidatId}`)
    .maybeSingle();

  const profil = errLarge ? null : profilLarge;
  return {
    nom: profil?.utilisateur?.nom || 'Candidat',
    titre_profil: profil?.titre_profil || profil?.titre_poste || posteVise,
    competences: Array.isArray(profil?.competences) ? profil.competences : [],
    experience_annees: Number.isFinite(Number(profil?.experience_annees))
      ? Number(profil?.experience_annees)
      : estimerAnneesExperience(profil?.experiences),
    domaine_activite: profil?.domaine_activite || domaine || profil?.about || '',
    niveau_etudes: profil?.niveau_etudes || '',
    langues: Array.isArray(profil?.langues) ? profil.langues : [],
    objectif: profil?.objectif_professionnel || '',
  };
}

function estimerAnneesExperience(experiences) {
  if (!Array.isArray(experiences) || experiences.length === 0) return 0;
  let nb = 0;
  for (const exp of experiences) {
    const debut = new Date(exp?.date_debut || exp?.debut || exp?.start_date || 0);
    const fin = exp?.en_cours ? new Date() : new Date(exp?.date_fin || exp?.fin || exp?.end_date || Date.now());
    if (!Number.isNaN(debut.getTime()) && !Number.isNaN(fin.getTime()) && fin > debut) {
      nb += (fin.getTime() - debut.getTime()) / (365.25 * 24 * 3600 * 1000);
    }
  }
  return Math.max(0, Math.round(nb));
}

router.post('/demarrer', async (req, res) => {
  try {
    const {
      poste_vise: posteVise, domaine, niveau, recruteur = {},
    } = req.body || {};
    const candidatId = req.user.id;

    if (!posteVise) {
      return res.status(400).json({ success: false, message: 'Poste visé requis' });
    }

    const profilComplet = await chargerProfilSimulation(candidatId, posteVise, domaine);

    const messageAccueil = await genererPremierMessage(posteVise, profilComplet, recruteur);
    const now = new Date().toISOString();

    const { data: session, error: insertError } = await supabase
      .from('simulation_sessions')
      .insert({
        candidat_id: candidatId,
        poste_vise: posteVise,
        domaine: domaine || profilComplet.domaine_activite,
        niveau: niveau || 'junior',
        statut: 'en_cours',
        messages: [{ role: 'recruteur', contenu: messageAccueil, timestamp: now }],
        nb_questions: 0,
      })
      .select('*')
      .single();

    if (insertError) throw insertError;

    return res.json({
      success: true,
      data: {
        session_id: session.id,
        message_accueil: messageAccueil,
        profil: profilComplet,
        recruteur,
      },
    });
  } catch (err) {
    console.error('[simulation/demarrer]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

router.post('/:id/repondre', async (req, res) => {
  try {
    const { reponse_candidat: reponseCandidat, recruteur = {} } = req.body || {};
    const sessionId = req.params.id;
    if (!reponseCandidat || !String(reponseCandidat).trim()) {
      return res.status(400).json({ success: false, message: 'Réponse candidat requise' });
    }

    const { data: session, error: sessionError } = await supabase
      .from('simulation_sessions')
      .select('*')
      .eq('id', sessionId)
      .maybeSingle();
    if (sessionError) throw sessionError;

    if (!session || session.statut !== 'en_cours' || session.candidat_id !== req.user.id) {
      return res.status(400).json({ success: false, message: 'Session invalide ou terminée' });
    }

    const profilComplet = await chargerProfilSimulation(req.user.id, session.poste_vise, session.domaine);

    const historique = [
      ...(Array.isArray(session.messages) ? session.messages : []),
      { role: 'candidat', contenu: String(reponseCandidat).trim(), timestamp: new Date().toISOString() },
    ];

    const nbQuestions = Number(session.nb_questions || 0) + 1;
    const { message, estFin } = await genererProchainMessage(
      historique,
      session.poste_vise,
      {
        nom: profilComplet.nom || req.user.nom || 'Candidat',
        titre_profil: profilComplet.titre_profil || session.poste_vise,
        competences: profilComplet.competences || [],
        experience_annees: profilComplet.experience_annees || 0,
        domaine_activite: profilComplet.domaine_activite || session.domaine,
        niveau_etudes: profilComplet.niveau_etudes || '',
        langues: profilComplet.langues || [],
        objectif: profilComplet.objectif || '',
      },
      nbQuestions,
      recruteur,
    );

    const historiqueComplet = [
      ...historique,
      { role: 'recruteur', contenu: message, timestamp: new Date().toISOString() },
    ];

    let rapportFinal = null;
    let scoreGlobal = null;
    if (estFin) {
      rapportFinal = await genererRapportFinal(historiqueComplet, session.poste_vise, profilComplet || {}, {
        recruteur,
        nbQuestions,
        entretienCourt: nbQuestions < 5,
      });
      scoreGlobal = Number(rapportFinal?.score_global ?? 0) || null;
    }

    const createdAt = new Date(session.created_at);
    const dureeSecondes = Number.isNaN(createdAt.getTime())
      ? null
      : Math.max(0, Math.round((Date.now() - createdAt.getTime()) / 1000));

    const { error: updateError } = await supabase
      .from('simulation_sessions')
      .update({
        messages: historiqueComplet,
        nb_questions: nbQuestions,
        statut: estFin ? 'termine' : 'en_cours',
        score_final: scoreGlobal,
        rapport_ia: rapportFinal,
        duree_secondes: estFin ? dureeSecondes : session.duree_secondes,
        termine_le: estFin ? new Date().toISOString() : null,
      })
      .eq('id', sessionId);
    if (updateError) throw updateError;

    return res.json({
      success: true,
      data: {
        message_recruteur: message,
        est_fin: estFin,
        rapport: rapportFinal,
        score: scoreGlobal,
        nb_questions: nbQuestions,
      },
    });
  } catch (err) {
    console.error('[simulation/repondre]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

router.get('/historique', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('simulation_sessions')
      .select('id, poste_vise, domaine, niveau, statut, score_final, nb_questions, duree_secondes, created_at, termine_le')
      .eq('candidat_id', req.user.id)
      .order('created_at', { ascending: false })
      .limit(20);
    if (error) throw error;
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    console.error('[simulation/historique]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

export default router;
