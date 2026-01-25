-- Migración: Agregar columna foto_url a la tabla grupos_ruta
-- Ejecutar en Supabase SQL Editor

-- 1. Agregar columna foto_url
ALTER TABLE grupos_ruta ADD COLUMN IF NOT EXISTS foto_url TEXT;

-- 2. Verificar que la columna se agregó correctamente
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'grupos_ruta'
  AND column_name = 'foto_url';

-- 3. Mostrar estructura completa de la tabla
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'grupos_ruta'
ORDER BY ordinal_position;

-- ============================================
-- CONFIGURACIÓN DE STORAGE (Hacer manualmente en Supabase Dashboard)
-- ============================================
--
-- Ir a Storage → Create bucket:
-- - Nombre: grupos
-- - Public: ✅ Sí (para que las URLs sean públicas)
-- - Allowed MIME types: image/jpeg, image/png, image/webp
-- - Max file size: 5 MB
--
-- ============================================
