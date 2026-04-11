import { Router } from 'express';
import { auditLog } from '../../middleware/auditLog.js';
import { uploadRessourcesParcours } from '../../middleware/uploadRessourcesParcours.js';
import * as ctrl from '../../controllers/admin/ressourcesParcours.controller.js';

const router = Router();

router.get('/', ctrl.listRessources);
router.get('/:id', ctrl.getRessourceById);
router.post(
  '/',
  uploadRessourcesParcours.fields([
    { name: 'fichier', maxCount: 1 },
    { name: 'couverture', maxCount: 1 },
  ]),
  auditLog('CREATION_RESSOURCE_PARCOURS', 'ressource'),
  ctrl.createRessource,
);
router.patch('/:id/publier', auditLog('PUBLICATION_RESSOURCE_PARCOURS', 'ressource'), ctrl.patchPublier);
router.patch('/:id', auditLog('MODIFICATION_RESSOURCE_PARCOURS', 'ressource'), ctrl.patchRessource);
router.delete('/:id', auditLog('SUPPRESSION_RESSOURCE_PARCOURS', 'ressource'), ctrl.deleteRessource);

export default router;
