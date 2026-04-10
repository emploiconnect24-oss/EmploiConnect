import { supabase, BUCKET_CV } from '../config/supabase.js';

/** Durée des liens signés pour les fichiers CV (téléchargement recruteur / API). */
export const CV_SIGNED_URL_TTL_SEC = 86400; // 24 h

/**
 * Extrait le chemin objet dans le bucket à partir d'une URL publique/signée
 * ou renvoie la chaîne telle quelle si c'est déjà un chemin relatif.
 */
export function storagePathFromFichierUrl(fichierUrl, bucket = BUCKET_CV) {
  if (fichierUrl == null || fichierUrl === '') return null;
  const s = String(fichierUrl).trim();
  const marker = `/${bucket}/`;
  const i = s.indexOf(marker);
  if (i >= 0) {
    return decodeURIComponent(s.slice(i + marker.length).split('?')[0]);
  }
  return s.split('?')[0];
}

/**
 * @returns {{ signedUrl: string | null, error: Error | null }}
 */
export async function createCvSignedUrl(fichierUrl, expiresSec = CV_SIGNED_URL_TTL_SEC) {
  const path = storagePathFromFichierUrl(fichierUrl);
  if (!path) {
    return { signedUrl: null, error: new Error('Chemin fichier CV manquant') };
  }
  const { data, error } = await supabase.storage.from(BUCKET_CV).createSignedUrl(path, expiresSec);
  if (error) {
    return { signedUrl: null, error };
  }
  return { signedUrl: data?.signedUrl ?? null, error: null };
}
