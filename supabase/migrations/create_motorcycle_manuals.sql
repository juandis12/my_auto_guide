-- Migration: Crear tabla de manuales y especificaciones técnicas de motocicletas
-- Permite acceso offline/online a la ficha técnica de miles de motocicletas.

CREATE TABLE IF NOT EXISTS public.motorcycle_manuals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    year TEXT NOT NULL,
    type TEXT,
    displacement TEXT,
    engine TEXT,
    power TEXT,
    torque TEXT,
    compression TEXT,
    valves_per_cylinder TEXT,
    fuel_system TEXT,
    fuel_control TEXT,
    lubrication TEXT,
    cooling TEXT,
    gearbox TEXT,
    transmission TEXT,
    clutch TEXT,
    frame TEXT,
    front_suspension TEXT,
    rear_suspension TEXT,
    front_wheel_travel TEXT,
    rear_wheel_travel TEXT,
    front_tire TEXT,
    rear_tire TEXT,
    front_brakes TEXT,
    rear_brakes TEXT,
    seat_height TEXT,
    ground_clearance TEXT,
    wheelbase TEXT,
    fuel_capacity TEXT,
    fuel_consumption TEXT,
    emission TEXT,
    total_weight TEXT,
    dry_weight TEXT,
    starter TEXT,
    ignition TEXT,
    top_speed TEXT,
    manual_pdf_url TEXT,
    raw_specs JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_motorcycle_spec UNIQUE (make, model, year)
);

-- Índices para búsqueda ultra rápida por marca, modelo y año
CREATE INDEX IF NOT EXISTS idx_motorcycle_manuals_make ON public.motorcycle_manuals (make);
CREATE INDEX IF NOT EXISTS idx_motorcycle_manuals_model ON public.motorcycle_manuals (model);
CREATE INDEX IF NOT EXISTS idx_motorcycle_manuals_year ON public.motorcycle_manuals (year);
CREATE INDEX IF NOT EXISTS idx_motorcycle_manuals_make_model ON public.motorcycle_manuals (make, model);

-- Habilitar Row Level Security (RLS)
ALTER TABLE public.motorcycle_manuals ENABLE ROW LEVEL SECURITY;

-- Política de lectura pública: cualquier usuario autenticado o anónimo puede consultar el manual
CREATE POLICY "Permitir lectura publica de manuales"
    ON public.motorcycle_manuals
    FOR SELECT
    TO public, anon, authenticated
    USING (true);

-- Política de inserción / actualización para administradores o servicio
CREATE POLICY "Permitir insercion/actualizacion de manuales"
    ON public.motorcycle_manuals
    FOR ALL
    TO public, anon, authenticated
    USING (true)
    WITH CHECK (true);
