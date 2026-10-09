-- =============================================================================
-- publish_v1_0_1_build9.sql — REGISTRO DE ACTUALIZACIÓN OBLIGATORIA v1.1.0+10
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
    10,
    '1.1.0',
    'https://github.com/juandis12/my_auto_guide/releases/download/v1.1.0/app-release.apk',
    '⚡ Rendimiento Élite: Optimización profunda para reducir el consumo de batería y memoria de tu dispositivo.\n\n🔔 Nuevo Centro de Notificaciones: Rediseñamos el sistema de alertas para que nunca te pierdas un vencimiento. Ahora recibirás recordatorios inteligentes y a tiempo para: \n• Mantenimientos preventivos.  \n• Renovación de SOAT y Tecnomecánica. \n• Pólizas de seguro activo. \n• Avisos críticos de seguridad vial. \n\n✨ Función de Diagnóstico IA: Añadimos un traductor de códigos de error (DTC) que te explica de forma sencilla qué le pasa a tu carro.\n\n✅ Ahora puedes conectar tu Scanner OBD2 y ver los datos en tiempo real de tu vehículo.',
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
