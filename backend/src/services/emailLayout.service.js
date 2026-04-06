/**
 * Enveloppe HTML des emails transactionnels (admin : template_wrapper + couleur).
 */
import { getMailSettings } from '../config/mailSettings.js';

function htmlEscape(s) {
  return String(s || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function applyTemplateVars(str, vars) {
  let out = String(str || '');
  Object.entries(vars).forEach(([k, v]) => {
    const re = new RegExp(`\\{\\{\\s*${k}\\s*\\}\\}`, 'g');
    out = out.replace(re, v == null ? '' : String(v));
  });
  return out;
}

/**
 * @param {string} innerHtml — fragments HTML sûrs (contrôlés serveur)
 */
export async function buildWrappedEmailHtml(innerHtml) {
  const cfg = await getMailSettings();
  const primary = htmlEscape(cfg.emailCouleurPrimaire || '#1A56DB');
  const nom = htmlEscape(cfg.platformName || 'EmploiConnect');
  const inner = innerHtml || '';
  const wrapperVarsBase = {
    CONTENU: inner,
    contenu: inner,
    content: inner,
    plateforme: nom,
    couleur_primaire: primary,
  };
  let wrapper = String(cfg.emailTemplateWrapperHtml || '').trim();
  if (wrapper && (wrapper.includes('{{CONTENU}}') || wrapper.includes('{{contenu}}'))) {
    return applyTemplateVars(wrapper, wrapperVarsBase);
  }
  if (wrapper && wrapper.includes('{{content}}')) {
    return applyTemplateVars(wrapper, wrapperVarsBase);
  }
  if (wrapper.length > 20) {
    return applyTemplateVars(wrapper, wrapperVarsBase);
  }

  return `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"/></head>
<body style="margin:0;background:#f1f5f9;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="padding:24px 12px;">
<tr><td align="center">
<table role="presentation" width="600" style="max-width:600px;background:#ffffff;border-radius:14px;overflow:hidden;box-shadow:0 4px 24px rgba(15,23,42,.08);">
<tr><td style="background:${primary};padding:22px 26px;color:#ffffff;font-size:20px;font-weight:700;">${nom}</td></tr>
<tr><td style="padding:28px 26px;color:#334155;font-size:15px;line-height:1.6;">${inner}</td></tr>
<tr><td style="padding:18px 26px;background:#f8fafc;color:#64748b;font-size:12px;line-height:1.5;">Cet email a été envoyé par ${nom}. Ne répondez pas directement si l’expéditeur est une adresse technique.</td></tr>
</table>
</td></tr>
</table></body></html>`;
}
