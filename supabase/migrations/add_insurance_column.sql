-- =============================================================================
-- Migración: Soporte para Aseguradora Todo Riesgo en la tabla vehiculos
-- =============================================================================

ALTER TABLE vehiculos 
ADD COLUMN IF NOT EXISTS aseguradora_id TEXT DEFAULT NULL;

COMMENT ON COLUMN vehiculos.aseguradora_id IS 'Identificador de la aseguradora todo riesgo seleccionada por el usuario (ej. sura, allianz, bolivar o NULL si no tiene)';
