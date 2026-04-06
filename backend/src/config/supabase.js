/**
 * Client Supabase - Backend uniquement (service_role)
 * Toutes les opérations DB passent par ce client.
 * Le frontend ne reçoit jamais les clés Supabase.
 */
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error('SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY doivent être définis dans .env');
}

export const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

export const BUCKET_CV = process.env.SUPABASE_STORAGE_BUCKET || 'cv-files';

/**
 * Photos de profil / avatars (admin, etc.) : doit autoriser image/jpeg, image/png, image/webp.
 * Si non défini, on retombe sur BUCKET_CV — qui est souvent limité aux PDF → erreur « mime type not supported ».
 */
export const BUCKET_ADMIN_AVATARS =
  process.env.SUPABASE_STORAGE_BUCKET_AVATARS?.trim() ||
  process.env.SUPABASE_STORAGE_BUCKET_PHOTOS?.trim() ||
  'avatars';
