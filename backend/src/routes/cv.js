/**
 * Routes CV : upload (chercheur), consulter mon CV, URL signée pour téléchargement
 */
import { Router } from 'express';
import multer from 'multer';
import { supabase, BUCKET_CV } from '../config/supabase.js';
import { createCvSignedUrl, CV_SIGNED_URL_TTL_SEC } from '../helpers/cvSignedUrl.js';
import { authenticate, requireRole } from '../middleware/auth.js';
import { attachProfileIds } from '../helpers/userProfile.js';
import { ROLES } from '../config/constants.js';
import { extractTextFromBuffer, simpleExtractSkills } from '../services/cvExtract.js';
import { parseResumeWithApi } from '../services/nlpRapidApi.js';
import { analyserCV } from '../services/ia.service.js';
import { sendCvAnalyseTermineeEmail } from '../services/mail.service.js';
import { resumerTexteProfil } from '../services/textResume.service.js';

const router = Router();

const MAX_FILE_SIZE = 20 * 1024 * 1024; // 20 MB
const ALLOWED_EXTS = ['pdf', 'doc', 'docx', 'txt'];

const MIME_MAP = {
  pdf: 'application/pdf',
  doc: 'application/msword',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  txt: 'text/plain',
};

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE },
  fileFilter: (req, file, cb) => {
    console.log('[Upload] Fichier reçu:', file.originalname, file.mimetype, file.size);
    cb(null, true);
  },
});

router.use(authenticate);
router.use(attachProfileIds);

async function prepareResumeForProfil(texteBrut) {
  let t = String(texteBrut || '').trim();
  if (!t) return '';
  if (t.length > 500) t = await resumerTexteProfil(t, 500);
  return t;
}

/** Met à jour `about` uniquement s’il est vide (PRD §1). */
async function applyAboutIfEmpty(chercheurId, resumeAPropos) {
  if (!resumeAPropos || String(resumeAPropos).trim().length <= 20) return false;
  const { data: ch } = await supabase
    .from('chercheurs_emploi')
    .select('about')
    .eq('id', chercheurId)
    .maybeSingle();
  if (String(ch?.about || '').trim()) return false;
  await supabase
    .from('chercheurs_emploi')
    .update({ about: String(resumeAPropos).trim() })
    .eq('id', chercheurId);
  console.log('[/cv/analyser] À propos mis à jour depuis CV');
  return true;
}

async function mettreAJourProfilDepuisAnalyse(chercheurId, competences, experience, formation, langues) {
  try {
    const { data: profil } = await supabase
      .from('chercheurs_emploi')
      .select('competences, experiences, formations, langues')
      .eq('id', chercheurId)
      .maybeSingle();

    const compsExistantes = Array.isArray(profil?.competences) ? profil.competences : [];
    const nouvellesComps = [...new Set([
      ...compsExistantes,
      ...(Array.isArray(competences) ? competences : []),
    ])];

    const expsExistantes = Array.isArray(profil?.experiences) ? profil.experiences : [];
    const nouvellesExps = Array.isArray(experience) && experience.length > 0 ? experience : expsExistantes;

    const fmtsExistantes = Array.isArray(profil?.formations) ? profil.formations : [];
    const nouvellesFmts = Array.isArray(formation) && formation.length > 0 ? formation : fmtsExistantes;

    const langsExistantes = Array.isArray(profil?.langues) ? profil.langues : ['Français'];
    const nouvellesLangs = [...new Set([
      ...langsExistantes,
      ...(Array.isArray(langues) ? langues : []),
      'Français',
    ])];

    await supabase
      .from('chercheurs_emploi')
      .update({
        competences: nouvellesComps,
        experiences: nouvellesExps,
        formations: nouvellesFmts,
        langues: nouvellesLangs,
      })
      .eq('id', chercheurId);

    return true;
  } catch (err) {
    console.error('[mettreAJourProfilDepuisAnalyse]', err?.message || err);
    return false;
  }
}

/**
 * POST /cv/upload - Téléverser un CV (chercheur uniquement)
 * multipart/form-data, champ "file" (PDF ou DOCX, max 5 Mo)
 */
router.post('/upload', requireRole(ROLES.CHERCHEUR), (req, res, next) => {
  upload.single('file')(req, res, (err) => {
    if (!err && req.file) return next();
    upload.single('cv')(req, res, next);
  });
}, async (req, res) => {
  try {
    let chercheurId = req.chercheurId;
    if (!chercheurId) {
      const { data: created, error: insErr } = await supabase
        .from('chercheurs_emploi')
        .insert({ utilisateur_id: req.user.id })
        .select('id')
        .single();
      if (insErr || !created) {
        console.error('[uploadCV] création chercheur:', insErr);
        return res.status(404).json({
          success: false,
          message: 'Profil candidat non trouvé',
        });
      }
      chercheurId = created.id;
      req.chercheurId = chercheurId;
    }

    if (!req.file || !req.file.buffer) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier CV reçu (champ "file" ou "cv")',
      });
    }

    console.log('[uploadCV]', {
      name: req.file.originalname,
      mime: req.file.mimetype,
      size: req.file.size,
    });

    const rawExt = String(req.file.originalname || 'cv')
      .split('.')
      .pop()
      ?.toLowerCase()
      .replace(/[^a-z0-9]/g, '') || 'pdf';
    const ext = ALLOWED_EXTS.includes(rawExt)
      ? rawExt
      : (String(req.file.mimetype || '').includes('pdf') ? 'pdf' : 'docx');

    const nomPropre = String(req.file.originalname || `cv.${ext}`)
      .replace(/\.pdf\.pdf$/i, '.pdf')
      .replace(/\.docx\.docx$/i, '.docx')
      .replace(/[^a-zA-Z0-9._-]/g, '_');
    const extFromName = nomPropre.includes('.')
      ? nomPropre.split('.').pop()?.toLowerCase().replace(/[^a-z0-9]/g, '') || ext
      : ext;
    const extFinal = ALLOWED_EXTS.includes(extFromName) ? extFromName : ext;
    const mimeType = MIME_MAP[extFinal] || req.file.mimetype || 'application/octet-stream';

    const baseSansExt = nomPropre.includes('.')
      ? nomPropre.slice(0, nomPropre.lastIndexOf('.'))
      : nomPropre.replace(/_+$/, '');
    const fichierAvecExt = nomPropre.toLowerCase().endsWith(`.${extFinal}`)
      ? nomPropre
      : `${baseSansExt || 'cv'}.${extFinal}`;
    const storagePath = `${chercheurId}/${Date.now()}-${fichierAvecExt}`;

    console.log('[uploadCV] Upload vers:', BUCKET_CV, storagePath);

    const { error: uploadError } = await supabase.storage
      .from(BUCKET_CV)
      .upload(storagePath, req.file.buffer, {
        contentType: mimeType,
        upsert: false,
      });

    if (uploadError) {
      console.error('[uploadCV] Erreur Supabase:', uploadError);
      return res.status(500).json({
        success: false,
        message: `Erreur storage: ${uploadError.message}`,
      });
    }

    const fichierUrl = storagePath;

    let texteComplet = '';
    let competencesExtrait = null;
    let domaineActivite = null;
    let niveauExperience = null;
    let experienceJson = null;

    try {
      texteComplet = await extractTextFromBuffer(req.file.buffer, req.file.mimetype);
      const extracted = simpleExtractSkills(texteComplet);
      competencesExtrait = extracted.competences;
      domaineActivite = extracted.domaine_activite;
      niveauExperience = extracted.niveau_experience;
    } catch (err) {
      console.error('Extraction texte CV:', err);
    }

    const nlpResult = await parseResumeWithApi(
      req.file.buffer,
      req.file.originalname || `cv.${extFinal}`,
      req.file.mimetype
    );
    if (nlpResult) {
      if (nlpResult.competences?.length) competencesExtrait = nlpResult.competences;
      if (nlpResult.domaine_activite) domaineActivite = nlpResult.domaine_activite;
      if (nlpResult.niveau_experience) niveauExperience = nlpResult.niveau_experience;
      if (nlpResult.experience?.length) experienceJson = nlpResult.experience;
    }

    const cvPayload = {
      chercheur_id: chercheurId,
      fichier_url: fichierUrl,
      nom_fichier: req.file.originalname || null,
      type_fichier: extFinal.toUpperCase(),
      taille_fichier: req.file.size,
      competences_extrait: competencesExtrait,
      experience: experienceJson ?? undefined,
      domaine_activite: domaineActivite,
      niveau_experience: niveauExperience,
      texte_complet: texteComplet || null,
      date_analyse: (texteComplet || nlpResult) ? new Date().toISOString() : null,
    };

    const { data: existing } = await supabase
      .from('cv')
      .select('id')
      .eq('chercheur_id', chercheurId)
      .single();

    let result;
    if (existing) {
      const { data: updated, error: updateErr } = await supabase
        .from('cv')
        .update(cvPayload)
        .eq('chercheur_id', chercheurId)
        .select()
        .single();
      if (updateErr) {
        console.error('Update cv:', updateErr);
        return res.status(500).json({
          success: false,
          message: 'Erreur lors de la mise à jour du CV',
        });
      }
      result = updated;
    } else {
      const { data: inserted, error: insertErr } = await supabase
        .from('cv')
        .insert(cvPayload)
        .select()
        .single();
      if (insertErr) {
        console.error('Insert cv:', insertErr);
        return res.status(500).json({
          success: false,
          message: 'Erreur lors de l\'enregistrement du CV',
        });
      }
      result = inserted;
    }

    const { data: pub } = supabase.storage.from(BUCKET_CV).getPublicUrl(storagePath);
    const fichierUrlPublic = pub?.publicUrl || storagePath;

    const notifyUser = { id: req.user.id, email: req.user.email, nom: req.user.nom };
    setImmediate(() => {
      (async () => {
        try {
          const { data: signed, error: signErr } = await supabase.storage
            .from(BUCKET_CV)
            .createSignedUrl(storagePath, 3600);
          if (signErr || !signed?.signedUrl) return;
          const resultat = await analyserCV(signed.signedUrl);
          const nComp = Array.isArray(resultat.competences) ? resultat.competences.length : 0;
          const nExp = Array.isArray(resultat.experience) ? resultat.experience.length : 0;
          const nFmt = Array.isArray(resultat.formation) ? resultat.formation.length : 0;
          const resumeUp = await prepareResumeForProfil(resultat.resume_profil);
          const hasStructured = nComp > 0 || nExp > 0 || nFmt > 0;
          const hasResume = resumeUp.length > 20;

          const { data: cvRowUp } = await supabase
            .from('cv')
            .select('competences_extrait')
            .eq('id', result.id)
            .single();
          const prev = cvRowUp?.competences_extrait && typeof cvRowUp.competences_extrait === 'object'
            ? cvRowUp.competences_extrait
            : {};

          const mergedUp = {
            competences: hasStructured ? (resultat.competences || []) : (Array.isArray(prev.competences) ? prev.competences : []),
            experience: hasStructured ? (resultat.experience || []) : (Array.isArray(prev.experience) ? prev.experience : []),
            formation: hasStructured ? (resultat.formation || []) : (Array.isArray(prev.formation) ? prev.formation : []),
            langues: hasStructured ? (resultat.langues || ['Français']) : (Array.isArray(prev.langues) ? prev.langues : ['Français']),
            resume_profil: resumeUp || prev.resume_profil || prev.resume || '',
            score_ia: resultat.score_ia ?? prev.score_ia ?? null,
            fallback: resultat.fallback === true,
            source: resultat.source || 'api_externe',
            analyse_le: new Date().toISOString(),
          };

          await supabase
            .from('cv')
            .update({
              competences_extrait: mergedUp,
              date_analyse: new Date().toISOString(),
            })
            .eq('id', result.id);

          if (hasStructured) {
            await mettreAJourProfilDepuisAnalyse(
              chercheurId,
              resultat.competences || [],
              resultat.experience || [],
              resultat.formation || [],
              resultat.langues || ['Français'],
            );
            console.log('[uploadCV] Profil chercheur enrichi depuis analyse');
          }
          if (hasResume) {
            await applyAboutIfEmpty(chercheurId, resumeUp);
          }

          console.log('[uploadCV] IA OK:', nComp, 'compétences');
          const extractionRiche = hasStructured || hasResume;
          await supabase.from('notifications').insert({
            destinataire_id: notifyUser.id,
            type_destinataire: 'individuel',
            titre: extractionRiche
              ? 'Analyse de votre CV terminée'
              : 'Analyse CV : peu d’informations extraites',
            message: extractionRiche
              ? 'Les compétences extraites sont à jour dans votre profil.'
              : 'Le fichier a été analysé mais peu de compétences ou d’expériences ont été détectées (PDF scanné, API ou format). Complétez votre profil à la main si besoin.',
            type: 'systeme',
            lien: '/dashboard/profil',
          });
          if (extractionRiche) {
            void sendCvAnalyseTermineeEmail({ to: notifyUser.email, nom: notifyUser.nom });
          }
        } catch (e) {
          console.warn('[uploadCV] IA non bloquant:', e.message);
        }
      })();
    });

    res.status(existing ? 200 : 201).json({
      success: true,
      message: existing
        ? 'CV mis à jour'
        : 'CV uploadé avec succès. Analyse IA en cours...',
      data: {
        id: result.id,
        fichier_url: fichierUrlPublic,
        nom_fichier: req.file.originalname,
      },
      cv: {
        id: result.id,
        nom_fichier: result.nom_fichier,
        type_fichier: result.type_fichier,
        taille_fichier: result.taille_fichier,
        competences_extrait: result.competences_extrait,
        domaine_activite: result.domaine_activite,
        date_upload: result.date_upload,
        date_analyse: result.date_analyse,
      },
    });
  } catch (err) {
    if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'Fichier trop volumineux (max 20 Mo)',
      });
    }
    console.error('[uploadCV] Exception:', err);
    res.status(500).json({
      success: false,
      message: err.message || 'Erreur upload CV',
    });
  }
});

/**
 * POST /cv/analyser - Relancer l'analyse IA du CV courant (chercheur)
 * Téléchargement fichier côté serveur + multipart RapidAPI (voir ia.service).
 */
router.post('/analyser', requireRole(ROLES.CHERCHEUR), async (req, res) => {
  try {
    console.log('\n[/cv/analyser] ═══ NOUVELLE DEMANDE ═══');
    console.log('[/cv/analyser] Utilisateur:', req.user?.id);

    const chercheurId = req.chercheurId;
    if (!chercheurId) {
      return res.status(404).json({
        success: false,
        message: 'Profil candidat non trouvé',
      });
    }

    const { data: cvRow, error: cvErr } = await supabase
      .from('cv')
      .select('id, fichier_url, nom_fichier, competences_extrait, type_fichier, texte_complet, taille_fichier')
      .eq('chercheur_id', chercheurId)
      .single();

    if (cvErr || !cvRow) {
      return res.status(404).json({
        success: false,
        message: 'Aucun CV trouvé. Uploadez votre CV d\'abord.',
      });
    }

    if (!cvRow.fichier_url) {
      return res.status(400).json({
        success: false,
        message: 'URL du CV manquante. Veuillez ré-uploader votre CV.',
      });
    }

    console.log('[/cv/analyser] CV trouvé:', cvRow.id);
    console.log('[/cv/analyser] fichier_url:', String(cvRow.fichier_url).substring(0, 80));

    const srcPlateforme = cvRow.competences_extrait?.source;
    const compsExistantes = Array.isArray(cvRow.competences_extrait?.competences)
      ? cvRow.competences_extrait.competences
      : [];
    const expsExistantes = Array.isArray(cvRow.competences_extrait?.experience)
      ? cvRow.competences_extrait.experience
      : [];
    const ressembleCvGenere = String(cvRow.nom_fichier || '').startsWith('CV_')
      || String(cvRow.fichier_url || '').includes('cv-genere-');
    const bypassPlateforme = srcPlateforme === 'plateforme_cv_builder'
      || srcPlateforme === 'plateforme'
      || (ressembleCvGenere && (compsExistantes.length > 0 || expsExistantes.length > 0));

    if (bypassPlateforme) {
      const comps = compsExistantes;
      const exps = expsExistantes;
      const fmts = Array.isArray(cvRow.competences_extrait?.formation) ? cvRow.competences_extrait.formation : [];
      const langs = Array.isArray(cvRow.competences_extrait?.langues) ? cvRow.competences_extrait.langues : ['Français'];

      console.log('[/cv/analyser] CV plateforme → bypass API');
      console.log('[/cv/analyser] Compétences:', comps.length);

      const msgPlateforme = srcPlateforme === 'plateforme_cv_builder'
        ? `✅ ${comps.length} compétence(s) détectée(s) depuis votre CV plateforme`
        : `✅ Analyse terminée ! ${comps.length} compétence(s) et ${exps.length} expérience(s) détectée(s).`;

      const profilMaj = await mettreAJourProfilDepuisAnalyse(
        chercheurId,
        comps,
        exps,
        fmts,
        langs,
      );

      const { error: updBypass } = await supabase
        .from('cv')
        .update({ date_analyse: new Date().toISOString() })
        .eq('id', cvRow.id);

      if (updBypass) {
        console.error('[POST /cv/analyser] update bypass:', updBypass);
        return res.status(500).json({
          success: false,
          message: 'Erreur lors de la mise à jour',
        });
      }

      const resumePlat = String(
        cvRow.competences_extrait?.resume_profil
          || cvRow.competences_extrait?.resume
          || '',
      ).trim();

      return res.json({
        success: true,
        message: msgPlateforme,
        data: {
          cv_id: cvRow.id,
          competences: comps,
          experience: exps,
          formation: fmts,
          langues: langs,
          resume_profil: resumePlat,
          nb_competences: comps.length,
          nb_experiences: exps.length,
          nb_formations: fmts.length,
          source: srcPlateforme === 'plateforme_cv_builder' ? 'plateforme_cv_builder' : 'plateforme',
          profil_mis_a_jour: profilMaj,
          conseil: null,
        },
      });
    }

    const tailleOctets = Number(cvRow.taille_fichier);
    if (Number.isFinite(tailleOctets) && tailleOctets > 0 && tailleOctets < 5000) {
      console.warn('[/cv/analyser] Fichier < 5000 octets → pas d’appel API parsing externe');
      const comps = compsExistantes;
      const exps = expsExistantes;
      const fmts = Array.isArray(cvRow.competences_extrait?.formation)
        ? cvRow.competences_extrait.formation
        : [];
      const langs = Array.isArray(cvRow.competences_extrait?.langues)
        ? cvRow.competences_extrait.langues
        : ['Français'];

      let profilMajPetit = false;
      if (comps.length > 0 || exps.length > 0) {
        profilMajPetit = await mettreAJourProfilDepuisAnalyse(
          chercheurId,
          comps,
          exps,
          fmts,
          langs,
        );
        await supabase
          .from('cv')
          .update({ date_analyse: new Date().toISOString() })
          .eq('id', cvRow.id);
      }

      const conseilPetit =
        'Pour que l’IA analyse correctement : uploadez un vrai CV Word (.docx) ou un PDF avec du texte sélectionnable.';

      const resumePetit = String(
        cvRow.competences_extrait?.resume_profil
          || cvRow.competences_extrait?.resume
          || '',
      ).trim();

      return res.json({
        success: true,
        message:
          comps.length > 0 || exps.length > 0
            ? `✅ ${comps.length} compétence(s) réutilisée(s) (fichier court, analyse externe ignorée).`
            : '⚠️ Ce fichier CV est trop léger pour une extraction IA fiable.',
        data: {
          cv_id: cvRow.id,
          competences: comps,
          experience: exps,
          formation: fmts,
          langues: langs,
          resume_profil: resumePetit,
          nb_competences: comps.length,
          nb_experiences: exps.length,
          nb_formations: fmts.length,
          source: 'fichier_trop_petit',
          profil_mis_a_jour: profilMajPetit,
          conseil: conseilPetit,
        },
      });
    }

    console.log('[/cv/analyser] CV importé → appel API (multipart)');

    const resultat = await analyserCV(cvRow.fichier_url);

    const nbComps = resultat.competences?.length || 0;
    const nbExps = resultat.experience?.length || 0;
    const nbFmts = resultat.formation?.length || 0;

    console.log('[/cv/analyser] Résultat:', nbComps, 'compétences,', nbExps, 'expériences');

    const resumeFinal = await prepareResumeForProfil(resultat.resume_profil);
    const hasStructured = nbComps > 0 || nbExps > 0 || nbFmts > 0;
    const hasResume = resumeFinal.length > 20;

    let profilMaj = false;
    if (hasStructured || hasResume) {
      const prev = cvRow.competences_extrait && typeof cvRow.competences_extrait === 'object'
        ? cvRow.competences_extrait
        : {};
      const mergedCe = {
        competences: hasStructured ? (resultat.competences || []) : (Array.isArray(prev.competences) ? prev.competences : []),
        experience: hasStructured ? (resultat.experience || []) : (Array.isArray(prev.experience) ? prev.experience : []),
        formation: hasStructured ? (resultat.formation || []) : (Array.isArray(prev.formation) ? prev.formation : []),
        langues: hasStructured ? (resultat.langues || ['Français']) : (Array.isArray(prev.langues) ? prev.langues : ['Français']),
        resume_profil: resumeFinal || prev.resume_profil || prev.resume || '',
        score_ia: resultat.score_ia ?? prev.score_ia ?? null,
        fallback: resultat.fallback === true,
        source: 'api_externe',
        analyse_le: new Date().toISOString(),
      };

      const { error: updateErr } = await supabase
        .from('cv')
        .update({
          competences_extrait: mergedCe,
          date_analyse: new Date().toISOString(),
        })
        .eq('id', cvRow.id);

      if (updateErr) {
        console.error('[POST /cv/analyser] update cv:', updateErr);
        return res.status(500).json({
          success: false,
          message: 'Erreur lors de la sauvegarde de l\'analyse',
        });
      }
      console.log('[/cv/analyser] ✅ Données sauvegardées en BDD');
      if (hasStructured) {
        profilMaj = await mettreAJourProfilDepuisAnalyse(
          chercheurId,
          resultat.competences || [],
          resultat.experience || [],
          resultat.formation || [],
          resultat.langues || ['Français'],
        );
      }
      if (hasResume) {
        const aboutOk = await applyAboutIfEmpty(chercheurId, resumeFinal);
        if (aboutOk) profilMaj = true;
      }
    }

    const peutRecyclerExistant = (nbComps === 0 && nbExps === 0 && Boolean(resultat.erreur))
      && (compsExistantes.length > 0 || expsExistantes.length > 0);
    if (peutRecyclerExistant) {
      console.warn('[/cv/analyser] API indisponible, conservation des données existantes du CV');
      return res.json({
        success: true,
        message: '⚠️ API indisponible. Vos données CV existantes ont été conservées.',
        data: {
          cv_id: cvRow.id,
          competences: compsExistantes,
          experience: expsExistantes,
          formation: cvRow.competences_extrait?.formation || [],
          langues: cvRow.competences_extrait?.langues || ['Français'],
          nb_competences: compsExistantes.length,
          nb_experiences: expsExistantes.length,
          nb_formations: Array.isArray(cvRow.competences_extrait?.formation)
            ? cvRow.competences_extrait.formation.length
            : 0,
          resume_profil: String(
            cvRow.competences_extrait?.resume_profil
              || cvRow.competences_extrait?.resume
              || '',
          ).trim(),
          conseil: 'Vous pouvez réessayer plus tard ou utiliser le créateur CV intégré.',
          fallback: true,
          source: 'donnees_existantes',
          profil_mis_a_jour: false,
        },
      });
    }

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

    try {
      const extractionRiche = nbComps > 0 || nbExps > 0 || resumeFinal.length > 20;
      await supabase.from('notifications').insert({
        destinataire_id: req.user.id,
        type_destinataire: 'individuel',
        titre: extractionRiche
          ? 'Analyse de votre CV terminée'
          : 'Analyse CV : peu d’informations extraites',
        message: extractionRiche
          ? 'Les compétences extraites sont à jour dans votre profil.'
          : 'Peu de compétences ou d’expériences détectées. Vérifiez la qualité du CV ou complétez le profil manuellement.',
        type: 'systeme',
        lien: '/dashboard/profil',
      });
      if (extractionRiche) {
        void sendCvAnalyseTermineeEmail({ to: req.user.email, nom: req.user.nom });
      }
    } catch (nErr) {
      console.warn('[POST /cv/analyser] notif/email non bloquant:', nErr?.message || nErr);
    }

    return res.json({
      success: true,
      message,
      data: {
        cv_id: cvRow.id,
        competences: resultat.competences || [],
        experience: resultat.experience || [],
        formation: resultat.formation || [],
        langues: resultat.langues || ['Français'],
        resume_profil: resumeFinal,
        nb_competences: nbComps,
        nb_experiences: nbExps,
        nb_formations: nbFmts,
        profil_mis_a_jour: profilMaj,
        conseil,
        fallback: resultat.fallback === true,
      },
    });
  } catch (err) {
    console.error('[/cv/analyser] ERREUR:', err?.message, err?.stack);
    return res.status(500).json({
      success: false,
      message: err?.message ? `Erreur serveur: ${err.message}` : 'Erreur serveur',
    });
  }
});

/**
 * GET /cv/me - Mon CV (chercheur uniquement)
 */
router.get('/me', requireRole(ROLES.CHERCHEUR), async (req, res) => {
  try {
    const chercheurId = req.chercheurId;
    if (!chercheurId) {
      return res.status(400).json({ message: 'Profil chercheur introuvable' });
    }

    const { data, error } = await supabase
      .from('cv')
      .select('id, nom_fichier, type_fichier, taille_fichier, competences_extrait, domaine_activite, niveau_experience, date_upload, date_analyse')
      .eq('chercheur_id', chercheurId)
      .single();

    if (error || !data) {
      return res.status(404).json({ message: 'Aucun CV enregistré' });
    }

    res.json(data);
  } catch (err) {
    console.error('GET /cv/me:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * GET /cv/download-url - URL signée pour télécharger mon CV (chercheur)
 * Ou pour une candidature : ?candidature_id=xxx (entreprise propriétaire de l'offre)
 */
router.get('/download-url', async (req, res) => {
  try {
    const { candidature_id: candidatureId } = req.query;
    const { role } = req.user;

    if (candidatureId) {
      const { data: cand } = await supabase
        .from('candidatures')
        .select('id, cv_id, offre_id, offres_emploi(entreprise_id)')
        .eq('id', candidatureId)
        .single();

      if (!cand?.cv_id) {
        return res.status(404).json({ message: 'Candidature ou CV non trouvé' });
      }

      let entrepriseId = cand.offres_emploi?.entreprise_id;
      if (entrepriseId == null) {
        const { data: off } = await supabase.from('offres_emploi').select('entreprise_id').eq('id', cand.offre_id).single();
        entrepriseId = off?.entreprise_id;
      }
      const canAccess = role === ROLES.ADMIN || (role === ROLES.ENTREPRISE && req.entrepriseId === entrepriseId);
      if (!canAccess) {
        return res.status(403).json({ message: 'Accès non autorisé à ce CV' });
      }

      const { data: cvRow } = await supabase.from('cv').select('fichier_url').eq('id', cand.cv_id).single();
      if (!cvRow) return res.status(404).json({ message: 'CV non trouvé' });

      const { signedUrl, error: signErr } = await createCvSignedUrl(cvRow.fichier_url);
      if (signErr || !signedUrl) {
        console.error('[GET /cv/download-url candidature]', signErr?.message || signErr);
        return res.status(500).json({ message: 'Impossible de générer l\'URL de téléchargement' });
      }
      return res.json({ url: signedUrl, expiresIn: CV_SIGNED_URL_TTL_SEC });
    }

    if (role !== ROLES.CHERCHEUR) {
      return res.status(400).json({ message: 'Utilisez candidature_id= pour accéder au CV d\'une candidature' });
    }

    const chercheurId = req.chercheurId;
    if (!chercheurId) return res.status(400).json({ message: 'Profil chercheur introuvable' });

    const { data: cvRow } = await supabase.from('cv').select('fichier_url').eq('chercheur_id', chercheurId).single();
    if (!cvRow) return res.status(404).json({ message: 'Aucun CV enregistré' });

    const { signedUrl, error: signErr } = await createCvSignedUrl(cvRow.fichier_url);
    if (signErr || !signedUrl) {
      console.error('[GET /cv/download-url chercheur]', signErr?.message || signErr);
      return res.status(500).json({ message: 'Impossible de générer l\'URL de téléchargement' });
    }
    res.json({ url: signedUrl, expiresIn: CV_SIGNED_URL_TTL_SEC });
  } catch (err) {
    console.error('GET /cv/download-url:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

export default router;
