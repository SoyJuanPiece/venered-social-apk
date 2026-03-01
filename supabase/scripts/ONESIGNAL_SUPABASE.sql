-- ========================================================
-- SISTEMA AUTOMÁTICO DE NOTIFICACIONES CON ONESIGNAL
-- VENERED SOCIAL v1.0 (OFICIAL)
-- ========================================================

-- 1. FUNCIÓN: ENVIAR PUSH A ONESIGNAL
CREATE OR REPLACE FUNCTION public.send_onesignal_notification()
RETURNS TRIGGER AS $$
DECLARE
  sender_name TEXT;
BEGIN
  -- Obtener el nombre del que envía
  SELECT username INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

  -- Enviar el POST a OneSignal usando la extensión HTTP de Supabase
  PERFORM net.http_post(
    url := 'https://onesignal.com/api/v1/notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Basic os_v2_app_po76jzwc5banvfxlz7csrpfw4ym765qku7be4zm4xoegs7mlyyd5nrbf5w2lsedjl5tvwnri4hmulzvb3qi5guivug52xydq2jr2hza' -- <--- TU REST API KEY AQUÍ
    ),
    body := jsonb_build_object(
      'app_id', '7bbfe4e6-c2e8-40da-96eb-cfc528bcb6e6', -- <--- TU APP ID YA ESTÁ AQUÍ
      'include_external_user_ids', ARRAY[NEW.receiver_id::TEXT],
      'headings', jsonb_build_object('en', CASE WHEN NEW.type = 'message' THEN 'Mensaje de ' || sender_name ELSE 'Venered Social' END),
      'contents', jsonb_build_object('en', NEW.content),
      'android_channel_id', 'venered_messages_v2',
      'priority', 10
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. TRIGGER PARA ENVIAR LA NOTIFICACIÓN
DROP TRIGGER IF EXISTS on_notification_send_onesignal ON public.notifications;
CREATE TRIGGER on_notification_send_onesignal
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.send_onesignal_notification();

-- 3. HABILITAR EXTENSIÓN DE RED
CREATE EXTENSION IF NOT EXISTS pg_net;
