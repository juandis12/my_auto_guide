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
    6,
    '1.1.0',
    'https://github.com/juandis12/my_auto_guide/releases/download/v1.1.0/app-release.apk',
    '• Buscador inteligente de manuales y fichas técnicas (búsqueda tolerante a espacios y caracteres).\n• Corrección del botón "Recordarme" y auto-login de sesión activa.\n• Soporte de redirección Deep Link para inicio de sesión con Google y Facebook en iOS y Android.\n• Solución definitiva a conflictos de firma de instalación OTA.',
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
