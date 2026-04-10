# PRD — EmploiConnect · Fix Analyse IA des CVs
## Product Requirements Document v8.1 — Resume Parser Fix
**Stack : Node.js/Express + Flutter + RapidAPI Resume Parser**
**Outil : Cursor / Kirsoft AI**
**Objectif : Faire fonctionner vraiment l'analyse IA des CVs**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
>
> Ce PRD corrige un seul problème mais très important :
> l'API Resume Parser retourne 0 compétences.
> Lire tout le PRD avant de commencer.
> Implémenter dans l'ordre exact des sections.

---

## Comprendre le problème (lire attentivement)

```
SITUATION ACTUELLE — Pourquoi ça échoue :

Étape 1 : Le candidat uploade son CV sur Supabase Storage
          → Supabase génère une URL comme :
            https://xxxxx.supabase.co/storage/v1/object/sign/
            cv-files/mon-cv.pdf?token=eyJhbGci...

Étape 2 : Notre backend envoie cette URL à RapidAPI Resume Parser

Étape 3 : RapidAPI ESSAIE d'accéder à cette URL
          → ÉCHEC car :
            a) L'URL Supabase est une "Signed URL" (privée)
               Elle expire après 60 secondes
            b) RapidAPI n'a pas les droits d'accès à Supabase
            c) RapidAPI est un serveur externe qui ne peut pas
               s'authentifier sur notre Supabase

Étape 4 : RapidAPI retourne "0 compétences" car elle n'a
          jamais pu lire le fichier

─────────────────────────────────────────────────────
SOLUTION — Ce qu'il faut faire :

Étape 1 : Le candidat uploade son CV (pareil qu'avant)

Étape 2 : Quand le candidat clique "Analyser" :
          Notre backend Node.js va LUI-MÊME chercher
          le fichier sur Supabase et le met en mémoire
          (comme télécharger un fichier sur ton ordinateur
           mais c'est le serveur qui le fait)

Étape 3 : Notre backend ENVOIE le vrai fichier à RapidAPI
          (comme envoyer une pièce jointe sur WhatsApp —
           on n'envoie pas un lien, on envoie le fichier)

Étape 4 : RapidAPI reçoit le vrai fichier PDF/DOCX
          → Elle peut le lire
          → Elle retourne les compétences, expériences, etc.

Étape 5 : Les données s'affichent dans Flutter
─────────────────────────────────────────────────────
```

---

## Table des Matières

1. [Installation dépendances](#1-installation-dépendances)
2. [Backend — Service IA corrigé](#2-backend--service-ia-corrigé)
3. [Backend — Route analyser CV](#3-backend--route-analyser-cv)
4. [Flutter — Widget analyse animé](#4-flutter--widget-analyse-animé)
5. [Tests à effectuer](#5-tests-à-effectuer)

---

## 1. Installation dépendances

```bash
# Dans le dossier backend, exécuter ces commandes :
cd backend
npm install form-data
npm install axios

# Vérifier que pdfkit est installé
npm list pdfkit
# Si absent : npm install pdfkit

# Résultat attendu :
# + form-data@4.x.x
# + axios@1.x.x
```

---

## 2. Backend — Service IA corrigé

### Remplacer COMPLÈTEMENT le fichier `backend/src/services/ia.service.js`

```javascript
// backend/src/services/ia.service.js
// VERSION CORRIGÉE — Envoie le vrai fichier à l'API

'use strict';

const axios    = require('axios');
const FormData = require('form-data');
const https    = require('https');
const http     = require('http');
const { supabase } = require('../config/supabase');

// ═══════════════════════════════════════════════════════════
// FONCTION 1 : Télécharger un fichier depuis une URL
// C'est le SERVEUR qui télécharge, pas l'utilisateur
// ═══════════════════════════════════════════════════════════

const _telechargerFichier = (url) => {
  return new Promise((resolve, reject) => {

    console.log('[IA] Téléchargement fichier depuis:', url.substring(0, 80));

    // Choisir http ou https selon l'URL
    const client = url.startsWith('https://') ? https : http;

    const requete = client.get(url, (reponse) => {

      // Cas 1 : Redirection (301 ou 302)
      // → Suivre la redirection automatiquement
      if (reponse.statusCode === 301 || reponse.statusCode === 302) {
        const nouvelleUrl = reponse.headers.location;
        console.log('[IA] Redirection vers:', nouvelleUrl?.substring(0, 80));
        return _telechargerFichier(nouvelleUrl).then(resolve).catch(reject);
      }

      // Cas 2 : Erreur HTTP
      if (reponse.statusCode !== 200) {
        return reject(new Error(
          `Erreur téléchargement: HTTP ${reponse.statusCode}`
        ));
      }

      // Cas 3 : Succès → Lire le fichier par morceaux
      const morceaux = [];
      reponse.on('data', (morceau) => morceaux.push(morceau));
      reponse.on('end', () => {
        const buffer = Buffer.concat(morceaux);
        console.log('[IA] Fichier téléchargé:', buffer.length, 'bytes');
        resolve({
          buffer,
          // Type du fichier (PDF, Word, etc.)
          contentType: reponse.headers['content-type']
            || 'application/pdf',
        });
      });
      reponse.on('error', reject);
    });

    requete.on('error', reject);
    // Timeout : si le téléchargement prend plus de 15 secondes → abandonner
    requete.setTimeout(15000, () => {
      requete.destroy();
      reject(new Error('Timeout téléchargement fichier'));
    });
  });
};

// ═══════════════════════════════════════════════════════════
// FONCTION 2 : Récupérer les clés API depuis la BDD
// ═══════════════════════════════════════════════════════════

const _getClesAPI = async () => {
  const { data: rows } = await supabase
    .from('parametres_plateforme')
    .select('cle, valeur')
    .in('cle', [
      'rapidapi_key',
      'rapidapi_resume_parser_host',
      'rapidapi_similarity_host',
      'rapidapi_topic_tagging_host',
    ]);

  const cles = {};
  (rows || []).forEach(row => {
    cles[row.cle] = row.valeur;
  });

  return {
    apiKey:         cles['rapidapi_key'] || process.env.RAPIDAPI_KEY,
    parserHost:     cles['rapidapi_resume_parser_host']
                    || process.env.RAPIDAPI_RESUME_PARSER_HOST
                    || 'resume-parser3.p.rapidapi.com',
    similarityHost: cles['rapidapi_similarity_host']
                    || process.env.RAPIDAPI_SIMILARITY_HOST
                    || 'twinword-text-similarity-v1.p.rapidapi.com',
    taggingHost:    cles['rapidapi_topic_tagging_host']
                    || process.env.RAPIDAPI_TOPIC_TAGGING_HOST
                    || 'twinword-topic-tagging1.p.rapidapi.com',
  };
};

// ═══════════════════════════════════════════════════════════
// FONCTION 3 : Analyser un CV
// C'est la fonction principale — corrigée
// ═══════════════════════════════════════════════════════════

const analyserCV = async (cvUrl) => {
  console.log('\n[analyserCV] ═══ DÉBUT ANALYSE ═══');
  console.log('[analyserCV] URL:', cvUrl?.substring(0, 80));

  // ── Étape A : Récupérer les clés API ─────────────────────
  const cles = await _getClesAPI();

  if (!cles.apiKey) {
    console.warn('[analyserCV] ⚠️ Aucune clé API configurée');
    return {
      competences: [],
      experience:  [],
      formation:   [],
      langues:     ['Français'],
      erreur:      'Clé API non configurée dans les paramètres admin',
    };
  }

  // ── Étape B : Télécharger le fichier CV ──────────────────
  // (C'est le serveur qui télécharge, automatiquement)
  let fichier;
  try {
    fichier = await _telechargerFichier(cvUrl);
  } catch (errDl) {
    console.error('[analyserCV] ❌ Échec téléchargement:', errDl.message);
    return {
      competences: [],
      experience:  [],
      formation:   [],
      langues:     ['Français'],
      erreur:      `Impossible de télécharger le CV: ${errDl.message}`,
    };
  }

  // ── Étape C : Préparer l'envoi à l'API ──────────────────
  // Détecter l'extension du fichier
  const nomFichier = cvUrl.split('/').pop()?.split('?')[0] || 'cv.pdf';
  const extension  = nomFichier.split('.').pop()?.toLowerCase() || 'pdf';

  // Déterminer le bon type MIME selon l'extension
  const mimeTypes = {
    'pdf':  'application/pdf',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'doc':  'application/msword',
    'txt':  'text/plain',
  };
  const contentType = mimeTypes[extension] || fichier.contentType;

  console.log('[analyserCV] Fichier:', nomFichier, '|', contentType);
  console.log('[analyserCV] Taille:', fichier.buffer.length, 'bytes');

  // Créer le formulaire avec le fichier attaché
  // (exactement comme envoyer une pièce jointe)
  const formulaire = new FormData();
  formulaire.append('file', fichier.buffer, {
    filename:    nomFichier,
    contentType: contentType,
  });

  // ── Étape D : Envoyer le fichier à RapidAPI ──────────────
  console.log('[analyserCV] Envoi à RapidAPI:', cles.parserHost);

  let reponseAPI;
  try {
    reponseAPI = await axios.post(
      `https://${cles.parserHost}/api/resume_parser/`,
      formulaire,
      {
        headers: {
          // Headers du formulaire multipart (boundary, etc.)
          ...formulaire.getHeaders(),
          // Clés RapidAPI
          'X-RapidAPI-Key':  cles.apiKey,
          'X-RapidAPI-Host': cles.parserHost,
        },
        timeout: 30000, // 30 secondes max
        maxContentLength: Infinity,
        maxBodyLength:    Infinity,
      }
    );
    console.log('[analyserCV] ✅ Réponse API reçue !');
    console.log('[analyserCV] Données:',
      JSON.stringify(reponseAPI.data).substring(0, 400));
  } catch (errAPI) {
    const status = errAPI.response?.status;
    const detail = JSON.stringify(errAPI.response?.data || errAPI.message);
    console.error('[analyserCV] ❌ Erreur API:', status, detail);
    return {
      competences: [],
      experience:  [],
      formation:   [],
      langues:     ['Français'],
      erreur:      `API Error ${status}: ${detail}`,
    };
  }

  // ── Étape E : Extraire les données de la réponse ─────────
  return _extraireDonnees(reponseAPI.data);
};

// ═══════════════════════════════════════════════════════════
// FONCTION 4 : Extraire les données de la réponse API
// L'API peut retourner différentes structures
// ═══════════════════════════════════════════════════════════

const _extraireDonnees = (data) => {
  console.log('[extraire] Traitement de la réponse...');

  const competences = [];
  const experience  = [];
  const formation   = [];
  const langues     = ['Français'];

  // ── Compétences ───────────────────────────────────────────
  // L'API peut retourner les compétences sous différents noms
  const sourcesComps = [
    data.skills,
    data.Skills,
    data.technical_skills,
    data.TechnicalSkills,
    data.soft_skills,
    data.SoftSkills,
    data.extracted_skills,
    data.key_skills,
  ];

  for (const source of sourcesComps) {
    if (!source) continue;
    if (Array.isArray(source)) {
      for (const item of source) {
        if (typeof item === 'string') {
          competences.push(item.trim());
        } else if (item?.name) {
          competences.push(item.name.trim());
        } else if (item?.skill) {
          competences.push(item.skill.trim());
        }
      }
    } else if (typeof source === 'object') {
      // Parfois c'est un objet {skill: score}
      competences.push(...Object.keys(source));
    } else if (typeof source === 'string') {
      // Parfois c'est une chaîne "Flutter, Dart, Python"
      competences.push(...source.split(',').map(s => s.trim()));
    }
  }

  // ── Expériences ───────────────────────────────────────────
  const sourcesExp = [
    data.experience,
    data.Experience,
    data.work_experience,
    data.WorkExperience,
    data.employment_history,
  ];

  for (const source of sourcesExp) {
    if (!source) continue;
    const liste = Array.isArray(source) ? source : [source];
    for (const exp of liste) {
      if (exp && (exp.company || exp.title || exp.position)) {
        experience.push({
          titre:      exp.title || exp.position || exp.job_title || '',
          entreprise: exp.company || exp.employer || exp.organization || '',
          duree:      exp.duration || exp.dates || '',
          description: exp.description || exp.responsibilities || '',
        });
      }
    }
  }

  // ── Formations ────────────────────────────────────────────
  const sourcesEdu = [
    data.education,
    data.Education,
    data.academic_history,
  ];

  for (const source of sourcesEdu) {
    if (!source) continue;
    const liste = Array.isArray(source) ? source : [source];
    for (const edu of liste) {
      if (edu && (edu.school || edu.degree || edu.institution)) {
        formation.push({
          diplome: edu.degree || edu.qualification || '',
          ecole:   edu.school || edu.institution || edu.university || '',
          annee:   edu.year || edu.graduation_year || '',
        });
      }
    }
  }

  // ── Langues ───────────────────────────────────────────────
  const sourcesLang = [data.languages, data.Languages];
  for (const source of sourcesLang) {
    if (!source) continue;
    const liste = Array.isArray(source) ? source : [source];
    for (const lang of liste) {
      const nom = typeof lang === 'string' ? lang : lang?.language || lang?.name;
      if (nom && !langues.includes(nom)) langues.push(nom);
    }
  }

  // Nom du candidat depuis le CV
  const nomCV = data.name || data.Name || data.full_name || data.candidate_name || '';

  // Filtrer et dédoublonner les compétences
  const compsFiltrees = [...new Set(
    competences
      .filter(c => c && c.trim().length > 1 && c.length < 50)
      .map(c => c.trim())
  )];

  console.log('[extraire] Résultat final:');
  console.log('  Compétences:', compsFiltrees.length, '-', compsFiltrees.slice(0, 5).join(', '));
  console.log('  Expériences:', experience.length);
  console.log('  Formations:', formation.length);

  return {
    competences: compsFiltrees,
    experience,
    formation,
    langues:    [...new Set(langues)],
    nom:        nomCV,
    fallback:   false,
  };
};

// ═══════════════════════════════════════════════════════════
// FONCTION 5 : Calculer le score de matching
// Candidat ↔ Offre d'emploi
// ═══════════════════════════════════════════════════════════

const calculerMatchingScore = async (profilCandidat, offre) => {
  try {
    const cles = await _getClesAPI();
    if (!cles.apiKey || !cles.similarityHost) return 0;

    // Texte du candidat : ses compétences + titre
    const texteCandidат = [
      ...(profilCandidat.competences || []),
      profilCandidat.texte_cv || '',
    ].filter(Boolean).join(' ');

    // Texte de l'offre : titre + description + compétences requises
    const texteOffre = [
      offre.titre || '',
      offre.description || '',
      ...(Array.isArray(offre.competences_requises)
        ? offre.competences_requises
        : []),
    ].filter(Boolean).join(' ');

    if (!texteCandidат.trim() || !texteOffre.trim()) return 0;

    const { data: reponse } = await axios.get(
      `https://${cles.similarityHost}/similarity/`,
      {
        params: {
          text1: texteCandidат.substring(0, 500),
          text2: texteOffre.substring(0, 500),
        },
        headers: {
          'X-RapidAPI-Key':  cles.apiKey,
          'X-RapidAPI-Host': cles.similarityHost,
        },
        timeout: 10000,
      }
    );

    const similarity = reponse?.similarity || reponse?.score || 0;
    const score = Math.round(Math.min(similarity * 100, 100));
    console.log('[matching] Score:', score, '%');
    return score;

  } catch (err) {
    console.warn('[matching] Erreur:', err.message);
    return 0;
  }
};

// ═══════════════════════════════════════════════════════════
// FONCTION 6 : Extraire les mots-clés d'une offre
// (Pour le recruteur quand il crée une offre)
// ═══════════════════════════════════════════════════════════

const extraireMotsCles = async (texte) => {
  try {
    const cles = await _getClesAPI();
    if (!cles.apiKey || !cles.taggingHost) return [];

    const { data: reponse } = await axios.get(
      `https://${cles.taggingHost}/classify/`,
      {
        params: { text: texte.substring(0, 1000) },
        headers: {
          'X-RapidAPI-Key':  cles.apiKey,
          'X-RapidAPI-Host': cles.taggingHost,
        },
        timeout: 10000,
      }
    );

    const topics = reponse?.topic || {};
    return Object.keys(topics)
      .sort((a, b) => topics[b] - topics[a])
      .slice(0, 10);

  } catch (err) {
    console.warn('[tagging] Erreur:', err.message);
    return [];
  }
};

module.exports = {
  analyserCV,
  calculerMatchingScore,
  extraireMotsCles,
};
```

---

## 3. Backend — Route analyser CV

### Remplacer dans `backend/src/routes/cv.routes.js`

```javascript
// Route POST /api/cv/analyser
// Déclenche l'analyse IA du CV du candidat connecté

router.post('/analyser', auth, async (req, res) => {
  try {
    console.log('\n[/cv/analyser] ═══ NOUVELLE DEMANDE ═══');
    console.log('[/cv/analyser] Utilisateur:', req.user.id);

    // Récupérer le chercheur
    const { data: chercheur, error: cErr } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (cErr || !chercheur) {
      return res.status(404).json({
        success: false,
        message: 'Profil candidat non trouvé'
      });
    }

    // Récupérer le CV
    const { data: cv, error: cvErr } = await supabase
      .from('cv')
      .select('id, fichier_url, competences_extrait, type_fichier')
      .eq('chercheur_id', chercheur.id)
      .single();

    if (cvErr || !cv) {
      return res.status(404).json({
        success: false,
        message: 'Aucun CV trouvé. Uploadez d\'abord votre CV.'
      });
    }

    if (!cv.fichier_url) {
      return res.status(400).json({
        success: false,
        message: 'URL du CV manquante. Veuillez ré-uploader votre CV.'
      });
    }

    console.log('[/cv/analyser] CV trouvé:', cv.id);
    console.log('[/cv/analyser] URL:', cv.fichier_url.substring(0, 80));

    // ── CAS SPÉCIAL : CV créé depuis la plateforme ────────
    // Les compétences sont déjà sauvegardées → pas besoin d'API
    if (cv.competences_extrait?.source === 'plateforme_cv_builder') {
      const comps = cv.competences_extrait.competences || [];
      const exps  = cv.competences_extrait.experience  || [];

      console.log('[/cv/analyser] CV plateforme → bypass API');

      // Mettre à jour la date d'analyse
      await supabase.from('cv').update({
        date_analyse: new Date().toISOString(),
      }).eq('id', cv.id);

      return res.json({
        success: true,
        message: `✅ Analyse terminée ! ${comps.length} compétence(s) et ${exps.length} expérience(s) détectée(s).`,
        data: {
          competences:    comps,
          experience:     exps,
          formation:      cv.competences_extrait.formation || [],
          langues:        cv.competences_extrait.langues || ['Français'],
          nb_competences: comps.length,
          nb_experiences: exps.length,
          source:         'plateforme',
        }
      });
    }

    // ── CAS NORMAL : CV importé → appeler l'API ───────────
    console.log('[/cv/analyser] CV importé → appel API Resume Parser');

    const { analyserCV } = require('../services/ia.service');
    const resultat = await analyserCV(cv.fichier_url);

    const nbComps = resultat.competences?.length || 0;
    const nbExps  = resultat.experience?.length  || 0;

    console.log('[/cv/analyser] Résultat:', nbComps, 'compétences,', nbExps, 'expériences');

    // Sauvegarder les résultats en BDD
    if (nbComps > 0 || nbExps > 0) {
      await supabase.from('cv').update({
        competences_extrait: {
          competences: resultat.competences || [],
          experience:  resultat.experience  || [],
          formation:   resultat.formation   || [],
          langues:     resultat.langues     || ['Français'],
          source:      'api_externe',
          analyse_le:  new Date().toISOString(),
        },
        date_analyse: new Date().toISOString(),
      }).eq('id', cv.id);

      console.log('[/cv/analyser] ✅ Données sauvegardées en BDD');
    }

    // Construire le message de retour
    let message;
    let conseil = null;

    if (nbComps >= 8) {
      message = `✅ Excellent ! ${nbComps} compétences et ${nbExps} expériences extraites avec succès.`;
    } else if (nbComps >= 3) {
      message = `✅ ${nbComps} compétence(s) et ${nbExps} expérience(s) détectée(s).`;
    } else if (nbComps > 0) {
      message = `⚠️ Seulement ${nbComps} compétence(s) détectée(s).`;
      conseil = 'Pour de meilleurs résultats, utilisez le Créateur de CV de la plateforme ou uploadez un CV Word (.docx).';
    } else if (resultat.erreur) {
      message = `❌ Erreur d'analyse : ${resultat.erreur}`;
      conseil = 'Essayez le Créateur de CV intégré pour une analyse garantie.';
    } else {
      message = '❌ Aucune compétence détectée dans ce CV.';
      conseil = 'Assurez-vous que votre CV est en format texte (pas scanné) ou utilisez le Créateur de CV.';
    }

    return res.json({
      success: true,
      message,
      data: {
        competences:    resultat.competences || [],
        experience:     resultat.experience  || [],
        nb_competences: nbComps,
        nb_experiences: nbExps,
        conseil,
      }
    });

  } catch (err) {
    console.error('[/cv/analyser] ERREUR:', err.message, err.stack);
    res.status(500).json({
      success: false,
      message: `Erreur serveur: ${err.message}`
    });
  }
});
```

---

## 4. Flutter — Widget analyse animé

```dart
// lib/screens/candidat/widgets/analyse_ia_widget.dart
// Widget qui montre visuellement que l'IA travaille

class AnalyseIAWidget extends StatefulWidget {
  final VoidCallback onAnalysed;
  const AnalyseIAWidget({super.key, required this.onAnalysed});
  @override
  State<AnalyseIAWidget> createState() => _AnalyseIAWidgetState();
}

class _AnalyseIAWidgetState extends State<AnalyseIAWidget>
    with SingleTickerProviderStateMixin {

  bool    _isAnalysing    = false;
  int     _etapeActuelle  = -1; // -1 = pas encore commencé
  String? _message;
  int     _nbComps        = 0;
  String? _conseil;
  bool    _succes         = false;

  late AnimationController _dotCtrl;
  late Animation<double>   _dotAnim;

  // Les étapes visibles pendant l'analyse
  static const _etapes = [
    '📥  Téléchargement du CV...',
    '📄  Lecture du document...',
    '🤖  Analyse IA en cours...',
    '📊  Extraction des compétences...',
    '✅  Analyse terminée !',
  ];

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _dotAnim = Tween<double>(begin: 0.5, end: 1.0)
      .animate(_dotCtrl);
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  Future<void> _lancer() async {
    setState(() {
      _isAnalysing   = true;
      _etapeActuelle = 0;
      _message       = null;
      _conseil       = null;
      _succes        = false;
    });

    // Avancer les étapes visuelles pendant que l'API travaille
    // Chaque étape dure ~900ms (l'API peut prendre jusqu'à 30s)
    final avanceur = Stream.periodic(
      const Duration(milliseconds: 900), (i) => i + 1,
    ).take(3).listen((etape) {
      if (mounted && _isAnalysing) {
        setState(() => _etapeActuelle = etape);
      }
    });

    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/cv/analyser'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 40));

      // Arrêter les étapes visuelles
      await avanceur.cancel();

      final body = jsonDecode(res.body);

      if (mounted) {
        final data   = body['data'] as Map<String, dynamic>? ?? {};
        _nbComps     = data['nb_competences'] as int? ?? 0;
        _conseil     = data['conseil'] as String?;
        _message     = body['message'] as String? ?? '';
        _succes      = _nbComps > 0;

        setState(() {
          _etapeActuelle = 4; // Étape finale : terminé
          _isAnalysing   = false;
        });

        // Recharger le profil pour afficher les nouvelles données
        widget.onAnalysed();
      }
    } catch (e) {
      await avanceur.cancel();
      if (mounted) {
        setState(() {
          _message     = 'Erreur : $e';
          _isAnalysing = false;
          _etapeActuelle = -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isAnalysing
              ? const Color(0xFF1A56DB).withOpacity(0.5)
              : const Color(0xFFE2E8F0)),
        boxShadow: _isAnalysing ? [BoxShadow(
          color: const Color(0xFF1A56DB).withOpacity(0.1),
          blurRadius: 16, offset: const Offset(0, 4))] : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── En-tête ─────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF1A56DB), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(100)),
            child: Row(children: [
              const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text('IA', style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.white)),
            ])),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Analyse IA de votre CV',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
            Text('Extraction automatique des compétences',
              style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF64748B))),
          ])),
          // Bouton lancer
          if (!_isAnalysing)
            ElevatedButton.icon(
              icon: Icon(
                _etapeActuelle == 4
                    ? Icons.refresh_rounded
                    : Icons.play_arrow_rounded,
                size: 16),
              label: Text(
                _etapeActuelle == 4
                    ? 'Réanalyser' : 'Lancer l\'analyse',
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
              onPressed: _lancer),
        ]),

        // ── Étapes animées (visibles pendant l'analyse) ──
        if (_isAnalysing || _etapeActuelle >= 0) ...[
          const SizedBox(height: 16),
          ...List.generate(_etapes.length, (i) {
            final fait    = i < _etapeActuelle;
            final enCours = i == _etapeActuelle;
            final attente = i > _etapeActuelle;

            return AnimatedOpacity(
              opacity: attente && _etapeActuelle >= 0 ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [

                  // Icône état
                  SizedBox(width: 22, height: 22,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: fait
                          ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF10B981), size: 20,
                              key: ValueKey('fait'))
                          : enCours
                              ? FadeTransition(
                                  opacity: _dotAnim,
                                  child: Container(
                                    width: 20, height: 20,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1A56DB),
                                      shape: BoxShape.circle),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                        key: ValueKey('encours')))))
                              : const Icon(
                                  Icons.radio_button_unchecked,
                                  color: Color(0xFFCBD5E1), size: 20,
                                  key: ValueKey('attente')),
                    )),
                  const SizedBox(width: 10),

                  // Label étape
                  Text(_etapes[i], style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: fait || enCours
                        ? FontWeight.w600 : FontWeight.w400,
                    color: fait
                        ? const Color(0xFF10B981)
                        : enCours
                            ? const Color(0xFF1A56DB)
                            : const Color(0xFF94A3B8))),
                ])));
          }),
        ],

        // ── Résultat final ───────────────────────────────
        if (_message != null && !_isAnalysing) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _succes
                  ? const Color(0xFFECFDF5)
                  : _nbComps > 0
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _succes
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : _nbComps > 0
                        ? const Color(0xFFF59E0B).withOpacity(0.3)
                        : const Color(0xFFEF4444).withOpacity(0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_message!, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: _succes
                    ? const Color(0xFF065F46)
                    : _nbComps > 0
                        ? const Color(0xFF92400E)
                        : const Color(0xFF991B1B))),

              if (_conseil != null) ...[
                const SizedBox(height: 6),
                Text(_conseil!, style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _succes
                      ? const Color(0xFF065F46)
                      : const Color(0xFF92400E))),
              ],

              // Bouton Créer CV si peu de résultats
              if (!_succes) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () =>
                    context.push('/dashboard-candidat/cv/creer'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF1A56DB), Color(0xFF7C3AED)]),
                      borderRadius: BorderRadius.circular(100)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 13),
                      const SizedBox(width: 6),
                      Text('Créer mon CV depuis la plateforme',
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                    ]))),
              ],
            ])),
        ],
      ]),
    );
  }
}
```

---

## 5. Tests à effectuer

### Test 1 — Vérifier que form-data est installé

```bash
cd backend
npm list form-data
# Attendu : form-data@4.x.x ✅
```

### Test 2 — Redémarrer le backend et vérifier les logs

```bash
npm run dev
# Dans les logs, chercher :
# [analyserCV] ═══ DÉBUT ANALYSE ═══
# [analyserCV] Fichier téléchargé: XXXXX bytes
# [analyserCV] ✅ Réponse API reçue !
```

### Test 3 — CV créé depuis la plateforme

```
1. Aller dans Mon Profil → Créer mon CV
2. Remplir au moins : Nom, Titre, 2-3 compétences
3. Télécharger le PDF
4. Revenir dans Mon Profil → CV
5. Cliquer "Lancer l'analyse"
6. Voir les étapes défiler : Téléchargement → Lecture → Analyse → Extraction → ✅
7. Résultat attendu : "✅ X compétences détectées"
```

### Test 4 — CV importé (fichier externe)

```
Format recommandé : Word .docx (meilleur résultat)
Format acceptable : PDF avec texte sélectionnable

1. Uploader un vrai CV Word/PDF
2. Cliquer "Lancer l'analyse"
3. Voir les étapes défiler
4. Si succès → compétences affichées
5. Si échec → bouton "Créer mon CV" affiché
```

### Ce que doivent afficher les logs backend

```
Bon résultat :
[analyserCV] ═══ DÉBUT ANALYSE ═══
[analyserCV] Fichier téléchargé: 45823 bytes
[analyserCV] Envoi à RapidAPI: resume-parser3.p.rapidapi.com
[analyserCV] ✅ Réponse API reçue !
[analyserCV] Données: {"skills":["Flutter","Dart","Firebase"]...}
[extraire] Compétences: 8 - Flutter, Dart, Firebase, Git, REST, API...
[/cv/analyser] ✅ Données sauvegardées en BDD

Mauvais résultat (à déboguer) :
[analyserCV] ❌ Erreur API: 400 {"message":"..."}
→ Vérifier la clé API dans les paramètres admin

[analyserCV] ❌ Échec téléchargement: ...
→ Vérifier que le bucket cv-files existe dans Supabase
```

---

*PRD EmploiConnect v8.1 — Resume Parser Fix*
*Cursor / Kirsoft AI — Phase 14*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
