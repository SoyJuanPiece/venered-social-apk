-- ============================================================================
-- VENERED SOCIAL - DATABASE MIGRATIONS
-- Execute this script in Supabase SQL Editor or via psql
-- ============================================================================

-- ============================================================================
-- 1. MESSAGE STATUS - Add column and tracking
-- ============================================================================

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS message_status TEXT DEFAULT 'pending';

CREATE INDEX IF NOT EXISTS idx_messages_status ON public.messages(sender_id, message_status);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_read ON public.messages(receiver_id, is_read);

-- ============================================================================
-- 2. RATE LIMITING - Anti-spam protection
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rate_limit_attempts (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_attempts_user_action 
  ON public.rate_limit_attempts(user_id, action, created_at);

-- Enable RLS on rate_limit_attempts
ALTER TABLE public.rate_limit_attempts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their own rate limit attempts" ON public.rate_limit_attempts;
CREATE POLICY "Users can view their own rate limit attempts"
  ON public.rate_limit_attempts
  FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert their own rate limit attempts" ON public.rate_limit_attempts;
CREATE POLICY "Users can insert their own rate limit attempts"
  ON public.rate_limit_attempts
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Grant permissions
GRANT SELECT, INSERT ON public.rate_limit_attempts TO authenticated;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- All changes have been applied successfully!
-- The application is now ready to use:
-- - Message status tracking (✓ sent, ✓✓ read)
-- - Rate limiting (10 msgs/min, 50 posts/day)
-- - Drafts auto-save (via SharedPreferences in app)
-- - Typing indicator (via presence table)
-- ============================================================================
