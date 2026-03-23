/**
 * Agrégation des routes API
 */
import { Router } from 'express';
import authRoutes from './auth.js';
import usersRoutes from './users.js';
import offresRoutes from './offres.js';
import candidaturesRoutes from './candidatures.js';
import cvRoutes from './cv.js';
import signalementsRoutes from './signalements.js';
import adminRoutes from './admin.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/offres', offresRoutes);
router.use('/candidatures', candidaturesRoutes);
router.use('/cv', cvRoutes);
router.use('/signalements', signalementsRoutes);
router.use('/admin', adminRoutes);

// Santé de l'API (sans auth)
router.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'EmploiConnect API', timestamp: new Date().toISOString() });
});

export default router;
