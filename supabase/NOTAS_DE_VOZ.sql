-- ========================================================
-- NOTAS DE VOZ v1.2: ALMACENAMIENTO EFÍMERO (1 DÍA)
-- ========================================================

-- 1. Añadir columna para pedir resubida
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS needs_reupload BOOLEAN DEFAULT false;

-- 2. Actualizar el Cron para borrar cada 24 horas
-- Borramos la tarea anterior si existía
SELECT cron.unschedule('limpiar-audios-viejos');

-- Creamos la nueva tarea de 1 día
SELECT cron.schedule('limpiar-audios-viejos', '0 0 * * *', $$
    DELETE FROM storage.objects 
    WHERE bucket_id = 'voice-notes' 
      AND created_at < (NOW() - INTERVAL '1 day');
$$);
