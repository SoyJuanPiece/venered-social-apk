-- ========================================================
-- MASTER SETUP VENERED SOCIAL - VERSION FINAL 7.0 (COMPLETE)
-- ========================================================

-- 1. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. TABLAS BASE
-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    display_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    estado TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_admin BOOLEAN DEFAULT FALSE,
    is_online BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    media_url TEXT,
    type TEXT DEFAULT 'text',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user1_id, user2_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    media_url TEXT,
    type TEXT DEFAULT 'text', -- 'text', 'image', 'voice'
    is_read BOOLEAN DEFAULT FALSE,
    needs_reupload BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    type TEXT DEFAULT 'image',
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours'),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'like', 'comment', 'follow', 'message'
    related_id UUID,
    content TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.verification_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    message TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 3. VISTAS SQL
-- --------------------------------------------------------

CREATE OR REPLACE VIEW public.posts_with_likes_count AS
SELECT p.*, (SELECT count(*)::int FROM public.likes l WHERE l.post_id = p.id) as likes_count, (SELECT count(*)::int FROM public.comments c WHERE c.post_id = p.id) as comments_count, pr.username, pr.avatar_url
FROM public.posts p JOIN public.profiles pr ON p.user_id = pr.id;

CREATE OR REPLACE VIEW public.stories_with_profiles AS
SELECT s.*, p.username, p.avatar_url FROM public.stories s JOIN public.profiles p ON s.user_id = p.id WHERE s.expires_at > NOW();

CREATE OR REPLACE VIEW public.view_conversations AS
WITH last_msgs AS (SELECT DISTINCT ON (conversation_id) conversation_id, content, sender_id, created_at FROM public.messages ORDER BY conversation_id, created_at DESC)
SELECT c.id as conversation_id, c.last_message_at, lm.content as last_message_content, lm.sender_id as last_message_sender_id, p.id as other_user_id, p.username as other_username, p.avatar_url as other_avatar_url
FROM public.conversations c LEFT JOIN last_msgs lm ON c.id = lm.conversation_id JOIN public.profiles p ON (CASE WHEN c.user1_id = auth.uid() THEN c.user2_id ELSE c.user1_id END) = p.id
WHERE c.user1_id = auth.uid() OR c.user2_id = auth.uid();

GRANT SELECT ON public.posts_with_likes_count TO authenticated;
GRANT SELECT ON public.stories_with_profiles TO authenticated;
GRANT SELECT ON public.view_conversations TO authenticated;

-- 4. SEGURIDAD (RLS)
-- --------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura perfiles" ON public.profiles;
CREATE POLICY "Lectura perfiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Update perfiles" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Posts públicos" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Crear posts" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Ver mis chats" ON public.conversations FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Crear chats" ON public.conversations FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Ver mis mensajes" ON public.messages FOR SELECT USING (auth.uid() = sender_id OR auth.uid() IN (SELECT user1_id FROM public.conversations WHERE id = conversation_id) OR auth.uid() IN (SELECT user2_id FROM public.conversations WHERE id = conversation_id));
CREATE POLICY "Enviar mensajes" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Ver historias" ON public.stories FOR SELECT USING (true);
CREATE POLICY "Subir historias" ON public.stories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Ver mis notificaciones" ON public.notifications FOR SELECT USING (auth.uid() = receiver_id);
CREATE POLICY "Solicitar verificacion" ON public.verification_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. FUNCIONES
-- --------------------------------------------------------

-- Crear perfil con ESTADO incluido
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, estado)
  VALUES (
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)), 
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'estado'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Push Notif
CREATE OR REPLACE FUNCTION public.send_fcm_push()
RETURNS TRIGGER AS $$
DECLARE
  receiver_token TEXT;
  sender_name TEXT;
  server_key TEXT := 'TU_SERVER_KEY_AQUÍ'; 
BEGIN
  SELECT fcm_token INTO receiver_token FROM public.user_fcm_tokens WHERE user_id = NEW.receiver_id ORDER BY updated_at DESC LIMIT 1;
  IF receiver_token IS NULL THEN RETURN NEW; END IF;
  SELECT COALESCE(username, 'Alguien') INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;
  PERFORM net.http_post(
    url := 'https://fcm.googleapis.com/fcm/send',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'key=' || server_key),
    body := jsonb_build_object(
      'to', receiver_token,
      'notification', jsonb_build_object(
        'title', CASE WHEN NEW.type = 'message' THEN 'Mensaje de ' || sender_name ELSE 'Venered Social' END,
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

-- 6. REALTIME
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
    tables_to_add TEXT[] := ARRAY['posts', 'messages', 'stories', 'notifications', 'conversations', 'profiles', 'likes', 'comments'];
BEGIN
    FOREACH t_name IN ARRAY tables_to_add LOOP
        BEGIN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t_name);
        EXCEPTION WHEN others THEN NULL;
        END;
    END LOOP;
END $$;
