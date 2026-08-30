-- =============================================================================
-- TABLA DE REPORTES VIALES COMUNITARIOS (ESTILO WAZE) PARA MY AUTO GUIDE
-- =============================================================================
-- Permite que retenes, fotomultas, accidentes y obras se sincronicen
-- instantáneamente en tiempo real entre todos los celulares conectados.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.reportes_viales (
    id TEXT PRIMARY KEY,
    tipo TEXT NOT NULL,
    titulo TEXT NOT NULL,
    descripcion TEXT DEFAULT '',
    latitud DOUBLE PRECISION NOT NULL,
    longitud DOUBLE PRECISION NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    confirmaciones INTEGER DEFAULT 1,
    rechazos INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Índices de alto rendimiento para consultas geoespaciales y filtros por tiempo
CREATE INDEX IF NOT EXISTS idx_reportes_viales_created ON public.reportes_viales(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reportes_viales_coords ON public.reportes_viales(latitud, longitud);

-- Habilitar Row Level Security (RLS)
ALTER TABLE public.reportes_viales ENABLE ROW LEVEL SECURITY;

-- Políticas de Seguridad: Cualquier usuario autenticado puede leer, crear y votar reportes
DROP POLICY IF EXISTS "Permitir lectura publica de reportes viales" ON public.reportes_viales;
CREATE POLICY "Permitir lectura publica de reportes viales"
    ON public.reportes_viales FOR SELECT
    TO authenticated, anon
    USING (true);

DROP POLICY IF EXISTS "Permitir crear reportes viales" ON public.reportes_viales;
CREATE POLICY "Permitir crear reportes viales"
    ON public.reportes_viales FOR INSERT
    TO authenticated, anon
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir actualizar votos en reportes viales" ON public.reportes_viales;
CREATE POLICY "Permitir actualizar votos en reportes viales"
    ON public.reportes_viales FOR UPDATE
    TO authenticated, anon
    USING (true);

DROP POLICY IF EXISTS "Permitir eliminar reportes descartados" ON public.reportes_viales;
CREATE POLICY "Permitir eliminar reportes descartados"
    ON public.reportes_viales FOR DELETE
    TO authenticated, anon
    USING (true);

-- Habilitar Supabase Realtime para la tabla reportes_viales
ALTER PUBLICATION supabase_realtime ADD TABLE public.reportes_viales;
