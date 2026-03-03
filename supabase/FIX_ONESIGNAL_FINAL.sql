-- ========================================================
-- REPARACIÓN DEFINITIVA DE ONESIGNAL PUSH
-- ========================================================

-- 1. Habilitar extensión necesaria
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Función de envío optimizada
CREATE OR REPLACE FUNCTION public.send_onesignal_notification()
RETURNS TRIGGER AS $$
DECLARE
  sender_name TEXT;
  notif_title TEXT;
  notif_body TEXT;
  onesignal_app_id TEXT := '7bbfe4e6-c2e8-40da-96eb-cfc528bcb6e6';
  onesignal_api_key TEXT := 'os_v2_app_po76jzwc5banvfxlz7csrpfw4ym765qku7be4zm4xoegs7mlyyd5nrbf5w2lsedjl5tvwnri4hmulzvb3qi5guivug52xydq2jr2hza';
BEGIN
  -- Obtener nombre del remitente
  SELECT COALESCE(username, 'Alguien') INTO sender_name 
  FROM public.profiles 
  WHERE id = NEW.sender_id;

  -- Configurar Título y Cuerpo
  IF NEW.type = 'message' THEN
    notif_title := 'Mensaje de ' || sender_name;
    notif_body := 'Toca para ver el mensaje'; -- Privacidad: no mostrar contenido en push
  ELSIF NEW.type = 'follow' THEN
    notif_title := '¡Nuevo Seguidor!';
    notif_body := sender_name || ' ha comenzado a seguirte';
  ELSIF NEW.type = 'like' THEN
    notif_title := 'Venered Social';
    notif_body := sender_name || ' le ha gustado tu publicación';
  ELSE
    notif_title := 'Venered Social';
    notif_body := NEW.content;
  END IF;

  -- Enviar petición HTTP a OneSignal
  -- Usamos 'include_aliases' que es el estándar moderno de OneSignal v5
  PERFORM net.http_post(
    url := 'https://onesignal.com/api/v1/notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Basic ' || onesignal_api_key
    ),
    body := jsonb_build_object(
      'app_id', onesignal_app_id,
      'include_aliases', jsonb_build_object('external_id', ARRAY[NEW.receiver_id::TEXT]),
      'target_channel', 'push',
      'headings', jsonb_build_object('en', notif_title),
      'contents', jsonb_build_object('en', notif_body),
      'android_channel_id', 'venered_messages_v2',
      'priority', 10
    )
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Evitar que un error en OneSignal bloquee la inserción en la DB
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Re-crear el Trigger
DROP TRIGGER IF EXISTS on_notification_send_onesignal ON public.notifications;
CREATE TRIGGER on_notification_send_onesignal
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.send_onesignal_notification();
