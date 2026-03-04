-- ========================================================
-- MASTER SETUP VENERED SOCIAL - VERSION DEFINITIVA FINAL
-- ESTE ES EL ÚNICO SCRIPT QUE DEBES EJECUTAR
-- ========================================================

-- 1. EXTENSIONES Y LIMPIEZA INICIAL
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. TABLAS BASE (Solo se crean si no existen)
-- --------------------------------------------------------

-- Perfiles
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    display_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    estado TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_admin BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Publicaciones
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    media_url TEXT,
    type TEXT DEFAULT 'text',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Likes
CREATE TABLE IF NOT EXISTS public.likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

-- Comentarios
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seguidores
CREATE TABLE IF NOT EXISTS public.followers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- Mensajería (Chats)
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    media_url TEXT,
    type TEXT DEFAULT 'text',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Historias (Stories)
CREATE TABLE IF NOT EXISTS public.stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    type TEXT DEFAULT 'image',
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours'),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.story_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    viewer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(story_id, viewer_id)
);

-- Posts Guardados
CREATE TABLE IF NOT EXISTS public.saved_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

-- Reportes
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    reported_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notificaciones Generales
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    related_id UUID,
    content TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tokens Push (Firebase)
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 3. VISTAS SQL (REQUERIDAS POR LA APP)
-- --------------------------------------------------------

-- Vista de Posts con contador de Likes
CREATE OR REPLACE VIEW public.posts_with_likes_count AS
SELECT 
    p.*,
    (SELECT count(*)::int FROM public.likes l WHERE l.post_id = p.id) as likes_count,
    (SELECT count(*)::int FROM public.comments c WHERE c.post_id = p.id) as comments_count,
    pr.username,
    pr.avatar_url
FROM public.posts p
JOIN public.profiles pr ON p.user_id = pr.id;

-- Vista de Historias con Perfiles
CREATE OR REPLACE VIEW public.stories_with_profiles AS
SELECT 
    s.*,
    p.username,
    p.avatar_url
FROM public.stories s
JOIN public.profiles p ON s.user_id = p.id
WHERE s.expires_at > NOW();

-- Vista de Conversaciones (Mensajes Agrupados)
CREATE OR REPLACE VIEW public.view_conversations AS
WITH last_messages AS (
    SELECT DISTINCT ON (
        CASE WHEN sender_id < receiver_id THEN sender_id ELSE receiver_id END,
        CASE WHEN sender_id < receiver_id THEN receiver_id ELSE sender_id END
    ) *
    FROM public.messages
    ORDER BY 
        CASE WHEN sender_id < receiver_id THEN sender_id ELSE receiver_id END,
        CASE WHEN sender_id < receiver_id THEN receiver_id ELSE sender_id END,
        created_at DESC
)
SELECT 
    m.*,
    p.username as other_username,
    p.avatar_url as other_avatar_url
FROM last_messages m
JOIN public.profiles p ON (CASE WHEN m.sender_id = auth.uid() THEN m.receiver_id ELSE m.sender_id END) = p.id;

-- Dar permisos explícitos a las vistas
GRANT SELECT ON public.posts_with_likes_count TO authenticated;
GRANT SELECT ON public.stories_with_profiles TO authenticated;
GRANT SELECT ON public.view_conversations TO authenticated;

-- 4. SEGURIDAD (RLS)
-- --------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lectura pública perfiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Auto gestión perfiles" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Posts públicos" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Crear posts" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Lectura mensajes" ON public.messages FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Enviar mensajes" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Historias públicas" ON public.stories FOR SELECT USING (true);
CREATE POLICY "Subir historias" ON public.stories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Ver notificaciones" ON public.notifications FOR SELECT USING (auth.uid() = receiver_id);
CREATE POLICY "Mis tokens" ON public.user_fcm_tokens FOR ALL USING (auth.uid() = user_id);

-- 5. FUNCIONES Y TRIGGERS
-- --------------------------------------------------------

-- Crear perfil automáticamente al registrar usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)), NEW.raw_user_meta_data->>'username');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Notificación de mensaje automática
CREATE OR REPLACE FUNCTION public.handle_new_message_notif()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (receiver_id, sender_id, type, related_id, content)
  VALUES (NEW.receiver_id, NEW.sender_id, 'message', NEW.id, 'Te ha enviado un mensaje');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_message_created ON public.messages;
CREATE TRIGGER on_message_created AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.handle_new_message_notif();

-- Envío Push Firebase (FCM)
CREATE OR REPLACE FUNCTION public.send_fcm_push()
RETURNS TRIGGER AS $$
DECLARE
  receiver_token TEXT;
  sender_name TEXT;
  -- INSTRUCCIÓN: Reemplaza con tu Server Key de Firebase (Legacy API)
  server_key TEXT := 'PONER_AQUÍ_TU_SERVER_KEY'; 
BEGIN
  SELECT fcm_token INTO receiver_token FROM public.user_fcm_tokens 
  WHERE user_id = NEW.receiver_id ORDER BY updated_at DESC LIMIT 1;
  
  IF receiver_token IS NULL THEN RETURN NEW; END IF;

  SELECT COALESCE(username, 'Alguien') INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

  PERFORM net.http_post(
    url := 'https://fcm.googleapis.com/fcm/send',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'key=' || server_key),
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
        'sound', 'default'
      ),
      'priority', 'high'
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_notification_send_fcm ON public.notifications;
CREATE TRIGGER on_notification_send_fcm AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.send_fcm_push();

-- 6. ALMACENAMIENTO (STORAGE BUCKETS)
-- --------------------------------------------------------
INSERT INTO storage.buckets (id, name, public) VALUES ('media', 'media', true) ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Subida libre" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'media');
CREATE POLICY "Lectura libre" ON storage.objects FOR SELECT USING (bucket_id = 'media');

-- 7. HABILITAR REALTIME (Seguro)
-- --------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
END $$;

DO $$
DECLARE
    t_name TEXT;
    tables_to_add TEXT[] := ARRAY['posts', 'messages', 'stories', 'notifications', 'comments', 'likes', 'profiles'];
BEGIN
    FOREACH t_name IN ARRAY tables_to_add LOOP
        BEGIN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t_name);
        EXCEPTION WHEN duplicate_object THEN NULL;
        END;
    END LOOP;
END $$;
