# PRD — EmploiConnect · Configuration Google OAuth depuis l'Admin
## Product Requirements Document v9.7
**Stack : Flutter + Node.js/Express + Supabase**
**Date : Avril 2026**

## Vision

```
OBJECTIF :
L'administrateur configure Google OAuth
ENTIÈREMENT depuis l'interface d'administration.
Sans toucher au code ou aux fichiers .env.

FLOW HÉBERGEMENT :
1. Admin → Paramètres → Authentification
2. Renseigne Client ID + Client Secret Google
3. Copie l'URI de redirection auto → la colle dans Google Cloud
4. Active Google OAuth → Bouton Google apparaît sur le site
5. Teste → ✅ Prêt !
```

---

## 1. Migration SQL

```sql
INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('google_client_id',           '', 'string',
   'Client ID Google OAuth 2.0', 'auth'),
  ('google_client_secret',       '', 'string',
   'Client Secret Google OAuth 2.0', 'auth'),
  ('google_oauth_actif',         'false', 'boolean',
   'Activer la connexion Google', 'auth'),
  ('google_redirect_uri',        '', 'string',
   'URI de redirection OAuth', 'auth'),
  ('google_roles_defaut',        'chercheur', 'string',
   'Rôle par défaut nouveaux comptes Google', 'auth'),
  ('google_domaines_autorises',  '', 'string',
   'Domaines autorisés (vide = tous)', 'auth'),
  ('google_projet_id',           '', 'string',
   'ID projet Google Cloud', 'auth')
ON CONFLICT (cle) DO NOTHING;
```

---

## 2. Backend — googleOauth.service.js

```javascript
// backend/src/services/googleOauth.service.js

let _configCache = null;
let _cacheExpiry  = 0;

const getGoogleOAuthConfig = async () => {
  if (_configCache && Date.now() < _cacheExpiry)
    return _configCache;

  const { data } = await supabase
    .from('parametres_plateforme')
    .select('cle, valeur')
    .in('cle', [
      'google_client_id', 'google_client_secret',
      'google_oauth_actif', 'google_redirect_uri',
      'google_roles_defaut', 'google_domaines_autorises',
    ]);

  const c = {};
  (data || []).forEach(p => { c[p.cle] = p.valeur; });

  _configCache = {
    clientId:      c['google_client_id']
                     || process.env.GOOGLE_CLIENT_ID || '',
    clientSecret:  c['google_client_secret']
                     || process.env.GOOGLE_CLIENT_SECRET || '',
    actif:         c['google_oauth_actif'] === 'true',
    redirectUri:   c['google_redirect_uri']
                     || process.env.GOOGLE_REDIRECT_URI || '',
    rolesDefaut:   c['google_roles_defaut'] || 'chercheur',
    domainesAutorisés: (c['google_domaines_autorises'] || '')
      .split(',').map(d => d.trim()).filter(Boolean),
  };
  _configCache.estConfiguré = !!(
    _configCache.clientId && _configCache.clientSecret);
  _cacheExpiry = Date.now() + 5 * 60 * 1000;
  return _configCache;
};

const invaliderCache = () => {
  _configCache = null; _cacheExpiry = 0;
};

const testerConfiguration = async () => {
  const config = await getGoogleOAuthConfig();
  const etapes = [];

  const formatOk = config.clientId.includes(
    '.apps.googleusercontent.com');
  etapes.push({
    ok: formatOk,
    message: formatOk
      ? `✅ Client ID valide`
      : '❌ Client ID invalide (doit finir par .apps.googleusercontent.com)',
  });

  const secretOk = config.clientSecret.length > 10;
  etapes.push({
    ok: secretOk,
    message: secretOk
      ? '✅ Client Secret configuré'
      : '❌ Client Secret manquant',
  });

  etapes.push({
    ok: config.actif,
    message: config.actif
      ? '✅ Google OAuth activé'
      : '⚠️ Google OAuth désactivé',
  });

  const redirectUri = config.redirectUri
    || `${process.env.PUBLIC_API_URL
         || 'http://localhost:3000'}/api/auth/google/callback`;
  etapes.push({
    ok: true,
    message: `ℹ️ URI de redirection : ${redirectUri}`,
  });

  return {
    success: formatOk && secretOk,
    etapes,
    redirect_uri_suggere: redirectUri,
    message: formatOk && secretOk
      ? '✅ Configuration valide'
      : '❌ Configuration incomplète',
  };
};

module.exports = {
  getGoogleOAuthConfig, invaliderCache, testerConfiguration };
```

---

## 3. Routes admin backend

```javascript
// backend/src/routes/admin/index.js — Ajouter :

const {
  testerConfiguration, invaliderCache
} = require('../../services/googleOauth.service');

// GET /api/admin/oauth/config
router.get('/oauth/config', auth, requireAdmin,
  async (req, res) => {
  const { data } = await supabase
    .from('parametres_plateforme')
    .select('cle, valeur')
    .in('cle', [
      'google_client_id', 'google_client_secret',
      'google_oauth_actif', 'google_redirect_uri',
      'google_roles_defaut', 'google_domaines_autorises',
      'google_projet_id',
    ]);
  const c = {};
  (data || []).forEach(p => { c[p.cle] = p.valeur; });
  return res.json({
    success: true,
    data: {
      ...c,
      google_client_secret_configure:
        (c['google_client_secret'] || '').length > 0,
      redirect_uri_auto:
        `${process.env.PUBLIC_API_URL
          || 'http://localhost:3000'}/api/auth/google/callback`,
    }
  });
});

// POST /api/admin/oauth/test
router.post('/oauth/test', auth, requireAdmin,
  async (req, res) => {
  invaliderCache();
  const result = await testerConfiguration();
  return res.json(result);
});

// POST /api/admin/oauth/sauvegarder
router.post('/oauth/sauvegarder', auth, requireAdmin,
  async (req, res) => {
  try {
    const champs = [
      'google_client_id', 'google_client_secret',
      'google_oauth_actif', 'google_redirect_uri',
      'google_roles_defaut', 'google_domaines_autorises',
      'google_projet_id',
    ];
    for (const cle of champs) {
      if (req.body[cle] !== undefined
          && req.body[cle] !== '••••••••') {
        await supabase.from('parametres_plateforme')
          .upsert({
            cle, valeur: req.body[cle].toString()
          }, { onConflict: 'cle' });
      }
    }
    invaliderCache();
    return res.json({
      success: true,
      message: '✅ Configuration sauvegardée'
    });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});
```

---

## 4. Admin Flutter — Section OAuth

```dart
// Dans admin_settings_screen.dart
// Onglet Authentification — REMPLACER entièrement

// Contrôleurs à ajouter :
// final _googleClientIdCtrl     = TextEditingController();
// final _googleClientSecretCtrl = TextEditingController();
// final _googleProjetCtrl       = TextEditingController();
// final _googleDomainesCtrl     = TextEditingController();
// String  _googleRolesDefaut    = 'chercheur';
// bool    _googleOauthActif     = false;
// bool    _isTesting            = false;
// bool    _isSavingOAuth        = false;
// String  _redirectUriAuto      = '';
// Map?    _testResultat;
// bool    _guideExpanded        = false;

Widget _buildOngletAuthentification() =>
  SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Column(children: [

    // ── Statut ──────────────────────────────────
    _CarteSection(titre: '📊 Statut actuel', children: [
      Row(children: [
        Expanded(child: _BadgeStatut(
          label:    'Client ID',
          configure: (_params['google_client_id'] ?? '')
              .isNotEmpty)),
        const SizedBox(width: 12),
        Expanded(child: _BadgeStatut(
          label:    'Client Secret',
          configure: (_params['google_client_secret_configure']
              ?? 'false') == 'true'
              || (_params['google_client_secret'] ?? '')
                  .isNotEmpty)),
      ]),
      const SizedBox(height: 10),
      _ToggleNotif(
        icon:      Icons.g_mobiledata_rounded,
        couleur:   const Color(0xFF4285F4),
        titre:     'Google OAuth activé',
        sousTitre: 'Affiche "Se connecter avec Google"',
        valeur:    _googleOauthActif,
        onChanged: (v) {
          setState(() => _googleOauthActif = v);
          _saveParam('google_oauth_actif', v.toString());
        }),
    ]),
    const SizedBox(height: 16),

    // ── Guide ────────────────────────────────────
    _CarteSection(titre: '📋 Guide de configuration',
      children: [
      GestureDetector(
        onTap: () =>
          setState(() => _guideExpanded = !_guideExpanded),
        child: Row(children: [
          const Icon(Icons.help_outline_rounded,
            color: Color(0xFF1A56DB), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Comment créer des identifiants Google OAuth ?',
            style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: const Color(0xFF1A56DB)))),
          Icon(_guideExpanded
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded,
            color: const Color(0xFF1A56DB), size: 18),
        ])),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: _guideExpanded
            ? _buildGuideEtapes()
            : const SizedBox()),
    ]),
    const SizedBox(height: 16),

    // ── Identifiants ─────────────────────────────
    _CarteSection(
      titre: '🔑 Identifiants Google Cloud',
      sousTitre: 'console.cloud.google.com',
      children: [

      _ChampAdmin(_googleClientIdCtrl,
        'Client ID *',
        'xxx.apps.googleusercontent.com',
        Icons.fingerprint_rounded),
      const SizedBox(height: 12),

      _ChampSecret(_googleClientSecretCtrl,
        'Client Secret *',
        'GOCSPX-xxxxx'),
      const SizedBox(height: 12),

      // URI de redirection
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF1A56DB)
              .withOpacity(0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(children: [
            const Icon(Icons.link_rounded,
              color: Color(0xFF1A56DB), size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(
              'URI de redirection — À copier dans Google Cloud',
              style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A56DB)))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(
              _redirectUriAuto.isEmpty
                  ? 'Chargement...'
                  : _redirectUriAuto,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                color: const Color(0xFF0F172A)))),
            IconButton(
              icon: const Icon(Icons.copy_rounded,
                size: 14),
              color: const Color(0xFF1A56DB),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Copier',
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: _redirectUriAuto));
                ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(
                    content: Text('✅ URI copiée !'),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating));
              }),
          ]),
        ])),
    ]),
    const SizedBox(height: 16),

    // ── Config avancée ────────────────────────────
    _CarteSection(titre: '⚙️ Configuration avancée',
      children: [

      // Rôle par défaut
      Row(children: [
        Expanded(child: Text('Rôle nouveaux comptes',
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: const Color(0xFF374151)))),
        DropdownButton<String>(
          value:     _googleRolesDefaut,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'chercheur',
              child: Text('👤 Candidat')),
            DropdownMenuItem(value: 'entreprise',
              child: Text('🏢 Recruteur')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() => _googleRolesDefaut = v);
              _saveParam('google_roles_defaut', v);
            }
          }),
      ]),
      const SizedBox(height: 12),

      _ChampAdmin(_googleDomainesCtrl,
        'Domaines email autorisés (optionnel)',
        'Ex: gmail.com, orange-guinee.com',
        Icons.domain_rounded),
      const SizedBox(height: 4),
      Text('Vide = tous les emails autorisés',
        style: GoogleFonts.inter(
          fontSize: 10, color: const Color(0xFF94A3B8))),
    ]),
    const SizedBox(height: 16),

    // ── Actions ───────────────────────────────────
    _CarteSection(titre: '🧪 Test & Sauvegarde',
      children: [
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          icon: _isTesting
              ? const SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4285F4)))
              : const Icon(Icons.play_arrow_rounded,
                  size: 16),
          label: Text(_isTesting ? 'Test...' : 'Tester'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: Color(0xFF4285F4)),
            foregroundColor: const Color(0xFF4285F4),
            padding: const EdgeInsets.symmetric(
              vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: _isTesting ? null : _testerOAuth)),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(
          icon: _isSavingOAuth
              ? const SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded, size: 16),
          label: Text(_isSavingOAuth
            ? 'Sauvegarde...' : 'Sauvegarder'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4285F4),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(
              vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: _isSavingOAuth
              ? null : _sauvegarderOAuth)),
      ]),

      // Résultats du test
      if (_testResultat != null) ...[
        const SizedBox(height: 12),
        ...(_testResultat!['etapes'] as List)
          .map<Widget>((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(
                e['ok'] == true
                    ? Icons.check_circle_rounded
                    : Icons.warning_rounded,
                color: e['ok'] == true
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(
                e['message'] as String,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF374151)))),
            ]))).toList(),
      ],
    ]),
  ]));

// ── Fonctions ────────────────────────────────────────────

Future<void> _testerOAuth() async {
  setState(() { _isTesting = true; _testResultat = null; });
  try {
    final token = context.read<AuthProvider>().token ?? '';
    final res = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/oauth/test'),
      headers: {'Authorization': 'Bearer $token'})
      .timeout(const Duration(seconds: 15));
    setState(() => _testResultat = jsonDecode(res.body));
  } catch (e) {
    setState(() => _testResultat = {
      'success': false,
      'etapes': [{'ok': false, 'message': 'Erreur: $e'}],
    });
  } finally {
    if (mounted) setState(() => _isTesting = false);
  }
}

Future<void> _sauvegarderOAuth() async {
  setState(() => _isSavingOAuth = true);
  try {
    final token = context.read<AuthProvider>().token ?? '';
    final payload = {
      'google_client_id':
        _googleClientIdCtrl.text.trim(),
      'google_oauth_actif': _googleOauthActif,
      'google_roles_defaut': _googleRolesDefaut,
      'google_domaines_autorises':
        _googleDomainesCtrl.text.trim(),
    };
    // N'envoyer le secret que s'il a changé
    if (_googleClientSecretCtrl.text.isNotEmpty
        && _googleClientSecretCtrl.text != '••••••••') {
      payload['google_client_secret'] =
        _googleClientSecretCtrl.text.trim();
    }
    final res = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/oauth/sauvegarder'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload));
    final body = jsonDecode(res.body);
    if (body['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Config Google OAuth sauvegardée !'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
      if (_googleClientSecretCtrl.text != '••••••••') {
        setState(() =>
          _googleClientSecretCtrl.text = '••••••••');
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Erreur: $e'),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating));
  } finally {
    if (mounted) setState(() => _isSavingOAuth = false);
  }
}

// Badge statut
class _BadgeStatut extends StatelessWidget {
  final String label; final bool configure;
  const _BadgeStatut({required this.label,
    required this.configure});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: configure
          ? const Color(0xFFECFDF5)
          : const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: configure
            ? const Color(0xFF10B981).withOpacity(0.3)
            : const Color(0xFFEF4444).withOpacity(0.3))),
    child: Row(children: [
      Icon(
        configure
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded,
        color: configure
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        size: 14),
      const SizedBox(width: 6),
      Expanded(child: Text(label,
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: configure
              ? const Color(0xFF065F46)
              : const Color(0xFF991B1B)))),
    ]));
}
```

---

## 5. Charger redirect_uri_auto au démarrage

```dart
// Dans _loadParams() de admin_settings_screen.dart
// Ajouter après le chargement des params :

Future<void> _loadOAuthConfig() async {
  try {
    final token = context.read<AuthProvider>().token ?? '';
    final res = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/oauth/config'),
      headers: {'Authorization': 'Bearer $token'});
    final body = jsonDecode(res.body);
    if (body['success'] == true) {
      final d = body['data'];
      setState(() {
        _googleClientIdCtrl.text =
          d['google_client_id'] as String? ?? '';
        _googleClientSecretCtrl.text =
          (d['google_client_secret_configure'] == true
              || (d['google_client_secret'] ?? '')
                  .isNotEmpty)
              ? '••••••••' : '';
        _googleOauthActif =
          d['google_oauth_actif'] == 'true';
        _googleRolesDefaut =
          d['google_roles_defaut'] as String?
              ?? 'chercheur';
        _googleDomainesCtrl.text =
          d['google_domaines_autorises'] as String? ?? '';
        _redirectUriAuto =
          d['redirect_uri_auto'] as String? ?? '';
      });
    }
  } catch (_) {}
}
```

---

## Critères d'Acceptation

- [ ] Section OAuth dans Paramètres → Authentification
- [ ] Champs Client ID + Client Secret (masqué ••••)
- [ ] URI de redirection calculée auto + bouton copier
- [ ] Bouton "Tester" → étapes détaillées
- [ ] Bouton "Sauvegarder" → invalide le cache
- [ ] Toggle activer/désactiver
- [ ] Guide 7 étapes intégré (expandable)
- [ ] Backend charge config depuis BDD
- [ ] Fallback .env si BDD vide
- [ ] Cache 5 min pour performance
- [ ] Secret ne part pas en clair si non modifié

---

*PRD EmploiConnect v9.7 — Google OAuth Admin*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
