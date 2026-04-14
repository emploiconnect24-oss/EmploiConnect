import { supabase } from '../config/supabase.js';
import { _appellerIA, _getClesIA } from './ia.service.js';
import { getMailSettings } from '../config/mailSettings.js';
import { buildWrappedEmailHtml } from './emailLayout.service.js';
import { sendPlatformEmail } from './mail.service.js';

function boolTrue(v) {
  return String(v ?? '').toLowerCase() === 'true';
}

function safeJsonParse(raw) {
  try {
    return JSON.parse(String(raw || '').trim());
  } catch {
    return null;
  }
}

function normalizeHtml(txt) {
  return String(txt || '').replace(/<script[\s\S]*?>[\s\S]*?<\/script>/gi, '').trim();
}

function publicAppUrl(cfg) {
  return String(cfg?.publicAppUrl || '').trim().replace(/\/$/, '') || 'http://localhost:8080';
}

async function getNewsletterIaConfig() {
  const { data } = await supabase
    .from('parametres_plateforme')
    .select('cle, valeur')
    .in('cle', [
      'newsletter_ia_actif',
      'newsletter_ia_seuil_offres',
      'newsletter_ia_dernier_envoi',
    ]);
  const c = {};
  for (const p of data || []) c[p.cle] = p.valeur;
  return {
    actif: boolTrue(c.newsletter_ia_actif),
    seuil: Number.parseInt(String(c.newsletter_ia_seuil_offres || '3'), 10) || 3,
    dernierEnvoi: String(c.newsletter_ia_dernier_envoi || '').trim(),
  };
}

function mapOffre(o) {
  return {
    titre: o?.titre || '',
    entreprise: o?.entreprise?.nom_entreprise || o?.entreprises?.nom_entreprise || 'Entreprise',
    localisation: o?.localisation || 'Guinée',
    type_contrat: o?.type_contrat || '',
  };
}

async function getContexteComplet() {
  try {
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const [
      offresRes,
      candidatsRes,
      partenairesRes,
      topEntreprisesRes,
      featureRes,
    ] = await Promise.all([
      supabase
        .from('offres_emploi')
        .select(`
          titre,
          localisation,
          type_contrat,
          entreprise:entreprises(nom_entreprise)
        `)
        .eq('statut', 'publiee')
        .gte('date_publication', since)
        .order('date_publication', { ascending: false })
        .limit(8),
      supabase.from('chercheurs_emploi').select('*', { count: 'exact', head: true }),
      supabase
        .from('entreprises')
        .select('nom_entreprise, secteur_activite')
        .eq('statut_validation', 'validee')
        .gte('created_at', since)
        .order('created_at', { ascending: false })
        .limit(3),
      supabase
        .from('offres_emploi')
        .select('entreprise:entreprises(nom_entreprise)')
        .eq('statut', 'publiee')
        .order('date_publication', { ascending: false })
        .limit(5),
      supabase
        .from('parametres_plateforme')
        .select('valeur')
        .eq('cle', 'newsletter_feature_semaine')
        .maybeSingle(),
    ]);

    const nouvellesOffres = (offresRes.data || []).map(mapOffre);
    const nouveauxPartenaires = (partenairesRes.data || []).map((p) => ({
      nom_entreprise: p.nom_entreprise || '',
      secteur_activite: p.secteur_activite || '',
    }));
    const topEntreprises = (topEntreprisesRes.data || [])
      .map((x) => x.entreprise?.nom_entreprise || '')
      .filter(Boolean);
    return {
      nouvelles_offres: nouvellesOffres,
      nb_offres: nouvellesOffres.length,
      nb_candidats: candidatsRes.count || 0,
      nouveaux_partenaires: nouveauxPartenaires,
      top_entreprises: [...new Set(topEntreprises)].slice(0, 5),
      feature_semaine: String(featureRes.data?.valeur || '').trim(),
    };
  } catch (e) {
    console.error('[newsletterIA] contexte:', e?.message || e);
    return {
      nouvelles_offres: [],
      nb_offres: 0,
      nb_candidats: 0,
      nouveaux_partenaires: [],
      top_entreprises: [],
      feature_semaine: '',
    };
  }
}

function extractJsonObject(raw) {
  const t = String(raw || '').trim();
  const start = t.indexOf('{');
  const end = t.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) return null;
  return t.slice(start, end + 1);
}

function toNewsletterPayload(aiText, fallbackSujet = 'Nouvelles opportunités EmploiConnect') {
  const cleaned = String(aiText || '')
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .trim();
  const extracted = extractJsonObject(cleaned) || cleaned;
  const parsed = safeJsonParse(extracted);
  if (!parsed || typeof parsed !== 'object') {
    return {
      sujet: fallbackSujet,
      titre_principal: 'Opportunités et conseils de la semaine',
      introduction: 'Découvrez les dernières nouvelles sur EmploiConnect.',
      corps: 'Nouvelles offres, conseils carrière et outils IA vous attendent.',
      corps_offres: '',
      conseil_semaine: '',
      focus_ia: '',
      corps_partenaires: '',
      conclusion: 'Bonne exploration et bonnes candidatures.',
      cta_texte: 'Voir les offres',
      cta_lien: '/#/public/offres',
    };
  }
  return {
    sujet: String(parsed.sujet || fallbackSujet).slice(0, 200),
    titre_principal: String(parsed.titre_principal || 'Opportunités et conseils de la semaine'),
    introduction: String(parsed.introduction || ''),
    corps: String(parsed.corps || ''),
    corps_offres: String(parsed.corps_offres || ''),
    conseil_semaine: String(parsed.conseil_semaine || ''),
    focus_ia: String(parsed.focus_ia || ''),
    corps_partenaires: String(parsed.corps_partenaires || ''),
    conclusion: String(parsed.conclusion || ''),
    cta_texte: String(parsed.cta_texte || 'Voir les offres'),
    cta_lien: String(parsed.cta_lien || '/#/public/offres'),
  };
}

async function buildPrompt(declencheur, ctx) {
  let promptBase = 'Tu es le responsable communication d\'EmploiConnect, plateforme emploi Guinee. Base-toi uniquement sur les donnees reelles de la plateforme.';
  try {
    const { data } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'newsletter_prompt_base')
      .maybeSingle();
    if (String(data?.valeur || '').trim()) promptBase = String(data.valeur).trim();
  } catch (_) {
    // Fallback silencieux vers le prompt par defaut.
  }

  const donneesReelles = `
DONNEES REELLES DE LA PLATEFORME (ne pas inventer) :
- Nouvelles offres cette semaine : ${ctx.nb_offres}
${ctx.nouvelles_offres.slice(0, 5).map((o) => `  • "${o.titre}" chez ${o.entreprise} (${o.localisation} · ${o.type_contrat})`).join('\n')}
- Candidats inscrits : ${ctx.nb_candidats}
- Nouveaux partenaires : ${ctx.nouveaux_partenaires.length ? ctx.nouveaux_partenaires.map((p) => p.nom_entreprise).join(', ') : 'Aucun cette semaine'}
${ctx.feature_semaine ? `- Feature de la semaine : ${ctx.feature_semaine}` : ''}`;

  const offresList = ctx.nouvelles_offres
    .slice(0, 5)
    .map((o) => `• ${o.titre} chez ${o.entreprise} (${o.localisation} · ${o.type_contrat})`)
    .join('\n') || '(Aucune nouvelle offre cette semaine)';

  const partenairesList = ctx.nouveaux_partenaires.length
    ? ctx.nouveaux_partenaires.map((p) => `• ${p.nom_entreprise}`).join('\n')
    : '';

  const featureBloc = ctx.feature_semaine
    ? `\nFonctionnalité à mettre en avant : ${ctx.feature_semaine}`
    : '';

  if (declencheur === 'nouvelles_offres') {
    return `${promptBase}

${donneesReelles}

NOUVELLES OFFRES CETTE SEMAINE :
${offresList}

Rédige une newsletter courte et percutante axée sur ces nouvelles opportunités d'emploi.
Inclure 1 conseil rapide de recherche d'emploi.
Ton : dynamique, encourageant.
Maximum 150 mots dans le corps.
IMPORTANT : Ne mentionner que les offres listées et ne rien inventer.

JSON :
{
  "sujet": "...(max 60 chars)",
  "titre_principal": "...",
  "introduction": "...",
  "corps": "...",
  "conseil_semaine": "...(1 phrase max)",
  "conclusion": "...",
  "cta_texte": "Voir les offres",
  "cta_lien": "/#/public/offres"
}`;
  }

  if (declencheur === 'hebdomadaire') {
    return `${promptBase}

${donneesReelles}

DONNÉES DE LA SEMAINE :
- Nouvelles offres : ${ctx.nb_offres}
${offresList}
${partenairesList ? `\nNOUVEAUX PARTENAIRES :\n${partenairesList}` : ''}
- Candidats inscrits : ${ctx.nb_candidats}
${featureBloc}

Rédige une newsletter hebdomadaire complète avec :
1. Un résumé des nouvelles offres
2. Un conseil carrière pertinent pour le marché guinéen
3. Un rappel des outils IA disponibles sur la plateforme
   (simulateur entretien, calculateur salaire, matching IA)
${ctx.nouveaux_partenaires.length ? '4. Mention des nouveaux partenaires' : ''}
${ctx.feature_semaine ? '5. Focus sur la fonctionnalité de la semaine' : ''}

Ton : professionnel, chaleureux, inspirant.
Adapté au contexte guinéen/africain.
Maximum 250 mots dans le corps.
IMPORTANT : Donnees reelles uniquement, ne pas inventer.

JSON :
{
  "sujet": "...(max 60 chars, accrocheur)",
  "titre_principal": "...",
  "introduction": "...",
  "corps_offres": "...",
  "conseil_semaine": "...",
  "focus_ia": "...(1-2 phrases sur les outils IA)",
  "corps_partenaires": "${ctx.nouveaux_partenaires.length ? '...' : ''}",
  "conclusion": "...",
  "cta_texte": "Découvrir les offres",
  "cta_lien": "/#/public/offres"
}`;
  }

  const contexteAdmin = String(ctx.contexte_libre || '').trim()
    || 'Genere une newsletter engageante sur l\'actualite de la plateforme.';
  return `${promptBase}

${donneesReelles}

INSTRUCTIONS SPECIFIQUES DE L'ADMINISTRATEUR :
${contexteAdmin}

Contexte plateforme :
- Offres actives : ${ctx.nb_offres}
- Candidats : ${ctx.nb_candidats}

IMPORTANT : Base-toi uniquement sur les donnees reelles listees ci-dessus. Ne pas inventer.
Maximum 200 mots dans le corps.

JSON :
{
  "sujet": "...(max 60 chars)",
  "titre_principal": "...",
  "introduction": "...",
  "corps": "...",
  "conseil_semaine": "...",
  "conclusion": "...",
  "cta_texte": "Explorer la plateforme",
  "cta_lien": "/"
}`;
}

function buildHtmlNewsletter(newsletter, ctx, ab, declencheur, appUrl) {
  const offresHtml = ctx.nouvelles_offres.slice(0, 4)
    .map((o) => `
      <div style="background:#F8FAFC; border-radius:8px;
                  padding:12px; margin:8px 0;
                  border-left:3px solid #1A56DB;">
        <strong style="color:#0F172A;">${o.titre}</strong>
        <span style="color:#64748B;"> · ${o.entreprise}</span>
        <br/>
        <small style="color:#94A3B8;">
          📍 ${o.localisation} · 💼 ${o.type_contrat}
        </small>
      </div>`).join('');

  const conseilHtml = newsletter.conseil_semaine ? `
    <div style="background:linear-gradient(135deg,#EFF6FF,#F5F3FF);
                border-radius:8px; padding:16px; margin:16px 0;
                border:1px solid #DBEAFE;">
      <h3 style="color:#1A56DB; margin:0 0 8px;
                 font-size:14px;">💡 Conseil de la semaine</h3>
      <p style="color:#374151; margin:0; font-size:13px;
                line-height:1.6;">
        ${newsletter.conseil_semaine}
      </p>
    </div>` : '';

  const iaHtml = newsletter.focus_ia ? `
    <div style="background:linear-gradient(135deg,#F5F3FF,#EFF6FF);
                border-radius:8px; padding:16px; margin:16px 0;
                border:1px solid #E9D5FF;">
      <h3 style="color:#7C3AED; margin:0 0 8px;
                 font-size:14px;">✨ Outils IA disponibles</h3>
      <p style="color:#374151; margin:0; font-size:13px;
                line-height:1.6;">
        ${newsletter.focus_ia}
      </p>
    </div>` : '';

  const partenairesHtml = ctx.nouveaux_partenaires.length
    && declencheur === 'hebdomadaire' ? `
    <div style="background:#F0FFF4; border-radius:8px;
                padding:16px; margin:16px 0;
                border:1px solid #BBF7D0;">
      <h3 style="color:#10B981; margin:0 0 8px;
                 font-size:14px;">🤝 Nouveaux partenaires</h3>
      ${ctx.nouveaux_partenaires.map((p) =>
        `<p style="color:#374151; margin:4px 0;
                   font-size:13px;">• ${p.nom_entreprise}</p>`
      ).join('')}
    </div>` : '';

  const ctaHref = newsletter.cta_lien?.startsWith('http')
    ? newsletter.cta_lien
    : `${appUrl}${newsletter.cta_lien || '/#/public/offres'}`;

  return `
    <div style="font-family:Arial,sans-serif;
                max-width:600px; margin:0 auto;">

      <div style="background:linear-gradient(
                    135deg,#1A56DB,#7C3AED);
                  padding:28px; border-radius:12px 12px 0 0;
                  text-align:center;">
        <h1 style="color:white; margin:0; font-size:26px;
                    font-weight:900;">EmploiConnect</h1>
        <p style="color:rgba(255,255,255,0.8);
                  margin:6px 0 0; font-size:13px;">
          🇬🇳 Guinée · Plateforme d'emploi intelligente
        </p>
      </div>

      <div style="background:white; padding:28px;
                  border:1px solid #E2E8F0;
                  border-top:none;">
        <h2 style="color:#0F172A; font-size:20px;
                    margin-bottom:12px;">
          ${newsletter.titre_principal}
        </h2>
        <p style="color:#374151; line-height:1.7;
                  font-size:14px;">
          ${ab.nom ? `Bonjour <strong>${ab.nom}</strong>,`
    : 'Bonjour,'}
        </p>
        <p style="color:#374151; line-height:1.7;
                  font-size:14px;">
          ${newsletter.introduction}
        </p>

        ${ctx.nouvelles_offres.length ? `
          <h3 style="color:#1A56DB; font-size:15px;
                      margin:20px 0 8px;">
            💼 Nouvelles opportunités
          </h3>
          ${offresHtml}` : ''}

        <p style="color:#374151; line-height:1.7;
                  font-size:14px; margin-top:16px;">
          ${newsletter.corps || newsletter.corps_offres || ''}
        </p>

        ${conseilHtml}
        ${iaHtml}
        ${partenairesHtml}

        <div style="text-align:center; margin:24px 0;">
          <a href="${ctaHref}"
             style="background:#1A56DB; color:white;
                    padding:14px 28px; text-decoration:none;
                    border-radius:8px; font-weight:bold;
                    font-size:14px; display:inline-block;">
            ${newsletter.cta_texte} →
          </a>
        </div>

        <p style="color:#374151; line-height:1.7;
                  font-size:13px;">
          ${newsletter.conclusion}
        </p>
      </div>

      <div style="background:#F8FAFC; padding:16px;
                  border-radius:0 0 12px 12px;
                  text-align:center;
                  border:1px solid #E2E8F0; border-top:none;">
        <p style="color:#94A3B8; font-size:11px; margin:0;">
          © 2025 EmploiConnect · Conakry, Guinée
        </p>
        <p style="margin:6px 0 0;">
          <a href="${appUrl}/api/newsletter/unsubscribe?token=${encodeURIComponent(ab.token_desabo || '')}"
             style="color:#94A3B8; font-size:11px;
                    text-decoration:underline;">
            Se désabonner
          </a>
        </p>
      </div>
    </div>`;
}

export async function genererEtEnvoyerNewsletter(declencheur = 'admin', contexte = {}) {
  try {
    const iaCfg = await getNewsletterIaConfig();
    if (!iaCfg.actif && declencheur !== 'admin') {
      return { success: false, message: 'Newsletter IA désactivée' };
    }

    const cfg = await getMailSettings();
    if (!cfg.enabled) return { success: false, message: 'SMTP désactivé' };

    const [ctx, subsRes] = await Promise.all([
      getContexteComplet(),
      supabase
        .from('newsletter_abonnes')
        .select('email, nom, token_desabo')
        .eq('est_actif', true),
    ]);
    const abonnes = subsRes.data || [];
    if (!abonnes.length) return { success: false, message: 'Aucun abonné actif' };

    const cles = await _getClesIA();
    const prompt = await buildPrompt(declencheur, {
      ...ctx,
      contexte_libre: String(contexte?.contexte_libre || '').trim(),
    });
    const iaText = await _appellerIA(prompt, cles, 'texte');
    if (!iaText) throw new Error('IA non disponible');
    const newsletter = toNewsletterPayload(iaText, 'Nouvelles opportunités EmploiConnect');
    const appUrl = publicAppUrl(cfg);

    console.log('[newsletterIA] Type:', declencheur);
    console.log('[newsletterIA] Sujet:', newsletter.sujet);

    let nbEnvois = 0;
    for (const ab of abonnes) {
      const htmlInner = buildHtmlNewsletter(newsletter, ctx, ab, declencheur, appUrl);
      // eslint-disable-next-line no-await-in-loop
      const html = await buildWrappedEmailHtml(normalizeHtml(htmlInner));
      // eslint-disable-next-line no-await-in-loop
      const sent = await sendPlatformEmail({
        to: ab.email,
        subject: newsletter.sujet,
        text: `${newsletter.introduction}\n\n${newsletter.corps || newsletter.corps_offres || ''}\n\n${appUrl}${newsletter.cta_lien || '/#/public/offres'}`,
        html,
      });
      if (sent.ok) nbEnvois += 1;
    }

    await supabase.from('newsletter_envois').insert({
      sujet: newsletter.sujet,
      contenu: newsletter.corps || newsletter.corps_offres || '',
      nb_destinataires: nbEnvois,
      source: declencheur === 'hebdomadaire' ? 'hebdo' : (declencheur === 'admin' ? 'manuel' : 'ia_auto'),
      declencheur,
    });

    await supabase
      .from('parametres_plateforme')
      .upsert(
        {
          cle: 'newsletter_ia_dernier_envoi',
          valeur: new Date().toISOString(),
          type_valeur: 'string',
          description: 'Date ISO du dernier envoi automatique newsletter IA',
          categorie: 'email',
        },
        { onConflict: 'cle' },
      );

    return {
      success: true,
      sujet: newsletter.sujet,
      nb_envois: nbEnvois,
      declencheur,
      contexte: { ...contexte, nb_offres: ctx.nb_offres, feature: ctx.feature_semaine },
    };
  } catch (e) {
    console.error('[newsletterIA] Erreur:', e?.message || e);
    return { success: false, message: e?.message || 'Erreur newsletter IA' };
  }
}

export async function verifierEtEnvoyerAuto() {
  try {
    const cfg = await getNewsletterIaConfig();
    if (!cfg.actif) return { success: false, message: 'newsletter_ia_actif=false' };
    const ctx = await getContexteComplet();
    const nb = (ctx.nouvelles_offres || []).length;
    if (nb < cfg.seuil) {
      return { success: true, message: `Seuil non atteint (${nb}/${cfg.seuil})` };
    }
    return genererEtEnvoyerNewsletter('nouvelles_offres', { nb_nouvelles: nb, last_auto: cfg.dernierEnvoi });
  } catch (e) {
    console.error('[newsletterIA] verifierEtEnvoyerAuto:', e?.message || e);
    return { success: false, message: e?.message || 'Erreur vérification auto newsletter IA' };
  }
}
