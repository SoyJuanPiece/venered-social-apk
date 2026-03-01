-- ========================================================
-- REPARACIÓN TOTAL DEL TRIGGER DE ONESIGNAL (CORREGIDO)
-- ========================================================

-- 1. Asegurar que la extensión de red existe
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Borrar triggers viejos
DROP TRIGGER IF EXISTS on_notification_send_onesignal ON public.notifications;

-- 3. Crear la función de envío
CREATE OR REPLACE FUNCTION public.send_onesignal_notification()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://onesignal.com/api/v1/notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Basic os_v2_app_po76jzwc5banvfxlz7csrpfw4ym765qku7be4zm4xoegs7mlyyd5nrbf5w2lsedjl5tvwnri4hmulzvb3qi5guivug52xydq2jr2hza'
    ),
    body := jsonb_build_object(
      'app_id', '7bbfe4e6-c2e8-40da-96eb-cfc528bcb6e6',
      'include_external_user_ids', ARRAY[NEW.receiver_id::TEXT],
      'headings', jsonb_build_object('en', 'Venered Social'),
      'contents', jsonb_build_object('en', NEW.content),
      'android_channel_id', 'venered_messages_v2'
    )
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Re-crear el trigger
CREATE TRIGGER on_notification_send_onesignal
  AFTER INSERT ON public.notifications
  FOR EACH ROW 
  EXECUTE FUNCTION public.send_onesignal_notification();

-- 5. VERIFICACIÓN (SIN LA COLUMNA STATUS)
SELECT trigger_name, event_object_table, action_timing, event_manipulation
FROM information_schema.triggers 
WHERE event_object_table = 'notifications'
AND trigger_name = 'on_notification_send_onesignal';
