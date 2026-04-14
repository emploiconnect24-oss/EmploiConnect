import multer from 'multer';
import sharp from 'sharp';
import { supabase } from '../../config/supabase.js';

const TABLE = 'bannieres_homepage';

function isFetchFailedError(err) {
  const msg = String(err?.message || '').toLowerCase();
  return msg.includes('fetch failed') || msg.includes('network') || err?.name === 'TypeError';
}

export const uploadBanniere = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    console.log('[Upload] Fichier reçu:', file.originalname, file.mimetype, file.size);
    cb(null, true);
  },
});

export async function uploadImageBanniere(req, res) {
  try {
    console.log('[uploadBanniere] Fichier:', req.file?.originalname, req.file?.size, req.file?.mimetype);
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Aucune image reçue',
      });
    }

    let buffer = req.file.buffer;
    try {
      // Cible alignée sur l’affichage accueil (bande large ~1920×440).
      buffer = await sharp(req.file.buffer)
        .resize(1920, 440, {
          fit: 'cover',
          position: 'center',
        })
        .jpeg({ quality: 85 })
        .toBuffer();
    } catch (sharpErr) {
      console.warn('[uploadBanniere] Sharp non disponible, upload direct:', sharpErr?.message);
    }

    const bucket = process.env.SUPABASE_BANNIERES_BUCKET || 'bannieres';
    console.log('[uploadBanniere] Bucket:', bucket);
    const fileName = `banniere-${Date.now()}.jpg`;

    const { error: uploadErr } = await supabase.storage.from(bucket).upload(fileName, buffer, {
      contentType: 'image/jpeg',
      upsert: false,
    });

    if (uploadErr) {
      console.error('[uploadBanniere] Erreur:', uploadErr);
      return res.status(500).json({
        success: false,
        message: `Erreur Storage: ${uploadErr.message}`,
      });
    }

    const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(fileName);
    return res.json({
      success: true,
      message: 'Image uploadée avec succès',
      data: { image_url: urlData.publicUrl },
    });
  } catch (err) {
    console.error('[uploadBanniere] Exception:', err);
    res.status(500).json({
      success: false,
      message: err.message || 'Erreur upload image',
    });
  }
}

export async function listBannieresAdmin(req, res) {
  try {
    const { data, error } = await supabase
      .from(TABLE)
      .select('*')
      .order('ordre', { ascending: true });

    if (error) throw error;
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    console.error('[listBannieresAdmin]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function listBannieresPubliques(req, res) {
  try {
    // `*` évite l’erreur « column couleur_badge does not exist » tant que la migration 051
    // n’est pas appliquée ; une fois la colonne créée, elle est renvoyée automatiquement.
    const { data, error } = await supabase
      .from(TABLE)
      .select('*')
      .eq('est_actif', true)
      .order('ordre', { ascending: true });

    if (error) {
      console.error('[GET /bannieres] Erreur:', error.message);
      return res.json({ success: true, data: [] });
    }
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    if (isFetchFailedError(err)) {
      console.warn('[GET /bannieres] Supabase indisponible, fallback liste vide.');
    } else {
      console.error('[GET /bannieres] Exception:', err.message);
    }
    return res.json({ success: true, data: [] });
  }
}

export async function createBanniere(req, res) {
  try {
    const {
      titre,
      sous_titre,
      texte_badge,
      label_cta_1,
      lien_cta_1,
      label_cta_2,
      lien_cta_2,
      type_banniere,
      largeur_px,
      hauteur_px,
      lien_externe,
      ordre_pub,
      couleur_badge,
    } = req.body;

    let image_url = req.body.image_url != null ? String(req.body.image_url).trim() : '';

    if (req.file) {
      const bucket = process.env.SUPABASE_BANNIERES_BUCKET || 'bannieres';
      const fileName = `banniere-${Date.now()}.${req.file.mimetype.includes('png') ? 'png' : 'jpg'}`;

      const { error: uploadErr } = await supabase.storage
        .from(bucket)
        .upload(fileName, req.file.buffer, {
          contentType: req.file.mimetype,
          upsert: false,
        });

      if (uploadErr) throw uploadErr;

      const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(fileName);
      image_url = urlData.publicUrl;
    }

    const typeBan = ['hero', 'ticker', 'pub'].includes(String(type_banniere || '').trim())
      ? String(type_banniere).trim()
      : 'hero';

    if (typeBan !== 'ticker' && !image_url) {
      return res.status(400).json({
        success: false,
        message: 'Image requise (upload ou URL externe) pour ce type de bannière',
      });
    }

    const { data: lastBan } = await supabase
      .from(TABLE)
      .select('ordre')
      .order('ordre', { ascending: false })
      .limit(1)
      .maybeSingle();

    const nextOrdre = (lastBan?.ordre ?? 0) + 1;

    const wPx = Math.min(Math.max(parseInt(String(largeur_px ?? ''), 10) || 320, 120), 1200);
    const hPx = Math.min(Math.max(parseInt(String(hauteur_px ?? ''), 10) || 180, 80), 800);
    const ordPub = Math.max(parseInt(String(ordre_pub ?? ''), 10) || 0, 0);
    const lienExt = lien_externe != null ? String(lien_externe).trim() : '';
    const couleurHex =
      couleur_badge != null && String(couleur_badge).trim()
        ? String(couleur_badge).trim().slice(0, 32)
        : '#1A56DB';

    const { data, error } = await supabase
      .from(TABLE)
      .insert({
        titre,
        sous_titre,
        texte_badge,
        image_url: image_url || null,
        label_cta_1,
        lien_cta_1,
        label_cta_2,
        lien_cta_2,
        ordre: nextOrdre,
        est_actif: true,
        type_banniere: typeBan,
        largeur_px: wPx,
        hauteur_px: hPx,
        lien_externe: lienExt || null,
        ordre_pub: ordPub,
        couleur_badge: couleurHex,
      })
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      success: true,
      message: 'Bannière créée avec succès',
      data,
    });
  } catch (err) {
    console.error('[createBanniere]', err);
    res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function updateBanniere(req, res) {
  try {
    const allowed = [
      'titre',
      'sous_titre',
      'texte_badge',
      'image_url',
      'lien_cta_1',
      'label_cta_1',
      'lien_cta_2',
      'label_cta_2',
      'ordre',
      'est_actif',
      'type_banniere',
      'largeur_px',
      'hauteur_px',
      'lien_externe',
      'ordre_pub',
      'couleur_badge',
    ];
    const updates = { date_modification: new Date().toISOString() };
    for (const k of allowed) {
      if (req.body[k] === undefined) continue;
      if (k === 'largeur_px' || k === 'hauteur_px') {
        const n = parseInt(String(req.body[k]), 10);
        updates[k] = Number.isFinite(n) ? n : k === 'largeur_px' ? 320 : 180;
      } else if (k === 'ordre_pub') {
        const n = parseInt(String(req.body[k]), 10);
        updates[k] = Number.isFinite(n) ? Math.max(0, n) : 0;
      } else if (k === 'est_actif') {
        const v = req.body[k];
        updates[k] = v === true || v === 'true' || v === '1' || v === 1;
      } else if (k === 'couleur_badge') {
        const s = String(req.body[k] ?? '').trim();
        updates[k] = s ? s.slice(0, 32) : '#1A56DB';
      } else if (k === 'image_url') {
        const s = req.body[k] != null ? String(req.body[k]).trim() : '';
        updates[k] = s || null;
      } else {
        updates[k] = req.body[k];
      }
    }

    const { data, error } = await supabase
      .from(TABLE)
      .update(updates)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    return res.json({ success: true, message: 'Bannière mise à jour', data });
  } catch (err) {
    console.error('[updateBanniere]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function reorderBannieres(req, res) {
  try {
    const { ordre } = req.body;
    if (!Array.isArray(ordre)) {
      return res.status(400).json({
        success: false,
        message: 'Tableau ordre requis',
      });
    }

    for (const item of ordre) {
      if (!item.id) continue;
      await supabase.from(TABLE).update({ ordre: item.ordre }).eq('id', item.id);
    }

    return res.json({
      success: true,
      message: 'Ordre des bannières mis à jour',
    });
  } catch (err) {
    console.error('[reorderBannieres]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

function storagePathFromPublicUrl(imageUrl, bucket) {
  if (!imageUrl || !imageUrl.includes('supabase')) return null;
  const marker = `/object/public/${bucket}/`;
  const idx = imageUrl.indexOf(marker);
  if (idx === -1) return null;
  return imageUrl.slice(idx + marker.length).split('?')[0];
}

export async function deleteBanniere(req, res) {
  try {
    const bucket = process.env.SUPABASE_BANNIERES_BUCKET || 'bannieres';

    const { data: ban } = await supabase
      .from(TABLE)
      .select('image_url, titre')
      .eq('id', req.params.id)
      .maybeSingle();

    const { error } = await supabase.from(TABLE).delete().eq('id', req.params.id);

    if (error) throw error;

    const path = ban?.image_url ? storagePathFromPublicUrl(ban.image_url, bucket) : null;
    if (path) {
      await supabase.storage.from(bucket).remove([path]);
    }

    return res.json({
      success: true,
      message: `Bannière "${ban?.titre || ''}" supprimée`,
    });
  } catch (err) {
    console.error('[deleteBanniere]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
