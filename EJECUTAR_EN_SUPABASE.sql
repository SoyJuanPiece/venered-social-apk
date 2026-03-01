-- ==========================================
-- SQL FINAL PARA VENERED SOCIAL v1.0
-- (Copia y pega todo esto en Supabase)
-- ==========================================

-- 1. Permitir guardar el Token del teléfono
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 2. Asegurar que cada usuario pueda actualizar su propio token
DROP POLICY IF EXISTS "Usuarios actualizan su token" ON public.profiles;
CREATE POLICY "Usuarios actualizan su token" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 3. Trigger para Notificaciones de Chat
CREATE OR REPLACE FUNCTION public.handle_new_message_notification()
RETURNS TRIGGER AS $$
DECLARE
  target_id UUID;
BEGIN
  -- Buscar al otro usuario
  SELECT CASE WHEN user1_id = NEW.sender_id THEN user2_id ELSE user1_id END 
  INTO target_id FROM public.conversations WHERE id = NEW.conversation_id;

  -- Crear la notificación
  INSERT INTO public.notifications (receiver_id, sender_id, type, content, related_id)
  VALUES (target_id, NEW.sender_id, 'message', NEW.content, NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_message_created_notification ON public.messages;
CREATE TRIGGER on_message_created_notification
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_message_notification();

-- 4. Trigger para Likes
CREATE OR REPLACE FUNCTION public.handle_new_like_notification()
RETURNS TRIGGER AS $$
DECLARE
  owner_id UUID;
BEGIN
  SELECT user_id INTO owner_id FROM public.posts WHERE id = NEW.post_id;
  IF owner_id = NEW.user_id THEN RETURN NEW; END IF;

  INSERT INTO public.notifications (receiver_id, sender_id, type, content, related_id)
  VALUES (owner_id, NEW.user_id, 'like', 'le ha gustado tu publicación', NEW.post_id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_like_created_notification ON public.likes;
CREATE TRIGGER on_like_created_notification
  AFTER INSERT ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_like_notification();

-- 5. Trigger para Seguidores
CREATE OR REPLACE FUNCTION public.handle_new_follow_notification()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (receiver_id, sender_id, type, content, related_id)
  VALUES (NEW.following_id, NEW.follower_id, 'follow', 'ha comenzado a seguirte', NEW.follower_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_follow_created_notification ON public.followers;
CREATE TRIGGER on_follow_created_notification
  AFTER INSERT ON public.followers
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_follow_notification();
