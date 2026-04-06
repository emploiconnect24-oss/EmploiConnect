/**
 * Multer dédié à la photo admin — acceptation large (validation après coup si besoin).
 */
import multer from 'multer';

export const uploadAdminPhoto = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    console.log('[Upload] Fichier reçu:', file.originalname, file.mimetype, file.size);
    cb(null, true);
  },
});
