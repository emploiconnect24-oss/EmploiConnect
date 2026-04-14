import bcrypt from 'bcryptjs';
import { supabase } from '../../config/supabase.js';
import { sendAccountValidatedEmail, sendAccountRejectedEmail } from '../../services/mail.service.js';

export async function getUtilisateursStats(req, res) {
  try {
    const { data: rows } = await supabase.from('utilisateurs').select('role, est_actif, est_valide');
    const list = rows || [];
    return res.json({
      success: true,
      data: {
        total: list.length,
        chercheurs: list.filter((u) => u.role === 'chercheur').length,
        entreprises: list.filter((u) => u.role === 'entreprise').length,
        admins: list.filter((u) => u.role === 'admin').length,
        en_attente: list.filter((u) => !u.est_valide).length,
        bloques: list.filter((u) => !u.est_actif && u.est_valide).length,
      },
    });
  } catch (err) {
    console.error('[getUtilisateursStats]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function getUtilisateurs(req, res) {
  try {
    const {
      page = 1,
      limite = 20,
      role,
      statut,
      recherche,
      ville,
      ordre = 'date_creation',
      direction = 'desc',
      offset: offsetQ,
      limit: limitLegacy,
    } = req.query;

    const lim = parseInt(limitLegacy || limite, 10) || 20;
    const off = offsetQ != null ? parseInt(offsetQ, 10) : (parseInt(page, 10) - 1) * lim;

    let query = supabase
      .from('utilisateurs')
      .select(
        `
        id, nom, email, role, telephone, adresse,
        photo_url, est_actif, est_valide, raison_blocage,
        derniere_connexion, date_creation,
        chercheurs_emploi ( id, disponibilite, niveau_etude ),
        entreprises ( id, nom_entreprise, secteur_activite, logo_url, banniere_url ),
        administrateurs (
          est_super_admin,
          admin_roles ( nom, couleur, icone )
        )
      `,
        { count: 'exact' },
      )
      .order(ordre, { ascending: direction === 'asc' })
      .range(off, off + lim - 1);

    if (role) query = query.eq('role', role);
    if (statut === 'actif') query = query.eq('est_actif', true).eq('est_valide', true);
    if (statut === 'en_attente') query = query.eq('est_valide', false);
    if (statut === 'bloque') query = query.eq('est_actif', false).eq('est_valide', true);
    if (recherche) {
      const q = String(recherche).trim();
      query = query.or(`nom.ilike.%${q}%,email.ilike.%${q}%`);
    }
    if (ville) query = query.ilike('adresse', `%${ville}%`);

    const { data, count, error } = await query;
    if (error) throw error;

    const utilisateurs = (data || []).map((u) => {
      const rawAdm = u.administrateurs;
      const adm = Array.isArray(rawAdm) ? rawAdm[0] : rawAdm;
      const rawRole = adm?.admin_roles;
      const roleRow = Array.isArray(rawRole) ? rawRole[0] : rawRole;
      const { administrateurs: _adm, ...rest } = u;
      return {
        ...rest,
        ville: u.adresse ?? u.ville ?? null,
        created_at: u.date_creation ?? u.created_at,
        est_super_admin: Boolean(adm?.est_super_admin),
        role_admin: roleRow
          ? {
              nom: roleRow.nom,
              couleur: roleRow.couleur,
              icone: roleRow.icone,
            }
          : null,
      };
    });

    const { data: compteurs } = await supabase.from('utilisateurs').select('role, est_actif, est_valide');
    const stats = {
      total: count || 0,
      chercheurs: compteurs?.filter((u) => u.role === 'chercheur').length || 0,
      entreprises: compteurs?.filter((u) => u.role === 'entreprise').length || 0,
      en_attente: compteurs?.filter((u) => !u.est_valide).length || 0,
      bloques: compteurs?.filter((u) => !u.est_actif && u.est_valide).length || 0,
    };

    return res.json({
      success: true,
      utilisateurs,
      total: count ?? utilisateurs.length,
      data: {
        utilisateurs,
        stats,
        pagination: {
          total: count || 0,
          page: parseInt(page, 10),
          limite: lim,
          total_pages: Math.ceil((count || 0) / lim),
        },
      },
    });
  } catch (err) {
    console.error('[getUtilisateurs]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function getUtilisateur(req, res) {
  try {
    const { id } = req.params;

    const { data: user, error } = await supabase
      .from('utilisateurs')
      .select(
        `
        id, nom, email, role, telephone, adresse,
        photo_url, est_actif, est_valide,
        derniere_connexion, date_creation, date_modification,
        raison_blocage, traite_par,
        chercheurs_emploi ( id, disponibilite, niveau_etude, genre, competences, date_naissance ),
        entreprises ( id, nom_entreprise, description, secteur_activite, taille_entreprise, site_web, logo_url, banniere_url, adresse_siege )
      `,
      )
      .eq('id', id)
      .single();

    if (error || !user) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    const chProfil = Array.isArray(user.chercheurs_emploi)
      ? user.chercheurs_emploi[0]
      : user.chercheurs_emploi;
    const entProfil = Array.isArray(user.entreprises) ? user.entreprises[0] : user.entreprises;

    let candidatures = [];
    if (user.role === 'chercheur' && chProfil?.id) {
      const { data: c } = await supabase
        .from('candidatures')
        .select('id, statut, date_candidature, offres_emploi ( titre )')
        .eq('chercheur_id', chProfil.id)
        .order('date_candidature', { ascending: false })
        .limit(10);
      candidatures = c || [];
    }

    let offres = [];
    if (user.role === 'entreprise' && entProfil?.id) {
      const entId = entProfil.id;
      const { data: o } = await supabase
        .from('offres_emploi')
        .select('id, titre, statut, date_publication')
        .eq('entreprise_id', entId)
        .order('date_publication', { ascending: false })
        .limit(10);
      offres = o || [];
    }

    return res.json({
      success: true,
      data: { ...user, candidatures, offres },
    });
  } catch (err) {
    console.error('[getUtilisateur]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function updateUtilisateur(req, res) {
  try {
    const { id } = req.params;
    const { action, raison, est_valide, est_actif, mot_de_passe, ...updates } = req.body;

    const { data: prevUser, error: prevErr } = await supabase
      .from('utilisateurs')
      .select('id, est_valide, email, nom')
      .eq('id', id)
      .single();
    if (prevErr || !prevUser) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    if (action === 'bloquer' && id === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Vous ne pouvez pas bloquer votre propre compte',
      });
    }

    if (!action && (typeof est_valide === 'boolean' || typeof est_actif === 'boolean')) {
      const update = {};
      if (typeof est_valide === 'boolean') update.est_valide = est_valide;
      if (typeof est_actif === 'boolean') update.est_actif = est_actif;
      if (Object.keys(update).length === 0) {
        return res.status(400).json({ message: 'Indiquez est_valide et/ou est_actif' });
      }
      const { data, error } = await supabase
        .from('utilisateurs')
        .update(update)
        .eq('id', id)
        .select('id, nom, email, role, est_actif, est_valide')
        .single();
      if (error) throw error;
      if (data.est_valide && !prevUser.est_valide) {
        void sendAccountValidatedEmail(data);
      }
      return res.json(data);
    }

    if (!action) {
      return res.status(400).json({
        success: false,
        message: 'action requise (valider, activer, bloquer, modifier) ou champs est_valide/est_actif',
      });
    }

    let updateData = {};

    switch (action) {
      case 'valider':
        updateData = { est_valide: true, est_actif: true, traite_par: req.user.id };
        break;
      case 'activer':
        updateData = { est_actif: true, raison_blocage: null, traite_par: req.user.id };
        break;
      case 'bloquer':
        if (!raison) {
          return res.status(400).json({
            success: false,
            message: 'Une raison est requise pour bloquer un compte',
          });
        }
        updateData = { est_actif: false, raison_blocage: raison, traite_par: req.user.id };
        break;
      case 'debloquer':
        updateData = { est_actif: true, raison_blocage: null, traite_par: req.user.id };
        break;
      case 'rejeter':
        updateData = {
          est_valide: false,
          est_actif: false,
          raison_blocage: raison || 'Compte rejeté par l’administrateur',
          traite_par: req.user.id,
        };
        break;
      case 'modifier':
        Object.assign(updateData, updates);
        break;
      default:
        return res.status(400).json({
          success: false,
          message: 'Action invalide. Valeurs: valider, activer, bloquer, debloquer, rejeter, modifier',
        });
    }

    if (mot_de_passe && action === 'modifier') {
      if (String(mot_de_passe).length < 8) {
        return res.status(400).json({ message: 'Le mot de passe doit faire au moins 8 caractères' });
      }
      updateData.mot_de_passe = await bcrypt.hash(mot_de_passe, 10);
    }

    const { data, error } = await supabase
      .from('utilisateurs')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    if (data.est_valide && !prevUser.est_valide) {
      void sendAccountValidatedEmail(data);
    }
    if (action === 'rejeter' && data.email) {
      void sendAccountRejectedEmail(data, data.raison_blocage);
    }

    return res.json({
      success: true,
      message: 'Compte mis à jour',
      data,
    });
  } catch (err) {
    console.error('[updateUtilisateur]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function exportUtilisateursCsv(req, res) {
  try {
    const { data, error } = await supabase
      .from('utilisateurs')
      .select('nom, email, role, telephone, adresse, est_actif, est_valide, date_creation')
      .order('date_creation', { ascending: false });

    if (error) throw error;

    const esc = (v) => {
      const s = v == null ? '' : String(v);
      if (/[",\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
      return s;
    };

    const lines = ['Nom,Email,Rôle,Téléphone,Adresse,Actif,Validé,Date inscription'];
    for (const u of data || []) {
      lines.push(
        [
          esc(u.nom),
          esc(u.email),
          esc(u.role),
          esc(u.telephone),
          esc(u.adresse),
          u.est_actif ? 'Oui' : 'Non',
          u.est_valide ? 'Oui' : 'Non',
          esc((u.date_creation || '').toString().split('T')[0]),
        ].join(','),
      );
    }

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="utilisateurs_emploiconnect.csv"');
    return res.send(`\uFEFF${lines.join('\n')}`);
  } catch (err) {
    console.error('[exportUtilisateursCsv]', err);
    res.status(500).json({ success: false, message: 'Erreur export' });
  }
}

export async function deleteUtilisateur(req, res) {
  try {
    const { id } = req.params;
    if (id === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Vous ne pouvez pas supprimer votre propre compte',
      });
    }

    const { data: user } = await supabase.from('utilisateurs').select('id, nom, role').eq('id', id).single();
    if (!user) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    const { error } = await supabase.from('utilisateurs').delete().eq('id', id);
    if (error) throw error;

    return res.json({
      success: true,
      message: `Compte de ${user.nom} supprimé définitivement`,
    });
  } catch (err) {
    console.error('[deleteUtilisateur]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
