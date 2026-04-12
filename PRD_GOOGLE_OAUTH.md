# PRD — EmploiConnect · Connexion avec Google (OAuth 2.0)
## Product Requirements Document v8.9
**Stack : Flutter + Node.js/Express + Supabase + Google OAuth**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Vue d'ensemble

```
OBJECTIF :
Permettre aux candidats et recruteurs de se connecter
ou s'inscrire avec leur compte Google en 1 clic.

SANS Google → Formulaire email + mot de passe (existant)
AVEC Google → Clic → Popup Google → Connecté ✅

AVANTAGES :
→ Plus rapide que de créer un compte manuel
→ Plus sécurisé (Google gère l'authentification)
→ Réduit les abandons d'inscription
→ Récupère automatiquement nom + photo Google
```

---

## Architecture technique

```
Flutter (Web/Mobile)
    ↓ Clic "Continuer avec Google"
    ↓ Popup Google OAuth
    ↓ Google retourne un token
    ↓ Envoyer token au backend
Backend Node.js
    ↓ Vérifier le token avec Google API
    ↓ Créer ou trouver l'utilisateur en BDD
    ↓ Générer un JWT EmploiConnect
Flutter
    ↓ Recevoir JWT + rôle
    ↓ Rediriger vers le bon espace (candidat/recruteur)
```

---

## Ce que TU dois faire (configuration externe)

### ÉTAPE A — Google Cloud Console (15 minutes)

```
1. Aller sur : https://console.cloud.google.com
2. Créer un projet ou sélectionner un existant
   → Nom : "EmploiConnect"

3. Activer les APIs Google (obligatoire pour Flutter Web avec `google_sign_in`) :
   → APIs & Services → Library (Bibliothèque)
   → Chercher **"People API"** → **Activer**  
     *(Sans elle, après la popup OAuth vous obtenez une erreur 403  
     `People API has not been used in project … or it is disabled`  
     car le plugin Web appelle `people.googleapis.com` pour le profil.)*
   → (Optionnel) **Google Identity Services** / APIs liées à OAuth si proposées

4. Créer les identifiants OAuth :
   → APIs & Services → Credentials
   → + CREATE CREDENTIALS → OAuth 2.0 Client IDs

5. Configurer l'écran de consentement :
   → OAuth consent screen
   → User Type : External
   → App name : EmploiConnect
   → User support email : ton@email.com
   → App logo : (optionnel)
   → Authorized domains : localhost (pour dev)
   → Developer contact : ton@email.com
   → Save and Continue

6. Créer le Client ID Web :
   → Application type : Web application
   → Name : EmploiConnect Web
   → Authorized JavaScript origins :
     http://localhost:3001
     http://localhost:3000
     https://TON_DOMAINE.com (si déployé)
   → Authorized redirect URIs :
     http://localhost:3001
     http://localhost:3000/auth/google/callback
   → CREATE
   → Copier :
     CLIENT ID     : xxx.apps.googleusercontent.com
     CLIENT SECRET : GOCSPX-xxx

7. Créer le Client ID Android (si app mobile) :
   → Application type : Android
   → Package name : com.emploiconnect.app (adapter)
   → SHA-1 certificate fingerprint :
     (obtenir avec : keytool -list -v -keystore ~/.android/debug.keystore)
```

### ÉTAPE B — Mettre les clés dans l'administration

```
Admin → Paramètres → Authentification
→ Google Client ID : xxx.apps.googleusercontent.com
→ Google Client Secret : GOCSPX-xxx
→ Sauvegarder ✅
```

---

## Table des Matières PRD

1. [Migration SQL — Colonnes Google](#1-migration-sql)
2. [Backend — Routes OAuth Google](#2-backend--routes-oauth-google)
3. [Admin — Section Authentification](#3-admin--section-authentification)
4. [Flutter — Bouton Google + Logique](#4-flutter--bouton-google--logique)

---

## 1. Migration SQL

```sql
-- database/migrations/047_google_oauth.sql

-- Ajouter colonnes Google dans utilisateurs
ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS google_id     TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS google_email  TEXT,
  ADD COLUMN IF NOT EXISTS google_photo  TEXT,
  ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email'
    CHECK (auth_provider IN ('email', 'google', 'both'));

-- Index pour recherche rapide par google_id
CREATE INDEX IF NOT EXISTS idx_utilisateurs_google_id
  ON utilisateurs(google_id);

-- Paramètres Google OAuth dans l'admin
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('google_client_id',      '', 'string',
   'Google OAuth Client ID (xxx.apps.googleusercontent.com)', 'auth'),
  ('google_client_secret',  '', 'string',
   'Google OAuth Client Secret (GOCSPX-xxx)', 'auth'),
  ('google_oauth_actif',    'true', 'boolean',
   'Activer la connexion avec Google', 'auth'),
  ('google_roles_defaut',   'candidat', 'string',
   'Rôle par défaut pour les nouveaux comptes Google', 'auth')
ON CONFLICT (cle) DO NOTHING;

-- Ajouter 'auth' aux catégories si CHECK existe
DO $$
BEGIN
  -- Mettre à jour la contrainte si nécessaire
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'parametres_plateforme_categorie_check'
  ) THEN
    ALTER TABLE parametres_plateforme
      DROP CONSTRAINT parametres_plateforme_categorie_check;
    ALTER TABLE parametres_plateforme
      ADD CONSTRAINT parametres_plateforme_categorie_check
      CHECK (categorie IN (
        'general', 'api', 'email', 'securite',
        'apparence', 'notifications', 'paiement',
        'ia', 'rapidapi', 'anthropic', 'openai', 'auth'
      ));
  END IF;
END $$;

-- Vérifier
SELECT cle, valeur FROM parametres_plateforme
WHERE categorie = 'auth';
```

---

## 2. Backend — Routes OAuth Google

### Installer les dépendances

```bash
cd backend
npm install google-auth-library
```

### Service Google OAuth

```javascript
// backend/src/services/googleAuth.service.js

const { OAuth2Client } = require('google-auth-library');

let _client = null;
let _config  = null;

// Récupérer la config Google depuis la BDD
const _getGoogleConfig = async (supabase) => {
  try {
    const { data: rows } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'google_client_id',
        'google_client_secret',
        'google_oauth_actif',
        'google_roles_defaut',
      ]);

    const c = {};
    (rows || []).forEach(r => { c[r.cle] = r.valeur; });

    return {
      clientId:     c['google_client_id']     || process.env.GOOGLE_CLIENT_ID     || '',
      clientSecret: c['google_client_secret'] || process.env.GOOGLE_CLIENT_SECRET || '',
      actif:        c['google_oauth_actif'] !== 'false',
      roleDefaut:   c['google_roles_defaut'] || 'candidat',
    };
  } catch (e) {
    console.error('[googleAuth] Config error:', e.message);
    return {
      clientId:     process.env.GOOGLE_CLIENT_ID     || '',
      clientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
      actif:        true,
      roleDefaut:   'candidat',
    };
  }
};

// Vérifier un token Google
const verifierTokenGoogle = async (idToken, supabase) => {
  const config = await _getGoogleConfig(supabase);

  if (!config.actif) {
    throw new Error('La connexion Google est désactivée');
  }

  if (!config.clientId) {
    throw new Error(
      'Google Client ID non configuré dans les paramètres admin');
  }

  const client = new OAuth2Client(config.clientId);

  const ticket = await client.verifyIdToken({
    idToken,
    audience: config.clientId,
  });

  const payload = ticket.getPayload();

  return {
    googleId:   payload['sub'],
    email:      payload['email'],
    nom:        payload['name'],
    prenom:     payload['given_name'],
    nomFamille: payload['family_name'],
    photo:      payload['picture'],
    emailVerifie: payload['email_verified'],
    roleDefaut: config.roleDefaut,
  };
};

module.exports = { verifierTokenGoogle };
```

### Route POST /api/auth/google

```javascript
// backend/src/routes/auth.routes.js
// Ajouter la route Google OAuth

const { verifierTokenGoogle } =
  require('../services/googleAuth.service');

// POST /api/auth/google
router.post('/google', async (req, res) => {
  try {
    const { id_token, role } = req.body;

    if (!id_token) {
      return res.status(400).json({
        success: false,
        message: 'Token Google manquant'
      });
    }

    console.log('[auth/google] Vérification token...');

    // Vérifier le token avec Google
    const googleUser = await verifierTokenGoogle(
      id_token, supabase);

    console.log('[auth/google] Utilisateur Google:',
      googleUser.email);

    // Chercher si l'utilisateur existe déjà
    let { data: utilisateur } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, role, photo_url, google_id, statut')
      .or(`email.eq.${googleUser.email},google_id.eq.${googleUser.googleId}`)
      .single();

    if (utilisateur) {
      // ── Utilisateur existant ─────────────────────────
      console.log('[auth/google] Utilisateur existant:', utilisateur.id);

      // Vérifier statut
      if (utilisateur.statut === 'suspendu') {
        return res.status(403).json({
          success: false,
          message: 'Votre compte est suspendu'
        });
      }

      // Mettre à jour les infos Google si manquantes
      const updates = {};
      if (!utilisateur.google_id) updates.google_id = googleUser.googleId;
      if (!utilisateur.photo_url && googleUser.photo)
        updates.photo_url = googleUser.photo;
      if (Object.keys(updates).length > 0) {
        updates.auth_provider = 'both'; // email + google
        await supabase.from('utilisateurs')
          .update(updates)
          .eq('id', utilisateur.id);
      }

    } else {
      // ── Nouvel utilisateur — Inscription automatique ─
      console.log('[auth/google] Nouveau compte Google:', googleUser.email);

      // Déterminer le rôle
      const roleChoisi = role || googleUser.roleDefaut || 'candidat';

      // Créer l'utilisateur
      const { data: newUser, error: errUser } = await supabase
        .from('utilisateurs')
        .insert({
          nom:           googleUser.nom || googleUser.email.split('@')[0],
          email:         googleUser.email,
          mot_de_passe:  null, // Pas de mot de passe pour OAuth
          role:          roleChoisi,
          google_id:     googleUser.googleId,
          google_email:  googleUser.email,
          google_photo:  googleUser.photo,
          photo_url:     googleUser.photo,
          auth_provider: 'google',
          statut:        'actif',
          email_verifie: googleUser.emailVerifie,
          date_creation: new Date().toISOString(),
        })
        .select()
        .single();

      if (errUser) throw errUser;
      utilisateur = newUser;

      // Créer le profil selon le rôle
      if (roleChoisi === 'candidat') {
        await supabase.from('chercheurs_emploi').insert({
          utilisateur_id: newUser.id,
          profil_visible: true,
          recevoir_propositions: true,
        });
      } else if (roleChoisi === 'recruteur') {
        await supabase.from('entreprises').insert({
          utilisateur_id:   newUser.id,
          nom_entreprise:   googleUser.nom || 'Mon Entreprise',
          email_contact:    googleUser.email,
          statut_validation: 'en_attente',
        });
      }

      console.log('[auth/google] ✅ Nouveau compte créé:',
        newUser.id, '| Rôle:', roleChoisi);
    }

    // Générer le JWT EmploiConnect
    const jwt = require('jsonwebtoken');
    const token = jwt.sign(
      {
        id:    utilisateur.id,
        email: utilisateur.email,
        role:  utilisateur.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Récupérer photo actuelle
    const { data: userFinal } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, role, photo_url, statut')
      .eq('id', utilisateur.id)
      .single();

    console.log('[auth/google] ✅ Token JWT généré pour:',
      utilisateur.email);

    return res.json({
      success: true,
      message: 'Connexion Google réussie',
      data: {
        token,
        user: {
          id:        userFinal.id,
          nom:       userFinal.nom,
          email:     userFinal.email,
          role:      userFinal.role,
          photo_url: userFinal.photo_url,
        }
      }
    });

  } catch (err) {
    console.error('[auth/google] Erreur:', err.message);

    // Messages d'erreur clairs
    if (err.message.includes('Token used too late')) {
      return res.status(401).json({
        success: false,
        message: 'Session Google expirée. Reconnectez-vous.'
      });
    }
    if (err.message.includes('Invalid token signature')) {
      return res.status(401).json({
        success: false,
        message: 'Token Google invalide.'
      });
    }

    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

module.exports = router;
```

---

## 3. Admin — Section Authentification

```dart
// Dans admin_settings_screen.dart
// Ajouter une nouvelle section "Authentification"

// Dans le TabBar admin paramètres :
// Ajouter onglet "Auth" ou section dans l'onglet existant

Widget _buildSectionAuthentification() =>
  _CarteSection(
    titre: '🔐 Authentification — Connexion Google',
    children: [

    // Toggle activer/désactiver Google
    _ToggleNotif(
      icon:      Icons.account_circle_rounded,
      couleur:   const Color(0xFF4285F4), // Couleur Google
      titre:     'Connexion avec Google',
      sousTitre: 'Permettre aux utilisateurs de se connecter via Google',
      valeur:    (_params['google_oauth_actif'] ?? 'true') == 'true',
      onChanged: (v) {
        final val = v ? 'true' : 'false';
        setState(() => _params['google_oauth_actif'] = val);
        _saveParam('google_oauth_actif', val);
      }),
    const SizedBox(height: 16),

    // Info configuration
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A56DB).withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📋 Comment configurer Google OAuth :',
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: const Color(0xFF1E40AF))),
        const SizedBox(height: 8),
        ...[
          '1. Aller sur console.cloud.google.com',
          '2. Créer un projet EmploiConnect',
          '3. APIs & Services → Credentials → OAuth 2.0',
          '4. Copier le Client ID et Client Secret',
          '5. Coller ci-dessous et sauvegarder',
        ].map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(s, style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFF1E40AF))))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final url = Uri.parse(
              'https://console.cloud.google.com');
            if (await canLaunchUrl(url)) {
              await launchUrl(url,
                mode: LaunchMode.externalApplication);
            }
          },
          child: Text(
            '→ Ouvrir Google Cloud Console',
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: const Color(0xFF1A56DB),
              decoration: TextDecoration.underline))),
      ])),
    const SizedBox(height: 14),

    // Client ID
    _buildChampCle(
      label:     'Google Client ID',
      hint:      'xxx.apps.googleusercontent.com',
      cle:       'google_client_id',
      lienAide:  'https://console.cloud.google.com',
      texteAide: 'Obtenir sur Google Cloud Console'),
    const SizedBox(height: 12),

    // Client Secret
    _buildChampCle(
      label:     'Google Client Secret',
      hint:      'GOCSPX-...',
      cle:       'google_client_secret',
      lienAide:  'https://console.cloud.google.com',
      texteAide: 'Obtenir sur Google Cloud Console'),
    const SizedBox(height: 12),

    // Rôle par défaut
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Rôle par défaut (nouveaux comptes Google)',
        style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: const Color(0xFF374151))),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: _params['google_roles_defaut'] ?? 'candidat',
        decoration: InputDecoration(
          filled: true, fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0)))),
        items: const [
          DropdownMenuItem(
            value: 'candidat',
            child: Text('👤 Candidat (chercheur d\'emploi)')),
          DropdownMenuItem(
            value: 'recruteur',
            child: Text('🏢 Recruteur (entreprise)')),
        ],
        onChanged: (v) {
          if (v != null) {
            setState(() =>
              _params['google_roles_defaut'] = v);
            _saveParam('google_roles_defaut', v);
          }
        }),
    ]),
    const SizedBox(height: 16),

    // Bouton tester
    SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.verified_rounded, size: 16),
        label: const Text('Vérifier la configuration'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF4285F4)),
          foregroundColor: const Color(0xFF4285F4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8))),
        onPressed: _verifierConfigGoogle)),
  ]);

Future<void> _verifierConfigGoogle() async {
  final clientId = _params['google_client_id'] ?? '';
  if (clientId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('❌ Client ID manquant'),
      backgroundColor: Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating));
    return;
  }
  if (!clientId.contains('apps.googleusercontent.com')) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('❌ Format Client ID invalide'),
      backgroundColor: Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating));
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('✅ Configuration Google valide !'),
    backgroundColor: Color(0xFF10B981),
    behavior: SnackBarBehavior.floating));
}
```

---

## 4. Flutter — Bouton Google + Logique

### Dépendances à ajouter

```yaml
# Dans frontend/pubspec.yaml
dependencies:
  google_sign_in: ^6.2.1
```

### Service Google Sign In

```dart
// frontend/lib/services/google_auth_service.dart

import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final _instance = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Client ID Web (pour Flutter Web)
    // Sera récupéré depuis l'API admin
  );

  // Se connecter avec Google
  static Future<String?> signIn() async {
    try {
      // Déconnecter d'abord pour forcer le choix de compte
      await _instance.signOut();

      final account = await _instance.signIn();
      if (account == null) return null; // Annulé par l'utilisateur

      final auth     = await account.authentication;
      final idToken  = auth.idToken;

      print('[GoogleAuth] Connecté: ${account.email}');
      print('[GoogleAuth] Token obtenu: ${idToken?.substring(0, 20)}...');

      return idToken;
    } catch (e) {
      print('[GoogleAuth] Erreur: $e');
      return null;
    }
  }

  // Se déconnecter
  static Future<void> signOut() async {
    await _instance.signOut();
  }
}
```

### Bouton Google dans les pages Login/Register

```dart
// Dans frontend/lib/screens/auth/login_page.dart
// ET dans register_page.dart
// Remplacer le bouton Google existant par la version fonctionnelle

// ── Bouton Continuer avec Google ──────────────────────────
Widget _buildBoutonGoogle({String role = 'candidat'}) =>
  Container(
    width: double.infinity,
    height: 48,
    margin: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
        elevation: 0),
      onPressed: _isGoogleLoading
          ? null : () => _connecterAvecGoogle(role),
      child: _isGoogleLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4285F4))),
              const SizedBox(width: 10),
              Text('Connexion Google...',
                style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF374151))),
            ])
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Logo Google SVG officiel
              SizedBox(width: 20, height: 20,
                child: _GoogleLogo()),
              const SizedBox(width: 10),
              Text('Continuer avec Google',
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151))),
            ])));

bool _isGoogleLoading = false;

Future<void> _connecterAvecGoogle([String role = 'candidat']) async {
  setState(() => _isGoogleLoading = true);
  try {
    // 1. Obtenir le token Google
    final idToken = await GoogleAuthService.signIn();

    if (idToken == null) {
      // Utilisateur a annulé
      setState(() => _isGoogleLoading = false);
      return;
    }

    // 2. Envoyer au backend EmploiConnect
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_token': idToken,
        'role':     role, // 'candidat' ou 'recruteur'
      })).timeout(const Duration(seconds: 15));

    final body = jsonDecode(res.body);

    if (body['success'] == true) {
      final data  = body['data'] as Map<String, dynamic>;
      final token = data['token']   as String;
      final user  = data['user']    as Map<String, dynamic>;
      final userRole = user['role'] as String;

      // 3. Sauvegarder le token JWT
      await context.read<AuthProvider>().setToken(
        token: token,
        userId:   user['id'],
        userRole: userRole,
        userName: user['nom'],
        photoUrl: user['photo_url'],
        email:    user['email'],
      );

      // 4. Rediriger selon le rôle
      if (mounted) {
        switch (userRole) {
          case 'candidat':
            context.go('/dashboard-candidat');
            break;
          case 'recruteur':
            context.go('/dashboard-recruteur');
            break;
          case 'admin':
            context.go('/dashboard-admin');
            break;
          default:
            context.go('/dashboard-candidat');
        }
      }
    } else {
      throw Exception(body['message'] ?? 'Erreur connexion Google');
    }

  } catch (e) {
    print('[Google Login] Erreur: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded,
            color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
            e.toString().contains('désactivée')
                ? 'Connexion Google désactivée par l\'administrateur'
                : e.toString().contains('non configuré')
                    ? 'Connexion Google non configurée'
                    : 'Erreur connexion Google. Réessayez.',
            style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white))),
        ]),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4)));
    }
  } finally {
    if (mounted) setState(() => _isGoogleLoading = false);
  }
}

// Logo Google officiel (SVG)
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Google G coloré
    final paint = Paint()..style = PaintingStyle.fill;

    // Rouge (partie supérieure droite)
    paint.color = const Color(0xFFEA4335);
    final path1 = Path()
      ..moveTo(w * 0.5, h * 0.21)
      ..lineTo(w * 0.5, h * 0.42)
      ..lineTo(w * 0.79, h * 0.42)
      ..quadraticBezierTo(w * 0.72, h * 0.21, w * 0.5, h * 0.21);
    canvas.drawPath(path1, paint);

    // Bleu (partie droite)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h), -0.5, 1.0, false,
      paint..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.18
            ..strokeCap = StrokeCap.round);

    // Vert (partie inférieure gauche)
    paint.color = const Color(0xFF34A853);

    // Jaune (partie gauche)
    paint.color = const Color(0xFFFBBC05);

    // Version simplifiée : dessiner un G coloré
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4))),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(
      (w - textPainter.width) / 2,
      (h - textPainter.height) / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}
```

### Version simplifiée du bouton Google (recommandée)

```dart
// Version plus simple et plus fiable :
// Utiliser une image PNG du logo Google

Widget _buildBoutonGoogle({String role = 'candidat'}) =>
  SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10))),
      onPressed: _isGoogleLoading
          ? null : () => _connecterAvecGoogle(role),
      child: _isGoogleLoading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4285F4)))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Image PNG du logo Google (à placer dans assets/)
              Image.asset(
                'assets/images/google_logo.png',
                width: 20, height: 20,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_circle_rounded,
                  color: Color(0xFF4285F4), size: 20)),
              const SizedBox(width: 10),
              Text('Continuer avec Google',
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151))),
            ])));
```

### Placer le bouton dans les pages auth

```dart
// Dans login_page.dart — Après le formulaire email/password
// AVANT le bouton "Se connecter"

// Séparateur
Row(children: [
  const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text('ou', style: GoogleFonts.inter(
      fontSize: 12, color: const Color(0xFF94A3B8)))),
  const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
]),
const SizedBox(height: 14),

// Bouton Google
_buildBoutonGoogle(role: 'candidat'),
const SizedBox(height: 14),

// Bouton connexion normal
// ... bouton existant ...
```

```dart
// Dans register_candidat_page.dart
// Ajouter en haut du formulaire :

_buildBoutonGoogle(role: 'candidat'),
const SizedBox(height: 12),

// Séparateur
Row(children: [
  const Expanded(child: Divider()),
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text('ou créer un compte',
      style: GoogleFonts.inter(
        fontSize: 12, color: const Color(0xFF94A3B8)))),
  const Expanded(child: Divider()),
]),
const SizedBox(height: 14),

// Formulaire existant...
```

### Configuration pour Flutter Web

```dart
// Dans frontend/web/index.html
// Ajouter dans <head> :
// <meta name="google-signin-client_id" content="TON_CLIENT_ID.apps.googleusercontent.com">
```

```dart
// Dans frontend/lib/main.dart
// Initialiser Google Sign In avec le client ID depuis l'API

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pour Flutter Web : configurer le client ID Google
  // Le client ID sera chargé depuis l'API au démarrage
  // Via AppConfigProvider

  runApp(const MyApp());
}
```

### Charger le client ID Google au démarrage

```dart
// Dans frontend/lib/providers/app_config_provider.dart
// Ajouter le chargement du client ID Google

class AppConfigProvider extends ChangeNotifier {
  String _googleClientId = '';
  String get googleClientId => _googleClientId;

  Future<void> loadConfig() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/config/general'));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        _googleClientId = data['google_client_id'] as String? ?? '';
        notifyListeners();
      }
    } catch (_) {}
  }
}
```

### Route backend pour exposer le Client ID publiquement

```javascript
// Dans backend/src/routes/config.routes.js
// Exposer le Client ID (pas le secret) pour Flutter

router.get('/google-client-id', async (req, res) => {
  try {
    const { data: row } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'google_client_id')
      .single();

    const clientId = row?.valeur || process.env.GOOGLE_CLIENT_ID || '';

    return res.json({
      success:   true,
      client_id: clientId,
      actif:     clientId.length > 0,
    });
  } catch (err) {
    res.status(500).json({ success: false });
  }
});
```

---

## Ajouter le logo Google dans les assets

```bash
# Créer le dossier assets si nécessaire
mkdir -p frontend/assets/images

# Télécharger le logo Google officiel
# OU créer un fichier SVG simple

# Dans pubspec.yaml, s'assurer que assets est configuré :
# flutter:
#   assets:
#     - assets/images/
```

Logo Google SVG à placer dans `assets/images/google_logo.svg` :
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/>
  <path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/>
  <path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/>
  <path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24C44,22.659,43.862,21.35,43.611,20.083z"/>
</svg>
```

---

## Variables d'environnement backend (.env)

```env
# Ajouter dans backend/.env
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxx
```

---

## Résumé — Ce que TU dois faire vs ce que Cursor fait

### TOI (15-20 minutes) :

```
1. Aller sur console.cloud.google.com
2. Créer projet "EmploiConnect"
3. Configurer OAuth consent screen
4. Créer Client ID OAuth 2.0 Web
5. Copier Client ID + Client Secret
6. Mettre dans Admin → Paramètres → Authentification
7. Mettre aussi dans backend/.env
8. Télécharger logo Google PNG (google_logo.png)
   → Chercher "google logo png" sur Google Images
   → Sauvegarder dans frontend/assets/images/
```

### CURSOR (code) :

```
→ Migration SQL 047
→ Service googleAuth.service.js
→ Route POST /api/auth/google
→ Section Admin paramètres authentification
→ Bouton Google dans login + register
→ Service GoogleAuthService Flutter
→ Logique connexion + redirection
→ Chargement Client ID depuis API
```

---

## Critères d'Acceptation

- [ ] Bouton "Continuer avec Google" visible sur login
- [ ] Bouton "Continuer avec Google" visible sur register
- [ ] Clic → Popup Google → Choix du compte
- [ ] Connexion réussie → JWT généré → Redirection
- [ ] Nouvel utilisateur créé automatiquement en BDD
- [ ] Photo Google récupérée dans le profil
- [ ] Admin peut désactiver Google OAuth
- [ ] Admin configure les clés sans toucher au code
- [ ] Message clair si Google désactivé ou non configuré

---

*PRD EmploiConnect v8.9 — Google OAuth*
*Cursor / Kirsoft AI — Phase 22*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
