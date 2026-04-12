/**
 * Tests isolés Claude / OpenAI (texte) et DALL-E (image) — admin uniquement.
 */
import { _getClesIA, _appellerProviderSpecifique } from '../../services/ia.service.js';

export async function postTestIa(req, res) {
  try {
    const provider = String(req.body?.provider || '').toLowerCase();
    if (!['anthropic', 'openai'].includes(provider)) {
      return res.status(400).json({
        success: false,
        message: 'Provider invalide (utilisez anthropic ou openai)',
      });
    }

    const cles = await _getClesIA();
    const prompt = 'Réponds uniquement par le mot OK, sans autre texte.';
    const resultat = await _appellerProviderSpecifique(prompt, cles, provider, 'texte');

    if (!resultat) {
      return res.json({
        success: false,
        provider,
        message: `Provider ${provider} indisponible, clé absente ou erreur API`,
      });
    }

    return res.json({
      success: true,
      provider,
      reponse: resultat.substring(0, 80),
      message: `${provider} fonctionne correctement`,
    });
  } catch (err) {
    return res.json({
      success: false,
      provider: req.body?.provider,
      message: err?.message || String(err),
    });
  }
}

export async function postTestDalle(req, res) {
  try {
    const cles = await _getClesIA();
    if (!cles.openaiKey) {
      return res.json({
        success: false,
        message: 'Clé OpenAI non configurée',
      });
    }

    const response = await fetch('https://api.openai.com/v1/images/generations', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${cles.openaiKey}`,
      },
      body: JSON.stringify({
        model: 'dall-e-2',
        prompt: 'Minimal flat company logo icon, single color',
        n: 1,
        size: '256x256',
      }),
    });

    const data = await response.json();

    if (data?.error) {
      return res.json({
        success: false,
        message: data.error.message || 'Erreur OpenAI images',
      });
    }

    if (!response.ok) {
      return res.json({
        success: false,
        message: `HTTP ${response.status}`,
      });
    }

    return res.json({
      success: true,
      message: 'DALL-E opérationnel (test image 256×256, dall-e-2).',
      test_url: data.data?.[0]?.url,
    });
  } catch (err) {
    return res.json({
      success: false,
      message: err?.message || String(err),
    });
  }
}
