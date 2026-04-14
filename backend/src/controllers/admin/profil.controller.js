import bcrypt from 'bcryptjs';
import sharp from 'sharp';
import { supabase, BUCKET_ADMIN_AVATARS, BUCKET_CV } from '../../config/supabase.js';
import {
  demanderChangementEmailAdmin,
  confirmerChangementEmailAdmin,
} from '../../services/adminEmailChange.service.js';

function storageErrorMessage(err) {
  if (!err) return 'Erreur stockage inconnue';
  if (typeof err.message === 'string' && err.message.length) return err.message;
  if (typeof err === 'string') return err;
  try {
    return JSON.stringify(err);
  } catch {
    return 'Erreur stockage';
  }
}

/** Détecte JPG / PNG / WEBP depuis les octets (navigateurs envoient souvent application/octet-stream). */
function sniffImage(buffer) {
  if (buffer == null || buffer.length < 12) return null;
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return { ext: '.jpg', contentType: 'image/jpeg' };
  }
  if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) {
    return { ext: '.png', contentType: 'image/png' };
  }
  if (
    buffer[0] === 0x52 &&
    buffer[1] === 0x49 &&
    buffer[2] === 0x46 &&
    buffer[3] === 0x46 &&
    buffer[8] === 0x57 &&
    buffer[9] === 0x45 &&
    buffer[10] === 0x42 &&
    buffer[11] === 0x50
  ) {
    return { ext: '.webp', contentType: 'image/webp' };
  }
  return null;
}

/** Buffer Node pour sharp / Blob (évite les soucis de type Multer / Uint8Array). */
function toNodeBuffer(input) {
  if (Buffer.isBuffer(input)) return input;
  return Buffer.from(input);
}

/**
 * Upload Storage via Blob + FormData (chemin storage-js) : sur Node 18+, un Buffer brut
 * peut faire échouer fetch (duplex / corps) et provoquer un 500 non géré.
 */
async function uploadBufferToBucket(bucket, storagePath, imageBuffer, contentType) {
  const ct = lowerContentType(contentType);
  const buf = toNodeBuffer(imageBuffer);
  if (typeof Blob !== 'undefined') {
    const blob = new Blob([buf], { type: ct });
    return supabase.storage.from(bucket).upload(storagePath, blob, {
      contentType: ct,
      upsert: true,
      cacheControl: '3600',
    });
  }
  return supabase.storage.from(bucket).upload(storagePath, buf, {
    contentType: ct,
    upsert: true,
    cacheControl: '3600',
    duplex: 'half',
  });
}

/** Supabase attend des sous-types MIME en minuscules (évite image/PNG rejeté). */
function lowerContentType(ct) {
  if (!ct || typeof ct !== 'string') return 'image/jpeg';
  const parts = ct.split('/');
  if (parts.length !== 2) return ct.trim().toLowerCase();
  return `${parts[0].trim().toLowerCase()}/${parts[1].trim().toLowerCase()}`;
}

/** Extrait bucket + chemin depuis une URL publique Supabase Storage. */
function parsePublicStorageUrl(photoUrl) {
  if (!photoUrl || typeof photoUrl !== 'string') return null;
  const m = photoUrl.match(/\/object\/public\/([^/]+)\/([^?#]+)/);
  if (!m) return null;
  return { bucket: m[1], path: decodeURIComponent(m[2]) };
}

export async function getProfilAdmin(req, res) {
  try {
    const { data: user, error: uErr } = await supabase
      .from('utilisateurs')
      .select(
        'id, nom, email, telephone, adresse, photo_url, date_creation, derniere_connexion, date_modification',
      )
      .eq('id', req.user.id)
      .single();

    if (uErr || !user) {
      return res.status(404).json({ success: false, message: 'Profil non trouvé' });
    }

    const { data: adm } = await supabase
      .from('administrateurs')
      .select(
        `
        niveau_acces,
        est_super_admin,
        role_id,
        admin_roles ( nom, couleur )
      `,
      )
      .eq('utilisateur_id', req.user.id)
      .maybeSingle();

    let adminPayload = adm ? { ...adm } : { niveau_acces: 'admin' };
    const rawRole = adminPayload.admin_roles;
    const roleRow = Array.isArray(rawRole) ? rawRole[0] : rawRole;
    delete adminPayload.admin_roles;
    if (roleRow && typeof roleRow === 'object') {
      adminPayload.role_nom = roleRow.nom ?? null;
      adminPayload.role_couleur = roleRow.couleur ?? null;
    } else {
      adminPayload.role_nom = null;
      adminPayload.role_couleur = null;
    }

    return res.json({
      success: true,
      data: {
        ...user,
        admin: adminPayload,
      },
    });
  } catch (err) {
    console.error('[getProfilAdmin]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function updateProfilAdmin(req, res) {
  try {
    const { nom, telephone, adresse, ancien_mdp, nouveau_mdp } = req.body;

    const updateData = { date_modification: new Date().toISOString() };
    if (nom != null && String(nom).trim()) updateData.nom = String(nom).trim();
    if (telephone !== undefined) updateData.telephone = telephone;
    if (adresse !== undefined) updateData.adresse = adresse;

    if (Object.prototype.hasOwnProperty.call(req.body, 'email')) {
      const emailNorm = String(req.body.email ?? '')
        .trim()
        .toLowerCase();
      const { data: curUser, error: curErr } = await supabase
        .from('utilisateurs')
        .select('email')
        .eq('id', req.user.id)
        .single();
      if (curErr || !curUser) {
        return res.status(400).json({ success: false, message: 'Profil introuvable' });
      }
      if (emailNorm && emailNorm !== String(curUser.email).toLowerCase()) {
        return res.status(400).json({
          success: false,
          code: 'EMAIL_VERIFICATION_REQUIRED',
          message:
            'Pour changer d’adresse e-mail, utilisez « Envoyer le code » puis confirmez avec le code reçu sur la nouvelle adresse.',
        });
      }
    }

    if (nouveau_mdp) {
      if (!ancien_mdp) {
        return res.status(400).json({
          success: false,
          message: 'Ancien mot de passe requis',
        });
      }

      const { data: row, error: fetchErr } = await supabase
        .from('utilisateurs')
        .select('mot_de_passe')
        .eq('id', req.user.id)
        .single();

      if (fetchErr || !row?.mot_de_passe) {
        return res.status(400).json({ success: false, message: 'Impossible de vérifier le mot de passe' });
      }

      const ok = await bcrypt.compare(String(ancien_mdp), row.mot_de_passe);
      if (!ok) {
        return res.status(400).json({ success: false, message: 'Ancien mot de passe incorrect' });
      }

      if (String(nouveau_mdp).length < 8) {
        return res.status(400).json({
          success: false,
          message: 'Le nouveau mot de passe doit contenir au moins 8 caractères',
        });
      }

      updateData.mot_de_passe = await bcrypt.hash(String(nouveau_mdp), 10);
    }

    const { data, error } = await supabase
      .from('utilisateurs')
      .update(updateData)
      .eq('id', req.user.id)
      .select('id, nom, email, telephone, adresse, photo_url')
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: 'Profil mis à jour avec succès',
      data,
    });
  } catch (err) {
    console.error('[updateProfilAdmin]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

/** POST /admin/profil/email/demande — envoie un code à 6 chiffres sur la nouvelle adresse */
export async function postDemandeChangementEmail(req, res) {
  try {
    const nouvelEmail = req.body?.nouvel_email ?? req.body?.email;
    const result = await demanderChangementEmailAdmin(
      req.user.id,
      req.user.nom,
      nouvelEmail,
    );
    if (!result.ok) {
      return res.status(result.status).json({ success: false, message: result.message });
    }
    return res.json({
      success: true,
      message: 'Un code de vérification a été envoyé à la nouvelle adresse e-mail.',
    });
  } catch (err) {
    console.error('[postDemandeChangementEmail]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

/** POST /admin/profil/email/confirmer — valide le code et met à jour l’e-mail */
export async function postConfirmerChangementEmail(req, res) {
  try {
    const nouvelEmail = req.body?.nouvel_email ?? req.body?.email;
    const code = req.body?.code;
    const result = await confirmerChangementEmailAdmin(req.user.id, nouvelEmail, code);
    if (!result.ok) {
      return res.status(result.status).json({ success: false, message: result.message });
    }
    return res.json({
      success: true,
      message: 'Adresse e-mail mise à jour avec succès',
      data: result.data,
    });
  } catch (err) {
    console.error('[postConfirmerChangementEmail]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function uploadPhotoAdmin(req, res) {
  try {
    if (!req.file?.buffer) {
      return res.status(400).json({ success: false, message: 'Aucun fichier fourni' });
    }

    const inputBuf = toNodeBuffer(req.file.buffer);

    const { data: userActuel, error: fetchPhotoErr } = await supabase
      .from('utilisateurs')
      .select('photo_url')
      .eq('id', req.user.id)
      .single();

    if (fetchPhotoErr) {
      console.warn('[uploadPhotoAdmin] lecture photo_url:', fetchPhotoErr.message);
    }

    if (userActuel?.photo_url) {
      const parsed = parsePublicStorageUrl(userActuel.photo_url);
      if (parsed?.bucket && parsed.path) {
        const { error: rmErr } = await supabase.storage.from(parsed.bucket).remove([parsed.path]);
        if (rmErr) {
          console.warn('[uploadPhotoAdmin] suppression ancienne photo:', rmErr.message);
        }
      }
    }

    let imageBuffer;
    let storagePath;
    let contentType;

    try {
      imageBuffer = await sharp(inputBuf)
        .rotate()
        .resize(200, 200, { fit: 'cover', position: 'center' })
        .jpeg({ quality: 85 })
        .toBuffer();
      storagePath = `photos/admin-${req.user.id}-${Date.now()}.jpg`;
      contentType = 'image/jpeg';
    } catch (sharpErr) {
      console.warn('[uploadPhotoAdmin] sharp, repli buffer d’origine:', sharpErr?.message);
      try {
        imageBuffer = await sharp(inputBuf)
          .resize(200, 200, { fit: 'cover', position: 'center' })
          .jpeg({ quality: 85 })
          .toBuffer();
        storagePath = `photos/admin-${req.user.id}-${Date.now()}.jpg`;
        contentType = 'image/jpeg';
      } catch (sharpErr2) {
        console.warn('[uploadPhotoAdmin] sharp sans rotate:', sharpErr2?.message);
        const sniffed = sniffImage(inputBuf);
        if (!sniffed) {
          return res.status(400).json({
            success: false,
            message: 'Image illisible ou format non supporté (JPG, PNG, WEBP).',
          });
        }
        imageBuffer = inputBuf;
        contentType = lowerContentType(sniffed.contentType);
        const ext = sniffed.ext === '.jpeg' ? '.jpg' : sniffed.ext;
        storagePath = `photos/admin-${req.user.id}-${Date.now()}${ext}`;
      }
    }

    contentType = lowerContentType(contentType);

    let uploadError;
    try {
      const up = await uploadBufferToBucket(
        BUCKET_ADMIN_AVATARS,
        storagePath,
        imageBuffer,
        contentType,
      );
      uploadError = up.error;
    } catch (uploadThrown) {
      console.error('[uploadPhotoAdmin] Storage (exception):', uploadThrown);
      return res.status(500).json({
        success: false,
        message:
          uploadThrown?.message ||
          "Erreur réseau vers le stockage. Vérifiez le bucket Supabase et la clé service_role.",
      });
    }

    if (uploadError) {
      console.error('[uploadPhotoAdmin] Storage:', uploadError);
      const raw = storageErrorMessage(uploadError);
      const mimeRejected =
        /mime type/i.test(raw) && /not supported/i.test(raw);
      const hint =
        mimeRejected &&
        BUCKET_ADMIN_AVATARS === BUCKET_CV &&
        ` Le bucket « ${BUCKET_CV} » n’autorise probablement pas les images (souvent réservé aux CV/PDF). Créez un bucket « avatars » dans Supabase (Storage → New bucket), laissez « Allowed MIME types » vide ou ajoutez image/jpeg, puis dans backend/.env : SUPABASE_STORAGE_BUCKET_AVATARS=avatars`;
      return res.status(mimeRejected ? 400 : 500).json({
        success: false,
        message: raw + (hint || ''),
      });
    }

    const { data: urlData } = supabase.storage.from(BUCKET_ADMIN_AVATARS).getPublicUrl(storagePath);
    const photoUrl = urlData.publicUrl;

    const { error: dbErr } = await supabase
      .from('utilisateurs')
      .update({ photo_url: photoUrl, date_modification: new Date().toISOString() })
      .eq('id', req.user.id);

    if (dbErr) {
      console.error('[uploadPhotoAdmin] DB:', dbErr);
      return res.status(500).json({
        success: false,
        message: dbErr.message || 'Impossible d’enregistrer l’URL de la photo',
      });
    }

    return res.json({
      success: true,
      message: 'Photo de profil mise à jour avec succès',
      data: { photo_url: photoUrl },
    });
  } catch (err) {
    console.error('[uploadPhotoAdmin]', err);
    res.status(500).json({
      success: false,
      message: err?.message || 'Erreur serveur',
    });
  }
}
