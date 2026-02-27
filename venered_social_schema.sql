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

-- 11. POLÍTICAS DE LECTURA PÚBLICA
DROP POLICY IF EXISTS "Permitir lectura de perfiles a todos" ON public.profiles;
CREATE POLICY "Permitir lectura de perfiles a todos" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir lectura de posts a todos" ON public.posts;
CREATE POLICY "Permitir lectura de posts a todos" ON public.posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir lectura de likes a todos" ON public.likes;
CREATE POLICY "Permitir lectura de likes a todos" ON public.likes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir lectura de comentarios a todos" ON public.comments;
CREATE POLICY "Permitir lectura de comentarios a todos" ON public.comments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir lectura de seguidores a todos" ON public.followers;
CREATE POLICY "Permitir lectura de seguidores a todos" ON public.followers FOR SELECT USING (true);

-- 12. DISPARADOR (Trigger) PARA CREAR PERFIL AUTOMÁTICAMENTE AL REGISTRARSE
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, profile_pic_url)
  VALUES (new.id, COALESCE(new.raw_user_meta_data->>'username', 'usuario_' || substr(new.id::text, 1, 5)), NULL);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
