import { supabase } from '../config/supabase.js';

/**
 * Extrait bucket + chemin objet depuis une URL Supabase Storage (public ou signée).
 * @param {string} rawUrl
 * @returns {{ bucket: string, path: string } | null}
 */
export function parseSupabaseStorageObjectFromUrl(rawUrl) {
  const s = String(rawUrl || '').trim();
  if (!s) return null;
  let u;
  try {
    u = new URL(s);
  } catch {
    return null;
  }
  const p = u.pathname;
  const markers = [
    '/storage/v1/object/public/',
    '/storage/v1/object/sign/',
    '/storage/v1/object/authenticated/',
  ];
  for (const key of markers) {
    const i = p.indexOf(key);
    if (i === -1) continue;
    const rest = p.slice(i + key.length);
    const segments = rest.split('/').filter(Boolean).map((seg) => {
      try {
        return decodeURIComponent(seg);
      } catch {
        return seg;
      }
    });
    if (segments.length < 2) return null;
    const bucket = segments[0];
    const objectPath = segments.slice(1).join('/');
    if (!bucket || !objectPath) return null;
    return { bucket, path: objectPath };
  }
  return null;
}

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

/**
 * GET /…/messages/file/:messageId — flux fichier authentifié (ignore URL signée expirée).
 */
export async function handleMessageAttachmentDownload(req, res) {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;
    if (!messageId) {
      return res.status(400).json({ success: false, message: 'messageId requis' });
    }

    const { data: row, error: selErr } = await supabase
      .from('messages')
      .select('id, expediteur_id, destinataire_id, piece_jointe_url, fichier_url, piece_jointe_nom, fichier_nom')
      .eq('id', messageId)
      .maybeSingle();

    if (selErr) throw selErr;
    if (!row) {
      return res.status(404).json({ success: false, message: 'Message introuvable' });
    }

    const participant = row.expediteur_id === userId || row.destinataire_id === userId;
    if (!participant) {
      return res.status(403).json({ success: false, message: 'Non autorisé' });
    }

    const fileUrl = row.fichier_url || row.piece_jointe_url || null;
    const fileNom = row.fichier_nom || row.piece_jointe_nom || 'piece-jointe';
    if (!fileUrl) {
      return res.status(404).json({ success: false, message: 'Aucune pièce jointe' });
    }

    const parsed = parseSupabaseStorageObjectFromUrl(fileUrl);
    if (!parsed) {
      return res.status(400).json({
        success: false,
        message: 'Lien de fichier non reconnu (téléchargement direct uniquement).',
      });
    }

    const { data, error: dlErr } = await supabase.storage
      .from(parsed.bucket)
      .download(parsed.path);

    if (dlErr || !data) {
      console.error('[messageAttachmentDownload]', dlErr?.message || dlErr, parsed);
      return res.status(404).json({
        success: false,
        message: 'Fichier introuvable sur le stockage.',
      });
    }

    const ab = await data.arrayBuffer();
    const buf = Buffer.from(ab);
    const mime = inferMimeFromFilename(fileNom) || 'application/octet-stream';
    const safeAscii = String(fileNom).replace(/[^\x20-\x7E]/g, '_').replace(/"/g, '_').slice(0, 180) || 'piece-jointe';

    res.setHeader('Content-Type', mime);
    res.setHeader('Content-Length', String(buf.length));
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${safeAscii}"; filename*=UTF-8''${encodeURIComponent(String(fileNom).slice(0, 200))}`,
    );
    return res.status(200).send(buf);
  } catch (err) {
    console.error('[messageAttachmentDownload]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
