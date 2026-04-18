/**
 * Agrégation des routes API
 */
import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import authRoutes from './auth.routes.js';
import usersRoutes from './users.js';
import offresRoutes from './offres.js';
import candidaturesRoutes from './candidatures.js';
import cvRoutes from './cv.js';
import signalementsRoutes from './signalements.js';
import notificationsRoutes from './notifications.js';
import adminRoutes from './admin/index.js';
import matchingRoutes from './matching.js';
import recruteurDashboardRoutes from './recruteur/dashboard.js';
import recruteurOffresRoutes from './recruteur/offres.js';
import recruteurCandidaturesRoutes from './recruteur/candidatures.js';
import recruteurProfilRoutes from './recruteur/profil.js';
import recruteurMessagesRoutes from './recruteur/messages.js';
import recruteurNotificationsRoutes from './recruteur/notifications.js';
import recruteurTalentsRoutes from './recruteur/talents.js';
import recruteurStatsRoutes from './recruteur/stats.js';
import candidatDashboardRoutes from './candidat/dashboard.js';
import candidatMessagesRoutes from './candidat/messages.js';
import candidatSavedRoutes from './candidat/sauvegardes.js';
import candidatAlertesRoutes from './candidat/alertes.js';
import candidatCandidaturesRoutes from './candidat/candidatures.js';
import candidatParametresRoutes from './candidat/parametres.js';
import candidatCvCreatorRoutes from './candidat/cvCreator.js';
import candidatProfilRoutes from './candidat/profil.js';
import candidatRecommandationsRoutes from './candidat/recommandations.js';
import candidatParcoursRoutes from './candidat/parcoursCarriere.js';
import candidatSimulationRoutes from './candidat/simulation.routes.js';
import { listBannieresPubliques } from '../controllers/admin/bannieres.controller.js';
import { getFooterConfig, getGeneralConfig } from '../controllers/public/siteConfig.controller.js';
import { getTopEntreprisesPublic } from '../controllers/public/entreprisesPublic.controller.js';
import { getTemoignagesPublic } from '../controllers/public/temoignagesPublic.controller.js';
import { getApropos, getAproposEquipe, postAproposContact } from '../controllers/apropos.controller.js';
import {
  postNewsletterSubscribe,
  getNewsletterUnsubscribe,
} from '../controllers/public/newsletter.controller.js';
import candidatTemoignagesRoutes from './candidat/temoignages.js';
import statsRoutes from './stats.routes.js';
import illustrationRoutes from './illustration.routes.js';

const router = Router();

router.get('/bannieres', listBannieresPubliques);
router.use('/illustration', illustrationRoutes);
router.use('/stats', statsRoutes);
router.get('/config/footer', getFooterConfig);
router.get('/config/general', getGeneralConfig);
router.get('/entreprises/top-public', getTopEntreprisesPublic);
router.get('/temoignages/public', getTemoignagesPublic);
router.get('/temoignages', getTemoignagesPublic);

router.get('/apropos', optionalAuth, getApropos);
router.get('/apropos/equipe', getAproposEquipe);
router.post('/apropos/contact', postAproposContact);
router.post('/newsletter/subscribe', postNewsletterSubscribe);
router.get('/newsletter/unsubscribe', getNewsletterUnsubscribe);

router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/offres', offresRoutes);
router.use('/candidatures', candidaturesRoutes);
router.use('/cv', cvRoutes);
router.use('/signalements', signalementsRoutes);
router.use('/notifications', notificationsRoutes);
router.use('/matching', matchingRoutes);
router.use('/recruteur/dashboard', recruteurDashboardRoutes);
router.use('/recruteur/offres', recruteurOffresRoutes);
router.use('/recruteur/candidatures', recruteurCandidaturesRoutes);
router.use('/recruteur/profil', recruteurProfilRoutes);
router.use('/recruteur/messages', recruteurMessagesRoutes);
router.use('/messages', recruteurMessagesRoutes); // alias compat
router.use('/recruteur/notifications', recruteurNotificationsRoutes);
router.use('/recruteur/talents', recruteurTalentsRoutes);
router.use('/recruteur/stats', recruteurStatsRoutes);
router.use('/candidat/dashboard', candidatDashboardRoutes);
router.use('/candidat/messages', candidatMessagesRoutes);
router.use('/candidat/sauvegardes', candidatSavedRoutes);
router.use('/candidat/alertes', candidatAlertesRoutes);
router.use('/candidat/candidatures', candidatCandidaturesRoutes);
router.use('/candidat/temoignages', candidatTemoignagesRoutes);
router.use('/temoignages', candidatTemoignagesRoutes);
router.use('/candidat/parametres', candidatParametresRoutes);
router.use('/candidat/cv', candidatCvCreatorRoutes);
router.use('/candidat', candidatProfilRoutes);
router.use('/candidat', candidatRecommandationsRoutes);
router.use('/candidat', candidatParcoursRoutes);
router.use('/candidat/simulation', candidatSimulationRoutes);
router.use('/admin', adminRoutes);

// Santé de l'API (sans auth)
router.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'EmploiConnect API', timestamp: new Date().toISOString() });
});

export default router;
