-- ========================================================
-- MASTER SETUP VENERED SOCIAL (VERSION FINAL SUPABASE + FCM)
-- ========================================================

-- 1. Habilitar Extensiones Necesarias
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABLAS CORE DE LA RED SOCIAL
-- --------------------------------------------------------

-- Tabla de Perfiles (Extiende Auth Users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    display_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    estado TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de Publicaciones
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    media_url TEXT,
    type TEXT DEFAULT 'text', -- 'text', 'image', 'video'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de Likes
CREATE TABLE IF NOT EXISTS public.likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

-- Tabla de Comentarios
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de Seguidores
CREATE TABLE IF NOT EXISTS public.followers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- Tabla de Notificaciones
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'like', 'comment', 'follow', 'message'
    related_id UUID, -- post_id o message_id
    content TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de Tokens FCM (Firebase Push)
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 3. HABILITAR REALTIME (Para Chats y Notificaciones)
-- --------------------------------------------------------
ALTER publication supabase_realtime ADD TABLE public.posts;
ALTER publication supabase_realtime ADD TABLE public.likes;
ALTER publication supabase_realtime ADD TABLE public.comments;
ALTER publication supabase_realtime ADD TABLE public.notifications;

-- 4. SEGURIDAD (RLS)
-- --------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Políticas de Perfiles
CREATE POLICY "Perfiles visibles para todos" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Usuarios pueden editar su perfil" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Políticas de Posts
CREATE POLICY "Posts visibles para todos" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Usuarios pueden crear posts" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Políticas de Notificaciones
CREATE POLICY "Ver notificaciones propias" ON public.notifications FOR SELECT USING (auth.uid() = receiver_id);
CREATE POLICY "Sistema puede insertar notificaciones" ON public.notifications FOR INSERT WITH CHECK (true);

-- Políticas de FCM Tokens
CREATE POLICY "Gestión de tokens propia" ON public.user_fcm_tokens FOR ALL USING (auth.uid() = user_id);

-- 5. LÓGICA DE FIREBASE PUSH (FCM)
-- --------------------------------------------------------

CREATE OR REPLACE FUNCTION public.send_fcm_push()
RETURNS TRIGGER AS $$
DECLARE
  receiver_token TEXT;
  sender_name TEXT;
  -- INSTRUCCIÓN: Reemplaza 'TU_SERVER_KEY_AQUÍ' con la clave que empieza por 'AAAA...'
  -- de Firebase Console -> Cloud Messaging (Legacy).
  server_key TEXT := 'TU_SERVER_KEY_AQUÍ'; 
BEGIN
  -- A. Buscar token del receptor
  SELECT fcm_token INTO receiver_token FROM public.user_fcm_tokens 
  WHERE user_id = NEW.receiver_id ORDER BY updated_at DESC LIMIT 1;
  
  IF receiver_token IS NULL THEN RETURN NEW; END IF;

  -- B. Buscar nombre del remitente
  SELECT COALESCE(username, 'Alguien') INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

  -- C. Enviar a Firebase
  PERFORM net.http_post(
    url := 'https://fcm.googleapis.com/fcm/send',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'key=' || server_key
    ),
    body := jsonb_build_object(
      'to', receiver_token,
      'notification', jsonb_build_object(
        'title', CASE 
            WHEN NEW.type = 'message' THEN 'Mensaje de ' || sender_name 
            WHEN NEW.type = 'follow' THEN '¡Nuevo Seguidor!'
            WHEN NEW.type = 'like' THEN 'A alguien le gusta tu foto'
            ELSE 'Venered Social' 
        END,
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

CREATE TRIGGER on_notification_send_fcm
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.send_fcm_push();

-- 6. TRIGGER PARA CREAR PERFIL AUTOMÁTICAMENTE AL REGISTRARSE
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'username', NEW.raw_user_meta_data->>'username');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
