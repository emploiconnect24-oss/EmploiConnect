/**
 * Routes /api/admin/* — authentification JWT + rôle admin + profil admin.
 */
import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import { requireAdmin } from '../../middleware/adminAuth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';

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

const router = Router();

router.use(authenticate);
router.use(requireAdmin);
router.use(attachProfileIds);

router.get('/dashboard', dashboard.getDashboard);

router.get('/recherche', search.rechercheGlobale);

router.get('/statistiques/export', dashboard.exportStatistiques);
router.get('/statistiques/top-entreprises', dashboard.getTopEntreprises);
router.get('/statistiques/historique', dashboard.getStatistiquesHistorique);
router.get('/statistiques', dashboard.getStatistiques);

router.get('/activite', dashboard.getActivite);

router.get('/utilisateurs/stats', users.getUtilisateursStats);
router.get('/utilisateurs/export/csv', users.exportUtilisateursCsv);
router.get('/utilisateurs', users.getUtilisateurs);
router.get('/utilisateurs/:id', users.getUtilisateur);
router.patch(
  '/utilisateurs/:id',
  auditLog('MODIFICATION_UTILISATEUR', 'utilisateur'),
  users.updateUtilisateur,
);
router.delete(
  '/utilisateurs/:id',
  auditLog('SUPPRESSION_UTILISATEUR', 'utilisateur'),
  users.deleteUtilisateur,
);

router.get('/offres/export/csv', offres.exportOffresCsv);
router.get('/offres', offres.getOffres);
router.get('/offres/:id', offres.getOffreById);
router.patch('/offres/:id', auditLog('MODERATION_OFFRE', 'offre'), offres.updateOffre);
router.delete('/offres/:id', auditLog('SUPPRESSION_OFFRE', 'offre'), offres.deleteOffre);

router.get('/entreprises', entreprises.getEntreprises);
router.get('/entreprises/:id', entreprises.getEntrepriseDetail);
router.patch(
  '/entreprises/:id',
  auditLog('MODERATION_ENTREPRISE', 'entreprise'),
  entreprises.updateEntreprise,
);

router.get('/candidatures/export', candidatures.exportCandidatures);
router.get('/candidatures/:id', candidatures.getCandidatureById);
router.get('/candidatures', candidatures.getCandidatures);

router.get('/signalements', signalements.getSignalements);
router.get('/signalements/:id', signalements.getSignalementById);
router.patch(
  '/signalements/:id',
  auditLog('TRAITEMENT_SIGNALEMENT', 'signalement'),
  signalements.updateSignalement,
);

router.get('/temoignages', temoignages.getTemoignages);
router.patch(
  '/temoignages/:id/valider',
  auditLog('MODERATION_TEMOIGNAGE', 'temoignage'),
  (req, _res, next) => {
    req.body = { ...(req.body || {}), action: 'approuver' };
    next();
  },
  temoignages.patchTemoignage,
);
router.patch(
  '/temoignages/:id/refuser',
  auditLog('MODERATION_TEMOIGNAGE', 'temoignage'),
  (req, _res, next) => {
    req.body = { ...(req.body || {}), action: 'refuser' };
    next();
  },
  temoignages.patchTemoignage,
);
router.patch(
  '/temoignages/:id',
  auditLog('MODERATION_TEMOIGNAGE', 'temoignage'),
  temoignages.patchTemoignage,
);
router.delete(
  '/temoignages/:id',
  auditLog('SUPPRESSION_TEMOIGNAGE', 'temoignage'),
  temoignages.deleteTemoignage,
);

router.use('/ressources', ressourcesParcoursRoutes);

router.post(
  '/notifications',
  auditLog('ENVOI_NOTIFICATION', 'notification'),
  notifications.envoyerNotification,
);
router.get('/notifications', notifications.getNotifications);

router.post(
  '/parametres/upload-logo',
  parametres.uploadLogoMulter.single('logo'),
  auditLog('UPLOAD_LOGO_PLATEFORME', 'parametres'),
  parametres.uploadLogo,
);
router.post('/parametres/tester-ia', parametres.testerConnexionIA);
router.post('/parametres/test-ia-apropos', parametres.testIaApropos);
router.post('/test-ia', testIaApi.postTestIa);
router.post('/test-dalle', testIaApi.postTestDalle);
router.post('/parametres/tester-smtp', parametres.testerSMTP);
router.post('/tester-email', parametres.testerSMTP);
router.post(
  '/parametres/vider-cache',
  auditLog('VIDER_CACHE_PARAMETRES', 'parametres'),
  parametres.viderCache,
);

router.get('/parametres', parametres.getParametres);
router.get('/parametres/:cle', parametres.getParametreByCle);
router.put('/parametres', auditLog('MODIFIER_PARAMETRES', 'parametres'), parametres.updateParametres);

router.get('/bannieres', bannieres.listBannieresAdmin);
router.post(
  '/bannieres/upload-image',
  bannieres.uploadBanniere.single('image'),
  auditLog('UPLOAD_IMAGE_BANNIERE', 'banniere'),
  bannieres.uploadImageBanniere,
);
router.post(
  '/bannieres',
  bannieres.uploadBanniere.single('image'),
  auditLog('CREATION_BANNIERE', 'banniere'),
  bannieres.createBanniere,
);
router.patch(
  '/bannieres/reordonner/ordre',
  auditLog('REORDONNEMENT_BANNIERES', 'banniere'),
  bannieres.reorderBannieres,
);
router.patch('/bannieres/:id', auditLog('MODIFICATION_BANNIERE', 'banniere'), bannieres.updateBanniere);
router.delete('/bannieres/:id', auditLog('SUPPRESSION_BANNIERE', 'banniere'), bannieres.deleteBanniere);

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
