/**
 * Configuration RapidAPI (optionnelle)
 * Si RAPIDAPI_KEY est défini, les services NLP utilisent les APIs externes.
 * Sinon, le backend utilise l'extraction locale et le score par recoupement de termes.
 *
 * Obtenir une clé gratuite : https://rapidapi.com/ → s'inscrire → souscrire à l'API (plan gratuit)
 */
export const RAPIDAPI_KEY = process.env.RAPIDAPI_KEY || '';

/** Host RapidAPI pour la similarité texte (ex: twinword-text-similarity.p.rapidapi.com) */
export const RAPIDAPI_SIMILARITY_HOST =
  process.env.RAPIDAPI_SIMILARITY_HOST || 'twinword-text-similarity.p.rapidapi.com';

/** Host RapidAPI pour le parsing de CV (ex: resumeparser-api.p.rapidapi.com) */
export const RAPIDAPI_RESUME_PARSER_HOST =
  process.env.RAPIDAPI_RESUME_PARSER_HOST || 'resumeparser-api.p.rapidapi.com';

export const isNlpApiEnabled = () => Boolean(RAPIDAPI_KEY && RAPIDAPI_KEY.length > 0);
