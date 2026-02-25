-- SQL Script para limpiar la base de datos de Venered Social para producción.
-- Este script eliminará *todos* los usuarios de prueba y su contenido asociado.

-- Advertencia: Este script es destructivo y eliminará permanentemente datos.
-- Asegúrate de tener una copia de seguridad reciente de tu base de datos antes de ejecutarlo.

-- 1. Eliminar todos los usuarios de la tabla auth.users.
--    Debido a las políticas ON DELETE CASCADE definidas en tu esquema,
--    esto también eliminará automáticamente los registros correspondientes en:
--    - public.profiles
--    - public.posts
--    - public.likes
--    - public.followers
DELETE FROM auth.users;

-- Consideraciones adicionales:
-- Si encuentras problemas de permisos al intentar DELETE FROM auth.users
-- en el editor SQL de Supabase (especialmente si no eres el rol 'postgres'),
-- puedes intentar vaciar las tablas públicas directamente. Sin embargo, esto
-- NO eliminará los usuarios de la tabla auth.users.
-- Para vaciar las tablas públicas (en caso de que la eliminación de auth.users no funcione):
-- TRUNCATE TABLE public.profiles RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE public.posts RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE public.likes RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE public.followers RESTART IDENTITY CASCADE;

-- Es importante recalcar que 'DELETE FROM auth.users;' es el método preferido
-- para una limpieza completa de usuarios y sus datos asociados, ya que respeta
-- la integridad referencial y las reglas de cascada.
