-- ========================================================
-- ACTUALIZACIÓN: NOTIFICACIONES PRO (v1.2)
-- Solo lógica de Likes, Comentarios y Control de Spam
-- ========================================================

-- 1. LIMPIEZA DE TRIGGERS VIEJOS (Para evitar duplicados)
DROP TRIGGER IF EXISTS on_notification_send_onesignal ON public.notifications;
DROP TRIGGER IF EXISTS on_comment_created_notification ON public.comments;
DROP TRIGGER IF EXISTS on_like_created_notification ON public.likes;
DROP TRIGGER IF EXISTS on_message_created_notification ON public.messages;

-- 2. FUNCIÓN DE ENVÍO CON CONTROL DE SPAM Y PRIVACIDAD
CREATE OR REPLACE FUNCTION public.send_onesignal_notification()
RETURNS TRIGGER AS $$
DECLARE
  sender_name TEXT;
  notif_text TEXT;
  recent_count INTEGER;
BEGIN
  -- A. Obtener el nombre del remitente
  SELECT COALESCE(username, 'Alguien') INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

  -- B. Lógica de Mensajes (Siempre se notifican)
  IF NEW.type = 'message' THEN
    notif_text := 'Tienes un mensaje de ' || sender_name;
  
  -- C. Lógica de Likes y Comentarios (Control de relevancia: 1 cada 15 min por post)
  ELSIF NEW.type IN ('like', 'comment') THEN
    SELECT count(*) INTO recent_count 
    FROM public.notifications 
    WHERE receiver_id = NEW.receiver_id 
      AND type = NEW.type 
      AND related_id = NEW.related_id
      AND id != NEW.id 
      AND created_at > (NOW() - INTERVAL '15 minutes');

    IF recent_count > 0 THEN RETURN NEW; END IF;

    IF NEW.type = 'like' THEN
      notif_text := sender_name || ' le ha gustado tu publicación';
    ELSE
      notif_text := sender_name || ' ha comentado tu publicación';
    END IF;

  -- D. Seguidores
  ELSIF NEW.type = 'follow' THEN
    notif_text := sender_name || ' ha comenzado a seguirte';
  ELSE
    RETURN NEW;
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. HANDLERS DE CADA TABLA
-- Aseguramos que los comentarios y likes generen la notificación en la DB primero
CREATE OR REPLACE FUNCTION public.handle_new_like_notification()
RETURNS TRIGGER AS $$
DECLARE owner_id UUID;
BEGIN
  SELECT user_id INTO owner_id FROM public.posts WHERE id = NEW.post_id;
  IF owner_id = NEW.user_id THEN RETURN NEW; END IF;
  INSERT INTO public.notifications (receiver_id, sender_id, type, content, related_id)
  VALUES (owner_id, NEW.user_id, 'like', 'like', NEW.post_id);
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
  VALUES (owner_id, NEW.user_id, 'comment', 'comment', NEW.post_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RE-ACTIVAR TRIGGERS
CREATE TRIGGER on_message_created_notification AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.handle_new_message_notification();
CREATE TRIGGER on_like_created_notification AFTER INSERT ON public.likes FOR EACH ROW EXECUTE FUNCTION public.handle_new_like_notification();
CREATE TRIGGER on_comment_created_notification AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION public.handle_new_comment_notification();
CREATE TRIGGER on_notification_send_onesignal AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.send_onesignal_notification();
