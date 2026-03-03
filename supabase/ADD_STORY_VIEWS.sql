-- ========================================================
-- SISTEMA DE VISTAS DE HISTORIAS
-- Ejecuta este script en el SQL Editor de Supabase
-- ========================================================

-- 1. Crear tabla de vistas
CREATE TABLE IF NOT EXISTS public.story_views (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    story_id UUID REFERENCES public.stories(id) ON DELETE CASCADE NOT NULL,
    viewer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(story_id, viewer_id)
);

-- 2. Habilitar RLS
ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de seguridad
-- El dueño de la historia puede ver la lista de quién la vió
CREATE POLICY "Usuarios pueden ver quién vio sus historias" 
ON public.story_views FOR SELECT 
USING (auth.uid() IN (SELECT user_id FROM public.stories WHERE id = story_id));

-- Cualquier usuario puede registrar que vio una historia
CREATE POLICY "Usuarios pueden registrar sus propias vistas" 
ON public.story_views FOR INSERT 
WITH CHECK (auth.uid() = viewer_id);
