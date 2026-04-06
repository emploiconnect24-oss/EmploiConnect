/**
 * Vérifie / crée les buckets Supabase Storage (avatars, cv-files, logos, bannieres).
 * Usage : depuis la racine backend → node src/scripts/check_buckets.js
 */
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '../../.env') });

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !key) {
  console.error('❌ SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY requis dans .env');
  process.exit(1);
}

const supabase = createClient(url, key);

async function checkBuckets() {
  const buckets = ['avatars', 'cv-files', 'logos', 'bannieres'];
  for (const name of buckets) {
    try {
      const { data, error } = await supabase.storage.getBucket(name);
      if (error) {
        console.log(`❌ Bucket "${name}" MANQUANT : ${error.message}`);
        const { error: createErr } = await supabase.storage.createBucket(name, {
          public: ['avatars', 'logos', 'bannieres'].includes(name),
          fileSizeLimit: 20 * 1024 * 1024,
        });
        if (createErr) {
          console.log(`  → Création échouée : ${createErr.message}`);
        } else {
          console.log(`  → ✅ Bucket "${name}" créé avec succès`);
        }
      } else {
        console.log(`✅ Bucket "${name}" OK (public: ${data.public})`);
      }
    } catch (e) {
      console.log(`❌ Erreur "${name}" : ${e.message}`);
    }
  }
}

checkBuckets().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
