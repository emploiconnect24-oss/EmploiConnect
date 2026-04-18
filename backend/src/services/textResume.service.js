/**
 * Résume un texte « À propos » via Claude si clé disponible (PRD profil).
 */
import { _appellerIA, _getClesIA } from './ia.service.js';

export async function resumerTexteProfil(texte, maxChars = 500) {
  const raw = String(texte || '').trim();
  if (!raw) return '';
  if (raw.length <= maxChars) return raw;

  const cles = await _getClesIA();
  if (!cles.anthropicKey && !cles.openaiKey) {
    return raw.slice(0, maxChars);
  }

  try {
    const prompt =
      `Résume ce texte de profil professionnel en maximum ${maxChars} caractères. `
      + 'Garde l\'essentiel. Réponds UNIQUEMENT avec le résumé, sans guillemets ni explication :\n\n'
      + raw.slice(0, 8000);
    const out = String(await _appellerIA(prompt, cles, 'texte') || '').trim();
    if (out.length > 0) return out.slice(0, maxChars);
  } catch (e) {
    console.warn('[resumerTexteProfil]', e?.message || e);
  }
  return raw.slice(0, maxChars);
}
