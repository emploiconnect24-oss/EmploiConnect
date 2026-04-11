import { Router } from 'express';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { ROLES } from '../../config/constants.js';
import * as ctrl from '../../controllers/candidat/parcoursCarriere.controller.js';

const router = Router();

router.use(authenticate);
router.use(requireRole(ROLES.CHERCHEUR));

router.get('/ressources-carrieres', ctrl.listRessourcesPubliees);
router.get('/ressources-carrieres/:id', ctrl.getRessourcePubliee);
router.post('/ressources-carrieres/:id/vue', ctrl.marquerVue);

router.post('/simulateur/generer-questions', ctrl.genererQuestionsSimulateur);
router.post('/simulateur/evaluer-reponse', ctrl.evaluerReponseSimulateur);
router.post('/simulateur/sauvegarder', ctrl.sauvegarderSimulation);

router.post('/calculateur-salaire', ctrl.calculateurSalaire);

export default router;
