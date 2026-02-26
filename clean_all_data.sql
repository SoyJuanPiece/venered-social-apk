-- Venered Social - DATA WIPE SCRIPT
-- Este script borra TODO el contenido de la base de datos para un reinicio total.
-- ⚠️ ÚSALO CON PRECAUCIÓN.

-- 1. Desactivar triggers temporalmente para evitar conflictos durante el borrado
SET session_replication_role = 'replica';

-- 2. Limpiar las tablas de actividad en cascada
TRUNCATE TABLE public.comments RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.likes RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.saved_posts RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.posts RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.followers RESTART IDENTITY CASCADE;

-- 3. Limpiar perfiles públicos
TRUNCATE TABLE public.profiles RESTART IDENTITY CASCADE;

-- 4. Reactivar triggers
SET session_replication_role = 'origin';

-- NOTA SOBRE USUARIOS (AUTH):
-- El comando SQL para borrar usuarios de autenticación es:
-- DELETE FROM auth.users;
-- Sin embargo, Supabase a veces bloquea este comando en el editor SQL por seguridad.
-- Si 'DELETE FROM auth.users' te da error, borra los usuarios manualmente desde:
-- Authentication -> Users -> Select all -> Delete.
