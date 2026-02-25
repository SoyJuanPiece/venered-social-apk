-- Create a view to get posts with their like counts and check if the current user liked it
CREATE OR REPLACE VIEW public.posts_with_likes_count AS
SELECT
    p.id,
    p.user_id,
    p.image_url,
    p.description,
    p.created_at,
    count(l.id) AS likes_count,
    EXISTS (SELECT 1 FROM public.likes WHERE post_id = p.id AND user_id = auth.uid()) AS is_liked_by_user
FROM
    public.posts p
LEFT JOIN
    public.likes l ON p.id = l.post_id
GROUP BY
    p.id, p.user_id, p.image_url, p.description, p.created_at;