import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
);

async function main() {
  const { error } = await supabase.storage.updateBucket('cv-files', { public: true });
  if (error) console.error('❌', error.message);
  else console.log('✅ cv-files rendu public !');
  const { data } = supabase.storage.from('cv-files').getPublicUrl('test.pdf');
  console.log('Format URL publique:', data.publicUrl);
}

main().catch((e) => {
  console.error('❌', e?.message || e);
  process.exit(1);
});
