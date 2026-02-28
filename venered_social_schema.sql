-- ==========================================
-- SCRIPT MAESTRO DE BASE DE DATOS (v1.0 OFICIAL)
-- PROYECTO: VENERED SOCIAL
-- ==========================================

-- 0. LIMPIEZA PREVIA
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

DROP VIEW IF EXISTS public.view_conversations;
DROP VIEW IF EXISTS public.posts_with_likes_count;
DROP TABLE IF EXISTS public.notifications;
DROP TABLE IF EXISTS public.messages;
DROP TABLE IF EXISTS public.conversations;
DROP TABLE IF EXISTS public.saved_posts;
DROP TABLE IF EXISTS public.followers;
DROP TABLE IF EXISTS public.comments;
DROP TABLE IF EXISTS public.likes;
DROP TABLE IF EXISTS public.posts;
DROP TABLE IF EXISTS public.profiles;

-- 1. TABLA DE PERFILES
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  profile_pic_url TEXT,
  bio TEXT,
  website TEXT,
  is_online BOOLEAN DEFAULT FALSE,
  last_seen TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABLA DE POSTS
CREATE TABLE public.posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  image_url TEXT,
  image_deletehash TEXT,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABLA DE LIKES
CREATE TABLE public.likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- 4. TABLA DE COMENTARIOS
CREATE TABLE public.comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TABLA DE SEGUIDORES
CREATE TABLE public.followers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- 6. TABLA DE POSTS GUARDADOS (Agregada de nuevo)
CREATE TABLE public.saved_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- 7. TABLA DE CONVERSACIONES
CREATE TABLE public.conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user1_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  user2_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. TABLA DE MENSAJES
CREATE TABLE public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. TABLA DE NOTIFICACIONES
CREATE TABLE public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL, -- 'follow', 'message', 'like'
  content TEXT,
  related_id UUID,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. VISTAS OPTIMIZADAS

-- Vista Feed
CREATE OR REPLACE VIEW public.posts_with_likes_count AS
SELECT 
  p.*,
  pr.username,
  pr.profile_pic_url,
  (SELECT COUNT(*) FROM public.likes l WHERE l.post_id = p.id) as likes_count,
  (SELECT COUNT(*) FROM public.comments c WHERE c.post_id = p.id) as comments_count,
  EXISTS (
    SELECT 1 FROM public.likes l 
    WHERE l.post_id = p.id AND l.user_id = auth.uid()
  ) as is_liked_by_user,
  EXISTS (
    SELECT 1 FROM public.saved_posts s 
    WHERE s.post_id = p.id AND s.user_id = auth.uid()
  ) as is_saved_by_user,
  pr.id as author_id
FROM public.posts p
JOIN public.profiles pr ON p.user_id = pr.id;

-- Vista de Conversaciones
CREATE OR REPLACE VIEW public.view_conversations 
WITH (security_invoker = true) AS
SELECT 
  c.id as conversation_id,
  c.last_message_at,
  CASE 
    WHEN c.user1_id = auth.uid() THEN c.user2_id 
    ELSE c.user1_id 
  END as other_user_id,
  COALESCE(
    CASE WHEN c.user1_id = auth.uid() THEN p2.username ELSE p1.username END,
    'Usuario desconocido'
  ) as other_username,
  CASE 
    WHEN c.user1_id = auth.uid() THEN p2.profile_pic_url 
    ELSE p1.profile_pic_url 
  END as other_avatar_url,
  m.content as last_message_content,
  m.sender_id as last_message_sender_id
FROM public.conversations c
LEFT JOIN public.profiles p1 ON c.user1_id = p1.id
LEFT JOIN public.profiles p2 ON c.user2_id = p2.id
LEFT JOIN LATERAL (
  SELECT content, sender_id 
  FROM public.messages 
  WHERE conversation_id = c.id 
  ORDER BY created_at DESC 
  LIMIT 1
) m ON true
WHERE c.user1_id = auth.uid() OR c.user2_id = auth.uid();

-- 11. HABILITAR RLS Y POLÍTICAS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_posts ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Lectura perfiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Lectura posts" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Lectura likes" ON public.likes FOR SELECT USING (true);
CREATE POLICY "Lectura followers" ON public.followers FOR SELECT USING (true);
CREATE POLICY "Lectura saved_posts" ON public.saved_posts FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Edición perfil propio" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Creación posts propios" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Borrado posts propios" ON public.posts FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Ver sus propias conversaciones" ON public.conversations FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Crear conversaciones" ON public.conversations FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Ver mensajes de sus chats" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.conversations WHERE id = conversation_id AND (user1_id = auth.uid() OR user2_id = auth.uid()))
);
CREATE POLICY "Enviar mensajes" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Ver notificaciones propias" ON public.notifications FOR SELECT USING (auth.uid() = receiver_id);

-- 12. TRIGGERS

CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, profile_pic_url)
  VALUES (
    new.id, 
    COALESCE(new.raw_user_meta_data->>'username', 'usuario_' || substr(new.id::text, 1, 5)), 
    NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations SET last_message_at = NOW() WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_message_update_chat ON public.messages;
CREATE TRIGGER on_message_update_chat
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.update_conversation_timestamp();

-- 13. REALTIME
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages, public.conversations, public.notifications, public.profiles;
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
END $$;
