-- ═══════════════════════════════════════════════════════════
-- MIGRATION 009 : Buckets Storage Supabase (bannières + logos)
-- Sans DROP : idempotent, évite l’avertissement « destructive » du SQL Editor.
-- ═══════════════════════════════════════════════════════════

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'bannieres',
    'bannieres',
    true,
    10485760,
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']::text[]
  ),
  (
    'logos',
    'logos',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml']::text[]
  )
ON CONFLICT (id) DO NOTHING;

-- Politiques SELECT publiques uniquement si elles n’existent pas encore
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Lecture publique bannieres'
  ) THEN
    CREATE POLICY "Lecture publique bannieres"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'bannieres');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Lecture publique logos'
  ) THEN
    CREATE POLICY "Lecture publique logos"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'logos');
  END IF;
END $$;

-- Upload : service_role (backend) contourne RLS ; pas de policy INSERT anon requise ici.
