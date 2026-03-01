-- ========================================================
-- MASTER SETUP: VENERED SOCIAL (OFICIAL v1.3)
-- El script definitivo para configurar TODO el backend.
-- Incluye: Regionalización, Notificaciones Pro, Verificación y Moderación.
-- ========================================================

-- 1. EXTENSIONES Y SEGURIDAD INICIAL
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. PREPARAR TABLA DE PERFILES (Columnas Críticas)
DO $$ 
BEGIN
    -- Identidad y Notificaciones
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='username') THEN
        ALTER TABLE public.profiles ADD COLUMN username TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='fcm_token') THEN
        ALTER TABLE public.profiles ADD COLUMN fcm_token TEXT;
    END IF;

    -- Regionalización (Venezuela)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='estado') THEN
        ALTER TABLE public.profiles ADD COLUMN estado TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='last_state_change') THEN
        ALTER TABLE public.profiles ADD COLUMN last_state_change TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Seguridad y Moderación
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='is_verified') THEN
        ALTER TABLE public.profiles ADD COLUMN is_verified BOOLEAN DEFAULT false;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='is_banned') THEN
        ALTER TABLE public.profiles ADD COLUMN is_banned BOOLEAN DEFAULT false;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='role') THEN
        ALTER TABLE public.profiles ADD COLUMN role TEXT DEFAULT 'user'; -- 'user', 'moderator', 'admin'
    END IF;
END $$;

-- 3. TABLAS DE SOPORTE (Reportes y Verificaciones)
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending', 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.verification_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    category TEXT NOT NULL, 
    message TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

-- 4. POLÍTICAS DE SEGURIDAD (RLS)
-- Perfiles
DROP POLICY IF EXISTS "Actualizar propio perfil" ON public.profiles;
CREATE POLICY "Actualizar propio perfil" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Reportes
DROP POLICY IF EXISTS "Usuarios pueden reportar" ON public.reports;
CREATE POLICY "Usuarios pueden reportar" ON public.reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "Moderadores ven reportes" ON public.reports;
CREATE POLICY "Moderadores ven reportes" ON public.reports FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role IN ('moderator', 'admin')))
);

-- Verificaciones
DROP POLICY IF EXISTS "Usuarios pueden solicitar" ON public.verification_requests;
CREATE POLICY "Usuarios pueden solicitar" ON public.verification_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Moderadores gestionan verif" ON public.verification_requests;
CREATE POLICY "Moderadores gestionan verif" ON public.verification_requests FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role IN ('moderator', 'admin')))
);

-- 5. LÓGICA DE ENVÍO A ONESIGNAL (Notificaciones Inteligentes)
CREATE OR REPLACE FUNCTION public.send_onesignal_notification()
RETURNS TRIGGER AS $$
DECLARE
  sender_name TEXT;
  notif_text TEXT;
  recent_count INTEGER;
BEGIN
  -- Obtener el nombre del remitente
  SELECT COALESCE(username, 'Alguien') INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

  -- A. MENSAJES (Siempre)
  IF NEW.type = 'message' THEN
    notif_text := 'Tienes un mensaje de ' || sender_name;
  
  -- B. LIKES Y COMENTARIOS (Spam Control: 1 cada 15 min)
  ELSIF NEW.type IN ('like', 'comment') THEN
    SELECT count(*) INTO recent_count FROM public.notifications 
    WHERE receiver_id = NEW.receiver_id AND type = NEW.type AND (related_id = NEW.related_id)
      AND id != NEW.id AND created_at > (NOW() - INTERVAL '15 minutes');

    IF recent_count > 0 THEN RETURN NEW; END IF;
    notif_text := sender_name || CASE WHEN NEW.type = 'like' THEN ' le ha gustado tu post' ELSE ' ha comentado tu post' END;

  -- C. SEGUIDORES
  ELSIF NEW.type = 'follow' THEN
    notif_text := sender_name || ' ha comenzado a seguirte';
  ELSE
    RETURN NEW;
  END IF;

  -- ENVÍO POST
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
      'contents', jsonb_build_object('en', notif_text)
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. TRIGGERS DE NEGOCIO (Estados, Baneo, Notificaciones)

-- Regla de 7 días para Estados
CREATE OR REPLACE FUNCTION public.check_state_change_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.estado IS NOT NULL AND OLD.estado IS DISTINCT FROM NEW.estado THEN
    IF OLD.last_state_change > (NOW() - INTERVAL '7 days') THEN
      RAISE EXCEPTION 'Solo puedes cambiar tu estado una vez cada 7 días.';
    END IF;
    NEW.last_state_change := NOW();
  END IF;
  IF OLD.estado IS NULL AND NEW.estado IS NOT NULL THEN NEW.last_state_change := NOW(); END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Anti-Baneo
CREATE OR REPLACE FUNCTION public.check_user_status()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_banned = true) THEN
        RAISE EXCEPTION 'Cuenta suspendida.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. ACTIVACIÓN DE TRIGGERS
DROP TRIGGER IF EXISTS on_state_limit ON public.profiles;
CREATE TRIGGER on_state_limit BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.check_state_change_limit();

DROP TRIGGER IF EXISTS on_post_ban ON public.posts;
CREATE TRIGGER on_post_ban BEFORE INSERT ON public.posts FOR EACH ROW EXECUTE FUNCTION public.check_user_status();

DROP TRIGGER IF EXISTS on_notif_send ON public.notifications;
CREATE TRIGGER on_notif_send AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.send_onesignal_notification();

-- 8. VISTAS DE ADMINISTRACIÓN
CREATE OR REPLACE VIEW public.moderation_dashboard AS
SELECT 
    r.*,
    p_reporter.username as reporter_username,
    p_reported.username as reported_username,
    posts.description as post_content
FROM public.reports r
LEFT JOIN public.profiles p_reporter ON r.reporter_id = p_reporter.id
LEFT JOIN public.profiles p_reported ON r.reported_user_id = p_reported.id
LEFT JOIN public.posts posts ON r.reported_post_id = posts.id;

-- 9. FUNCIÓN DE APROBACIÓN
CREATE OR REPLACE FUNCTION public.approve_verification(request_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.profiles SET is_verified = true 
    WHERE id = (SELECT user_id FROM public.verification_requests WHERE id = request_id);
    UPDATE public.verification_requests SET status = 'approved' WHERE id = request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
