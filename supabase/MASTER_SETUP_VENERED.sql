-- ========================================================
-- MASTER SETUP: VENERED SOCIAL (OFICIAL v1.2)
-- Control de SPAM y Notificaciones Relevantes
-- ========================================================

-- 1. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABLAS BASE
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS username TEXT;

-- 3. FUNCIÓN DE ENVÍO CON CONTROL DE SPAM
CREATE OR REPLACE FUNCTION public.send_onesignal_notification()
RETURNS TRIGGER AS $$
DECLARE
  sender_name TEXT;
  notif_text TEXT;
  recent_count INTEGER;
BEGIN
  -- A. MENSAJES: Siempre se notifican (Prioridad alta)
  IF NEW.type = 'message' THEN
    SELECT COALESCE(username, 'Alguien') INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;
    notif_text := 'Tienes un mensaje de ' || sender_name;
  
  -- B. LIKES Y COMENTARIOS: Control de relevancia
  ELSIF NEW.type IN ('like', 'comment') THEN
    -- Verificamos si ya enviamos un push por este MISMO post al MISMO usuario en los últimos 15 minutos
    SELECT count(*) INTO recent_count 
    FROM public.notifications 
    WHERE receiver_id = NEW.receiver_id 
      AND type = NEW.type 
      AND (related_id = NEW.related_id OR related_id IS NULL)
      AND id != NEW.id -- No contarnos a nosotros mismos
      AND created_at > (NOW() - INTERVAL '15 minutes');

    -- Si ya notificamos hace poco, NO enviamos el PUSH (pero la notificación queda guardada en la DB)
    IF recent_count > 0 THEN
      RETURN NEW;
    END IF;

    -- Si es relevante (primero en 15 min), preparamos el texto
    SELECT COALESCE(username, 'Alguien') INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;
    IF NEW.type = 'like' THEN
      notif_text := sender_name || ' le ha gustado tu publicación';
    ELSE
      notif_text := sender_name || ' ha comentado tu publicación';
    END IF;

  -- C. SEGUIDORES: Siempre se notifican (Suele ser menos frecuente que un like)
  ELSIF NEW.type = 'follow' THEN
    SELECT COALESCE(username, 'Alguien') INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;
    notif_text := sender_name || ' ha comenzado a seguirte';
  
  ELSE
    RETURN NEW; -- Tipo desconocido, no enviamos push
  END IF;

  -- ENVIAR A ONESIGNAL
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
      'contents', jsonb_build_object('en', notif_text),
      'priority', 10
    )
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. TRIGGERS DE GENERACIÓN (Misma lógica de inserción)
-- Estos aseguran que el registro SIEMPRE exista en la tabla notifications (la lista de la app)

CREATE OR REPLACE FUNCTION public.handle_new_message_notification()
RETURNS TRIGGER AS $$
DECLARE target_id UUID;
BEGIN
  SELECT CASE WHEN user1_id = NEW.sender_id THEN user2_id ELSE user1_id END 
  INTO target_id FROM public.conversations WHERE id = NEW.conversation_id;
  INSERT INTO public.notifications (receiver_id, sender_id, type, content, related_id)
  VALUES (target_id, NEW.sender_id, 'message', NEW.content, NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.handle_new_like_notification()
RETURNS TRIGGER AS $$
DECLARE owner_id UUID;
BEGIN
  SELECT user_id INTO owner_id FROM public.posts WHERE id = NEW.post_id;
  IF owner_id = NEW.user_id THEN RETURN NEW; END IF;
  INSERT INTO public.notifications (receiver_id, sender_id, type, content, related_id)
  VALUES (owner_id, NEW.user_id, 'like', 'le ha gustado tu publicación', NEW.post_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.handle_new_comment_notification()
RETURNS TRIGGER AS $$
DECLARE owner_id UUID;
BEGIN
  SELECT user_id INTO owner_id FROM public.posts WHERE id = NEW.post_id;
  IF owner_id = NEW.user_id THEN RETURN NEW; END IF;
  INSERT INTO public.notifications (receiver_id, sender_id, type, content, related_id)
  VALUES (owner_id, NEW.user_id, 'comment', 'ha comentado tu publicación', NEW.post_id); -- Usamos post_id para el control de spam
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. VINCULAR TRIGGERS
DROP TRIGGER IF EXISTS on_message_created_notification ON public.messages;
CREATE TRIGGER on_message_created_notification AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.handle_new_message_notification();

DROP TRIGGER IF EXISTS on_like_created_notification ON public.likes;
CREATE TRIGGER on_like_created_notification AFTER INSERT ON public.likes FOR EACH ROW EXECUTE FUNCTION public.handle_new_like_notification();

DROP TRIGGER IF EXISTS on_comment_created_notification ON public.comments;
CREATE TRIGGER on_comment_created_notification AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION public.handle_new_comment_notification();

DROP TRIGGER IF EXISTS on_notification_send_onesignal ON public.notifications;
CREATE TRIGGER on_notification_send_onesignal AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.send_onesignal_notification();

-- 6. SEGURIDAD
DROP POLICY IF EXISTS "Actualizar propio token" ON public.profiles;
CREATE POLICY "Actualizar propio token" ON public.profiles FOR UPDATE USING (auth.uid() = id);
