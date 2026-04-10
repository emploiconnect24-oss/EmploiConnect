/**
 * Résume un texte « À propos » via Claude si clé disponible (PRD profil).
 */
export async function resumerTexteProfil(texte, maxChars = 500) {
  const raw = String(texte || '').trim();
  if (!raw) return '';
  if (raw.length <= maxChars) return raw;

  const anthropicKey = String(process.env.ANTHROPIC_API_KEY || '').trim();
  if (!anthropicKey) {
    return raw.slice(0, maxChars);
  }

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-3-5-haiku-latest',
        max_tokens: 220,
        messages: [{
          role: 'user',
          content:
            `Résume ce texte de profil professionnel en maximum ${maxChars} caractères. `
            + 'Garde l\'essentiel. Réponds UNIQUEMENT avec le résumé, sans guillemets ni explication :\n\n'
            + raw.slice(0, 8000),
        }],
      }),
    });
    const data = await response.json();
    const out = String(data?.content?.[0]?.text || '').trim();
    if (out.length > 0) return out.slice(0, maxChars);
  } catch (e) {
    console.warn('[resumerTexteProfil]', e?.message || e);
  }
  return raw.slice(0, maxChars);
}
