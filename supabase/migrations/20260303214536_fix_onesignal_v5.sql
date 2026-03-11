-- ========================================================
-- REPARACIÓN DEFINITIVA DE ONESIGNAL PUSH (Migration)
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
  recent_count INTEGER;
  onesignal_app_id TEXT := '';
  onesignal_api_key TEXT := '';
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

-- 3. Re-crear el Trigger (solo si la tabla existe)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'notifications'
  ) THEN
    DROP TRIGGER IF EXISTS on_notification_send_onesignal ON public.notifications;
    CREATE TRIGGER on_notification_send_onesignal
      AFTER INSERT ON public.notifications
      FOR EACH ROW EXECUTE FUNCTION public.send_onesignal_notification();
  END IF;
END
$$;
