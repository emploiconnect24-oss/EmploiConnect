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

const router = Router();

const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB
const ALLOWED_MIMES = [
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
];

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE },
  fileFilter: (req, file, cb) => {
    if (!ALLOWED_MIMES.includes(file.mimetype)) {
      return cb(new Error('Format accepté : PDF ou DOCX uniquement'), false);
    }
    cb(null, true);
  },
});

router.use(authenticate);
router.use(attachProfileIds);

/**
 * POST /cv/upload - Téléverser un CV (chercheur uniquement)
 * multipart/form-data, champ "file" (PDF ou DOCX, max 5 Mo)
 */
router.post('/upload', requireRole(ROLES.CHERCHEUR), upload.single('file'), async (req, res) => {
  try {
    const chercheurId = req.chercheurId;
    if (!chercheurId) {
      return res.status(400).json({ message: 'Profil chercheur introuvable' });
    }

    if (!req.file || !req.file.buffer) {
      return res.status(400).json({ message: 'Aucun fichier envoyé (attendu : champ "file", PDF ou DOCX)' });
    }

    const ext = req.file.mimetype === 'application/pdf' ? 'pdf' : 'docx';
    const storagePath = `${chercheurId}/${Date.now()}-${(req.file.originalname || 'cv').replace(/[^a-zA-Z0-9._-]/g, '_')}.${ext}`;

    const { error: uploadError } = await supabase.storage
      .from(BUCKET_CV)
      .upload(storagePath, req.file.buffer, {
        contentType: req.file.mimetype,
        upsert: true,
      });

    if (uploadError) {
      console.error('Storage upload:', uploadError);
      return res.status(500).json({ message: 'Erreur lors de l\'enregistrement du fichier' });
    }

    const { data: publicUrl } = supabase.storage.from(BUCKET_CV).getPublicUrl(storagePath);
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
        return res.status(500).json({ message: 'Erreur lors de la mise à jour du CV' });
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
        return res.status(500).json({ message: 'Erreur lors de l\'enregistrement du CV' });
      }
      result = inserted;
    }

    res.status(existing ? 200 : 201).json({
      message: existing ? 'CV mis à jour' : 'CV enregistré',
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
      return res.status(400).json({ message: 'Fichier trop volumineux (max 5 Mo)' });
    }
    console.error('POST /cv/upload:', err);
    res.status(500).json({ message: 'Erreur serveur' });
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
