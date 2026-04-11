import crypto from 'crypto';
import { Router } from 'express';
import multer from 'multer';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { supabase } from '../../config/supabase.js';
import { ROLES } from '../../config/constants.js';
import { sendNewMessageEmail } from '../../services/mail.service.js';
import { handleMessageAttachmentDownload } from '../../helpers/messageAttachmentDownload.js';
import { recordTyping, isPeerTyping, clearTypingForUser } from '../../services/messageTypingPresence.js';

const router = Router();
router.use(authenticate, requireRole(ROLES.CHERCHEUR), attachProfileIds);

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

function conversationId(a, b) {
  return crypto.createHash('md5').update([a, b].sort().join('-')).digest('hex');
}

function isMissingMessagesTable(err) {
  return err?.code === 'PGRST205'
    && typeof err?.message === 'string'
    && err.message.includes("Could not find the table 'public.messages'");
}

async function allowedDestinatairesForChercheur(chercheurId) {
  const { data: cands, error: cErr } = await supabase
    .from('candidatures')
    .select('offre_id')
    .eq('chercheur_id', chercheurId);
  if (cErr) throw cErr;

  const offreIds = [...new Set((cands || []).map((c) => c.offre_id).filter(Boolean))];
  if (!offreIds.length) return new Set();

  const { data: offres, error: oErr } = await supabase
    .from('offres_emploi')
    .select('id, entreprise:entreprise_id ( utilisateur_id )')
    .in('id', offreIds);
  if (oErr) throw oErr;

  return new Set(
    (offres || [])
      .map((o) => o.entreprise?.utilisateur_id)
      .filter(Boolean),
  );
}

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
    console.error('[candidat/messages upload]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur upload' });
  }
}

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

    const visibleRows = (rows || []).filter((m) => {
      if (m.expediteur_id === userId && m.est_supprime_exp === true) return false;
      if (m.destinataire_id === userId && m.est_supprime_dest === true) return false;
      return true;
    });

    const seenCid = new Set();
    const summaries = [];
    const unreadByCid = {};

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
        .select('id, titre, entreprise:entreprise_id ( nom_entreprise, logo_url )')
        .in('id', offreIds);
      offreMap = Object.fromEntries((offres || []).map((o) => [o.id, o]));
    }

    const data = summaries.map((s) => {
      const peer = userMap[s.peer_id] || { id: s.peer_id, nom: 'Entreprise', email: '', photo_url: null };
      const offre = s.offre_id ? offreMap[s.offre_id] : null;
      const ent = offre?.entreprise;
      return {
        conversation_id: s.conversation_id,
        peer_id: s.peer_id,
        peer,
        dernier_message: s.dernier_message,
        date_dernier: s.date_dernier,
        nb_non_lus: s.nb_non_lus,
        offre_id: s.offre_id,
        offre_titre: offre?.titre || null,
        entreprise_nom: ent?.nom_entreprise || null,
        entreprise_logo_url: ent?.logo_url || null,
      };
    });

    data.sort((a, b) => new Date(b.date_dernier || 0) - new Date(a.date_dernier || 0));
    return res.json({ success: true, data });
  } catch (err) {
    console.error('[candidat/messages GET /]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.post('/attachment', uploadPj.single('file'), handleUploadMessageFile);

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
    console.error('[candidat/messages POST /typing]', err);
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
    console.error('[candidat/messages GET /peer-typing]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.get('/file/:messageId', handleMessageAttachmentDownload);

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
      const { error: delErr } = await supabase
        .from('messages')
        .delete()
        .eq('id', messageId);
      if (delErr) throw delErr;
    }
    return res.json({ success: true, message: 'Message supprimé' });
  } catch (err) {
    console.error('[candidat/messages DELETE]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.get('/:destinataireId', async (req, res) => {
  try {
    const { destinataireId } = req.params;
    const { since } = req.query;
    const cid = conversationId(req.user.id, destinataireId);
    let query = supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', cid)
      .order('date_envoi', { ascending: true });
    if (since) query = query.gt('date_envoi', since);
    const { data, error } = await query;
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

    const { data: interlocuteur } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, photo_url, role')
      .eq('id', destinataireId)
      .maybeSingle();

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

    return res.json({
      success: true,
      data: {
        messages,
        conversation_id: cid,
        interlocuteur: interlocuteur || null,
        timestamp: new Date().toISOString(),
      },
    });
  } catch (err) {
    console.error('[candidat/messages/:id]', err);
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

    const allowedSet = await allowedDestinatairesForChercheur(req.chercheurId);
    const cid = conversationId(req.user.id, destinataireId);

    const { data: alreadyConv } = await supabase
      .from('messages')
      .select('id')
      .eq('conversation_id', cid)
      .limit(1);

    if ((!alreadyConv || !alreadyConv.length) && !allowedSet.has(destinataireId)) {
      return res.status(403).json({
        success: false,
        message: 'Vous ne pouvez démarrer une conversation qu’avec une entreprise liée à vos candidatures.',
      });
    }

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

    const notifExcerpt = (rawContenu || pjNom || '📎 Fichier').slice(0, 140);

    try {
      await supabase.from('notifications').insert({
        destinataire_id: destinataireId,
        type_destinataire: 'individuel',
        titre: `💬 Message de ${req.user.nom || 'un candidat'}`,
        message: notifExcerpt,
        type: 'message',
        lien: '/dashboard-recruteur/messages',
        est_lue: false,
      });
    } catch (_) {
      // Ne pas bloquer l'envoi du message si la notif échoue.
    }

    void sendNewMessageEmail(destinataireId, {
      senderLabel: `Message de ${req.user.nom || 'un candidat'}`,
      excerpt: notifExcerpt,
      lienLibelle:
        'Ouvrez la messagerie dans votre espace recruteur sur la plateforme pour répondre.',
    });

    return res.status(201).json({ success: true, data: { ...data, is_mine: true } });
  } catch (err) {
    console.error('[candidat/messages POST]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;
