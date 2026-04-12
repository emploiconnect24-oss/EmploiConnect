/**
 * Routes publiques + admin pour les illustrations IA (homepage).
 */
import { Router } from 'express';
import multer from 'multer';
import { supabase } from '../config/supabase.js';
import { authenticate } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/adminAuth.js';
import {
  genererIllustrationsJour,
  getIllustrationActive,
  ILLUSTRATIONS_STORAGE_BUCKET,
} from '../services/illustrationIa.service.js';

const router = Router();

const uploadIllustrationManuelle = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok =
      /^image\/(png|jpeg|jpg|webp)$/i.test(file.mimetype) || file.mimetype === 'image/jpg';
    cb(null, ok);
  },
});

router.get('/active', async (_req, res) => {
  try {
    const illus = await getIllustrationActive();
    return res.json({ success: true, data: illus });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/generer', authenticate, requireAdmin, async (_req, res) => {
  try {
    console.log('[illustration] Génération manuelle…');
    const result = await genererIllustrationsJour();
    return res.json(result);
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

router.post(
  '/upload-manuel',
  authenticate,
  requireAdmin,
  uploadIllustrationManuelle.single('image'),
  async (req, res) => {
    try {
      if (!req.file?.buffer) {
        return res.status(400).json({ success: false, message: 'Fichier manquant ou type non autorisé (PNG, JPG, WebP)' });
      }

      const rawName = String(req.file.originalname || 'image.png');
      const ext = (rawName.split('.').pop() || 'png').toLowerCase().replace(/[^a-z0-9]/g, '') || 'png';
      const safeExt = ['png', 'jpg', 'jpeg', 'webp'].includes(ext) ? ext : 'png';
      const nomFichier = `manuel_${Date.now()}.${safeExt}`;
      const chemin = `illustrations_ia/${nomFichier}`;
      const mime = req.file.mimetype || (safeExt === 'jpg' || safeExt === 'jpeg' ? 'image/jpeg' : `image/${safeExt}`);

      const { error: uploadError } = await supabase.storage
        .from(ILLUSTRATIONS_STORAGE_BUCKET)
        .upload(chemin, req.file.buffer, {
          contentType: mime,
          upsert: true,
          cacheControl: '86400',
        });

      if (uploadError) {
        return res.status(500).json({ success: false, message: uploadError.message });
      }

      const { data: pub } = supabase.storage
        .from(ILLUSTRATIONS_STORAGE_BUCKET)
        .getPublicUrl(chemin);

      const publicUrl = pub.publicUrl;

      const { error: offErr } = await supabase
        .from('illustrations_ia')
        .update({ est_active: false })
        .eq('est_active', true);
      if (offErr) throw offErr;

      const { data: row, error: insErr } = await supabase
        .from('illustrations_ia')
        .insert({
          url_image: publicUrl,
          source: 'upload',
          est_active: true,
          prompt_utilise: 'Upload manuel',
        })
        .select('id')
        .maybeSingle();

      if (insErr) throw insErr;

      await supabase
        .from('parametres_plateforme')
        .update({
          valeur: publicUrl,
          date_modification: new Date().toISOString(),
        })
        .eq('cle', 'illustration_url_manuelle');

      return res.json({
        success: true,
        data: { url: publicUrl, id: row?.id },
      });
    } catch (err) {
      return res.status(500).json({ success: false, message: err.message });
    }
  },
);

router.get('/liste', authenticate, requireAdmin, async (_req, res) => {
  try {
    const { data, error } = await supabase
      .from('illustrations_ia')
      .select('*')
      .order('date_generation', { ascending: false })
      .limit(30);

    if (error) throw error;
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/:id/activer', authenticate, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const { error: offErr } = await supabase
      .from('illustrations_ia')
      .update({ est_active: false })
      .eq('est_active', true);

    if (offErr) throw offErr;

    const { data, error } = await supabase
      .from('illustrations_ia')
      .update({ est_active: true })
      .eq('id', id)
      .select()
      .maybeSingle();

    if (error) throw error;
    if (!data) {
      return res.status(404).json({ success: false, message: 'Illustration introuvable' });
    }
    return res.json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

export default router;
