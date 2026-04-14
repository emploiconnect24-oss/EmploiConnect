/**
 * Routes /api/admin/* — authentification JWT + rôle admin + profil admin.
 */
import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import { requireAdmin } from '../../middleware/adminAuth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { supabase } from '../../config/supabase.js';

import * as dashboard from '../../controllers/admin/dashboard.controller.js';
import * as users from '../../controllers/admin/users.controller.js';
import * as offres from '../../controllers/admin/offres.controller.js';
import * as entreprises from '../../controllers/admin/entreprises.controller.js';
import * as candidatures from '../../controllers/admin/candidatures.controller.js';
import * as signalements from '../../controllers/admin/signalements.controller.js';
import * as notifications from '../../controllers/admin/notifications.controller.js';
import * as parametres from '../../controllers/admin/parametres.controller.js';
import * as bannieres from '../../controllers/admin/bannieres.controller.js';
import * as profil from '../../controllers/admin/profil.controller.js';
import * as search from '../../controllers/admin/search.controller.js';
import * as temoignages from '../../controllers/admin/temoignages.controller.js';
import ressourcesParcoursRoutes from './ressourcesParcours.routes.js';
import { uploadAdminPhoto } from '../../middleware/uploadAdminPhoto.js';
import { auditLog } from '../../middleware/auditLog.js';
import * as testIaApi from '../../controllers/admin/testIaApi.controller.js';
import * as aproposAdmin from '../../controllers/admin/aproposAdmin.controller.js';
import * as newsletterAdmin from '../../controllers/admin/newsletterAdmin.controller.js';
import * as infra from '../../controllers/admin/infra.controller.js';
import * as twoFactorAdmin from '../../controllers/admin/twoFactorAdmin.controller.js';
import { testerConfiguration, invaliderCache } from '../../services/googleOauth.service.js';
import { genererImageGemini } from '../../services/illustrationIa.service.js';
import { requirePermission, requireSuperAdmin } from '../../middleware/adminPermissions.js';
import sousAdminsRoutes from './sousAdmins.routes.js';

const router = Router();

function requireParcoursAccess(req, res, next) {
  if (req.method === 'GET') {
    return requirePermission('parcours', 'peut_voir')(req, res, next);
  }
  if (req.method === 'DELETE') {
    return requirePermission('parcours', 'peut_supprimer')(req, res, next);
  }
  return requirePermission('parcours', 'peut_modifier')(req, res, next);
}

router.use(authenticate);
router.use(requireAdmin);
router.use(attachProfileIds);

router.get('/2fa/status', twoFactorAdmin.get2faStatus);
router.get('/2fa/setup', twoFactorAdmin.get2faSetup);
router.post('/2fa/activer', twoFactorAdmin.post2faActiver);
router.post('/2fa/desactiver', twoFactorAdmin.post2faDesactiver);

router.use('/sous-admins', sousAdminsRoutes);

router.get('/dashboard', requirePermission('dashboard', 'peut_voir'), dashboard.getDashboard);

router.get('/recherche', requirePermission('recherche', 'peut_voir'), search.rechercheGlobale);

router.get(
  '/statistiques/export',
  requirePermission('statistiques', 'peut_modifier'),
  dashboard.exportStatistiques,
);
router.get(
  '/statistiques/top-entreprises',
  requirePermission('statistiques', 'peut_voir'),
  dashboard.getTopEntreprises,
);
router.get(
  '/statistiques/historique',
  requirePermission('statistiques', 'peut_voir'),
  dashboard.getStatistiquesHistorique,
);
router.get('/statistiques', requirePermission('statistiques', 'peut_voir'), dashboard.getStatistiques);

router.get('/activite', requirePermission('dashboard', 'peut_voir'), dashboard.getActivite);

router.get('/utilisateurs/stats', requirePermission('utilisateurs', 'peut_voir'), users.getUtilisateursStats);
router.get(
  '/utilisateurs/export/csv',
  requirePermission('utilisateurs', 'peut_voir'),
  users.exportUtilisateursCsv,
);
router.get('/utilisateurs', requirePermission('utilisateurs', 'peut_voir'), users.getUtilisateurs);
router.get('/utilisateurs/:id', requirePermission('utilisateurs', 'peut_voir'), users.getUtilisateur);
router.patch(
  '/utilisateurs/:id',
  requirePermission('utilisateurs', 'peut_modifier'),
  auditLog('MODIFICATION_UTILISATEUR', 'utilisateur'),
  users.updateUtilisateur,
);
router.delete(
  '/utilisateurs/:id',
  requirePermission('utilisateurs', 'peut_supprimer'),
  auditLog('SUPPRESSION_UTILISATEUR', 'utilisateur'),
  users.deleteUtilisateur,
);

router.get('/offres/export/csv', requirePermission('offres', 'peut_voir'), offres.exportOffresCsv);
router.get('/offres', requirePermission('offres', 'peut_voir'), offres.getOffres);
router.get('/offres/:id', requirePermission('offres', 'peut_voir'), offres.getOffreById);
router.patch(
  '/offres/:id',
  requirePermission('offres', 'peut_modifier'),
  auditLog('MODERATION_OFFRE', 'offre'),
  offres.updateOffre,
);
router.delete(
  '/offres/:id',
  requirePermission('offres', 'peut_supprimer'),
  auditLog('SUPPRESSION_OFFRE', 'offre'),
  offres.deleteOffre,
);

router.get('/entreprises', requirePermission('entreprises', 'peut_voir'), entreprises.getEntreprises);
router.get('/entreprises/:id', requirePermission('entreprises', 'peut_voir'), entreprises.getEntrepriseDetail);
router.patch(
  '/entreprises/:id',
  requirePermission('entreprises', 'peut_modifier'),
  auditLog('MODERATION_ENTREPRISE', 'entreprise'),
  entreprises.updateEntreprise,
);

router.get(
  '/candidatures/export',
  requirePermission('candidatures', 'peut_voir'),
  candidatures.exportCandidatures,
);
router.get('/candidatures/:id', requirePermission('candidatures', 'peut_voir'), candidatures.getCandidatureById);
router.get('/candidatures', requirePermission('candidatures', 'peut_voir'), candidatures.getCandidatures);

router.get('/signalements', requirePermission('signalements', 'peut_voir'), signalements.getSignalements);
router.get('/signalements/:id', requirePermission('signalements', 'peut_voir'), signalements.getSignalementById);
router.patch(
  '/signalements/:id',
  requirePermission('signalements', 'peut_modifier'),
  auditLog('TRAITEMENT_SIGNALEMENT', 'signalement'),
  signalements.updateSignalement,
);

router.get('/temoignages', requirePermission('temoignages', 'peut_voir'), temoignages.getTemoignages);
router.patch(
  '/temoignages/:id/valider',
  requirePermission('temoignages', 'peut_modifier'),
  auditLog('MODERATION_TEMOIGNAGE', 'temoignage'),
  (req, _res, next) => {
    req.body = { ...(req.body || {}), action: 'approuver' };
    next();
  },
  temoignages.patchTemoignage,
);
router.patch(
  '/temoignages/:id/refuser',
  requirePermission('temoignages', 'peut_modifier'),
  auditLog('MODERATION_TEMOIGNAGE', 'temoignage'),
  (req, _res, next) => {
    req.body = { ...(req.body || {}), action: 'refuser' };
    next();
  },
  temoignages.patchTemoignage,
);
router.patch(
  '/temoignages/:id',
  requirePermission('temoignages', 'peut_modifier'),
  auditLog('MODERATION_TEMOIGNAGE', 'temoignage'),
  temoignages.patchTemoignage,
);
router.delete(
  '/temoignages/:id',
  requirePermission('temoignages', 'peut_supprimer'),
  auditLog('SUPPRESSION_TEMOIGNAGE', 'temoignage'),
  temoignages.deleteTemoignage,
);

router.use('/ressources', requireParcoursAccess, ressourcesParcoursRoutes);

router.post(
  '/notifications',
  requirePermission('messages', 'peut_modifier'),
  auditLog('ENVOI_NOTIFICATION', 'notification'),
  notifications.envoyerNotification,
);
router.get('/notifications', requirePermission('messages', 'peut_voir'), notifications.getNotifications);

router.post(
  '/parametres/upload-logo',
  requireSuperAdmin,
  parametres.uploadLogoMulter.single('logo'),
  auditLog('UPLOAD_LOGO_PLATEFORME', 'parametres'),
  parametres.uploadLogo,
);
router.post('/parametres/tester-ia', requireSuperAdmin, parametres.testerConnexionIA);
router.post('/parametres/test-ia-apropos', requireSuperAdmin, parametres.testIaApropos);
router.post('/test-ia', requireSuperAdmin, testIaApi.postTestIa);
router.post('/test-dalle', requireSuperAdmin, testIaApi.postTestDalle);
router.post('/parametres/tester-smtp', requireSuperAdmin, parametres.testerSMTP);
router.post('/tester-email', requireSuperAdmin, parametres.testerSMTP);
router.post(
  '/parametres/vider-cache',
  requireSuperAdmin,
  auditLog('VIDER_CACHE_PARAMETRES', 'parametres'),
  parametres.viderCache,
);

router.get('/parametres', requireSuperAdmin, parametres.getParametres);
router.get('/parametres/:cle', requireSuperAdmin, parametres.getParametreByCle);
router.put('/parametres', requireSuperAdmin, auditLog('MODIFIER_PARAMETRES', 'parametres'), parametres.updateParametres);

router.get('/infra/test', requireSuperAdmin, infra.getInfraTest);

router.get('/oauth/config', requireSuperAdmin, async (_req, res) => {
  try {
    const { data, error } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'google_client_id',
        'google_client_secret',
        'google_oauth_actif',
        'google_redirect_uri',
        'google_roles_defaut',
        'google_domaines_autorises',
        'google_projet_id',
        'app_url_prod',
      ]);
    if (error) throw error;
    const c = {};
    (data || []).forEach((p) => { c[p.cle] = p.valeur; });
    const publicApi = String(c.app_url_prod || process.env.PUBLIC_API_URL || 'http://localhost:3000').replace(/\/$/, '');
    return res.json({
      success: true,
      data: {
        ...c,
        google_client_secret_configure: String(c.google_client_secret || '').length > 0,
        redirect_uri_auto: `${publicApi}/api/auth/google/callback`,
      },
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

router.post('/oauth/test', requireSuperAdmin, async (_req, res) => {
  try {
    invaliderCache();
    const result = await testerConfiguration();
    return res.json(result);
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

router.post('/oauth/sauvegarder', requireSuperAdmin, async (req, res) => {
  try {
    const champs = [
      'google_client_id',
      'google_client_secret',
      'google_oauth_actif',
      'google_redirect_uri',
      'google_roles_defaut',
      'google_domaines_autorises',
      'google_projet_id',
      'app_url_prod',
    ];
    for (const cle of champs) {
      if (req.body?.[cle] !== undefined && req.body[cle] !== '••••••••' && req.body[cle] !== '********') {
        const valeur = String(req.body[cle]);
        // eslint-disable-next-line no-await-in-loop
        const categorie = cle === 'app_url_prod' ? 'general' : 'auth';
        await supabase.from('parametres_plateforme').upsert(
          {
            cle,
            valeur,
            type_valeur: cle === 'google_oauth_actif' ? 'boolean' : 'string',
            description: '',
            categorie,
            modifiable_admin: true,
            modifie_par: req.user?.id,
            date_modification: new Date().toISOString(),
          },
          { onConflict: 'cle' },
        );
      }
    }
    if (req.body?.app_url_prod) {
      process.env.PUBLIC_API_URL = String(req.body.app_url_prod).trim().replace(/\/$/, '');
    }
    invaliderCache();
    return res.json({ success: true, message: 'Configuration sauvegardee' });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

router.post('/test-gemini-image', requireSuperAdmin, async (_req, res) => {
  try {
    const { data: rows } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', ['gemini_api_key', 'gemini_modele']);
    const params = {};
    (rows || []).forEach((r) => { params[r.cle] = r.valeur; });
    const geminiKey = String(params.gemini_api_key || process.env.GEMINI_API_KEY || '').trim();
    const geminiModele = String(params.gemini_modele || 'auto').trim() || 'auto';
    if (!geminiKey) {
      return res.json({
        success: false,
        message: 'Cle Gemini non configuree',
      });
    }
    const result = await genererImageGemini(
      'Professional African woman smiling in modern office, blue background, no text, HD quality.',
      geminiKey,
      geminiModele,
    );
    return res.json({
      success: true,
      message: 'Gemini Image operationnel !',
      image_size: String(result.base64 || '').length,
      mime_type: result.mimeType,
    });
  } catch (err) {
    return res.json({
      success: false,
      message: err.message || 'Erreur test Gemini',
    });
  }
});

router.put(
  '/apropos/:id',
  requirePermission('apropos', 'peut_modifier'),
  auditLog('MODIFIER_PAGE_A_PROPOS', 'page_a_propos'),
  aproposAdmin.putAproposSection,
);
router.get(
  '/newsletter',
  requirePermission('newsletter', 'peut_voir'),
  newsletterAdmin.getNewsletterAbonnes,
);
router.post(
  '/newsletter/envoyer',
  requirePermission('newsletter_envoi', 'peut_modifier'),
  auditLog('ENVOI_NEWSLETTER', 'newsletter'),
  newsletterAdmin.postNewsletterEnvoyer,
);
router.post(
  '/newsletter/ia/generer',
  requirePermission('newsletter', 'peut_modifier'),
  auditLog('ENVOI_NEWSLETTER_IA', 'newsletter'),
  newsletterAdmin.postNewsletterIaGenerer,
);

router.get('/bannieres', requirePermission('bannieres', 'peut_voir'), bannieres.listBannieresAdmin);
router.post(
  '/bannieres/upload-image',
  requirePermission('bannieres', 'peut_modifier'),
  bannieres.uploadBanniere.single('image'),
  auditLog('UPLOAD_IMAGE_BANNIERE', 'banniere'),
  bannieres.uploadImageBanniere,
);
router.post(
  '/bannieres',
  requirePermission('bannieres', 'peut_modifier'),
  bannieres.uploadBanniere.single('image'),
  auditLog('CREATION_BANNIERE', 'banniere'),
  bannieres.createBanniere,
);
router.patch(
  '/bannieres/reordonner/ordre',
  requirePermission('bannieres', 'peut_modifier'),
  auditLog('REORDONNEMENT_BANNIERES', 'banniere'),
  bannieres.reorderBannieres,
);
router.patch(
  '/bannieres/:id',
  requirePermission('bannieres', 'peut_modifier'),
  auditLog('MODIFICATION_BANNIERE', 'banniere'),
  bannieres.updateBanniere,
);
router.delete(
  '/bannieres/:id',
  requirePermission('bannieres', 'peut_supprimer'),
  auditLog('SUPPRESSION_BANNIERE', 'banniere'),
  bannieres.deleteBanniere,
);

router.get('/profil', profil.getProfilAdmin);
router.patch('/profil', auditLog('MODIFICATION_PROFIL_ADMIN', 'profil'), profil.updateProfilAdmin);
router.post('/profil/email/demande', profil.postDemandeChangementEmail);
router.post(
  '/profil/email/confirmer',
  auditLog('VALIDATION_CHANGEMENT_EMAIL_ADMIN', 'profil'),
  profil.postConfirmerChangementEmail,
);
router.post(
  '/profil/photo',
  uploadAdminPhoto.single('photo'),
  auditLog('MAJ_PHOTO_PROFIL_ADMIN', 'profil'),
  profil.uploadPhotoAdmin,
);

export default router;
