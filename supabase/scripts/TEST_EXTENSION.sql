-- ========================================================
-- PRUEBA DE FUEGO: ¿FUNCIONA LA EXTENSIÓN PG_NET?
-- ========================================================

-- 1. Intentar una petición manual a Google (solo para ver si se encola)
SELECT net.http_post(
    url := 'https://google.com',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{"test": "data"}'::jsonb
);

-- 2. VERIFICAR INMEDIATAMENTE LA COLA
-- Si esto sigue saliendo vacío, la extensión pg_net no está funcionando en tu Supabase.
SELECT * FROM net.http_request_queue;

-- 3. VERIFICAR SI LA EXTENSIÓN ESTÁ EN EL ESQUEMA CORRECTO
SELECT n.nspname as schema_name,
       p.proname as function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'http_post';
