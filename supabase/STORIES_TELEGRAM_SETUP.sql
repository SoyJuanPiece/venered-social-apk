-- ==========================================
-- CONFIGURACIÓN DE HISTORIAS (TELEGRAM STORAGE)
-- ==========================================

-- 1. Crear la tabla de historias
CREATE TABLE IF NOT EXISTS public.stories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    file_id TEXT NOT NULL, -- El ID que nos da Telegram
    media_type TEXT CHECK (media_type IN ('photo', 'video')) NOT NULL,
    thumbnail_url TEXT, -- Opcional: para mostrar una previsualización rápida
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (timezone('utc'::text, now()) + interval '24 hours') NOT NULL
);

-- 2. Habilitar RLS (Seguridad de filas)
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de seguridad
-- Cualquiera puede ver las historias (o solo seguidores, según tu lógica actual)
CREATE POLICY "Stories son visibles para todos los usuarios autenticados" 
ON public.stories FOR SELECT 
USING (true);

-- Solo el dueño puede subir sus propias historias
CREATE POLICY "Usuarios pueden subir sus propias historias" 
ON public.stories FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Solo el dueño puede borrar sus historias si quiere
CREATE POLICY "Usuarios pueden borrar sus propias historias" 
ON public.stories FOR DELETE 
USING (auth.uid() = user_id);

-- 4. Unir con perfiles (Muy útil para el StoriesBar)
-- Esto permite traer el username y la foto de perfil en una sola consulta
CREATE OR REPLACE VIEW stories_with_profiles AS
SELECT 
    s.*,
    p.username,
    p.profile_pic_url,
    p.is_verified
FROM public.stories s
JOIN public.profiles p ON s.user_id = p.id
WHERE s.expires_at > now() -- Solo traer las que NO han expirado
ORDER BY s.created_at DESC;
