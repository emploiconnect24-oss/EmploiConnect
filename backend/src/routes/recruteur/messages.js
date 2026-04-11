import crypto from 'crypto';
import { Router } from 'express';
import multer from 'multer';
import { authenticate } from '../../middleware/auth.js';
import { requireRecruteur } from '../../middleware/recruteurAuth.js';
import { supabase, BUCKET_CV, BUCKET_ADMIN_AVATARS } from '../../config/supabase.js';
import { sendNewMessageEmail } from '../../services/mail.service.js';
import { handleMessageAttachmentDownload } from '../../helpers/messageAttachmentDownload.js';
import { recordTyping, isPeerTyping, clearTypingForUser } from '../../services/messageTypingPresence.js';

const router = Router();
router.use(authenticate, requireRecruteur);

const uploadPj = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 },
});

function inferMimeFromFilename(name = '') {
  const lower = String(name).toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.doc')) return 'application/msword';
  if (lower.endsWith('.txt')) return 'text/plain';
  return null;
}

function inferMimeFromMagic(buffer) {
  if (!buffer || buffer.length < 4) return null;
  const b = buffer;
  if (b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return 'image/jpeg';
  if (b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47) return 'image/png';
  if (b[0] === 0x47 && b[1] === 0x49 && b[2] === 0x46 && b[3] === 0x38) return 'image/gif';
  if (b[0] === 0x25 && b[1] === 0x50 && b[2] === 0x44 && b[3] === 0x46) return 'application/pdf';
  if (
    b[0] === 0x52
    && b[1] === 0x49
    && b[2] === 0x46
    && b[3] === 0x46
    && b.length > 11
    && b[8] === 0x57
    && b[9] === 0x45
    && b[10] === 0x42
    && b[11] === 0x50
  ) {
    return 'image/webp';
  }
  return null;
}

function resolveUploadMime(file) {
  const raw = String(file?.mimetype || '').trim().toLowerCase();
  if (raw && raw !== 'application/octet-stream') return raw;
  return (
    inferMimeFromMagic(file?.buffer)
    || inferMimeFromFilename(file?.originalname)
    || 'application/octet-stream'
  );
}

function isMimeRejected(err) {
  const msg = String(err?.message || '');
  return /mime type/i.test(msg) && /not supported/i.test(msg);
}

async function uploadWithBucketFallback(path, buffer, contentType) {
  const logosBucket = process.env.SUPABASE_LOGOS_BUCKET || 'logos';
  const messageBucket = process.env.SUPABASE_STORAGE_BUCKET_MESSAGES?.trim() || '';
  const docsBucket = process.env.SUPABASE_STORAGE_BUCKET_DOCS?.trim() || BUCKET_CV;
  const avatarsBucket = BUCKET_ADMIN_AVATARS;
  const isImage = String(contentType).startsWith('image/');

  const candidates = isImage
    ? [messageBucket, logosBucket, avatarsBucket, docsBucket]
    : [messageBucket, docsBucket, logosBucket, avatarsBucket];
  const buckets = [...new Set(candidates.filter(Boolean))];

  let lastError = null;
  for (const bucket of buckets) {
    try {
      const { error } = await supabase.storage
        .from(bucket)
        .upload(path, buffer, { contentType, upsert: false });
      if (!error) return { bucket, error: null };
      lastError = error;
      // Si l'erreur n'est pas liée au MIME, on tente quand même les autres buckets (permissions/règles différentes).
      if (!isMimeRejected(error)) continue;
    } catch (thrown) {
      lastError = thrown;
      continue;
    }
  }
  return { bucket: null, error: lastError };
}

function conversationId(a, b) {
  return crypto.createHash('md5').update([a, b].sort().join('-')).digest('hex');
}

function isMissingMessagesTable(err) {
  return err?.code === 'PGRST205'
    && typeof err?.message === 'string'
    && err.message.includes("Could not find the table 'public.messages'");
}

/**
 * Liste des conversations (dernier message, interlocuteur, non lus).
 * Format attendu par le front recruteur.
 */
router.get('/', async (req, res) => {
  try {
    const userId = req.user.id;
    const { data: rows, error } = await supabase
      .from('messages')
      .select('id, conversation_id, expediteur_id, destinataire_id, contenu, est_lu, date_envoi, offre_id, est_supprime_exp, est_supprime_dest, piece_jointe_nom, piece_jointe_url, fichier_nom')
      .or(`expediteur_id.eq.${userId},destinataire_id.eq.${userId}`)
      .order('date_envoi', { ascending: false });

    if (error) {
      if (isMissingMessagesTable(error)) {
        return res.json({
          success: true,
          data: [],
          warning: 'messages_table_missing',
          message: 'La table messages est absente. Appliquez la migration SQL messages.',
        });
      }
      throw error;
    }

    const seenCid = new Set();
    const summaries = [];
    const unreadByCid = {};

    const visibleRows = (rows || []).filter((m) => {
      if (m.expediteur_id === userId && m.est_supprime_exp === true) return false;
      if (m.destinataire_id === userId && m.est_supprime_dest === true) return false;
      return true;
    });

    for (const m of visibleRows) {
      if (m.destinataire_id === userId && m.est_lu === false) {
        unreadByCid[m.conversation_id] = (unreadByCid[m.conversation_id] || 0) + 1;
      }
    }

    for (const m of visibleRows) {
      if (seenCid.has(m.conversation_id)) continue;
      seenCid.add(m.conversation_id);
      const peerId = m.expediteur_id === userId ? m.destinataire_id : m.expediteur_id;
      const hasAttachment = !!(m.piece_jointe_url);
      const preview = String(m.contenu || '').trim().length > 0
        ? m.contenu
        : (hasAttachment
            ? `📎 ${m.piece_jointe_nom || m.fichier_nom || 'Pièce jointe'}`
            : '');
      summaries.push({
        conversation_id: m.conversation_id,
        peer_id: peerId,
        dernier_message: preview,
        date_dernier: m.date_envoi,
        offre_id: m.offre_id,
        nb_non_lus: unreadByCid[m.conversation_id] || 0,
      });
    }

    const peerIds = [...new Set(summaries.map((s) => s.peer_id).filter(Boolean))];
    let userMap = {};
    if (peerIds.length) {
      const { data: users } = await supabase
        .from('utilisateurs')
        .select('id, nom, email, photo_url, role')
        .in('id', peerIds);
      userMap = Object.fromEntries((users || []).map((u) => [u.id, u]));
    }

    const offreIds = [...new Set(summaries.map((s) => s.offre_id).filter(Boolean))];
    let offreMap = {};
    if (offreIds.length) {
      const { data: offres } = await supabase
        .from('offres_emploi')
        .select('id, titre')
        .in('id', offreIds)
        .eq('entreprise_id', req.entreprise.id);
      offreMap = Object.fromEntries((offres || []).map((o) => [o.id, o]));
    }

    const conversations = summaries.map((s) => {
      const peer = userMap[s.peer_id] || { id: s.peer_id, nom: 'Utilisateur', email: '', photo_url: null };
      const offre = s.offre_id ? offreMap[s.offre_id] : null;
      return {
        conversation_id: s.conversation_id,
        peer_id: s.peer_id,
        peer,
        destinataire: peer,
        expediteur: peer,
        dernier_message: s.dernier_message,
        date_dernier: s.date_dernier,
        nb_non_lus: s.nb_non_lus,
        offre_id: s.offre_id,
        offre_titre: offre?.titre || null,
      };
    });

    conversations.sort((a, b) => new Date(b.date_dernier || 0) - new Date(a.date_dernier || 0));
    const totalNonLus = conversations.reduce((sum, c) => sum + (Number(c.nb_non_lus) || 0), 0);

    return res.json({
      success: true,
      data: {
        conversations,
        total_non_lus: totalNonLus,
      },
    });
  } catch (err) {
    console.error('[recruteur/messages GET /]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

/**
 * Recherche destinataires pour « Nouveau message ».
 * - type=postule : uniquement candidats ayant postulé aux offres de l’entreprise.
 * - type=tous (défaut) : idem puis, si aucun résultat, élargit aux utilisateurs role=chercheur (PRD §8.1).
 *
 * GET /recruteur/messages/peers/search?q=&type=
 * GET /recruteur/messages/rechercher-destinataire?q=&type=  (alias PRD)
 */
async function handlePeerSearch(req, res) {
  try {
    const q = String(req.query.q || '').trim();
    if (q.length < 2) {
      return res.json({ success: true, data: [] });
    }
    const type = String(req.query.type || 'tous').toLowerCase();
    const needle = q.toLowerCase();

    const { data: offres, error: offErr } = await supabase
      .from('offres_emploi')
      .select('id')
      .eq('entreprise_id', req.entreprise.id);
    if (offErr) throw offErr;

    const offreIds = (offres || []).map((o) => o.id);
    let peers = [];

    if (offreIds.length) {
      const { data: candRows, error: candErr } = await supabase
        .from('candidatures')
        .select('chercheur_id')
        .in('offre_id', offreIds);
      if (candErr) throw candErr;

      const chercheurIds = [...new Set((candRows || []).map((c) => c.chercheur_id).filter(Boolean))];
      if (chercheurIds.length) {
        const userIds = new Set();

        const { data: chEmp, error: chEmpErr } = await supabase
          .from('chercheurs_emploi')
          .select('id, utilisateur_id')
          .in('id', chercheurIds);
        if (!chEmpErr) {
          for (const row of chEmp || []) {
            if (row.utilisateur_id) userIds.add(row.utilisateur_id);
          }
        }

        const { data: ch, error: chErr } = await supabase
          .from('chercheurs')
          .select('id, utilisateur_id')
          .in('id', chercheurIds);
        if (!chErr) {
          for (const row of ch || []) {
            if (row.utilisateur_id) userIds.add(row.utilisateur_id);
          }
        }

        // Certains schémas stockent déjà utilisateur_id dans candidatures.chercheur_id.
        if (userIds.size === 0) {
          for (const id of chercheurIds) userIds.add(id);
        }

        const ids = [...userIds].filter(Boolean);
        if (ids.length) {
          const { data: users, error: uErr } = await supabase
            .from('utilisateurs')
            .select('id, nom, email, photo_url, role')
            .in('id', ids)
            .eq('role', 'chercheur')
            .limit(80);
          if (uErr) throw uErr;

          const seen = new Set();
          peers = (users || [])
            .filter((u) => {
              const nom = String(u.nom || '').toLowerCase();
              const email = String(u.email || '').toLowerCase();
              return nom.includes(needle) || email.includes(needle);
            })
            .filter((u) => {
              const id = u.id;
              if (!id || seen.has(id)) return false;
              seen.add(id);
              return true;
            })
            .slice(0, 25);
        }
      }
    }

    if (peers.length === 0 && type !== 'postule') {
      const { data: users, error: uErr } = await supabase
        .from('utilisateurs')
        .select('id, nom, email, photo_url, role')
        .eq('role', 'chercheur')
        .limit(120);
      if (uErr) throw uErr;
      peers = (users || [])
        .filter((u) => {
          const nom = String(u.nom || '').toLowerCase();
          const email = String(u.email || '').toLowerCase();
          return nom.includes(needle) || email.includes(needle);
        })
        .slice(0, 10);
    }

    return res.json({ success: true, data: peers });
  } catch (err) {
    console.error('[recruteur/messages peers search]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

router.get('/peers/search', handlePeerSearch);
router.get('/rechercher-destinataire', handlePeerSearch);

async function handleUploadMessageFile(req, res) {
  try {
    if (!req.file?.buffer) {
      return res.status(400).json({ success: false, message: 'Aucun fichier reçu' });
    }
    const rawName = String(req.file.originalname || 'piece-jointe').replace(/[^\w.\-()+ ]/g, '_').slice(0, 200);
    const contentType = resolveUploadMime(req.file);
    const ext = (rawName.split('.').pop() || 'bin').toLowerCase();
    const isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext);
    const bucket = isImage ? (process.env.SUPABASE_STORAGE_BUCKET_AVATARS || 'avatars') : 'messagerie-files';
    const path = `msg-pj/${req.user.id}/${Date.now()}-${rawName}`;

    const { error: uploadErr } = await supabase.storage
      .from(bucket)
      .upload(path, req.file.buffer, {
        contentType,
        upsert: false,
      });
    if (uploadErr) throw uploadErr;

    let finalUrl = '';
    if (isImage) {
      const { data } = supabase.storage.from(bucket).getPublicUrl(path);
      finalUrl = data?.publicUrl || '';
    } else {
      const { data: signed, error: signedErr } = await supabase.storage
        .from(bucket)
        .createSignedUrl(path, 60 * 60 * 24 * 7);
      if (!signedErr && signed?.signedUrl) {
        finalUrl = signed.signedUrl;
      }
    }
    if (!finalUrl) {
      throw new Error('Impossible de générer une URL de téléchargement pour la pièce jointe.');
    }
    return res.json({
      success: true,
      data: {
        url: finalUrl,
        nom: rawName,
        bucket,
        path,
        fichier_url: finalUrl,
        fichier_nom: rawName,
        fichier_taille: req.file.size,
        fichier_type: contentType,
        type_message: isImage ? 'image' : 'fichier',
      },
    });
  } catch (err) {
    console.error('[recruteur/messages upload-fichier]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur upload' });
  }
}

router.post('/upload-fichier', uploadPj.single('fichier'), handleUploadMessageFile);
router.post('/attachment', uploadPj.single('file'), handleUploadMessageFile);

router.get('/file/:messageId', handleMessageAttachmentDownload);

router.post('/typing', async (req, res) => {
  try {
    const destinataireId = req.body?.destinataire_id;
    if (!destinataireId || String(destinataireId).trim() === '') {
      return res.status(400).json({ success: false, message: 'destinataire_id requis' });
    }
    const cid = conversationId(req.user.id, String(destinataireId));
    await recordTyping(cid, req.user.id);
    return res.json({ success: true });
  } catch (err) {
    console.error('[recruteur/messages POST /typing]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.get('/peer-typing/:destinataireId', async (req, res) => {
  try {
    const { destinataireId } = req.params;
    if (!destinataireId || String(destinataireId).trim() === '') {
      return res.status(400).json({ success: false, message: 'destinataire_id requis' });
    }
    const cid = conversationId(req.user.id, destinataireId);
    const peerTyping = await isPeerTyping(cid, req.user.id);
    return res.json({ success: true, data: { peer_typing: peerTyping } });
  } catch (err) {
    console.error('[recruteur/messages GET /peer-typing]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.get('/:destinataireId', async (req, res) => {
  try {
    const { destinataireId } = req.params;
    const cid = conversationId(req.user.id, destinataireId);
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', cid)
      .order('date_envoi', { ascending: true });
    if (error) {
      if (isMissingMessagesTable(error)) {
        return res.json({
          success: true,
          data: { messages: [], conversation_id: cid },
          warning: 'messages_table_missing',
          message: 'La table messages est absente. Appliquez la migration SQL messages.',
        });
      }
      throw error;
    }

    await supabase
      .from('messages')
      .update({ est_lu: true, date_lecture: new Date().toISOString() })
      .eq('conversation_id', cid)
      .eq('destinataire_id', req.user.id)
      .eq('est_lu', false);

    const messages = (data || [])
      .filter((m) => {
        if (m.expediteur_id === req.user.id && m.est_supprime_exp === true) return false;
        if (m.destinataire_id === req.user.id && m.est_supprime_dest === true) return false;
        return true;
      })
      .map((m) => {
        const fileUrl = m.fichier_url || m.piece_jointe_url || null;
        const fileNom = m.fichier_nom || m.piece_jointe_nom || null;
        let type = m.type_message || 'texte';
        if (type === 'texte' && fileUrl) {
          const lower = String(fileNom || fileUrl).toLowerCase();
          const isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].some((ext) => lower.endsWith(ext));
          type = isImage ? 'image' : 'fichier';
        }
        return {
          ...m,
          type_message: type,
          fichier_url: fileUrl,
          fichier_nom: fileNom,
          piece_jointe_url: fileUrl,
          piece_jointe_nom: fileNom,
          is_mine: m.expediteur_id === req.user.id,
        };
      });

    const { data: interlocuteur } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, photo_url, role')
      .eq('id', destinataireId)
      .maybeSingle();

    return res.json({
      success: true,
      data: {
        messages,
        interlocuteur: interlocuteur || null,
        conversation_id: cid,
      },
    });
  } catch (err) {
    console.error('[recruteur/messages/:id]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.post('/', async (req, res) => {
  try {
    const {
      destinataire_id: destinataireId,
      contenu,
      offre_id: offreId,
      piece_jointe_url: pieceUrl,
      piece_jointe_nom: pieceNom,
    } = req.body || {};
    const rawContenu = contenu != null ? String(contenu).trim() : '';
    const pjUrl = pieceUrl != null ? String(pieceUrl).trim() || null : null;
    const pjNom = pieceNom != null ? String(pieceNom).trim() || null : null;
    if (!destinataireId || (!rawContenu && !pjUrl)) {
      return res.status(400).json({ success: false, message: 'destinataire_id et (contenu ou pièce jointe) requis' });
    }
    const cid = conversationId(req.user.id, destinataireId);
    const row = {
      conversation_id: cid,
      expediteur_id: req.user.id,
      destinataire_id: destinataireId,
      contenu: rawContenu,
      offre_id: offreId || null,
    };
    if (pjUrl) row.piece_jointe_url = pjUrl;
    if (pjNom) row.piece_jointe_nom = pjNom;
    if (pjUrl) row.fichier_url = pjUrl;
    if (pjNom) row.fichier_nom = pjNom;
    if (pjUrl) row.type_message = 'fichier';
    const { data, error } = await supabase
      .from('messages')
      .insert(row)
      .select()
      .single();
    if (error) {
      if (isMissingMessagesTable(error)) {
        return res.status(503).json({
          success: false,
          message: 'Messagerie indisponible: table messages absente. Appliquez la migration SQL messages.',
          code: 'messages_table_missing',
        });
      }
      throw error;
    }

    await clearTypingForUser(cid, req.user.id);

    try {
      await supabase.from('notifications').insert({
        destinataire_id: destinataireId,
        type_destinataire: 'individuel',
        titre: `💬 Message de ${req.entreprise?.nom_entreprise || 'une entreprise'}`,
        message: rawContenu.slice(0, 140),
        type: 'message',
        lien: '/dashboard/messages',
        est_lue: false,
      });
    } catch (e) {
      console.warn('[messages] notification non créée:', e.message);
    }

    void sendNewMessageEmail(destinataireId, {
      senderLabel: `Message de ${req.entreprise?.nom_entreprise || 'une entreprise'}`,
      excerpt: rawContenu,
      lienLibelle:
          'Ouvrez la messagerie dans votre espace candidat sur la plateforme pour répondre.',
    });

    return res.status(201).json({ success: true, data: { ...data, is_mine: true } });
  } catch (err) {
    console.error('[recruteur/messages POST]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.delete('/:messageId', async (req, res) => {
  try {
    const { messageId } = req.params;
    if (!messageId) {
      return res.status(400).json({ success: false, message: 'messageId requis' });
    }
    const userId = req.user.id;
    const { data: row, error: selErr } = await supabase
      .from('messages')
      .select('id, expediteur_id, destinataire_id')
      .eq('id', messageId)
      .maybeSingle();
    if (selErr) throw selErr;
    if (!row) {
      return res.status(404).json({ success: false, message: 'Message introuvable' });
    }
    const participant = row.expediteur_id === userId || row.destinataire_id === userId;
    if (!participant) {
      return res.status(403).json({ success: false, message: 'Action non autorisée' });
    }
    const field = row.expediteur_id === userId ? 'est_supprime_exp' : 'est_supprime_dest';
    const { error: softErr } = await supabase
      .from('messages')
      .update({ [field]: true })
      .eq('id', messageId);
    if (softErr) {
      // Fallback si colonnes soft-delete absentes.
      const { error: delErr } = await supabase
        .from('messages')
        .delete()
        .eq('id', messageId);
      if (delErr) throw delErr;
    }
    return res.json({ success: true, message: 'Message supprimé' });
  } catch (err) {
    console.error('[recruteur/messages DELETE]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;
