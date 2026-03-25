/**
 * Point d'entrée - API EmploiConnect
 * Auth custom (JWT + bcrypt), Supabase en service_role
 */
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import routes from './routes/index.js';
import { logError, logInfo } from './utils/logger.js';

const PORT = process.env.PORT || 3000;
const CORS_ORIGIN = process.env.CORS_ORIGIN || 'http://localhost:3000,http://localhost:8080';

/**
 * CORS : en dev, Flutter Web utilise un port aléatoire (ex. localhost:58294).
 * On autorise tout http://localhost:* et http://127.0.0.1:* + les origines listées dans CORS_ORIGIN.
 * En production, définissez CORS_STRICT=1 et listez uniquement les domaines dans CORS_ORIGIN.
 */
function corsOriginCallback(origin, callback) {
  if (!origin) {
    return callback(null, true);
  }
  const strict = process.env.CORS_STRICT === '1' || process.env.CORS_STRICT === 'true';
  if (!strict) {
    if (/^https?:\/\/localhost(:\d+)?$/i.test(origin)) {
      return callback(null, true);
    }
    if (/^https?:\/\/127\.0\.0\.1(:\d+)?$/i.test(origin)) {
      return callback(null, true);
    }
  }
  const allowed = CORS_ORIGIN.split(',').map((s) => s.trim()).filter(Boolean);
  if (allowed.includes(origin)) {
    return callback(null, true);
  }
  return callback(new Error(`CORS: origine non autorisée: ${origin}`));
}

// Sécurité : exiger un secret JWT défini
if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET doit être défini dans .env pour démarrer le serveur en sécurité');
}

const app = express();

// Sécurité : en-têtes HTTP de base
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

app.use(cors({
  origin: corsOriginCallback,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Limitation de débit globale (rate limiting)
const windowMs = Number(process.env.RATE_LIMIT_WINDOW_MS || 15 * 60 * 1000); // 15 minutes
const maxRequests = Number(process.env.RATE_LIMIT_MAX || 300); // 300 requêtes / fenêtre / IP
const limiter = rateLimit({
  windowMs,
  max: maxRequests,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Trop de requêtes depuis cette adresse IP, veuillez réessayer plus tard.' },
});
app.use('/api', limiter);

// Parsing JSON limité pour éviter les payloads géants
app.use(express.json({ limit: '1mb' }));

app.use('/api', routes);

// 404
app.use((req, res) => {
  res.status(404).json({ message: 'Route non trouvée' });
});

// Erreurs
app.use((err, req, res, next) => {
  if (err.message && err.message.includes('Format accepté')) {
    return res.status(400).json({ message: err.message });
  }
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ message: 'Fichier trop volumineux (max 5 Mo)' });
  }
  logError(`Erreur non gérée sur ${req.method} ${req.originalUrl}`, err);
  res.status(500).json({ message: 'Erreur serveur' });
});

app.listen(PORT, () => {
  logInfo(`EmploiConnect API écoute sur http://localhost:${PORT}`);
  logInfo('Routes principales disponibles :');
  logInfo('  - Health:        GET /api/health');
  logInfo('  - Auth:          POST /api/auth/register, POST /api/auth/login');
  logInfo('  - Profil:        GET/PATCH /api/users/me (Bearer)');
  logInfo('  - Offres:        GET/POST /api/offres, GET/PATCH/DELETE /api/offres/:id');
  logInfo('  - Candidatures:  GET/POST /api/candidatures, GET/PATCH /api/candidatures/:id');
  logInfo('  - CV:            POST /api/cv/upload, GET /api/cv/me, GET /api/cv/download-url');
  logInfo('  - Signalements:  POST /api/signalements');
  logInfo('  - Admin:         GET/PATCH /api/admin/utilisateurs, GET /api/admin/statistiques, GET/PATCH /api/admin/signalements');
});
