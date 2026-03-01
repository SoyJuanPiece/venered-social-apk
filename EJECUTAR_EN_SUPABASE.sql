-- ========================================================
-- CONFIGURACIÓN INTEGRAL DE NOTIFICACIONES PUSH
-- VENERED SOCIAL v1.0 (OFICIAL)
-- ========================================================

-- 1. BASE DE DATOS: COLUMNA PARA TOKENS
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 2. PERMISOS: PERMITIR QUE CADA USUARIO GUARDE SU TOKEN
DROP POLICY IF EXISTS "Usuarios pueden actualizar su propio token" ON public.profiles;
CREATE POLICY "Usuarios pueden actualizar su propio token" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id);

-- 3. FUNCIÓN: GENERAR NOTIFICACIÓN AUTOMÁTICA (MENSAJES)
CREATE OR REPLACE FUNCTION public.handle_new_message_notification()
RETURNS TRIGGER AS $$
DECLARE
  target_receiver_id UUID;
BEGIN
  SELECT CASE WHEN user1_id = NEW.sender_id THEN user2_id ELSE user1_id END 
  INTO target_receiver_id FROM public.conversations WHERE id = NEW.conversation_id;

  INSERT INTO public.notifications (receiver_id, sender_id, type, content, related_id)
  VALUES (target_receiver_id, NEW.sender_id, 'message', NEW.content, NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. FUNCIÓN: ENVIAR PUSH A FIREBASE (APP CERRADA)
-- NOTA: Requiere que pegues tu SERVER KEY abajo.
CREATE OR REPLACE FUNCTION public.send_push_notification()
RETURNS TRIGGER AS $$
DECLARE
  target_token TEXT;
  sender_name TEXT;
BEGIN
  SELECT fcm_token INTO target_token FROM public.profiles WHERE id = NEW.receiver_id;
  SELECT username INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

  IF target_token IS NULL THEN RETURN NEW; END IF;

  -- Envío vía HTTP a Firebase (Legacy API)
  -- DEBES REEMPLAZAR 'TU_SERVER_KEY' CON LA DE FIREBASE CONSOLE
  PERFORM net.http_post(
    url := 'https://fcm.googleapis.com/fcm/send',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'key=TU_SERVER_KEY_DE_FIREBASE_AQUI'
    ),
    body := jsonb_build_object(
      'to', target_token,
      'notification', jsonb_build_object(
        'title', CASE WHEN NEW.type = 'message' THEN 'Mensaje de ' || sender_name ELSE 'Venered Social' END,
        'body', NEW.content,
        'sound', 'default',
        'click_action', 'FLUTTER_NOTIFICATION_CLICK'
      ),
      'priority', 'high'
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. ACTIVADORES (TRIGGERS)
DROP TRIGGER IF EXISTS on_message_created_notification ON public.messages;
CREATE TRIGGER on_message_created_notification
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_message_notification();

DROP TRIGGER IF EXISTS on_notification_send_push ON public.notifications;
CREATE TRIGGER on_notification_send_push
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.send_push_notification();

-- 6. HABILITAR EXTENSIÓN DE RED (NECESARIO PARA EL ENVÍO)
CREATE EXTENSION IF NOT EXISTS pg_net;
