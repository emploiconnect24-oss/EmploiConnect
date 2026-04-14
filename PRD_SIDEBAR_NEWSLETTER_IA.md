# PRD — EmploiConnect · Sidebar Mobile + IA Newsletter + Config Admin
## Product Requirements Document v9.6
**Stack : Flutter + Node.js/Express + Supabase + Claude/OpenAI**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Table des Matières

1. [Sidebar mobile redesignée](#1-sidebar-mobile)
2. [Déplacer À propos + Newsletter dans Paramètres](#2-déplacer-dans-paramètres)
3. [Newsletter IA automatique](#3-newsletter-ia-automatique)
4. [Résumés hebdomadaires — Explication + Vérification](#4-résumés-hebdomadaires)

---

## 1. Sidebar Mobile

```dart
// frontend/lib/screens/home/home_screen.dart
// ET home_header_widget.dart
// Changer endDrawer → drawer (gauche)
// ET redesigner complètement

// Dans home_screen.dart :
// AVANT ❌
Scaffold(endDrawer: _buildMenuMobile(), ...)

// APRÈS ✅
Scaffold(drawer: _buildMenuMobile(), ...)

// Le bouton hamburger :
// AVANT ❌
onTap: () => Scaffold.of(ctx).openEndDrawer()
// APRÈS ✅
onTap: () => Scaffold.of(ctx).openDrawer()

// ── Nouveau design du drawer ─────────────────────────────
Widget _buildMenuMobile(BuildContext context) => Drawer(
  width: MediaQuery.of(context).size.width * 0.82,
  child: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D1B3E),
          Color(0xFF1A2F5E),
        ])),
    child: SafeArea(child: Column(children: [

      // ── Header avec logo ──────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('E',
              style: TextStyle(
                color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w900)))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('EmploiConnect',
              style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w800,
                color: Colors.white)),
            Text('Guinée · Emploi & Carrière',
              style: GoogleFonts.inter(
                fontSize: 10, color: Colors.white54)),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                color: Colors.white54, size: 16))),
        ])),

      // Ligne de séparation avec dégradé
      Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.15),
              Colors.transparent,
            ]))),
      const SizedBox(height: 8),

      // ── Navigation principale ─────────────────────
      Expanded(child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [

          // Label section
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
            child: Text('NAVIGATION',
              style: GoogleFonts.inter(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: Colors.white30,
                letterSpacing: 1.5))),

          _DrawerItem(
            icone:  Icons.home_rounded,
            titre:  'Accueil',
            onTap:  () {
              Navigator.pop(context);
              context.go('/');
            }),
          _DrawerItem(
            icone:  Icons.work_outline_rounded,
            titre:  'Offres d\'emploi',
            badge:  'Nouveau',
            onTap:  () {
              Navigator.pop(context);
              context.push('/offres');
            }),
          _DrawerItem(
            icone:  Icons.business_outlined,
            titre:  'Entreprises',
            onTap:  () {
              Navigator.pop(context);
              context.push('/entreprises');
            }),
          _DrawerItem(
            icone:  Icons.school_outlined,
            titre:  'Parcours Carrière',
            onTap:  () {
              Navigator.pop(context);
              context.push('/parcours');
            }),
          _DrawerItem(
            icone:  Icons.info_outline_rounded,
            titre:  'À propos',
            onTap:  () {
              Navigator.pop(context);
              context.push('/a-propos');
            }),

          // Label section outils IA
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
            child: Text('OUTILS IA',
              style: GoogleFonts.inter(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: Colors.white30,
                letterSpacing: 1.5))),

          _DrawerItem(
            icone:    Icons.psychology_rounded,
            titre:    'Simulateur entretien',
            couleur:  const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.pop(context);
              context.push('/parcours?tab=simulateur');
            }),
          _DrawerItem(
            icone:    Icons.calculate_rounded,
            titre:    'Calculateur salaire',
            couleur:  const Color(0xFF10B981),
            onTap: () {
              Navigator.pop(context);
              context.push('/parcours?tab=calculateur');
            }),

          // Séparateur
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Container(height: 1,
              color: Colors.white.withOpacity(0.06))),

          // Toggle thème
          _DrawerItemToggle(),
        ])),

      // ── Boutons auth en bas ───────────────────────
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(
            color: Colors.white.withOpacity(0.08)))),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(context);
                context.push('/login');
              },
              child: Text('Se connecter',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600)))),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(context);
                context.push('/register');
              },
              child: Text('S\'inscrire gratuitement',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700)))),
        ])),
    ]))));

// ── Widget item drawer ────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData  icone;
  final String    titre;
  final String?   badge;
  final Color?    couleur;
  final VoidCallback onTap;
  const _DrawerItem({required this.icone,
    required this.titre, required this.onTap,
    this.badge, this.couleur});

  @override
  Widget build(BuildContext context) {
    final c = couleur ?? Colors.white70;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 2),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9)),
        child: Icon(icone, color: c, size: 18)),
      title: Text(titre, style: GoogleFonts.inter(
        fontSize: 14, color: Colors.white,
        fontWeight: FontWeight.w500)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(100)),
              child: Text(badge!,
                style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  color: Colors.white)))
          : const Icon(Icons.arrow_forward_ios_rounded,
              color: Color(0xFF334155), size: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10)),
      hoverColor: Colors.white.withOpacity(0.05),
      onTap: onTap);
  }
}

// ── Toggle thème dans le drawer ──────────────────────────
class _DrawerItemToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 2),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9)),
        child: Icon(
          isDark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          color: Colors.white70, size: 18)),
      title: Text(
        isDark ? 'Mode clair' : 'Mode sombre',
        style: GoogleFonts.inter(
          fontSize: 14, color: Colors.white,
          fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: isDark,
        activeColor: const Color(0xFF1A56DB),
        activeTrackColor:
          const Color(0xFF1A56DB).withOpacity(0.3),
        inactiveThumbColor: Colors.white38,
        inactiveTrackColor: Colors.white12,
        materialTapTargetSize:
          MaterialTapTargetSize.shrinkWrap,
        onChanged: (_) =>
          context.read<ThemeProvider>().toggle()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10)),
      onTap: () => context.read<ThemeProvider>().toggle());
  }
}
```

---

## 2. Déplacer À propos + Newsletter dans Paramètres

```dart
// Dans admin_sidebar.dart
// SUPPRIMER ces entrées du menu principal :
// ❌ _SidebarItem(titre: 'À propos', route: '/admin/apropos')
// ❌ _SidebarItem(titre: 'Newsletter', route: '/admin/newsletter')

// Dans admin_settings_screen.dart
// Ajouter un nouvel onglet "Contenu" ou une section dédiée
// dans les paramètres existants

// Structure des onglets paramètres :
// 1. Général        ← Existant
// 2. Email/SMTP     ← Existant
// 3. IA & Matching  ← Existant
// 4. Sécurité       ← Existant
// 5. Contenu        ← NOUVEAU → contient À propos + Newsletter

// Ajouter l'onglet "Contenu" :
Tab(child: Row(children: [
  const Icon(Icons.article_outlined, size: 14),
  const SizedBox(width: 6),
  const Text('Contenu'),
])),

// Contenu de l'onglet "Contenu" :
Widget _buildOngletContenu() => SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Column(children: [

    // ── Section À propos ──────────────────────────
    _CarteSection(
      titre: '📄 Page "À propos"',
      sousTitre: 'Modifier les sections de la page publique',
      children: [
        // Bouton accès rapide
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.edit_rounded, size: 14),
            label: const Text('Gérer les sections À propos'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFF1A56DB)),
              foregroundColor: const Color(0xFF1A56DB),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
            onPressed: () =>
              context.push('/admin/apropos'))),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            icon: const Icon(
              Icons.visibility_rounded, size: 14),
            label: const Text('Voir la page'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFFE2E8F0)),
              foregroundColor: const Color(0xFF64748B)),
            onPressed: () => context.push('/a-propos')),
        ]),
      ]),
    const SizedBox(height: 16),

    // ── Section Newsletter ────────────────────────
    _CarteSection(
      titre: '📧 Newsletter',
      sousTitre: 'Abonnés et envois automatiques IA',
      children: [
        // Stats abonnés
        FutureBuilder<int>(
          future: _getNbAbonnes(),
          builder: (ctx, snap) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.people_rounded,
                color: Color(0xFF1A56DB), size: 20),
              const SizedBox(width: 10),
              Text(
                '${snap.data ?? '...'} abonné(s) actif(s)',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56DB))),
            ])),
        ),
        const SizedBox(height: 12),

        // Toggle newsletter actif
        _ToggleNotif(
          icon:      Icons.email_rounded,
          couleur:   const Color(0xFF1A56DB),
          titre:     'Newsletter active',
          sousTitre: 'Permettre les inscriptions',
          valeur:    (_params['newsletter_actif'] ?? 'true')
              == 'true',
          onChanged: (v) {
            setState(() =>
              _params['newsletter_actif'] = v.toString());
            _saveParam('newsletter_actif', v.toString());
          }),
        const SizedBox(height: 12),

        // Toggle IA newsletter
        _ToggleNotif(
          icon:      Icons.auto_awesome_rounded,
          couleur:   const Color(0xFF8B5CF6),
          titre:     'Newsletter IA automatique',
          sousTitre: 'Claude envoie des newsletters intelligentes',
          valeur:    (_params['newsletter_ia_actif'] ?? 'false')
              == 'true',
          onChanged: (v) {
            setState(() =>
              _params['newsletter_ia_actif'] = v.toString());
            _saveParam('newsletter_ia_actif', v.toString());
          }),
        const SizedBox(height: 12),

        // Bouton gestion complète
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.email_outlined, size: 16),
            label: const Text('Gérer la Newsletter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
            onPressed: () =>
              context.push('/admin/newsletter'))),
      ]),
  ]));
```

---

## 3. Newsletter IA Automatique

### Comment ça fonctionne

```
DÉCLENCHEURS AUTOMATIQUES :

1. Nouvelles offres publiées (≥ 3 nouvelles offres)
   → IA génère une newsletter "Nouvelles opportunités"

2. Chaque semaine (lundi 9h)
   → IA génère un résumé hebdomadaire des offres

3. Événements spéciaux
   → Nouveau partenaire, fonctionnalité, etc.
   (déclenchés manuellement par l'admin)

L'IA (Claude) :
→ Analyse les données de la plateforme
→ Rédige un sujet accrocheur
→ Génère un contenu pertinent en français
→ Envoie à tous les abonnés actifs
```

### Migration SQL

```sql
-- Ajouter paramètres newsletter IA
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('newsletter_ia_actif',      'false', 'boolean',
   'Activer la newsletter IA automatique', 'email'),
  ('newsletter_ia_seuil_offres', '3',  'string',
   'Nb nouvelles offres pour déclencher une newsletter', 'email'),
  ('newsletter_ia_dernier_envoi', '', 'string',
   'Date du dernier envoi automatique', 'email')
ON CONFLICT (cle) DO NOTHING;

-- Table log des envois newsletter
CREATE TABLE IF NOT EXISTS newsletter_envois (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sujet        TEXT,
  contenu      TEXT,
  nb_destinataires INTEGER DEFAULT 0,
  source       TEXT DEFAULT 'manuel'
    CHECK (source IN ('manuel', 'ia_auto', 'hebdo')),
  declencheur  TEXT, -- 'nouvelles_offres' | 'hebdomadaire' | 'admin'
  date_envoi   TIMESTAMPTZ DEFAULT NOW()
);
```

### Backend — Service Newsletter IA

```javascript
// backend/src/services/newsletterIa.service.js

const { _appellerIA, _getClesIA } =
  require('./ia.service');

// ── Générer et envoyer une newsletter avec l'IA ──────────
const genererEtEnvoyerNewsletter = async (
    declencheur, contexte = {}) => {
  try {
    console.log('[newsletterIA] Déclencheur:', declencheur);

    // Vérifier si IA newsletter est activée
    const { data: param } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'newsletter_ia_actif')
      .single();

    if (param?.valeur !== 'true') {
      console.log('[newsletterIA] IA désactivée');
      return { success: false, message: 'IA désactivée' };
    }

    // Récupérer les données de la plateforme
    const [offres, stats] = await Promise.all([
      _getNouvellesOffres(),
      _getStatsPlateforme(),
    ]);

    // Récupérer les abonnés actifs
    const { data: abonnes } = await supabase
      .from('newsletter_abonnes')
      .select('email, nom, token_desabo')
      .eq('est_actif', true);

    if (!abonnes?.length) {
      return { success: false, message: 'Aucun abonné' };
    }

    const cles = await _getClesIA();

    // ── Générer le contenu avec Claude ──────────────────
    const prompt = `Tu es le responsable marketing
d'EmploiConnect, la plateforme N°1 de l'emploi en Guinée.

CONTEXTE :
- Déclencheur : ${declencheur}
- Nouvelles offres : ${offres.length}
${offres.slice(0, 5).map(o =>
  `  • ${o.titre} chez ${o.entreprise} (${o.localisation})`
).join('\n')}
- Total offres actives : ${stats.nb_offres}
- Candidats inscrits : ${stats.nb_candidats}
- Entreprises : ${stats.nb_entreprises}

INSTRUCTIONS :
Rédige une newsletter professionnelle en français pour
les abonnés guinéens. Elle doit :
1. Avoir un sujet accrocheur (max 60 caractères)
2. Commencer par une salutation chaleureuse
3. Mettre en avant les nouvelles opportunités
4. Encourager à postuler
5. Mentionner les outils IA disponibles
6. Être concise (max 200 mots)
7. Ton : professionnel mais chaleureux

Réponds UNIQUEMENT avec ce JSON :
{
  "sujet": "...",
  "titre_principal": "...",
  "introduction": "...",
  "corps": "...",
  "conclusion": "...",
  "cta_texte": "...",
  "cta_lien": "/offres"
}`;

    const texte = await _appellerIA(prompt, cles, 'texte');
    if (!texte) throw new Error('IA non disponible');

    const clean = texte
      .replace(/```json/g, '').replace(/```/g, '').trim();
    const newsletter = JSON.parse(clean);

    console.log('[newsletterIA] Sujet:', newsletter.sujet);

    // ── Construire le HTML de l'email ───────────────────
    const buildHtml = (ab) => `
      <div style="font-family: Arial, sans-serif;
                  max-width: 600px; margin: 0 auto;">

        <!-- Header -->
        <div style="background: linear-gradient(135deg, #1A56DB, #7C3AED);
                    padding: 32px; border-radius: 12px 12px 0 0;
                    text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 28px;
                      font-weight: 900;">EmploiConnect</h1>
          <p style="color: rgba(255,255,255,0.8); margin: 8px 0 0;">
            Guinée · Plateforme d'emploi intelligente
          </p>
        </div>

        <!-- Corps -->
        <div style="background: white; padding: 32px;
                    border: 1px solid #E2E8F0;
                    border-top: none;">
          <h2 style="color: #0F172A; font-size: 22px;
                      margin-bottom: 16px;">
            ${newsletter.titre_principal}
          </h2>
          <p style="color: #374151; line-height: 1.7;">
            ${ab.nom ? `Bonjour ${ab.nom},` : 'Bonjour,'}
          </p>
          <p style="color: #374151; line-height: 1.7;">
            ${newsletter.introduction}
          </p>
          <p style="color: #374151; line-height: 1.7;">
            ${newsletter.corps}
          </p>

          <!-- Offres récentes -->
          ${offres.slice(0, 3).map(o => `
            <div style="background: #F8FAFC; border-radius: 8px;
                        padding: 12px; margin: 8px 0;
                        border-left: 3px solid #1A56DB;">
              <strong style="color: #0F172A;">${o.titre}</strong>
              <span style="color: #64748B;"> · ${o.entreprise}</span>
              <br/>
              <small style="color: #94A3B8;">
                📍 ${o.localisation} · ${o.type_contrat}
              </small>
            </div>`).join('')}

          <!-- CTA -->
          <div style="text-align: center; margin: 28px 0;">
            <a href="${process.env.PUBLIC_API_URL || 'http://localhost:3001'}${newsletter.cta_lien}"
               style="background: #1A56DB; color: white;
                      padding: 14px 28px; text-decoration: none;
                      border-radius: 8px; font-weight: bold;
                      display: inline-block;">
              ${newsletter.cta_texte} →
            </a>
          </div>

          <p style="color: #374151; line-height: 1.7;">
            ${newsletter.conclusion}
          </p>
        </div>

        <!-- Footer -->
        <div style="background: #F8FAFC; padding: 16px;
                    border-radius: 0 0 12px 12px;
                    text-align: center;
                    border: 1px solid #E2E8F0; border-top: none;">
          <p style="color: #94A3B8; font-size: 12px; margin: 0;">
            © 2025 EmploiConnect · Conakry, Guinée
          </p>
          <p style="margin: 4px 0;">
            <a href="${process.env.PUBLIC_API_URL}/api/newsletter/unsubscribe?token=${ab.token_desabo}"
               style="color: #94A3B8; font-size: 11px;">
              Se désabonner
            </a>
          </p>
        </div>
      </div>`;

    // ── Envoyer à tous les abonnés ───────────────────────
    let nbEnvois = 0;
    const { envoyerEmail } = require('./email.service');

    for (const ab of abonnes) {
      try {
        await envoyerEmail({
          to:      ab.email,
          subject: newsletter.sujet,
          html:    buildHtml(ab),
        });
        nbEnvois++;
      } catch (e) {
        console.warn('[newsletterIA] Erreur email:', e.message);
      }
    }

    // ── Sauvegarder le log ───────────────────────────────
    await supabase.from('newsletter_envois').insert({
      sujet:           newsletter.sujet,
      contenu:         newsletter.corps,
      nb_destinataires: nbEnvois,
      source:          'ia_auto',
      declencheur:     declencheur,
    });

    // Mettre à jour la date du dernier envoi
    await supabase.from('parametres_plateforme')
      .upsert({
        cle:    'newsletter_ia_dernier_envoi',
        valeur: new Date().toISOString(),
      }, { onConflict: 'cle' });

    console.log(`[newsletterIA] ✅ ${nbEnvois} emails envoyés`);
    return {
      success: true,
      sujet:   newsletter.sujet,
      nb_envois: nbEnvois,
    };

  } catch (e) {
    console.error('[newsletterIA] Erreur:', e.message);
    return { success: false, message: e.message };
  }
};

// ── Récupérer les nouvelles offres (dernières 24h) ────────
const _getNouvellesOffres = async () => {
  const hier = new Date();
  hier.setDate(hier.getDate() - 1);

  const { data } = await supabase
    .from('offres_emploi')
    .select(`
      titre, localisation, type_contrat,
      entreprise:entreprises(nom_entreprise)
    `)
    .eq('statut', 'publiee')
    .gte('date_publication', hier.toISOString())
    .order('date_publication', { ascending: false })
    .limit(10);

  return (data || []).map(o => ({
    titre:       o.titre,
    entreprise:  o.entreprise?.nom_entreprise || 'Entreprise',
    localisation: o.localisation || 'Guinée',
    type_contrat: o.type_contrat || '',
  }));
};

// ── Stats globales de la plateforme ───────────────────────
const _getStatsPlateforme = async () => {
  const [offres, candidats, entreprises] = await Promise.all([
    supabase.from('offres_emploi')
      .select('*', { count: 'exact', head: true })
      .eq('statut', 'publiee'),
    supabase.from('chercheurs_emploi')
      .select('*', { count: 'exact', head: true }),
    supabase.from('entreprises')
      .select('*', { count: 'exact', head: true })
      .eq('statut_validation', 'validee'),
  ]);
  return {
    nb_offres:      offres.count     || 0,
    nb_candidats:   candidats.count  || 0,
    nb_entreprises: entreprises.count || 0,
  };
};

// ── Vérifier si une newsletter doit être envoyée ──────────
const verifierEtEnvoyerAuto = async () => {
  try {
    const { data: params } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'newsletter_ia_actif',
        'newsletter_ia_seuil_offres',
        'newsletter_ia_dernier_envoi',
      ]);

    const c = {};
    (params || []).forEach(p => { c[p.cle] = p.valeur; });

    if (c['newsletter_ia_actif'] !== 'true') return;

    const seuil = parseInt(c['newsletter_ia_seuil_offres'] || '3');
    const dernier = c['newsletter_ia_dernier_envoi'];

    // Compter les nouvelles offres depuis le dernier envoi
    let query = supabase
      .from('offres_emploi')
      .select('*', { count: 'exact', head: true })
      .eq('statut', 'publiee');

    if (dernier) {
      query = query.gte('date_publication', dernier);
    }

    const { count } = await query;

    if ((count || 0) >= seuil) {
      console.log(`[newsletterIA] ${count} nouvelles offres → envoi auto`);
      await genererEtEnvoyerNewsletter(
        'nouvelles_offres',
        { nb_nouvelles: count });
    }
  } catch (e) {
    console.error('[newsletterIA] verifierAuto:', e.message);
  }
};

module.exports = {
  genererEtEnvoyerNewsletter,
  verifierEtEnvoyerAuto,
};
```

### Intégrer dans les crons

```javascript
// backend/src/services/scheduledJobs.service.js
// Ajouter :

const {
  genererEtEnvoyerNewsletter,
  verifierEtEnvoyerAuto,
} = require('./newsletterIa.service');

// Vérification toutes les 6 heures
cron.schedule('0 */6 * * *', async () => {
  console.log('[CRON] Vérification newsletter IA...');
  await verifierEtEnvoyerAuto();
}, { timezone: 'Africa/Conakry' });

// Newsletter hebdomadaire IA - Lundi 9h
cron.schedule('0 9 * * 1', async () => {
  console.log('[CRON] Newsletter hebdomadaire IA...');
  await genererEtEnvoyerNewsletter('hebdomadaire');
}, { timezone: 'Africa/Conakry' });
```

### Route pour déclencher manuellement

```javascript
// Dans backend/src/routes/admin/newsletter.js
// Ajouter :

router.post('/ia/generer', auth, requireAdmin,
  async (req, res) => {
  try {
    const { declencheur = 'admin' } = req.body;
    const {
      genererEtEnvoyerNewsletter
    } = require('../../services/newsletterIa.service');

    const result = await genererEtEnvoyerNewsletter(
      declencheur);
    return res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});
```

---

## 4. Résumés hebdomadaires — Explication

### Comment ça fonctionne actuellement

```javascript
// Dans backend/src/services/scheduledJobs.service.js
// Cron existant : chaque lundi à 8h (Conakry)
// Expression : '0 8 * * 1'

// QUI REÇOIT :
// → Les CANDIDATS qui ont activé les notifications email
// → Les candidats avec des alertes emploi configurées

// QUE CONTIENT LE RÉSUMÉ :
// → Nouvelles offres de la semaine
// → Offres correspondant au profil du candidat
// → Statistiques de candidatures
// → Conseils de la semaine

// CONDITION :
// → Le paramètre email_service_actif = 'true'
// → L'utilisateur a email_notifications = true
```

### Vérifier que c'est actif

```bash
# Dans le terminal backend
grep -rn "lundi\|monday\|0 8 \* \* 1\|resume_hebdo\|resumeHebdo" \
  backend/src/services --include="*.js"

# Tester manuellement :
node -e "
const { executer } = require('./backend/src/services/scheduledJobs.service');
executer && executer('resume_hebdo');
"
```

```sql
-- Vérifier les paramètres email
SELECT cle, valeur FROM parametres_plateforme
WHERE cle IN (
  'email_service_actif',
  'smtp_host',
  'smtp_user',
  'template_resume_hebdo_sujet'
);
```

### Prompt pour Cursor — Vérifier + améliorer les résumés

```
"Vérifier que le cron du résumé hebdomadaire fonctionne.

1. Lire le fichier scheduledJobs.service.js complet
2. Vérifier que le cron '0 8 * * 1' existe
3. Vérifier qui reçoit les emails (candidats avec notifs actives)
4. Vérifier le contenu de l'email envoyé
5. Ajouter des logs si manquants :
   console.log('[CRON résumé] Envoi à X candidats...')
6. Si le cron n'existe pas → le créer avec :
   - Destinataires : candidats avec notifications actives
   - Contenu : offres de la semaine + stats
   - Template : template_resume_hebdo_sujet depuis BDD
7. Redémarrer et montrer les logs au démarrage"
```

---

## Résumé des 4 points

| Fonctionnalité | Description |
|---|---|
| **Sidebar mobile** | Gauche, fond bleu foncé, sections NAVIGATION + OUTILS IA, toggle thème |
| **À propos + Newsletter** | Déplacés dans Paramètres → onglet "Contenu" |
| **Newsletter IA** | Claude génère automatiquement si ≥3 nouvelles offres |
| **Résumés hebdomadaires** | Lundi 8h → candidats avec notifications actives |

---

*PRD EmploiConnect v9.6 — Sidebar + Newsletter IA + Config*
*Cursor / Kirsoft AI — Phase 29*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
