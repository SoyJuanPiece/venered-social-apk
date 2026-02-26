-- Venered Social - Notifications and Messaging Schema

-- 1. Extend Profiles with FCM Token for Push Notifications
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='fcm_token') THEN
        ALTER TABLE public.profiles ADD COLUMN fcm_token TEXT;
    END IF;

    -- 1a. Add basic presence tracking (online flag + last seen timestamp)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='is_online') THEN
        ALTER TABLE public.profiles ADD COLUMN is_online BOOLEAN DEFAULT FALSE NOT NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='last_seen') THEN
        ALTER TABLE public.profiles ADD COLUMN last_seen TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- 2. Conversations Table
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Conversation Participants Table
CREATE TABLE IF NOT EXISTS public.conversation_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    UNIQUE(conversation_id, user_id)
);

-- 4. Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    is_read BOOLEAN DEFAULT false
);

-- 5. Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL, -- 'like', 'comment', 'follow', 'message'
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    is_read BOOLEAN DEFAULT false
);

-- RLS (Row Level Security)
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 6. RPC: Listar conversaciones de un usuario en un solo llamado
-- Devuelve los metadatos necesarios para el front (otro participante, último mensaje, fecha)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'get_user_conversations'
    ) THEN
        CREATE FUNCTION public.get_user_conversations(p_user_id uuid)
        RETURNS TABLE(
            conversation_id uuid,
            other_user_id uuid,
            other_username text,
            other_avatar_url text,
            last_message_content text,
            last_message_sender_id uuid,
            last_message_created_at timestamptz,
            updated_at timestamptz
        )
        LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
        BEGIN
            RETURN QUERY
            SELECT
                c.id,
                p.id,
                p.username,
                p.avatar_url,
                m.content,
                m.sender_id,
                m.created_at,
                c.last_message_at
            FROM public.conversations c
            JOIN public.conversation_participants cp_user
                ON cp_user.conversation_id = c.id
                AND cp_user.user_id = p_user_id
            JOIN public.conversation_participants cp_other
                ON cp_other.conversation_id = c.id
                AND cp_other.user_id != p_user_id
            JOIN public.profiles p
                ON p.id = cp_other.user_id
            LEFT JOIN LATERAL (
                SELECT content, sender_id, created_at
                FROM public.messages
                WHERE conversation_id = c.id
                ORDER BY created_at DESC
                LIMIT 1
            ) m ON true
            ORDER BY c.last_message_at DESC;
        END;
        $$;
    END IF;
EXCEPTION WHEN duplicate_function THEN NULL; END $$;

-- 7. RPC: Crear/reutilizar conversación entre dos usuarios
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'create_conversation'
    ) THEN
        CREATE FUNCTION public.create_conversation(p_user1 uuid, p_user2 uuid)
        RETURNS uuid
        LANGUAGE plpgsql SECURITY DEFINER AS $$
        DECLARE
            conv_id uuid;
        BEGIN
            -- intentar recuperar una conversación existente
            SELECT c.id INTO conv_id
            FROM public.conversation_participants cp1
            JOIN public.conversation_participants cp2
                ON cp1.conversation_id = cp2.conversation_id
            JOIN public.conversations c
                ON c.id = cp1.conversation_id
            WHERE cp1.user_id = p_user1
              AND cp2.user_id = p_user2
            LIMIT 1;

            IF conv_id IS NOT NULL THEN
                RETURN conv_id;
            END IF;

            -- crear nueva conversación y añadir participantes
            INSERT INTO public.conversations DEFAULT VALUES
            RETURNING id INTO conv_id;

            INSERT INTO public.conversation_participants (conversation_id, user_id)
            VALUES (conv_id, p_user1), (conv_id, p_user2);

            RETURN conv_id;
        END;
        $$;
    END IF;
EXCEPTION WHEN duplicate_function THEN NULL; END $$;

-- Policies for conversation_participants
DO $$ BEGIN
    CREATE POLICY "Users can view their own participants" ON public.conversation_participants
        FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Policies for conversations
DO $$ BEGIN
    CREATE POLICY "Users can view conversations they participate in" ON public.conversations
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM public.conversation_participants
                WHERE conversation_id = public.conversations.id
                AND user_id = auth.uid()
            )
        );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Policies for messages
DO $$ BEGIN
    CREATE POLICY "Users can view messages in their conversations" ON public.messages
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM public.conversation_participants
                WHERE conversation_id = public.messages.conversation_id
                AND user_id = auth.uid()
            )
        );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Users can insert messages in their conversations" ON public.messages
        FOR INSERT WITH CHECK (
            auth.uid() = sender_id AND
            EXISTS (
                SELECT 1 FROM public.conversation_participants
                WHERE conversation_id = public.messages.conversation_id
                AND user_id = auth.uid()
            )
        );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Policies for notifications
DO $$ BEGIN
    CREATE POLICY "Users can view their own notifications" ON public.notifications
        FOR SELECT USING (auth.uid() = receiver_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Users can update their own notifications" ON public.notifications
        FOR UPDATE USING (auth.uid() = receiver_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Policy so that users can modify their own profile (needed for is_online/last_seen etc.)
DO $$ BEGIN
    CREATE POLICY "Users can update their own profile" ON public.profiles
        FOR UPDATE USING (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
