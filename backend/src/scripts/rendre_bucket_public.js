import 'dotenv/config';
import { supabase, BUCKET_CV } from '../config/supabase.js';

async function main() {
  const { error } = await supabase.storage.updateBucket(BUCKET_CV, { public: true });
  if (error) {
    console.error('❌', error.message);
  } else {
    console.log(`✅ ${BUCKET_CV} rendu public`);
  }
}

main().catch((err) => {
  console.error('❌', err?.message || err);
  process.exit(1);
});
