-- ==========================================
-- SCRIPT DE CREACIÓN DE BASE DE DATOS
-- PROYECTO: VENERED SOCIAL
-- ==========================================

-- 1. TABLA DE PERFILES (Extiende la autenticación de Supabase)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT, -- Antigua columna por compatibilidad
  profile_pic_url TEXT, -- Nueva columna usada en el rediseño
  bio TEXT,
  website TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABLA DE POSTS
CREATE TABLE IF NOT EXISTS public.posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  image_url TEXT,
  image_deletehash TEXT,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABLA DE LIKES
CREATE TABLE IF NOT EXISTS public.likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- 4. TABLA DE COMENTARIOS
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TABLA DE SEGUIDORES (Followers)
CREATE TABLE IF NOT EXISTS public.followers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- 6. TABLA DE POSTS GUARDADOS (Saved Posts)
CREATE TABLE IF NOT EXISTS public.saved_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- 7. TABLA DE CONVERSACIONES (Mensajería)
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user1_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  user2_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. TABLA DE MENSAJES
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. VISTA PARA EL FEED (Crucial para que la App no falle)
-- Esta vista une los posts con la info del perfil y cuenta likes/comentarios automáticamente
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

-- 10. HABILITAR RLS (Row Level Security)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 11. POLÍTICAS DE RLS (Seguridad)

-- Perfiles: Todos pueden ver, solo el dueño puede editar
DROP POLICY IF EXISTS "Permitir lectura de perfiles a todos" ON public.profiles;
CREATE POLICY "Permitir lectura de perfiles a todos" ON public.profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Permitir actualización a dueños" ON public.profiles;
CREATE POLICY "Permitir actualización a dueños" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Posts: Todos pueden ver, solo el dueño puede crear/borrar
DROP POLICY IF EXISTS "Permitir lectura de posts a todos" ON public.posts;
CREATE POLICY "Permitir lectura de posts a todos" ON public.posts FOR SELECT USING (true);
DROP POLICY IF EXISTS "Permitir creación a autenticados" ON public.posts;
CREATE POLICY "Permitir creación a autenticados" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Permitir borrado a dueños" ON public.posts;
CREATE POLICY "Permitir borrado a dueños" ON public.posts FOR DELETE USING (auth.uid() = user_id);

-- Likes: Todos pueden ver, solo autenticados pueden dar/quitar like
DROP POLICY IF EXISTS "Permitir lectura de likes a todos" ON public.likes;
CREATE POLICY "Permitir lectura de likes a todos" ON public.likes FOR SELECT USING (true);
DROP POLICY IF EXISTS "Permitir dar like a autenticados" ON public.likes;
CREATE POLICY "Permitir dar like a autenticados" ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Permitir quitar like a dueños" ON public.likes;
CREATE POLICY "Permitir quitar like a dueños" ON public.likes FOR DELETE USING (auth.uid() = user_id);

-- Seguidores: Todos pueden ver, solo autenticados pueden seguir/dejar de seguir
DROP POLICY IF EXISTS "Permitir lectura de seguidores a todos" ON public.followers;
CREATE POLICY "Permitir lectura de seguidores a todos" ON public.followers FOR SELECT USING (true);
DROP POLICY IF EXISTS "Permitir seguir a autenticados" ON public.followers;
CREATE POLICY "Permitir seguir a autenticados" ON public.followers FOR INSERT WITH CHECK (auth.uid() = follower_id);
DROP POLICY IF EXISTS "Permitir dejar de seguir a dueños" ON public.followers;
CREATE POLICY "Permitir dejar de seguir a dueños" ON public.followers FOR DELETE USING (auth.uid() = follower_id);

-- Conversaciones: Solo los participantes pueden ver/crear
DROP POLICY IF EXISTS "Usuarios pueden ver sus conversaciones" ON public.conversations;
CREATE POLICY "Usuarios pueden ver sus conversaciones" ON public.conversations FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
DROP POLICY IF EXISTS "Usuarios pueden crear conversaciones" ON public.conversations;
CREATE POLICY "Usuarios pueden crear conversaciones" ON public.conversations FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Mensajes: Solo los participantes de la conversación pueden ver/enviar
DROP POLICY IF EXISTS "Usuarios pueden ver mensajes de sus chats" ON public.messages;
CREATE POLICY "Usuarios pueden ver mensajes de sus chats" ON public.messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.conversations 
    WHERE id = conversation_id AND (user1_id = auth.uid() OR user2_id = auth.uid())
  )
);
DROP POLICY IF EXISTS "Usuarios pueden enviar mensajes" ON public.messages;
CREATE POLICY "Usuarios pueden enviar mensajes" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- 12. DISPARADOR (Trigger) PARA CREAR PERFIL AUTOMÁTICAMENTE AL REGISTRARSE
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, profile_pic_url)
  VALUES (new.id, COALESCE(new.raw_user_meta_data->>'username', 'usuario_' || substr(new.id::text, 1, 5)), NULL);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. ACTIVAR REALTIME PARA LAS TABLAS CRÍTICAS
-- Esto es lo que permite que .stream() funcione en la App
begin;
  -- Eliminar si ya existían para evitar errores
  alter publication supabase_realtime drop table if exists public.messages;
  alter publication supabase_realtime drop table if exists public.conversations;
  alter publication supabase_realtime drop table if exists public.notifications;
  alter publication supabase_realtime drop table if exists public.profiles;

  -- Añadir tablas a la publicación de tiempo real
  alter publication supabase_realtime add table public.messages;
  alter publication supabase_realtime add table public.conversations;
  alter publication supabase_realtime add table public.notifications;
  alter publication supabase_realtime add table public.profiles;
commit;

-- 14. TRIGGER PARA ACTUALIZAR LA CONVERSACIÓN AUTOMÁTICAMENTE
-- Cada vez que llegue un mensaje, la conversación se marcará como actualizada
CREATE OR REPLACE FUNCTION public.update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations
  SET last_message_at = NOW()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_message_update_chat ON public.messages;
CREATE TRIGGER on_message_update_chat
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.update_conversation_timestamp();
