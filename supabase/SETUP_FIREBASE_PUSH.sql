-- ========================================================
-- SETUP FIREBASE PUSH (FCM)
-- ========================================================

-- 1. Tabla para guardar los tokens de los dispositivos
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Permisos de RLS para la tabla de tokens
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden gestionar sus propios tokens"
ON public.user_fcm_tokens FOR ALL
USING (auth.uid() = user_id);

-- 2. Limpieza de OneSignal (Por si acaso)
DROP TRIGGER IF EXISTS on_notification_send_onesignal ON public.notifications;
DROP FUNCTION IF EXISTS public.send_onesignal_notification();

-- 3. NOTA IMPORTANTE:
-- Para enviar a Firebase directamente desde SQL se requiere configurar
-- la autenticación OAuth2 de Google. 
-- Se recomienda usar una Supabase Edge Function para el envío real.
