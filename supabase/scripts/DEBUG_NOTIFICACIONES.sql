-- ========================================================
-- CONSULTA CRÍTICA: ¿POR QUÉ NO SALEN LAS NOTIFICACIONES?
-- ========================================================

-- PASO 1: ASEGURAR QUE LA EXTENSIÓN PUEDE ENVIAR DATOS
CREATE EXTENSION IF NOT EXISTS pg_net;

-- PASO 2: VER LAS PETICIONES DE RED (EL ENVÍO A ONESIGNAL)
-- Esta consulta nos dirá si Supabase está intentando hablar con OneSignal.
-- Copia el resultado que te dé esta consulta y pégamelo aquí.
SELECT * FROM net.http_request_queue 
ORDER BY id DESC 
LIMIT 5;
