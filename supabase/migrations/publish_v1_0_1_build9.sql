-- =============================================================================
-- publish_v1_0_1_build9.sql — REGISTRO DE ACTUALIZACIÓN OBLIGATORIA v1.0.1+9
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
    9,
    '1.0.1',
    'https://github.com/juandis12/my_auto_guide/releases/download/v1.0.1/app-release.apk',
    '• Corrección definitiva en la persistencia y carga de Aseguradora Todo Riesgo en la pantalla principal.\n• Rediseño ergonómico premium del selector de aseguradoras (Apple HIG / Cupertino Wheel).\n• Tarjeta interactiva de póliza en el Dashboard con indicador de estado activo y acceso directo a líneas de asistencia 24/7.\n• Mejoras de estabilidad y rendimiento general.',
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
