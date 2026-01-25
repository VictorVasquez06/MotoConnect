-- ============================================
-- Políticas RLS para Storage Bucket 'grupos'
-- ============================================
-- Ejecutar en Supabase SQL Editor
--
-- IMPORTANTE: Ejecutar DESPUÉS de crear el bucket 'grupos' en Storage
--
-- Estas políticas permiten:
-- 1. Cualquier usuario autenticado puede SUBIR fotos (INSERT)
-- 2. Cualquiera puede VER fotos (SELECT) - bucket público
-- 3. Solo el creador del grupo puede ACTUALIZAR/ELIMINAR fotos
-- ============================================

-- ============================================
-- POLÍTICA 1: Permitir INSERT (upload) a usuarios autenticados
-- ============================================
CREATE POLICY "Usuarios autenticados pueden subir fotos de grupos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'grupos'
);

-- ============================================
-- POLÍTICA 2: Permitir SELECT (download) público
-- ============================================
CREATE POLICY "Las fotos de grupos son públicas"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'grupos'
);

-- ============================================
-- POLÍTICA 3: Permitir UPDATE a usuarios autenticados
-- ============================================
CREATE POLICY "Usuarios autenticados pueden actualizar fotos de grupos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'grupos'
)
WITH CHECK (
  bucket_id = 'grupos'
);

-- ============================================
-- POLÍTICA 4: Permitir DELETE a usuarios autenticados
-- ============================================
CREATE POLICY "Usuarios autenticados pueden eliminar fotos de grupos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'grupos'
);

-- ============================================
-- VERIFICACIÓN: Ver políticas creadas
-- ============================================
SELECT
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'objects'
  AND policyname LIKE '%grupos%';

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
--
-- 1. Si quieres restringir UPDATE/DELETE solo al creador del grupo,
--    necesitarías una tabla intermedia que relacione el archivo
--    con el grupo y verificar ownership.
--
-- 2. Para mayor seguridad, podrías limitar INSERT solo a miembros
--    del grupo, pero requeriría lógica más compleja.
--
-- 3. La política actual permite a cualquier usuario autenticado
--    subir/actualizar/eliminar fotos, lo cual es suficiente para
--    un MVP. Considera refinar en producción.
--
-- ============================================
