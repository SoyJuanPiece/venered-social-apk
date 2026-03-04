-- ========================================================
-- REPARACIÓN DEFINITIVA DE ONESIGNAL PUSH (API KEY NUEVA)
-- ========================================================

-- 1. Habilitar extensión necesaria
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Función de envío optimizada con la clave correcta
CREATE OR REPLACE FUNCTION public.send_onesignal_notification()
RETURNS TRIGGER AS $$
DECLARE
  sender_name TEXT;
  notif_title TEXT;
  notif_body TEXT;
  recent_count INTEGER;
  onesignal_app_id TEXT := '7bbfe4e6-c2e8-40da-96eb-cfc528bcb6e6';
  onesignal_api_key TEXT := 'os_v2_app_po76jzwc5banvfxlz7csrpfw43wn2wa4rkpuavmpszmghn7hx7tueznsp4q7i2pwyopfhr7e3pnzmsldv3skrhu4esly4rga3klwcji';
BEGIN
  -- A. Obtener nombre del remitente
  SELECT COALESCE(username, 'Alguien') INTO sender_name 
  FROM public.profiles 
  WHERE id = NEW.sender_id;

  -- B. Control de Spam (Solo para likes y comentarios: 1 cada 15 min por post)
  IF NEW.type IN ('like', 'comment') THEN
    SELECT count(*) INTO recent_count 
    FROM public.notifications 
    WHERE receiver_id = NEW.receiver_id 
      AND type = NEW.type 
      AND (related_id = NEW.related_id)
      AND id != NEW.id 
      AND created_at > (NOW() - INTERVAL '15 minutes');

    IF recent_count > 0 THEN RETURN NEW; END IF;
  END IF;

  -- C. Configurar Título y Cuerpo (Traducción y Privacidad)
  IF NEW.type = 'message' THEN
    notif_title := 'Mensaje de ' || sender_name;
    notif_body := 'Toca para ver el mensaje'; -- Privacidad: no mostrar contenido en push
  ELSIF NEW.type = 'follow' THEN
    notif_title := '¡Nuevo Seguidor!';
    notif_body := sender_name || ' ha comenzado a seguirte';
  ELSIF NEW.type = 'like' THEN
    notif_title := 'Venered Social';
    notif_body := sender_name || ' le ha gustado tu publicación';
  ELSIF NEW.type = 'comment' THEN
    notif_title := 'Nuevo Comentario';
    notif_body := sender_name || ' ha comentado tu publicación';
  ELSE
    notif_title := 'Venered Social';
    notif_body := NEW.content;
  END IF;

  -- D. Enviar a OneSignal (v5: include_aliases)
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
      'android_channel_id', 'venered_messages',
      'priority', 10
      )
      );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Re-crear el Trigger
DROP TRIGGER IF EXISTS on_notification_send_onesignal ON public.notifications;
CREATE TRIGGER on_notification_send_onesignal
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.send_onesignal_notification();
