-- Add message_status column to messages table
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS message_status TEXT DEFAULT 'pending';

-- Create enum type for status
CREATE TYPE public.message_status_enum AS ENUM ('pending', 'sent', 'delivered', 'read');

-- Update existing column to use enum (optional, if using strict enums)
-- ALTER TABLE public.messages ALTER COLUMN message_status TYPE public.message_status_enum USING message_status::public.message_status_enum;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_messages_status ON public.messages(sender_id, message_status);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_read ON public.messages(receiver_id, is_read);
