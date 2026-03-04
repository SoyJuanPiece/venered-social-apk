-- ========================================================
-- SETUP SUPABASE-ONLY (SIN ONESIGNAL)
-- ========================================================

-- 1. Eliminar Triggers y Funciones de OneSignal (Limpieza)
DROP TRIGGER IF EXISTS on_notification_send_onesignal ON public.notifications;
DROP TRIGGER IF EXISTS on_notif_send ON public.notifications;
DROP FUNCTION IF EXISTS public.send_onesignal_notification();

-- 2. Asegurar que Realtime está habilitado para la tabla de notificaciones
-- Esto permite que el .stream() de Flutter funcione instantáneamente
ALTER publication supabase_realtime ADD TABLE public.notifications;

-- 3. Crear función de utilidad para limpiar notificaciones antiguas (opcional)
CREATE OR REPLACE FUNCTION public.delete_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM public.notifications WHERE created_at < (NOW() - INTERVAL '30 days');
END;
$$ LANGUAGE plpgsql;

-- 4. Asegurar que los perfiles tienen los permisos correctos
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden ver sus propias notificaciones"
ON public.notifications FOR SELECT
USING (auth.uid() = receiver_id);

CREATE POLICY "El sistema puede insertar notificaciones"
ON public.notifications FOR INSERT
WITH CHECK (true);
