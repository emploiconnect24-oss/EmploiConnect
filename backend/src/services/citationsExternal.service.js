/**
 * Citations externes pour le tableau de bord candidat (paramètres admin).
 * ZenQuotes et Quotable : pas de clé API. URL custom : JSON simple uniquement.
 */
import axios from 'axios';

const BUILTIN_URLS = {
  zenquotes: 'https://zenquotes.io/api/random',
  quotable: 'https://api.quotable.io/random',
};

const MAX_LEN = 420;

function isUrlSafeForFetch(urlStr) {
  try {
    const u = new URL(urlStr);
    if (u.protocol !== 'http:' && u.protocol !== 'https:') return false;
    const h = u.hostname.toLowerCase();
    if (h === 'localhost' || h === '127.0.0.1' || h === '0.0.0.0') return false;
    if (h.endsWith('.local')) return false;
    if (/^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/.test(h)) return false;
    return true;
  } catch {
    return false;
  }
}

function parseCitationPayload(data) {
  if (data == null) return null;

  if (Array.isArray(data) && data.length && typeof data[0] === 'object') {
    const q = String(data[0].q ?? data[0].quote ?? data[0].text ?? '').trim();
    const a = String(data[0].a ?? data[0].author ?? '').trim();
    if (!q) return null;
    return a ? `${q} — ${a}` : q;
  }

  if (typeof data === 'object') {
    const q = String(data.content ?? data.quote ?? data.text ?? data.message ?? '').trim();
    const a = String(data.author ?? '').trim();
    if (q) return a ? `${q} — ${a}` : q;
  }

  return null;
}

/**
 * @param {string} source - zenquotes | quotable | custom
 * @param {string} customUrl - requis si source === custom
 * @returns {Promise<string|null>}
 */
export async function fetchCitationExterne(source, customUrl) {
  const src = String(source || '').toLowerCase().trim();
  let url;

  if (src === 'custom') {
    url = String(customUrl || '').trim();
    if (!url || !isUrlSafeForFetch(url)) return null;
  } else if (BUILTIN_URLS[src]) {
    url = BUILTIN_URLS[src];
  } else {
    return null;
  }

  try {
    const res = await axios.get(url, {
      timeout: 4500,
      maxRedirects: 3,
      validateStatus: (s) => s >= 200 && s < 400,
      headers: {
        Accept: 'application/json',
        'User-Agent': 'EmploiConnect/1.0 (citations-dashboard)',
      },
    });

    if (res.status !== 200 || res.data == null) return null;

    let text = parseCitationPayload(res.data);
    if (!text) return null;
    text = text.replace(/\s+/g, ' ').trim();
    if (text.length > MAX_LEN) text = `${text.slice(0, MAX_LEN - 1)}…`;
    return text;
  } catch {
    return null;
  }
}
