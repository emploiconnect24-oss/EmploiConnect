import { supabase } from '../../config/supabase.js';

const LIBELLE_ACTION_ADMIN = {
  MODIFIER_PARAMETRES: 'Paramètres plateforme modifiés',
  MODIFICATION_UTILISATEUR: 'Compte utilisateur modifié',
  SUPPRESSION_UTILISATEUR: 'Utilisateur supprimé',
  MODERATION_OFFRE: 'Offre modérée',
  SUPPRESSION_OFFRE: 'Offre supprimée',
  MODERATION_ENTREPRISE: 'Entreprise modérée',
  TRAITEMENT_SIGNALEMENT: 'Signalement traité',
  ENVOI_NOTIFICATION: 'Notification envoyée',
  UPLOAD_LOGO_PLATEFORME: 'Logo plateforme mis à jour',
  VIDER_CACHE_PARAMETRES: 'Cache paramètres vidé',
  UPLOAD_IMAGE_BANNIERE: 'Image bannière importée',
  CREATION_BANNIERE: 'Bannière créée',
  REORDONNEMENT_BANNIERES: 'Bannières réordonnées',
  MODIFICATION_BANNIERE: 'Bannière modifiée',
  SUPPRESSION_BANNIERE: 'Bannière supprimée',
  MODIFICATION_PROFIL_ADMIN: 'Profil administrateur modifié',
  VALIDATION_CHANGEMENT_EMAIL_ADMIN: 'Adresse e-mail administrateur confirmée',
  MAJ_PHOTO_PROFIL_ADMIN: 'Photo de profil administrateur mise à jour',
  MODERATION_TEMOIGNAGE: 'Témoignage modéré',
};

function avecLibelleAction(rows) {
  return (rows || []).map((r) => ({
    ...r,
    action_libelle: LIBELLE_ACTION_ADMIN[r.action] || r.action,
  }));
}

async function legacyStatsPayload() {
  const [
    { count: nbChercheurs },
    { count: nbEntreprises },
    { count: nbAdmins },
    { count: nbOffresActives },
    { count: nbOffresTotal },
    { count: nbCandidatures },
    { count: nbCandidaturesAcceptees },
    { count: nbCv },
    { count: nbSignalementsEnAttente },
    { count: nbTemoignagesEnAttente },
  ] = await Promise.all([
    supabase.from('chercheurs_emploi').select('id', { count: 'exact', head: true }),
    supabase.from('entreprises').select('id', { count: 'exact', head: true }),
    supabase.from('utilisateurs').select('id', { count: 'exact', head: true }).eq('role', 'admin'),
    supabase.from('offres_emploi').select('id', { count: 'exact', head: true }).in('statut', ['active', 'publiee']),
    supabase.from('offres_emploi').select('id', { count: 'exact', head: true }),
    supabase.from('candidatures').select('id', { count: 'exact', head: true }),
    supabase.from('candidatures').select('id', { count: 'exact', head: true }).eq('statut', 'acceptee'),
    supabase.from('cv').select('id', { count: 'exact', head: true }),
    supabase.from('signalements').select('id', { count: 'exact', head: true }).eq('statut', 'en_attente'),
    supabase
      .from('temoignages_recrutement')
      .select('id', { count: 'exact', head: true })
      .eq('statut_moderation', 'en_attente'),
  ]);
  return {
    nombre_chercheurs: nbChercheurs ?? 0,
    nombre_entreprises: nbEntreprises ?? 0,
    nombre_admins: nbAdmins ?? 0,
    nombre_offres_actives: nbOffresActives ?? 0,
    nombre_offres_total: nbOffresTotal ?? 0,
    nombre_candidatures: nbCandidatures ?? 0,
    nombre_candidatures_acceptees: nbCandidaturesAcceptees ?? 0,
    nombre_cv: nbCv ?? 0,
    nombre_signalements_en_attente: nbSignalementsEnAttente ?? 0,
    nombre_temoignages_en_attente: nbTemoignagesEnAttente ?? 0,
    date_collecte: new Date().toISOString(),
  };
}

export async function getDashboard(req, res) {
  try {
    const legacy = await legacyStatsPayload();

    const { data: activiteRows } = await supabase
      .from('activite_admin')
      .select('id, action, type_objet, objet_id, date_action, admin_id')
      .order('date_action', { ascending: false })
      .limit(20);

    let activite_recente = avecLibelleAction(activiteRows || []);
    const adminIds = [...new Set(activite_recente.map((a) => a.admin_id).filter(Boolean))];
    if (adminIds.length) {
      const { data: admins } = await supabase
        .from('utilisateurs')
        .select('id, nom, email, photo_url')
        .in('id', adminIds);
      const map = Object.fromEntries((admins || []).map((u) => [u.id, u]));
      activite_recente = activite_recente.map((a) => ({
        ...a,
        admin: map[a.admin_id] || null,
      }));
    }

    const { data: offresEnAttente } = await supabase
      .from('offres_emploi')
      .select(`
        id, titre, localisation, type_contrat, date_creation,
        entreprises ( nom_entreprise, logo_url, utilisateur_id )
      `)
      .in('statut', ['en_attente', 'brouillon'])
      .order('date_creation', { ascending: true })
      .limit(5);

    const { data: derniersUsers } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, role, est_actif, est_valide, date_creation')
      .order('date_creation', { ascending: false })
      .limit(5);

    const { data: offresAll } = await supabase.from('offres_emploi').select('statut');
    const { data: usersAll } = await supabase
      .from('utilisateurs')
      .select('role, est_actif, est_valide');

    const stats = {
      utilisateurs: {
        total: usersAll?.length ?? 0,
        chercheurs: usersAll?.filter((u) => u.role === 'chercheur').length ?? 0,
        entreprises: usersAll?.filter((u) => u.role === 'entreprise').length ?? 0,
        en_attente: usersAll?.filter((u) => !u.est_valide).length ?? 0,
        bloques: usersAll?.filter((u) => !u.est_actif && u.est_valide).length ?? 0,
      },
      offres: {
        total: offresAll?.length ?? 0,
        actives: offresAll?.filter((o) => o.statut === 'active' || o.statut === 'publiee').length ?? 0,
        en_attente: offresAll?.filter((o) => o.statut === 'en_attente' || o.statut === 'brouillon').length ?? 0,
        refusees: offresAll?.filter((o) => o.statut === 'suspendue' || o.statut === 'refusee').length ?? 0,
        expirees: offresAll?.filter((o) => o.statut === 'fermee').length ?? 0,
      },
      legacy,
    };

    return res.json({
      success: true,
      ...legacy,
      data: {
        stats,
        activite_recente,
        offres_en_attente: offresEnAttente || [],
        derniers_utilisateurs: derniersUsers || [],
      },
    });
  } catch (err) {
    console.error('[getDashboard]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

function tendance(actuel, precedent) {
  if (!precedent || precedent === 0) return actuel > 0 ? 100 : 0;
  return Math.round(((actuel - precedent) / precedent) * 100);
}

async function evolutionParJour(nbJours) {
  const since = new Date(Date.now() - nbJours * 24 * 60 * 60 * 1000).toISOString();
  const { data: users } = await supabase.from('utilisateurs').select('date_creation').gte('date_creation', since);
  const { data: offres } = await supabase.from('offres_emploi').select('date_creation').gte('date_creation', since);
  const parJour = {};
  const today = new Date();
  for (let i = nbJours - 1; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    const key = date.toISOString().split('T')[0];
    parJour[key] = { date: key, utilisateurs: 0, offres: 0 };
  }
  (users || []).forEach((u) => {
    const key = u.date_creation?.split('T')[0];
    if (key && parJour[key]) parJour[key].utilisateurs += 1;
  });
  (offres || []).forEach((o) => {
    const key = o.date_creation?.split('T')[0];
    if (key && parJour[key]) parJour[key].offres += 1;
  });
  return Object.values(parJour);
}

export async function getStatistiques(req, res) {
  try {
    const { periode = '30d' } = req.query;
    const periodeJours = { '7d': 7, '30d': 30, '3m': 90, '6m': 180, '1an': 365 }[periode] || 30;

    const dateDebut = new Date(Date.now() - periodeJours * 24 * 60 * 60 * 1000);
    const datePrecedente = new Date(Date.now() - 2 * periodeJours * 24 * 60 * 60 * 1000);

    const [usersActuel, offresActuel, candidActuel] = await Promise.all([
      supabase
        .from('utilisateurs')
        .select('id', { count: 'exact', head: true })
        .gte('date_creation', dateDebut.toISOString()),
      supabase
        .from('offres_emploi')
        .select('id', { count: 'exact', head: true })
        .gte('date_creation', dateDebut.toISOString()),
      supabase
        .from('candidatures')
        .select('id', { count: 'exact', head: true })
        .gte('date_candidature', dateDebut.toISOString()),
    ]);

    const [usersPrecedent, offresPrecedent, candidPrecedent] = await Promise.all([
      supabase
        .from('utilisateurs')
        .select('id', { count: 'exact', head: true })
        .gte('date_creation', datePrecedente.toISOString())
        .lt('date_creation', dateDebut.toISOString()),
      supabase
        .from('offres_emploi')
        .select('id', { count: 'exact', head: true })
        .gte('date_creation', datePrecedente.toISOString())
        .lt('date_creation', dateDebut.toISOString()),
      supabase
        .from('candidatures')
        .select('id', { count: 'exact', head: true })
        .gte('date_candidature', datePrecedente.toISOString())
        .lt('date_candidature', dateDebut.toISOString()),
    ]);

    const nbUsersActuel = usersActuel.count ?? 0;
    const nbUsersPrecedent = usersPrecedent.count ?? 0;
    const nbOffresActuel = offresActuel.count ?? 0;
    const nbOffresPrecedent = offresPrecedent.count ?? 0;
    const nbCandidActuel = candidActuel.count ?? 0;
    const nbCandidPrecedent = candidPrecedent.count ?? 0;

    const evolution_par_jour = await evolutionParJour(periodeJours);

    const { data: distribVilles } = await supabase
      .from('offres_emploi')
      .select('localisation')
      .eq('statut', 'active');
    const villesCount = {};
    (distribVilles || []).forEach((o) => {
      const v = o.localisation || 'Non précisé';
      villesCount[v] = (villesCount[v] || 0) + 1;
    });

    const { data: distribSecteurs } = await supabase.from('offres_emploi').select('domaine');
    const secteursCount = {};
    (distribSecteurs || []).forEach((o) => {
      const s = o.domaine || 'Autre';
      secteursCount[s] = (secteursCount[s] || 0) + 1;
    });

    const legacy = await legacyStatsPayload();

    return res.json({
      success: true,
      ...legacy,
      data: {
        periode,
        kpis: {
          nouveaux_utilisateurs: {
            valeur: nbUsersActuel,
            tendance: tendance(nbUsersActuel, nbUsersPrecedent),
          },
          nouvelles_offres: {
            valeur: nbOffresActuel,
            tendance: tendance(nbOffresActuel, nbOffresPrecedent),
          },
          nouvelles_candidatures: {
            valeur: nbCandidActuel,
            tendance: tendance(nbCandidActuel, nbCandidPrecedent),
          },
        },
        evolution_par_jour,
        distribution_villes: villesCount,
        distribution_secteurs: secteursCount,
      },
    });
  } catch (err) {
    console.error('[getStatistiques]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function getStatistiquesHistorique(req, res) {
  try {
    const { periode = '30d' } = req.query;
    const periodeJours = { '7d': 7, '30d': 30, '3m': 90 }[periode] || 30;
    const evolution_par_jour = await evolutionParJour(periodeJours);
    return res.json({ success: true, data: { periode, evolution_par_jour } });
  } catch (err) {
    console.error('[getStatistiquesHistorique]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function exportStatistiques(req, res) {
  try {
    const { periode = '30d' } = req.query;
    const periodeJours = { '7d': 7, '30d': 30, '3m': 90, '6m': 180, '1an': 365 }[periode] || 30;
    const dateDebut = new Date(Date.now() - periodeJours * 24 * 60 * 60 * 1000).toISOString();

    const legacy = await legacyStatsPayload();

    const [users, offres, candidats] = await Promise.all([
      supabase.from('utilisateurs').select('nom, email, role, date_creation').gte('date_creation', dateDebut),
      supabase.from('offres_emploi').select('titre, localisation, statut, date_creation').gte('date_creation', dateDebut),
      supabase.from('candidatures').select('statut, date_candidature').gte('date_candidature', dateDebut),
    ]);

    if (users.error) throw users.error;
    if (offres.error) throw offres.error;
    if (candidats.error) throw candidats.error;

    const lines = [
      'cle,valeur',
      `nombre_chercheurs,${legacy.nombre_chercheurs}`,
      `nombre_entreprises,${legacy.nombre_entreprises}`,
      `nombre_offres_actives,${legacy.nombre_offres_actives}`,
      `nombre_candidatures,${legacy.nombre_candidatures}`,
      `nombre_cv,${legacy.nombre_cv}`,
      '---',
      'Type,Valeur,Date',
    ];
    (users.data || []).forEach((u) => {
      lines.push(`Utilisateur,${csvEsc(`${u.role} · ${u.nom || u.email}`)},${(u.date_creation || '').split('T')[0]}`);
    });
    (offres.data || []).forEach((o) => {
      lines.push(`Offre,${csvEsc(`${o.statut} · ${o.titre}`)},${(o.date_creation || '').split('T')[0]}`);
    });
    (candidats.data || []).forEach((c) => {
      lines.push(`Candidature,${csvEsc(c.statut)},${(c.date_candidature || '').split('T')[0]}`);
    });

    const csv = lines.join('\n');
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="stats_emploiconnect_${periode}.csv"`,
    );
    return res.send(`\uFEFF${csv}`);
  } catch (err) {
    console.error('[exportStatistiques]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

function csvEsc(v) {
  const s = v == null ? '' : String(v);
  if (/[",\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

export async function getTopEntreprises(req, res) {
  try {
    const { data: offres, error } = await supabase.from('offres_emploi').select(`
        entreprise_id,
        entreprises ( nom_entreprise, logo_url )
      `);
    if (error) throw error;

    const counts = {};
    for (const o of offres || []) {
      const eid = o.entreprise_id;
      if (!eid) continue;
      const ent = o.entreprises;
      const row = Array.isArray(ent) ? ent[0] : ent;
      const nom = row?.nom_entreprise || 'Inconnu';
      if (!counts[eid]) {
        counts[eid] = { id: eid, nom, logo: row?.logo_url ?? null, nb: 0 };
      }
      counts[eid].nb += 1;
    }

    const top = Object.values(counts)
      .sort((a, b) => b.nb - a.nb)
      .slice(0, 10);

    return res.json({ success: true, data: top });
  } catch (err) {
    console.error('[getTopEntreprises]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function getActivite(req, res) {
  try {
    const { page = 1, limite = 20, action, type_objet } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.min(100, Math.max(1, parseInt(limite, 10) || 20));
    const offset = (p - 1) * l;

    let query = supabase
      .from('activite_admin')
      .select(
        `
        id, action, type_objet, objet_id, details,
        ip_address, date_action, admin_id
      `,
        { count: 'exact' },
      )
      .order('date_action', { ascending: false })
      .range(offset, offset + l - 1);

    if (action) query = query.eq('action', action);
    if (type_objet) query = query.eq('type_objet', type_objet);

    const { data, count, error } = await query;
    if (error) throw error;

    let activites = avecLibelleAction(data || []);
    const adminIds = [...new Set(activites.map((a) => a.admin_id).filter(Boolean))];
    if (adminIds.length) {
      const { data: admins } = await supabase
        .from('utilisateurs')
        .select('id, nom, email, photo_url')
        .in('id', adminIds);
      const map = Object.fromEntries((admins || []).map((u) => [u.id, u]));
      activites = activites.map((a) => ({ ...a, admin: map[a.admin_id] || null }));
    }

    return res.json({
      success: true,
      data: {
        activites,
        pagination: {
          total: count || 0,
          page: p,
          limite: l,
          total_pages: Math.ceil((count || 0) / l) || 0,
        },
      },
    });
  } catch (err) {
    console.error('[getActivite]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
