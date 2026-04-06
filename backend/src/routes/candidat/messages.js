import crypto from 'crypto';
import { Router } from 'express';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { supabase } from '../../config/supabase.js';
import { ROLES } from '../../config/constants.js';
import { sendNewMessageEmail } from '../../services/mail.service.js';

const router = Router();
router.use(authenticate, requireRole(ROLES.CHERCHEUR), attachProfileIds);

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

router.get('/:destinataireId', async (req, res) => {
  try {
    const { destinataireId } = req.params;
    const { since } = req.query;
    const cid = conversationId(req.user.id, destinataireId);
    let query = supabase
      .from('messages')
      .select('id, contenu, date_envoi, est_lu, expediteur_id, destinataire_id, offre:offre_id (id, titre), offre_id')
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

    const messages = (data || []).map((m) => ({
      ...m,
      is_mine: m.expediteur_id === req.user.id,
    }));
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
    const { destinataire_id: destinataireId, contenu, offre_id: offreId } = req.body || {};
    if (!destinataireId || !contenu) {
      return res.status(400).json({ success: false, message: 'destinataire_id et contenu requis' });
    }

    const allowedSet = await allowedDestinatairesForChercheur(req.chercheurId);
    const cid = conversationId(req.user.id, destinataireId);

    const { data: alreadyConv } = await supabase
      .from('messages')
      .select('id')
      .eq('conversation_id', cid)
      .limit(1);

    // Si pas de conversation existante, on exige une relation métier (candidature -> entreprise)
    if ((!alreadyConv || !alreadyConv.length) && !allowedSet.has(destinataireId)) {
      return res.status(403).json({
        success: false,
        message: 'Vous ne pouvez démarrer une conversation qu’avec une entreprise liée à vos candidatures.',
      });
    }

    const { data, error } = await supabase
      .from('messages')
      .insert({
        conversation_id: cid,
        expediteur_id: req.user.id,
        destinataire_id: destinataireId,
        contenu: String(contenu).trim(),
        offre_id: offreId || null,
      })
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
        titre: `💬 Message de ${req.user.nom || 'un candidat'}`,
        message: String(contenu).trim().slice(0, 140),
        type: 'message',
        lien: '/dashboard-recruteur/messages',
        est_lue: false,
      });
    } catch (_) {
      // Ne pas bloquer l'envoi du message si la notif échoue.
    }

    void sendNewMessageEmail(destinataireId, {
      senderLabel: `Message de ${req.user.nom || 'un candidat'}`,
      excerpt: String(contenu).trim(),
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

