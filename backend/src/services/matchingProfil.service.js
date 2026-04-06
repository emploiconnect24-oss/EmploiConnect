import { supabase } from '../config/supabase.js';

function estimerAnneesExperience(niveau) {
  const map = {
    sans_experience: 0,
    debutant: 1,
    junior: 1,
    '1_2_ans': 1.5,
    '3_5_ans': 4,
    '5_10_ans': 7,
    '10_ans_plus': 12,
  };
  return map[String(niveau)] || 0;
}

/**
 * Profil candidat pour calculerMatchingScore — même structure partout (liste offres, matching, suggestions).
 */
export async function loadProfilMatchingPourChercheur(chercheurId) {
  const { data: chercheur } = await supabase
    .from('chercheurs_emploi')
    .select('id, competences, niveau_etude, utilisateurs(adresse)')
    .eq('id', chercheurId)
    .single();

  if (!chercheur) return null;

  const { data: cv } = await supabase
    .from('cv')
    .select('competences_extrait, texte_complet, niveau_experience')
    .eq('chercheur_id', chercheur.id)
    .maybeSingle();

  const compCv = Array.isArray(cv?.competences_extrait?.competences)
    ? cv.competences_extrait.competences
    : [];
  const compProfil = Array.isArray(chercheur.competences)
    ? chercheur.competences
    : Object.values(chercheur.competences || {});

  return {
    chercheurId: chercheur.id,
    profil: {
      titre: cv?.niveau_experience || chercheur.niveau_etude || '',
      competences: [...compCv, ...compProfil],
      experience: cv?.competences_extrait?.experience || [],
      formation: cv?.competences_extrait?.formation || [],
      texte_cv: cv?.texte_complet || '',
      ville: chercheur.utilisateurs?.adresse || '',
      annees_experience: estimerAnneesExperience(cv?.niveau_experience),
    },
  };
}
