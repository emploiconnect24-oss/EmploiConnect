import { supabase } from '../../config/supabase.js';

function parseTags(tags) {
  if (tags == null || tags === '') return [];
  if (Array.isArray(tags)) return tags.map((t) => String(t).trim()).filter(Boolean);
  return String(tags)
    .split(',')
    .map((t) => t.trim())
    .filter(Boolean);
}

function youtubeEmbedUrl(url) {
  if (!url) return null;
  const s = String(url).trim();
  const m = s.match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/))([\w-]+)/);
  if (m) return `https://www.youtube.com/embed/${m[1]}`;
  return s;
}

async function notifierNouvelleRessource(ressource) {
  try {
    const { data: candidats, error } = await supabase
      .from('chercheurs_emploi')
      .select('utilisateur_id');
    if (error || !candidats?.length) return;

    const lien = `/dashboard/parcours?ressource=${ressource.id}`;
    const rows = candidats.map((c) => ({
      destinataire_id: c.utilisateur_id,
      type_destinataire: 'individuel',
      titre: 'Nouvelle ressource disponible',
      message: `"${ressource.titre}" vient d'être ajouté au Parcours Carrière`,
      type: 'ressource',
      lien,
      est_lue: false,
    }));

    await supabase.from('notifications').insert(rows);
  } catch (e) {
    console.warn('[ressourcesParcours] Notif échouée:', e?.message || e);
  }
}

export async function listRessources(req, res) {
  try {
    const { categorie, type, publie } = req.query;
    let q = supabase
      .from('ressources_carrieres')
      .select(
        'id, titre, description, type_ressource, categorie, niveau, est_publie, est_mis_en_avant, nb_vues, date_creation, date_publication, ordre_affichage, auteur_id, utilisateurs!ressources_carrieres_auteur_id_fkey ( nom )',
      )
      .order('ordre_affichage', { ascending: true })
      .order('date_creation', { ascending: false });

    if (categorie) q = q.eq('categorie', categorie);
    if (type) q = q.eq('type_ressource', type);
    if (publie !== undefined) q = q.eq('est_publie', String(publie) === 'true');

    const { data, error } = await q;
    if (error) throw error;

    const mapped = (data || []).map((row) => {
      const u = row.utilisateurs;
      delete row.utilisateurs;
      return { ...row, auteur_nom: u?.nom ?? null };
    });

    return res.json({ success: true, data: mapped });
  } catch (err) {
    console.error('[listRessources]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function getRessourceById(req, res) {
  try {
    const { id } = req.params;
    const { data, error } = await supabase
      .from('ressources_carrieres')
      .select(
        'id, titre, description, contenu, type_ressource, categorie, niveau, url_externe, fichier_url, image_couverture, duree_minutes, tags, est_publie, est_mis_en_avant, nb_vues, date_creation, date_publication, ordre_affichage, auteur_id, utilisateurs!ressources_carrieres_auteur_id_fkey ( nom )',
      )
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    if (!data) return res.status(404).json({ success: false, message: 'Ressource introuvable' });

    const u = data.utilisateurs;
    delete data.utilisateurs;
    return res.json({ success: true, data: { ...data, auteur_nom: u?.nom ?? null } });
  } catch (err) {
    console.error('[getRessourceById]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function createRessource(req, res) {
  try {
    const b = req.body || {};
    const titre = String(b.titre || '').trim();
    if (!titre) {
      return res.status(400).json({ success: false, message: 'Titre requis' });
    }

    const type_ressource = String(b.type_ressource || '').trim();
    const categorie = String(b.categorie || '').trim();
    if (!type_ressource || !categorie) {
      return res.status(400).json({ success: false, message: 'Type et catégorie requis' });
    }

    let fichierUrl = b.fichier_url ? String(b.fichier_url) : null;
    let couvertureUrl = b.image_couverture ? String(b.image_couverture) : null;

    const fichier = req.files?.fichier?.[0];
    const couverture = req.files?.couverture?.[0];

    if (fichier?.buffer) {
      const chemin = `fichiers/${Date.now()}-${fichier.originalname.replace(/[^\w.\-]/g, '_')}`;
      const { error: upErr } = await supabase.storage.from('ressources').upload(chemin, fichier.buffer, {
        contentType: fichier.mimetype || 'application/octet-stream',
        upsert: false,
      });
      if (!upErr) {
        const { data: pub } = supabase.storage.from('ressources').getPublicUrl(chemin);
        fichierUrl = pub.publicUrl;
      } else {
        console.warn('[createRessource] upload fichier:', upErr.message);
      }
    }

    if (couverture?.buffer) {
      const chemin = `couvertures/${Date.now()}-${couverture.originalname.replace(/[^\w.\-]/g, '_')}`;
      const { error: upErr } = await supabase.storage.from('ressources').upload(chemin, couverture.buffer, {
        contentType: couverture.mimetype || 'image/jpeg',
        upsert: false,
      });
      if (!upErr) {
        const { data: pub } = supabase.storage.from('ressources').getPublicUrl(chemin);
        couvertureUrl = pub.publicUrl;
      } else {
        console.warn('[createRessource] upload couverture:', upErr.message);
      }
    }

    let urlFinale = b.url_externe ? String(b.url_externe).trim() : null;
    if (type_ressource === 'video_youtube' && urlFinale) {
      urlFinale = youtubeEmbedUrl(urlFinale);
    }

    const est_publie = String(b.est_publie) === 'true' || b.est_publie === true;
    const est_mis_en_avant = String(b.est_mis_en_avant) === 'true' || b.est_mis_en_avant === true;

    const insertRow = {
      titre,
      description: b.description != null ? String(b.description) : null,
      contenu: b.contenu != null ? String(b.contenu) : null,
      type_ressource,
      categorie,
      niveau: b.niveau ? String(b.niveau) : 'tous',
      url_externe: urlFinale,
      fichier_url: fichierUrl,
      image_couverture: couvertureUrl,
      tags: parseTags(b.tags),
      duree_minutes: b.duree_minutes ? parseInt(String(b.duree_minutes), 10) : null,
      ordre_affichage: b.ordre_affichage != null ? parseInt(String(b.ordre_affichage), 10) : 0,
      est_publie,
      est_mis_en_avant,
      auteur_id: req.user?.id || null,
      date_publication: est_publie ? new Date().toISOString() : null,
    };

    const { data, error } = await supabase.from('ressources_carrieres').insert(insertRow).select().single();
    if (error) throw error;

    if (est_publie) await notifierNouvelleRessource(data);

    return res.status(201).json({ success: true, message: 'Ressource créée', data });
  } catch (err) {
    console.error('[createRessource]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function patchRessource(req, res) {
  try {
    const { id } = req.params;
    const b = req.body || {};
    const updates = {};

    const keys = [
      'titre',
      'description',
      'contenu',
      'type_ressource',
      'categorie',
      'niveau',
      'url_externe',
      'fichier_url',
      'image_couverture',
      'duree_minutes',
      'ordre_affichage',
      'est_mis_en_avant',
    ];
    for (const k of keys) {
      if (b[k] !== undefined) updates[k] = b[k];
    }
    if (b.tags !== undefined) updates.tags = parseTags(b.tags);

    if (b.url_externe !== undefined && updates.type_ressource === 'video_youtube') {
      updates.url_externe = youtubeEmbedUrl(String(b.url_externe));
    } else if (b.url_externe !== undefined && String(updates.type_ressource || b.type_ressource || '') === 'video_youtube') {
      updates.url_externe = youtubeEmbedUrl(String(b.url_externe));
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ success: false, message: 'Aucun champ à mettre à jour' });
    }

    const { data, error } = await supabase.from('ressources_carrieres').update(updates).eq('id', id).select().single();
    if (error) throw error;
    if (!data) return res.status(404).json({ success: false, message: 'Ressource introuvable' });

    return res.json({ success: true, data });
  } catch (err) {
    console.error('[patchRessource]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function patchPublier(req, res) {
  try {
    const { id } = req.params;
    const est_publie = req.body?.est_publie === true || String(req.body?.est_publie) === 'true';

    const { data, error } = await supabase
      .from('ressources_carrieres')
      .update({
        est_publie,
        date_publication: est_publie ? new Date().toISOString() : null,
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    if (!data) return res.status(404).json({ success: false, message: 'Ressource introuvable' });

    if (est_publie) await notifierNouvelleRessource(data);

    return res.json({ success: true, data });
  } catch (err) {
    console.error('[patchPublier]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function deleteRessource(req, res) {
  try {
    const { id } = req.params;
    const { error } = await supabase.from('ressources_carrieres').delete().eq('id', id);
    if (error) throw error;
    return res.json({ success: true, message: 'Ressource supprimée' });
  } catch (err) {
    console.error('[deleteRessource]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}
