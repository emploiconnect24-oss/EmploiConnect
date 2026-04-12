/**
 * Point d’entrée des routes d’authentification (montées sous `/api/auth`).
 *
 * Implémentation : {@link ./auth.js}
 *
 * Inclut notamment le flux Google OAuth :
 * - GET  /api/auth/google-config  — client_id public + flag actif
 * - POST /api/auth/google         — échange id_token Google → session JWT
 */
export { default } from './auth.js';
