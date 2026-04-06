/**
 * Routes CV : upload (chercheur), consulter mon CV, URL signée pour téléchargement
 */
import { Router } from 'express';
import multer from 'multer';
import { supabase, BUCKET_CV } from '../config/supabase.js';
import { authenticate, requireRole } from '../middleware/auth.js';
import { attachProfileIds } from '../helpers/userProfile.js';
import { ROLES } from '../config/constants.js';
import { extractTextFromBuffer, simpleExtractSkills } from '../services/cvExtract.js';
import { parseResumeWithApi } from '../services/nlpRapidApi.js';
import { analyserCV } from '../services/ia.service.js';
import { sendCvAnalyseTermineeEmail } from '../services/mail.service.js';

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
    const mimeType = MIME_MAP[ext] || req.file.mimetype || 'application/octet-stream';
    const storagePath = `${chercheurId}/${Date.now()}-${(req.file.originalname || 'cv').replace(/[^a-zA-Z0-9._-]/g, '_')}.${ext}`;

    console.log('[uploadCV] Upload vers:', BUCKET_CV, storagePath);

    const { error: uploadError } = await supabase.storage
      .from(BUCKET_CV)
      .upload(storagePath, req.file.buffer, {
        contentType: mimeType,
        upsert: true,
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
      req.file.originalname || `cv.${ext}`,
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
      type_fichier: ext.toUpperCase(),
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
          await supabase
            .from('cv')
            .update({
              competences_extrait: {
                competences: resultat.competences || [],
                experience: resultat.experience || [],
                formation: resultat.formation || [],
                langues: resultat.langues || ['Français'],
                fallback: resultat.fallback || true,
                analyse_le: new Date().toISOString(),
              },
              date_analyse: new Date().toISOString(),
            })
            .eq('id', result.id);
          console.log('[uploadCV] IA OK:', resultat.competences?.length, 'compétences');
          const nComp = Array.isArray(resultat.competences) ? resultat.competences.length : 0;
          const nExp = Array.isArray(resultat.experience) ? resultat.experience.length : 0;
          const extractionRiche = nComp > 0 || nExp > 0;
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
 */
router.post('/analyser', requireRole(ROLES.CHERCHEUR), async (req, res) => {
  try {
    const chercheurId = req.chercheurId;
    if (!chercheurId) {
      return res.status(404).json({
        success: false,
        message: 'Profil candidat non trouvé',
      });
    }

    const { data: cvRow, error: cvErr } = await supabase
      .from('cv')
      .select('id, fichier_url, texte_complet')
      .eq('chercheur_id', chercheurId)
      .single();

    if (cvErr || !cvRow) {
      return res.status(404).json({
        success: false,
        message: 'Aucun CV trouvé. Uploadez votre CV d\'abord.',
      });
    }

    let cvPublicUrl = null;
    if (cvRow.fichier_url) {
      const { data: signed } = await supabase.storage
        .from(BUCKET_CV)
        .createSignedUrl(cvRow.fichier_url, 60);
      cvPublicUrl = signed?.signedUrl || null;
    }

    const result = await analyserCV(cvPublicUrl || '');
    const payload = {
      competences_extrait: {
        competences: result.competences || [],
        experience: result.experience || [],
        formation: result.formation || [],
        langues: result.langues || ['Français'],
        score_ia: result.score_ia ?? null,
        fallback: result.fallback === true,
        analyse_le: new Date().toISOString(),
      },
      date_analyse: new Date().toISOString(),
    };

    const { error: updateErr } = await supabase
      .from('cv')
      .update(payload)
      .eq('id', cvRow.id);

    if (updateErr) {
      console.error('[POST /cv/analyser] update cv:', updateErr);
      return res.status(500).json({
        success: false,
        message: 'Erreur lors de la sauvegarde de l\'analyse',
      });
    }

    try {
      const nComp = Array.isArray(result.competences) ? result.competences.length : 0;
      const nExp = Array.isArray(result.experience) ? result.experience.length : 0;
      const extractionRiche = nComp > 0 || nExp > 0;
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
      message: 'CV analysé avec succès',
      data: {
        cv_id: cvRow.id,
        fallback: result.fallback === true,
        competences_count: Array.isArray(result.competences) ? result.competences.length : 0,
        competences: result.competences || [],
      },
    });
  } catch (err) {
    console.error('[POST /cv/analyser]', err);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
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

      const { data: signed } = await supabase.storage.from(BUCKET_CV).createSignedUrl(cvRow.fichier_url, 60);
      if (signed?.error) {
        return res.status(500).json({ message: 'Impossible de générer l\'URL de téléchargement' });
      }
      return res.json({ url: signed.signedUrl, expiresIn: 60 });
    }

    if (role !== ROLES.CHERCHEUR) {
      return res.status(400).json({ message: 'Utilisez candidature_id= pour accéder au CV d\'une candidature' });
    }

    const chercheurId = req.chercheurId;
    if (!chercheurId) return res.status(400).json({ message: 'Profil chercheur introuvable' });

    const { data: cvRow } = await supabase.from('cv').select('fichier_url').eq('chercheur_id', chercheurId).single();
    if (!cvRow) return res.status(404).json({ message: 'Aucun CV enregistré' });

    const { data: signed } = await supabase.storage.from(BUCKET_CV).createSignedUrl(cvRow.fichier_url, 60);
    if (signed?.error) {
      return res.status(500).json({ message: 'Impossible de générer l\'URL de téléchargement' });
    }
    res.json({ url: signed.signedUrl, expiresIn: 60 });
  } catch (err) {
    console.error('GET /cv/download-url:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

export default router;
