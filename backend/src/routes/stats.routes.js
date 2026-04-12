import { Router } from 'express';
import { getHomepageStats } from '../controllers/public/homepageStats.controller.js';

const router = Router();

router.get('/homepage', getHomepageStats);

export default router;
