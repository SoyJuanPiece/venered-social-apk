-- Anti-spam and rate limiting policies
-- This prevents users from sending too many messages/posts

-- Create a function to check rate limits
CREATE OR REPLACE FUNCTION public.check_message_rate_limit()
RETURNS VOID AS $$
DECLARE
  message_count INTEGER;
  last_minute_count INTEGER;
BEGIN
  -- Count messages in last minute
  SELECT COUNT(*) INTO last_minute_count
  FROM public.messages
  WHERE sender_id = auth.uid()
    AND created_at > NOW() - INTERVAL '1 minute';
  
  -- Max 10 messages per minute
  IF last_minute_count >= 10 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 10 messages per minute';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.check_post_rate_limit()
RETURNS VOID AS $$
DECLARE
  post_count_today INTEGER;
BEGIN
  -- Count posts created today
  SELECT COUNT(*) INTO post_count_today
  FROM public.posts
  WHERE user_id = auth.uid()
    AND created_at > NOW() - INTERVAL '24 hours';
  
  -- Max 50 posts per day
  IF post_count_today >= 50 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 50 posts per day';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create rate limit tracking table
CREATE TABLE IF NOT EXISTS public.rate_limit_attempts (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL, -- 'message', 'post', 'like', etc.
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rate_limit_attempts_user_action ON public.rate_limit_attempts(user_id, action, created_at);

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.check_message_rate_limit() TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_post_rate_limit() TO authenticated;
GRANT SELECT, INSERT ON public.rate_limit_attempts TO authenticated;

-- Security: Ensure users can only see and modify their own rate limit data
ALTER TABLE public.rate_limit_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own rate limit attempts"
  ON public.rate_limit_attempts
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own rate limit attempts"
  ON public.rate_limit_attempts
  FOR INSERT
  WITH CHECK (user_id = auth.uid());
