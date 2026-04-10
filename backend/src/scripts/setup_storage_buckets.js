/**
 * Configure/creates storage buckets for messaging and media.
 * Usage: node src/scripts/setup_storage_buckets.js
 */
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '../../.env') });

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
);

async function upsertBucket(name, opts) {
  try {
    const { data: existing } = await supabase.storage.getBucket(name);
    if (existing) {
      const { error: upErr } = await supabase.storage.updateBucket(name, opts);
      if (upErr) {
        console.error(`❌ Bucket "${name}" (update): ${upErr.message}`);
      } else {
        console.log(`✅ Bucket "${name}" mis à jour (${opts.public ? 'public' : 'privé'})`);
      }
      return;
    }
  } catch (e) {
    // proceed to create if getBucket throws
    if (!String(e?.message || '').toLowerCase().includes('not found')) {
      console.warn(`⚠️ getBucket("${name}") : ${e.message}`);
    }
  }

  const { error: createErr } = await supabase.storage.createBucket(name, opts);
  if (createErr) {
    console.error(`❌ Bucket "${name}" (create): ${createErr.message}`);
  } else {
    console.log(`✅ Bucket "${name}" créé (${opts.public ? 'public' : 'privé'})`);
  }
}

async function setupBuckets() {
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY manquants dans backend/.env');
  }

  const publicBuckets = ['avatars', 'logos', 'bannieres'];
  const privateBuckets = ['cv-files', 'messagerie-files'];

  for (const name of publicBuckets) {
    await upsertBucket(name, {
      public: true,
      allowedMimeTypes: null,
      fileSizeLimit: 15 * 1024 * 1024,
    });
  }

  for (const name of privateBuckets) {
    await upsertBucket(name, {
      public: false,
      allowedMimeTypes: null,
      fileSizeLimit: 20 * 1024 * 1024,
    });
  }

  console.log('\n=== Vérification finale ===');
  const { data: allBuckets, error } = await supabase.storage.listBuckets();
  if (error) {
    console.error(`❌ listBuckets: ${error.message}`);
    return;
  }
  for (const b of allBuckets || []) {
    console.log(`  ${b.public ? '🌐' : '🔒'} ${b.name}`);
  }
}

setupBuckets().catch((e) => {
  console.error('❌ setup_storage_buckets:', e.message);
  process.exit(1);
});
