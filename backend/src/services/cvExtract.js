/**
 * Extraction de texte depuis PDF/DOCX (pour analyse CV)
 * Utilisé pour remplir cv.texte_complet et une extraction simple de compétences
 */
import mammoth from 'mammoth';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const pdfParse = require('pdf-parse');

const MIME_PDF = 'application/pdf';
const MIME_DOCX = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

/**
 * Extrait le texte brut d'un buffer (PDF ou DOCX)
 * @param {Buffer} buffer
 * @param {string} mimeType
 * @returns {Promise<string>}
 */
export async function extractTextFromBuffer(buffer, mimeType) {
  if (!buffer || buffer.length === 0) return '';

  if (mimeType === MIME_PDF) {
    try {
      const data = await pdfParse(buffer);
      return (data?.text || '').trim();
    } catch (err) {
      console.error('pdf-parse error:', err);
      return '';
    }
  }

  if (mimeType === MIME_DOCX) {
    try {
      const result = await mammoth.extractRawText({ buffer });
      return (result?.value || '').trim();
    } catch (err) {
      console.error('mammoth error:', err);
      return '';
    }
  }

  return '';
}

/**
 * Extraction simple de "compétences" à partir du texte (mots-clés, lignes courtes, etc.)
 * À remplacer par un vrai modèle NLP (spaCy, BERT) plus tard.
 * @param {string} text
 * @returns {{ competences: string[], domaine_activite?: string, niveau_experience?: string }}
 */
export function simpleExtractSkills(text) {
  if (!text || typeof text !== 'string') return { competences: [] };

  const lines = text
    .split(/\n|\r/)
    .map((l) => l.trim())
    .filter((l) => l.length > 0);

  const stopWords = new Set(
    ['le', 'la', 'les', 'un', 'une', 'des', 'et', 'ou', 'en', 'au', 'aux', 'du', 'de', 'à', 'pour', 'par', 'avec', 'dans', 'sur', 'je', 'j\'', 'ma', 'mon', 'mes', 'expérience', 'expériences', 'formation', 'compétences', 'langues', 'logiciels', 'logiciel', 'outils', 'outil']
  );

  const words = text
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s\-+]/gu, ' ')
    .split(/\s+/)
    .filter((w) => w.length >= 2 && w.length <= 40 && !stopWords.has(w));

  const skillCandidates = [...new Set(words)].slice(0, 50);
  const competences = skillCandidates.filter((c) => /^[a-zàâäéèêëïîôùûüç0-9+\-]+$/i.test(c));

  return {
    competences: competences.slice(0, 30),
    domaine_activite: null,
    niveau_experience: null,
  };
}
