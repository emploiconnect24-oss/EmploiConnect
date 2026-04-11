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
import { checkBlockedIP } from './middleware/security.middleware.js';
import { checkMaintenance } from './middleware/maintenance.middleware.js';
import { supabase } from './config/supabase.js';
import { getRapidApiKeys } from './config/rapidApi.js';
import { startScheduledJobs } from './services/scheduledJobs.service.js';
import { closeRedisClient } from './config/redis.js';

const PORT = process.env.PORT || 3000;

['SIGINT', 'SIGTERM'].forEach((sig) => {
  process.on(sig, () => {
    void closeRedisClient();
  });
});
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

// Si vous utilisez un proxy (Cloudflare/Nginx), activer TRUST_PROXY=1 pour de vraies IPs.
if (process.env.TRUST_PROXY === '1' || process.env.TRUST_PROXY === 'true') {
  app.set('trust proxy', true);
}

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

// Sécurité : bloquer les IPs configurées (si la liste est vide, ne fait rien)
app.use('/api', checkBlockedIP);

// Limitation de débit globale (rate limiting)
const windowMs = Number(process.env.RATE_LIMIT_WINDOW_MS || 15 * 60 * 1000); // 15 minutes
// Dev / SPA : augmenter via RATE_LIMIT_MAX si la messagerie ou le polling déclenche 429.
const maxRequests = Number(process.env.RATE_LIMIT_MAX || 2000);
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

// Maintenance globale (sauf routes admin/auth/health)
app.use(checkMaintenance);

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
  if (err.message && String(err.message).includes('Format non supporté')) {
    return res.status(400).json({ success: false, message: err.message });
  }
  logError(`Erreur non gérée sur ${req.method} ${req.originalUrl}`, err);
  res.status(500).json({ message: 'Erreur serveur' });
});

app.listen(PORT, () => {
  void startScheduledJobs();
  logInfo(`EmploiConnect API écoute sur http://localhost:${PORT}`);
  logInfo('Routes principales disponibles :');
  logInfo('  - Health:        GET /api/health');
  logInfo('  - Auth:          POST /api/auth/register, POST /api/auth/login, POST /api/auth/forgot-password, POST /api/auth/reset-password');
  logInfo('  - Profil:        GET/PATCH /api/users/me (Bearer)');
  logInfo('  - Offres:        GET/POST /api/offres (?entreprise_id, q, …), GET/PATCH/DELETE /api/offres/:id');
  logInfo('  - Vitrine:       GET /api/entreprises/top-public');
  logInfo('  - Candidatures:  GET/POST /api/candidatures, GET/PATCH /api/candidatures/:id');
  logInfo('  - CV:            POST /api/cv/upload, GET /api/cv/me, GET /api/cv/download-url');
  logInfo('  - Signalements:  POST /api/signalements');
  logInfo('  - Admin:         /api/admin/* (dashboard, statistiques, activite, utilisateurs, offres, entreprises, candidatures, signalements, notifications, parametres) — JWT + rôle admin + table administrateurs');
  console.log('[IA] APIs configurées :');
  console.log('  ✅ Text Similarity  :', process.env.RAPIDAPI_SIMILARITY_HOST || 'NON CONFIGURÉ');
  console.log('  ⚠️  Resume Parser   :', process.env.RAPIDAPI_RESUME_PARSER_HOST || 'À CONFIGURER sur rapidapi.com');
  console.log('  ⚠️  Topic Tagging   :', process.env.RAPIDAPI_TOPIC_TAGGING_HOST || 'À CONFIGURER sur rapidapi.com');
});

async function checkBuckets() {
  const buckets = [
    process.env.SUPABASE_LOGOS_BUCKET || 'logos',
    process.env.SUPABASE_BANNIERES_BUCKET || 'bannieres',
    process.env.SUPABASE_STORAGE_BUCKET || 'cv-files',
    process.env.SUPABASE_STORAGE_BUCKET_AVATARS || process.env.SUPABASE_STORAGE_BUCKET_PHOTOS || 'avatars',
  ];
  for (const bucket of buckets) {
    try {
      const { data, error } = await supabase.storage.getBucket(bucket);
      if (error) {
        const msg = String(error.message || '');
        const notFound = /not found|does not exist|404/i.test(msg) || error.statusCode === '404';
        if (notFound) {
          const shouldBePublic = ['logos', 'bannieres', 'avatars'].includes(bucket);
          const { error: createErr } = await supabase.storage.createBucket(bucket, {
            public: shouldBePublic,
          });
          if (createErr) {
            console.warn(`⚠️  Bucket "${bucket}" absent et création impossible: ${createErr.message}`);
          } else {
            console.log(`✅ Bucket "${bucket}" créé automatiquement (public: ${shouldBePublic})`);
          }
        } else {
          console.warn(`⚠️  Bucket "${bucket}" inaccessible: ${msg}`);
        }
      } else {
        console.log(`✅ Bucket "${bucket}" OK (public: ${data.public})`);
      }
    } catch (e) {
      const msg = e?.message || String(e);
      if (/fetch failed|network|ENOTFOUND|ECONNREFUSED|timeout/i.test(msg)) {
        console.warn(`⚠️  Vérification bucket "${bucket}" ignorée (réseau Supabase indisponible): ${msg}`);
      } else {
        console.warn(`⚠️  Vérification bucket "${bucket}" en erreur: ${msg}`);
      }
    }
  }
}

checkBuckets();

async function checkIAApis() {
  const keys = await getRapidApiKeys();
  console.log('\n[IA] Statut des APIs :');
  console.log('  Clé RapidAPI :', keys.apiKey ? '✅ Configurée' : '❌ Manquante → Admin > Paramètres > IA');
  console.log('  Text Similarity :', keys.similarityHost ? `✅ ${keys.similarityHost}` : '❌ Manquant');
  console.log(
    '  Resume Parser :',
    keys.parserHost ? `✅ ${keys.parserHost}` : '⚠️  À configurer → rapidapi.com → "Resume Parser 3"',
  );
  console.log(
    '  Topic Tagging :',
    keys.taggingHost ? `✅ ${keys.taggingHost}` : '⚠️  À configurer → rapidapi.com → "Twinword Topic Tagging"',
  );
  console.log('');
}
checkIAApis();
