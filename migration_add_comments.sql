-- Migration: Add comments table and update view (FIXED for Joins)

-- 1. Create comments table pointing to PROFILES instead of AUTH.USERS for automatic joins
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, -- Changed to public.profiles
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

COMMENT ON TABLE public.comments IS 'Stores user comments on posts.';

-- 2. Enable RLS
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- 3. Policies
CREATE POLICY "Comments are viewable by everyone."
ON public.comments FOR SELECT
USING (true);

CREATE POLICY "Authenticated users can create comments."
ON public.comments FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments."
ON public.comments FOR DELETE
USING (auth.uid() = user_id);

-- 4. Update view to include comments count
DROP VIEW IF EXISTS public.posts_with_likes_count;

CREATE OR REPLACE VIEW public.posts_with_likes_count AS
SELECT
    p.id,
    p.user_id,
    p.image_url,
    p.description,
    p.created_at,
    count(DISTINCT l.id) AS likes_count,
    count(DISTINCT c.id) AS comments_count,
    EXISTS (SELECT 1 FROM public.likes WHERE post_id = p.id AND user_id = auth.uid()) AS is_liked_by_user,
    json_build_object(
        'username', pr.username,
        'profile_pic_url', pr.profile_pic_url
    ) AS profiles
FROM
    public.posts p
LEFT JOIN
    public.likes l ON p.id = l.post_id
LEFT JOIN
    public.comments c ON p.id = c.post_id
LEFT JOIN
    public.profiles pr ON p.user_id = pr.id
GROUP BY
    p.id, p.user_id, p.image_url, p.description, p.created_at, pr.username, pr.profile_pic_url;
