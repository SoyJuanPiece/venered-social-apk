-- Migration to fix foreign key in public.posts table
-- Changes posts.user_id to reference public.profiles(id) instead of auth.users(id)
-- This creates a direct foreign key relationship that PostgREST can easily infer.

BEGIN;

-- 1. Drop the existing foreign key constraint if it exists
--    Find the constraint name dynamically or use a known name if standard.
--    In this case, it's typically 'posts_user_id_fkey'.
ALTER TABLE public.posts
DROP CONSTRAINT IF EXISTS posts_user_id_fkey;

-- 2. Add a new foreign key constraint referencing public.profiles(id)
ALTER TABLE public.posts
ADD CONSTRAINT posts_user_id_fkey
FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

COMMIT;

-- After running this SQL, remember to refresh the PostgREST schema in your Supabase project settings:
-- Go to Settings -> API -> click "Refresh PostgREST schema".
