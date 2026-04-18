import { supabase } from '../../config/supabase.js';
import multer from 'multer';
import { sendPlatformEmail } from '../../services/mail.service.js';
import { _appellerIA, _getClesIA } from '../../services/ia.service.js';

export const uploadEquipePhoto = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
});

/**
 * PUT /api/admin/apropos/:id
 * Body: { titre?, contenu?, icone?, est_actif?, ordre?, meta_donnees? }
 */
export async function putAproposSection(req, res) {
  try {
    const { id } = req.params;
    const {
      titre, contenu, icone, est_actif, ordre, meta_donnees,
    } = req.body || {};

    const patch = {};
    if (titre !== undefined) patch.titre = titre;
    if (contenu !== undefined) patch.contenu = contenu;
    if (icone !== undefined) patch.icone = icone;
    if (est_actif !== undefined) patch.est_actif = Boolean(est_actif);
    if (ordre !== undefined && ordre !== null) patch.ordre = Number(ordre);
    if (meta_donnees !== undefined) patch.meta_donnees = meta_donnees;

    if (Object.keys(patch).length === 0) {
      return res.status(400).json({ success: false, message: 'Aucun champ à mettre à jour' });
    }

    const { data, error } = await supabase
      .from('page_a_propos')
      .update(patch)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[PUT /admin/apropos/:id]', error.message);
      return res.status(500).json({ success: false, message: error.message });
    }
    if (!data) {
      return res.status(404).json({ success: false, message: 'Section introuvable' });
    }
    return res.json({ success: true, data });
  } catch (err) {
    console.error('[PUT /admin/apropos/:id]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function getEquipeAdmin(_req, res) {
  try {
    const { data, error } = await supabase
      .from('equipe_membres')
      .select('*')
      .order('ordre', { ascending: true });
    if (error) throw error;
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

async function _uploadEquipePhoto(file) {
  if (!file) return null;
  const ext = String(file.originalname || '').split('.').pop() || 'jpg';
  const chemin = `equipe/${Date.now()}_${Math.random().toString(36).slice(2, 8)}.${ext}`;
  const { error } = await supabase.storage
    .from('avatars')
    .upload(chemin, file.buffer, {
      contentType: file.mimetype || 'image/jpeg',
      upsert: true,
    });
  if (error) return null;
  const { data: pub } = supabase.storage.from('avatars').getPublicUrl(chemin);
  return pub?.publicUrl || null;
}

export async function postEquipeAdmin(req, res) {
  try {
    const {
      nom = '',
      poste = '',
      description = '',
      linkedin = '',
      ordre = '0',
    } = req.body || {};
    if (!String(nom).trim()) {
      return res.status(400).json({ success: false, message: 'Nom requis' });
    }
    const photoUrl = await _uploadEquipePhoto(req.file);
    const { data, error } = await supabase
      .from('equipe_membres')
      .insert({
        nom: String(nom).trim(),
        poste: String(poste).trim(),
        description: String(description).trim(),
        linkedin: String(linkedin).trim(),
        photo_url: photoUrl,
        ordre: Number.parseInt(String(ordre), 10) || 0,
      })
      .select()
      .single();
    if (error) throw error;
    return res.status(201).json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function putEquipeAdmin(req, res) {
  try {
    const { id } = req.params;
    const {
      nom,
      poste,
      description,
      linkedin,
      ordre,
      est_actif,
    } = req.body || {};
    const patch = {};
    if (nom !== undefined) patch.nom = String(nom).trim();
    if (poste !== undefined) patch.poste = String(poste).trim();
    if (description !== undefined) patch.description = String(description).trim();
    if (linkedin !== undefined) patch.linkedin = String(linkedin).trim();
    if (ordre !== undefined) patch.ordre = Number.parseInt(String(ordre), 10) || 0;
    if (est_actif !== undefined) patch.est_actif = est_actif === true || est_actif === 'true';
    const photoUrl = await _uploadEquipePhoto(req.file);
    if (photoUrl) patch.photo_url = photoUrl;
    if (Object.keys(patch).length === 0) {
      return res.status(400).json({ success: false, message: 'Aucun champ à mettre à jour' });
    }
    const { data, error } = await supabase
      .from('equipe_membres')
      .update(patch)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return res.json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function deleteEquipeAdmin(req, res) {
  try {
    const { id } = req.params;
    const { error } = await supabase
      .from('equipe_membres')
      .update({ est_actif: false })
      .eq('id', id);
    if (error) throw error;
    return res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function getMessagesContactAdmin(_req, res) {
  try {
    const { data, error } = await supabase
      .from('messages_contact')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) throw error;
    const rows = data || [];
    const nonLus = rows.filter((m) => m.est_lu !== true).length;
    return res.json({ success: true, data: rows, non_lus: nonLus });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function patchMessageContactLu(req, res) {
  try {
    const { id } = req.params;
    const { error } = await supabase
      .from('messages_contact')
      .update({ est_lu: true })
      .eq('id', id);
    if (error) throw error;
    return res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function postMessageContactRepondre(req, res) {
  try {
    const { id } = req.params;
    const reponse = String(req.body?.reponse || '').trim();
    if (!reponse) {
      return res.status(400).json({ success: false, message: 'Réponse requise' });
    }
    const { data: msg, error: errMsg } = await supabase
      .from('messages_contact')
      .select('*')
      .eq('id', id)
      .single();
    if (errMsg || !msg) {
      return res.status(404).json({ success: false, message: 'Message non trouvé' });
    }

    const email = String(msg.email || '').trim();
    if (!email) {
      return res.status(400).json({ success: false, message: 'E-mail destinataire manquant' });
    }
    const sujetBase = String(msg.sujet || 'Votre message').trim() || 'Votre message';
    const nom = String(msg.nom || '').trim() || 'Bonjour';
    const text = `Bonjour ${nom},\n\n${reponse}\n\nCordialement,\nL'équipe EmploiConnect`;
    const html = `
      <div style="font-family:Arial,sans-serif;max-width:640px;margin:0 auto;">
        <h2 style="margin:0 0 16px;color:#0F172A;">EmploiConnect</h2>
        <p>Bonjour ${nom},</p>
        <p style="white-space:pre-wrap;line-height:1.6;">${reponse}</p>
        <p>Cordialement,<br/>L'équipe EmploiConnect</p>
      </div>
    `;
    const sent = await sendPlatformEmail({
      to: email,
      subject: `Re: ${sujetBase} — EmploiConnect`,
      text,
      html,
    });
    if (!sent.ok) {
      return res.status(500).json({ success: false, message: sent.error || 'Échec envoi e-mail' });
    }

    const { error: errUpdate } = await supabase
      .from('messages_contact')
      .update({ est_lu: true, repondu_le: new Date().toISOString() })
      .eq('id', id);
    if (errUpdate) throw errUpdate;
    return res.json({ success: true, message: 'Réponse envoyée.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function postMessageContactRepondreIa(req, res) {
  try {
    const { id } = req.params;
    const { data: msg, error: errMsg } = await supabase
      .from('messages_contact')
      .select('*')
      .eq('id', id)
      .single();
    if (errMsg || !msg) {
      return res.status(404).json({ success: false, message: 'Message non trouvé' });
    }

    const prompt = `Tu es le service client EmploiConnect.
Réponds en français, ton professionnel, chaleureux et concis (max 150 mots).
Message reçu :
Nom: ${String(msg.nom || '')}
Sujet: ${String(msg.sujet || '')}
Message: ${String(msg.message || '')}
Termine par "L'équipe EmploiConnect".`;
    const cles = await _getClesIA();
    const reponseIa = await _appellerIA(prompt, cles, 'texte');
    if (!reponseIa) {
      return res.status(500).json({ success: false, message: 'IA indisponible' });
    }

    const email = String(msg.email || '').trim();
    if (!email) {
      return res.status(400).json({ success: false, message: 'E-mail destinataire manquant' });
    }
    const sujetBase = String(msg.sujet || 'Votre message').trim() || 'Votre message';
    const nom = String(msg.nom || '').trim() || 'Bonjour';
    const text = `Bonjour ${nom},\n\n${reponseIa}`;
    const html = `
      <div style="font-family:Arial,sans-serif;max-width:640px;margin:0 auto;">
        <h2 style="margin:0 0 16px;color:#0F172A;">EmploiConnect</h2>
        <p>Bonjour ${nom},</p>
        <p style="white-space:pre-wrap;line-height:1.6;">${String(reponseIa).replace(/\n/g, '<br/>')}</p>
      </div>
    `;
    const sent = await sendPlatformEmail({
      to: email,
      subject: `Re: ${sujetBase} — EmploiConnect`,
      text,
      html,
    });
    if (!sent.ok) {
      return res.status(500).json({ success: false, message: sent.error || 'Échec envoi e-mail' });
    }

    const { error: errUpdate } = await supabase
      .from('messages_contact')
      .update({
        est_lu: true,
        reponse_ia: reponseIa,
        repondu_le: new Date().toISOString(),
      })
      .eq('id', id);
    if (errUpdate) throw errUpdate;
    return res.json({ success: true, message: 'Réponse IA envoyée.', reponse: reponseIa });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}
