-- =============================================================================
-- create_app_versions.sql — TABLA Y STORAGE PARA ACTUALIZACIONES OTA
-- =============================================================================

-- 1. Tabla de Versiones
CREATE TABLE IF NOT EXISTS public.app_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_code INTEGER NOT NULL UNIQUE,
    version_name TEXT NOT NULL,
    zip_url TEXT NOT NULL,
    release_notes TEXT,
    is_mandatory BOOLEAN NOT NULL DEFAULT true,
    min_supported_version INTEGER NOT NULL DEFAULT 1,
    file_size_bytes BIGINT,
    checksum_sha256 TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- Política de lectura pública para que cualquier cliente autenticado o anónimo pueda chequear updates
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'app_versions' AND schemaname = 'public' AND policyname = 'Permitir lectura publica de app_versions'
    ) THEN
        CREATE POLICY "Permitir lectura publica de app_versions"
            ON public.app_versions
            FOR SELECT
            TO public
            USING (true);
    END IF;
END $$;

-- 2. Registro del Bucket 'app-releases' en Storage (si no existe)
INSERT INTO storage.buckets (id, name, public)
VALUES ('app-releases', 'app-releases', true)
ON CONFLICT (id) DO NOTHING;

-- Política de descarga de archivos del bucket 'app-releases'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage' AND policyname = 'Descarga publica de app-releases'
    ) THEN
        CREATE POLICY "Descarga publica de app-releases"
            ON storage.objects
            FOR SELECT
            TO public
            USING (bucket_id = 'app-releases');
    END IF;
END $$;

-- 3. Registrar o actualizar la versión 1.1.0 (version_code: 2)
INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory
)
VALUES (
    7,
    '1.1.0',
    'https://github.com/juandis12/my_auto_guide/releases/download/v1.1.0/app-release.apk',
    '• Mejoras en el sistema ',
    true
)
ON CONFLICT (version_code) DO UPDATE 
SET 
    zip_url = EXCLUDED.zip_url,
    version_name = EXCLUDED.version_name,
    release_notes = EXCLUDED.release_notes,
    is_mandatory = EXCLUDED.is_mandatory;

