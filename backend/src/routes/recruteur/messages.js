import crypto from 'crypto';
import { Router } from 'express';
import multer from 'multer';
import { authenticate } from '../../middleware/auth.js';
import { requireRecruteur } from '../../middleware/recruteurAuth.js';
import { supabase } from '../../config/supabase.js';
import { sendNewMessageEmail } from '../../services/mail.service.js';

const router = Router();
router.use(authenticate, requireRecruteur);

const uploadPj = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024 },
});

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
      .select('id, conversation_id, expediteur_id, destinataire_id, contenu, est_lu, date_envoi, offre_id')
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

    for (const m of rows || []) {
      if (m.destinataire_id === userId && m.est_lu === false) {
        unreadByCid[m.conversation_id] = (unreadByCid[m.conversation_id] || 0) + 1;
      }
    }

    for (const m of rows || []) {
      if (seenCid.has(m.conversation_id)) continue;
      seenCid.add(m.conversation_id);
      const peerId = m.expediteur_id === userId ? m.destinataire_id : m.expediteur_id;
      summaries.push({
        conversation_id: m.conversation_id,
        peer_id: peerId,
        dernier_message: m.contenu,
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

    const data = summaries.map((s) => {
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

    data.sort((a, b) => new Date(b.date_dernier || 0) - new Date(a.date_dernier || 0));

    return res.json({ success: true, data });
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
        const { data: chercheurs, error: chErr } = await supabase
          .from('chercheurs_emploi')
          .select('id, utilisateur:utilisateur_id (id, nom, email, photo_url, role)')
          .in('id', chercheurIds);
        if (chErr) throw chErr;

        const seen = new Set();
        peers = (chercheurs || [])
          .map((c) => c.utilisateur)
          .filter(Boolean)
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

/**
 * POST /recruteur/messages/attachment — upload fichier → URL publique (bucket logos, préfixe dédié).
 */
router.post('/attachment', uploadPj.single('file'), async (req, res) => {
  try {
    if (!req.file?.buffer) {
      return res.status(400).json({ success: false, message: 'Fichier requis (champ file)' });
    }
    const rawName = String(req.file.originalname || 'piece-jointe').replace(/[^\w.\-()+ ]/g, '_').slice(0, 160);
    const path = `msg-pj/${req.user.id}/${Date.now()}-${rawName}`;
    const { error } = await supabase.storage
      .from('logos')
      .upload(path, req.file.buffer, {
        contentType: req.file.mimetype || 'application/octet-stream',
        upsert: false,
      });
    if (error) throw error;
    const { data } = supabase.storage.from('logos').getPublicUrl(path);
    return res.json({
      success: true,
      data: { url: data.publicUrl, nom: rawName },
    });
  } catch (err) {
    console.error('[recruteur/messages attachment]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur upload' });
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

    const messages = (data || []).map((m) => ({
      ...m,
      is_mine: m.expediteur_id === req.user.id,
    }));

    return res.json({ success: true, data: { messages, conversation_id: cid } });
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
    if (!destinataireId || !contenu) {
      return res.status(400).json({ success: false, message: 'destinataire_id et contenu requis' });
    }
    const cid = conversationId(req.user.id, destinataireId);
    const pjUrl = pieceUrl != null ? String(pieceUrl).trim() || null : null;
    const pjNom = pieceNom != null ? String(pieceNom).trim() || null : null;
    const row = {
      conversation_id: cid,
      expediteur_id: req.user.id,
      destinataire_id: destinataireId,
      contenu: String(contenu).trim(),
      offre_id: offreId || null,
    };
    if (pjUrl) row.piece_jointe_url = pjUrl;
    if (pjNom) row.piece_jointe_nom = pjNom;
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

    try {
      await supabase.from('notifications').insert({
        destinataire_id: destinataireId,
        type_destinataire: 'individuel',
        titre: `💬 Message de ${req.entreprise?.nom_entreprise || 'une entreprise'}`,
        message: String(contenu).trim().slice(0, 140),
        type: 'message',
        lien: '/dashboard/messages',
        est_lue: false,
      });
    } catch (e) {
      console.warn('[messages] notification non créée:', e.message);
    }

    void sendNewMessageEmail(destinataireId, {
      senderLabel: `Message de ${req.entreprise?.nom_entreprise || 'une entreprise'}`,
      excerpt: String(contenu).trim(),
      lienLibelle:
          'Ouvrez la messagerie dans votre espace candidat sur la plateforme pour répondre.',
    });

    return res.status(201).json({ success: true, data: { ...data, is_mine: true } });
  } catch (err) {
    console.error('[recruteur/messages POST]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;
