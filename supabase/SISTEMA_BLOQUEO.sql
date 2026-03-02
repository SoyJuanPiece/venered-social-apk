-- ========================================================
-- SISTEMA DE BLOQUEO ENTRE USUARIOS
-- ========================================================

-- 1. CREAR TABLA DE BLOQUEOS
CREATE TABLE IF NOT EXISTS public.blocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);

-- 2. HABILITAR RLS
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

-- 3. POLÍTICAS
CREATE POLICY "Usuarios pueden bloquear" ON public.blocks 
    FOR INSERT WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Usuarios pueden ver sus bloqueados" ON public.blocks 
    FOR SELECT USING (auth.uid() = blocker_id);

CREATE POLICY "Usuarios pueden desbloquear" ON public.blocks 
    FOR DELETE USING (auth.uid() = blocker_id);

-- 4. ACTUALIZAR VISTA DEL FEED (Para ocultar posts de bloqueados)
-- Esta función filtrará automáticamente cualquier consulta para que no veas a quien bloqueaste
-- ni a quien te bloqueó.
CREATE OR REPLACE VIEW public.posts_v2 AS
SELECT p.*
FROM public.posts_with_likes_count p
WHERE p.user_id NOT IN (
    SELECT blocked_id FROM public.blocks WHERE blocker_id = auth.uid()
) AND p.user_id NOT IN (
    SELECT blocker_id FROM public.blocks WHERE blocked_id = auth.uid()
);
