-- ========================================================
-- SISTEMA DE VERIFICACIÓN, MODERACIÓN Y REPORTES
-- ========================================================

-- 1. MEJORAR TABLA DE PERFILES
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user'; -- 'user', 'moderator', 'admin'

-- 2. CREAR TABLA DE REPORTES
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending', -- 'pending', 'reviewed', 'resolved'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. HABILITAR RLS EN REPORTES
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- 4. POLÍTICAS DE SEGURIDAD PARA REPORTES
-- Cualquier usuario autenticado puede crear un reporte
CREATE POLICY "Usuarios pueden reportar" ON public.reports 
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Solo moderadores y admins pueden ver todos los reportes
CREATE POLICY "Moderadores pueden ver reportes" ON public.reports 
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND (role = 'moderator' OR role = 'admin')
        )
    );

-- 5. LÓGICA DE BANEO (TRIGGER)
-- Impedir que un usuario baneado inserte nuevos posts o comentarios
CREATE OR REPLACE FUNCTION public.check_user_banned()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_banned = true
    ) THEN
        RAISE EXCEPTION 'Tu cuenta ha sido suspendida por incumplir las normas de la comunidad.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar el chequeo de baneo a posts y comentarios
DROP TRIGGER IF EXISTS on_post_check_banned ON public.posts;
CREATE TRIGGER on_post_check_banned 
    BEFORE INSERT ON public.posts
    FOR EACH ROW EXECUTE FUNCTION public.check_user_banned();

DROP TRIGGER IF EXISTS on_comment_check_banned ON public.comments;
CREATE TRIGGER on_comment_check_banned 
    BEFORE INSERT ON public.comments
    FOR EACH ROW EXECUTE FUNCTION public.check_user_banned();

-- 6. VISTA PARA MODERADORES (Facilitar el trabajo)
CREATE OR REPLACE VIEW public.moderation_dashboard AS
SELECT 
    r.*,
    p_reporter.username as reporter_username,
    p_reported.username as reported_username,
    posts.content as post_content
FROM public.reports r
LEFT JOIN public.profiles p_reporter ON r.reporter_id = p_reporter.id
LEFT JOIN public.profiles p_reported ON r.reported_user_id = p_reported.id
LEFT JOIN public.posts posts ON r.reported_post_id = posts.id;
