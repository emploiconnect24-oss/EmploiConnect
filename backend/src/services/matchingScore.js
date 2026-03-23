/**
 * Construit un résumé texte du CV pour la similarité sémantique
 */
function cvToSummary(cv) {
  const parts = [];
  if (Array.isArray(cv.competences_extrait) && cv.competences_extrait.length) {
    parts.push(cv.competences_extrait.join(', '));
  }
  if (cv.texte_complet) {
    parts.push(cv.texte_complet.slice(0, 3000));
  }
  return parts.join('\n\n').trim() || '';
}

/**
 * Construit un résumé texte de l'offre pour la similarité sémantique
 */
function offreToSummary(offre) {
  const parts = [];
  if (offre.exigences) parts.push(offre.exigences);
  if (Array.isArray(offre.competences_requises) && offre.competences_requises.length) {
    parts.push(offre.competences_requises.join(', '));
  }
  return parts.join('\n\n').trim() || '';
}

/**
 * Score de compatibilité avec NLP externe (RapidAPI) si disponible, sinon recoupement local.
 * @param {{ competences_extrait?: string[] | null, texte_complet?: string | null }} cv
 * @param {{ exigences?: string, competences_requises?: string[] | null }} offre
 * @returns {Promise<number>} Score 0-100
 */
export async function computeMatchingScoreAsync(cv, offre) {
  const { getTextSimilarityScore } = await import('./nlpRapidApi.js');
  const cvSummary = cvToSummary(cv);
  const offerSummary = offreToSummary(offre);
  if (cvSummary && offerSummary) {
    const semantic = await getTextSimilarityScore(cvSummary, offerSummary);
    if (typeof semantic === 'number') {
      return Math.round(Math.min(100, Math.max(0, semantic * 100)));
    }
  }
  return computeMatchingScore(cv, offre);
}

/**
 * Calcul simple du score de compatibilité candidat / offre (recoupement de termes)
 * Utilisé en fallback si l'API NLP n'est pas configurée ou en erreur.
 * @param {{ competences_extrait?: string[] | null, texte_complet?: string | null }} cv
 * @param {{ exigences?: string, competences_requises?: string[] | null }} offre
 * @returns {number} Score 0-100
 */
export function computeMatchingScore(cv, offre) {
  const cvSkills = new Set();
  if (Array.isArray(cv.competences_extrait)) {
    cv.competences_extrait.forEach((s) => cvSkills.add(String(s).toLowerCase().trim()));
  }
  if (cv.texte_complet) {
    const words = cv.texte_complet
      .toLowerCase()
      .replace(/[^\p{L}\p{N}\s]/gu, ' ')
      .split(/\s+/)
      .filter((w) => w.length >= 3);
    words.forEach((w) => cvSkills.add(w));
  }

  const offerTerms = new Set();
  if (offre.competences_requises && Array.isArray(offre.competences_requises)) {
    offre.competences_requises.forEach((s) => offerTerms.add(String(s).toLowerCase().trim()));
  }
  if (offre.exigences) {
    offre.exigences
      .toLowerCase()
      .replace(/[^\p{L}\p{N}\s]/gu, ' ')
      .split(/\s+/)
      .filter((w) => w.length >= 3)
      .forEach((w) => offerTerms.add(w));
  }

  if (offerTerms.size === 0) return 50;

  let match = 0;
  for (const term of offerTerms) {
    if (cvSkills.has(term)) match++;
    else {
      for (const skill of cvSkills) {
        if (skill.includes(term) || term.includes(skill)) {
          match++;
          break;
        }
      }
    }
  }

  const ratio = match / offerTerms.size;
  const score = Math.round(Math.min(100, Math.max(0, ratio * 100)));
  return score;
}
