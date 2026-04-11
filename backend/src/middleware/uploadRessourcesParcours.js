import multer from 'multer';

export const uploadRessourcesParcours = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
});
