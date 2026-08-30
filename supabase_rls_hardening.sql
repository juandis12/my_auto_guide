-- =====================================================================
-- HARDENING COMPLETO DE SEGURIDAD -- MY AUTO GUIDE
-- Ejecutar en SQL Editor de Supabase Dashboard
-- Fecha: 30 Agosto 2026
-- =====================================================================

-- 1. Habilitar RLS en todas las tablas con datos de usuario
ALTER TABLE public.vehiculos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rutas_historial ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gastos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reportes_viales ENABLE ROW LEVEL SECURITY;

-- 2. RLS -- vehiculos: solo el propietario puede ver/modificar sus vehiculos
DROP POLICY IF EXISTS "Usuarios solo ven sus vehiculos" ON public.vehiculos;
CREATE POLICY "Usuarios solo ven sus vehiculos"
  ON public.vehiculos FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 3. RLS -- rutas_historial: solo el usuario propietario accede a sus rutas
DROP POLICY IF EXISTS "Usuarios solo ven sus rutas" ON public.rutas_historial;
CREATE POLICY "Usuarios solo ven sus rutas"
  ON public.rutas_historial FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 4. RLS -- gastos: solo el usuario propietario accede a sus gastos
DROP POLICY IF EXISTS "Usuarios solo ven sus gastos" ON public.gastos;
CREATE POLICY "Usuarios solo ven sus gastos"
  ON public.gastos FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 5. RLS -- perfiles: cada usuario solo ve y modifica su propio perfil
DROP POLICY IF EXISTS "Usuarios solo ven su perfil" ON public.perfiles;
CREATE POLICY "Usuarios solo ven su perfil"
  ON public.perfiles FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 6. RLS -- reportes_viales: lectura publica, escritura solo autenticados
DROP POLICY IF EXISTS "Reportes son publicos para lectura" ON public.reportes_viales;
CREATE POLICY "Reportes son publicos para lectura"
  ON public.reportes_viales FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Solo autenticados pueden reportar" ON public.reportes_viales;
CREATE POLICY "Solo autenticados pueden reportar"
  ON public.reportes_viales FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Usuarios pueden actualizar sus propios reportes" ON public.reportes_viales;
CREATE POLICY "Usuarios pueden actualizar sus propios reportes"
  ON public.reportes_viales FOR UPDATE
  USING (auth.uid() = user_id);

-- 7. Verificacion: listar todas las politicas activas
SELECT tablename, policyname, cmd, permissive, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd;