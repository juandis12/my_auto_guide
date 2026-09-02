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
CREATE POLICY "Permitir lectura publica de app_versions"
    ON public.app_versions
    FOR SELECT
    TO public
    USING (true);

-- 2. Registro del Bucket 'app-releases' en Storage (si no existe)
INSERT INTO storage.buckets (id, name, public)
VALUES ('app-releases', 'app-releases', true)
ON CONFLICT (id) DO NOTHING;

-- Política de descarga de archivos del bucket 'app-releases'
CREATE POLICY "Descarga publica de app-releases"
    ON storage.objects
    FOR SELECT
    TO public
    USING (bucket_id = 'app-releases');
