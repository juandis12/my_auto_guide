-- =============================================================================
-- publish_v1_1_0_build5.sql — REGISTRO DE ACTUALIZACIÓN OBLIGATORIA v1.1.0+5
-- =============================================================================

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    7,
    '1.1.0',
    'https://github.com/juandis12/my_auto_guide/releases/download/v1.1.0/app-release.apk',
    '•Mejoras generales en el rendimiento y estabilidad de la aplicación.',
    true,
    1
)
ON CONFLICT (version_code) DO UPDATE 
SET 
    version_name = EXCLUDED.version_name,
    zip_url = EXCLUDED.zip_url,
    release_notes = EXCLUDED.release_notes,
    is_mandatory = EXCLUDED.is_mandatory,
    min_supported_version = EXCLUDED.min_supported_version;
