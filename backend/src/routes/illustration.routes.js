/**
 * Routes publiques + admin pour les illustrations IA (homepage).
 */
import { Router } from 'express';
import multer from 'multer';
import { supabase } from '../config/supabase.js';
import { authenticate } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/adminAuth.js';
import { requirePermission } from '../middleware/adminPermissions.js';
import {
  genererIllustrationsJour,
  getIllustrationActive,
  ILLUSTRATIONS_STORAGE_BUCKET,
} from '../services/illustrationIa.service.js';

const router = Router();

/** Pas de fileFilter : Flutter Web envoie souvent mimetype vide ou application/octet-stream. */
const uploadIllustrationManuelle = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
});

function _contentTypeFromName(originalname, multerMime) {
  const raw = String(originalname || '');
  const ext = (raw.split('.').pop() || '').toLowerCase().replace(/[^a-z0-9]/g, '') || '';
  const mimeMap = {
    png: 'image/png',
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    webp: 'image/webp',
  };
  const fromExt = mimeMap[ext];
  const m = String(multerMime || '').trim().toLowerCase();
  if (fromExt) return fromExt;
  if (m && m !== 'application/octet-stream' && m.startsWith('image/')) return multerMime;
  return 'image/png';
}

function _allowedImageExt(originalname, buffer) {
  const raw = String(originalname || '');
  const part = (raw.split('.').pop() || '').toLowerCase().replace(/[^a-z0-9]/g, '') || '';
  if (['png', 'jpg', 'jpeg', 'webp'].includes(part)) return part === 'jpg' ? 'jpeg' : part;
  const b = buffer;
  if (b?.length >= 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47) return 'png';
  if (b?.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return 'jpeg';
  if (b?.length >= 12 && b[0] === 0x52 && b[1] === 0x49 && b[2] === 0x46 && b[3] === 0x46) {
    const sig = String.fromCharCode(b[8], b[9], b[10], b[11]);
    if (sig === 'WEBP') return 'webp';
  }
  return null;
}

function _extractStoragePathFromPublicUrl(urlValue) {
  const raw = String(urlValue || '').trim();
  if (!raw) return null;
  try {
    const u = new URL(raw);
    const marker = `/storage/v1/object/public/${ILLUSTRATIONS_STORAGE_BUCKET}/`;
    const idx = u.pathname.indexOf(marker);
    if (idx < 0) return null;
    return decodeURIComponent(u.pathname.substring(idx + marker.length));
  } catch (_) {
    return null;
  }
}

router.get('/active', async (_req, res) => {
  try {
    const illus = await getIllustrationActive();
    return res.json({ success: true, data: illus });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

router.post(
  '/generer',
  authenticate,
  requireAdmin,
  requirePermission('illustrations', 'peut_modifier'),
  async (_req, res) => {
    try {
      console.log('[illustration] Génération manuelle…');
      const result = await genererIllustrationsJour();
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ success: false, message: err.message });
    }
  },
);

router.post(
  '/upload-manuel',
  authenticate,
  requireAdmin,
  requirePermission('illustrations', 'peut_modifier'),
  uploadIllustrationManuelle.single('image'),
  async (req, res) => {
    try {
      console.log(
        '[upload-manuel] file:',
        req.file
          ? {
              fieldname: req.file.fieldname,
              originalname: req.file.originalname,
              mimetype: req.file.mimetype,
              size: req.file.size,
            }
          : 'ABSENT',
      );

      if (!req.file?.buffer?.length) {
        return res.status(400).json({
          success: false,
          message: 'Aucun fichier reçu ou fichier vide (PNG, JPG, JPEG, WebP)',
        });
      }

      const rawName = String(req.file.originalname || 'image.png');
      const safeExt = _allowedImageExt(rawName, req.file.buffer);
      if (!safeExt) {
        return res.status(400).json({
          success: false,
          message: 'Extension non autorisée (utilisez .png, .jpg, .jpeg ou .webp)',
        });
      }

      const nomFichier = `manuel_${Date.now()}.${safeExt === 'jpeg' ? 'jpg' : safeExt}`;
      const chemin = `illustrations_ia/${nomFichier}`;
      const mimeTable = { png: 'image/png', jpeg: 'image/jpeg', webp: 'image/webp' };
      const mime = mimeTable[safeExt] || _contentTypeFromName(rawName, req.file.mimetype);

      console.log('[upload-manuel] contentType:', mime, '| chemin:', chemin);

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

      console.log('[upload-manuel] OK', publicUrl);

      return res.json({
        success: true,
        data: { url: publicUrl, id: row?.id },
      });
    } catch (err) {
      console.error('[upload-manuel]', err?.message || err);
      return res.status(500).json({ success: false, message: err.message });
    }
  },
);

router.get(
  '/liste',
  authenticate,
  requireAdmin,
  requirePermission('illustrations', 'peut_voir'),
  async (_req, res) => {
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
  },
);

router.patch(
  '/:id/activer',
  authenticate,
  requireAdmin,
  requirePermission('illustrations', 'peut_modifier'),
  async (req, res) => {
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
  },
);

router.delete(
  '/:id',
  authenticate,
  requireAdmin,
  requirePermission('illustrations', 'peut_supprimer'),
  async (req, res) => {
    try {
    const { id } = req.params;
    const { data: illus, error: getErr } = await supabase
      .from('illustrations_ia')
      .select('id, url_image, est_active')
      .eq('id', id)
      .maybeSingle();
    if (getErr) throw getErr;
    if (!illus) {
      return res.status(404).json({ success: false, message: 'Image non trouvee' });
    }

    const { error: delErr } = await supabase.from('illustrations_ia').delete().eq('id', id);
    if (delErr) throw delErr;

    const pathSto = _extractStoragePathFromPublicUrl(illus.url_image);
    if (pathSto) {
      await supabase.storage.from(ILLUSTRATIONS_STORAGE_BUCKET).remove([pathSto]);
    }

    if (illus.est_active) {
      const { data: suivante } = await supabase
        .from('illustrations_ia')
        .select('id')
        .order('date_generation', { ascending: false })
        .limit(1)
        .maybeSingle();
      if (suivante?.id) {
        await supabase
          .from('illustrations_ia')
          .update({ est_active: true })
          .eq('id', suivante.id);
      }
    }
      console.log('[illustration] Supprimee:', id);
      return res.json({ success: true, message: 'Image supprimee' });
    } catch (err) {
      return res.status(500).json({ success: false, message: err.message });
    }
  },
);

export default router;
