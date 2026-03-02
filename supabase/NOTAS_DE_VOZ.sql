-- ========================================================
-- NOTAS DE VOZ v1.3: EXTENSIÓN A 7 DÍAS
-- ========================================================

-- 1. Actualizar el Cron para borrar cada 7 días
SELECT cron.unschedule('limpiar-audios-viejos');

-- Nueva tarea de 7 días
SELECT cron.schedule('limpiar-audios-viejos', '0 0 * * *', $$
    DELETE FROM storage.objects 
    WHERE bucket_id = 'voice-notes' 
      AND created_at < (NOW() - INTERVAL '7 days');
$$);
