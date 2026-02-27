-- This script will delete all data from the tables in the database.
-- It will not delete the tables themselves and will not fail if a table does not exist.

DO $$ BEGIN
  TRUNCATE TABLE public.posts RESTART IDENTITY CASCADE;
EXCEPTION
  WHEN UNDEFINED_TABLE THEN
    RAISE NOTICE 'Table public.posts does not exist. Skipping truncation.';
END $$;

DO $$ BEGIN
  TRUNCATE TABLE public.comments RESTART IDENTITY CASCADE;
EXCEPTION
  WHEN UNDEFINED_TABLE THEN
    RAISE NOTICE 'Table public.comments does not exist. Skipping truncation.';
END $$;

DO $$ BEGIN
  TRUNCATE TABLE public.followers RESTART IDENTITY CASCADE;
EXCEPTION
  WHEN UNDEFINED_TABLE THEN
    RAISE NOTICE 'Table public.followers does not exist. Skipping truncation.';
END $$;

DO $$ BEGIN
  TRUNCATE TABLE public.conversations RESTART IDENTITY CASCADE;
EXCEPTION
  WHEN UNDEFINED_TABLE THEN
    RAISE NOTICE 'Table public.conversations does not exist. Skipping truncation.';
END $$;

DO $$ BEGIN
  TRUNCATE TABLE public.conversation_participants RESTART IDENTITY CASCADE;
EXCEPTION
  WHEN UNDEFINED_TABLE THEN
    RAISE NOTICE 'Table public.conversation_participants does not exist. Skipping truncation.';
END $$;

DO $$ BEGIN
  TRUNCATE TABLE public.messages RESTART IDENTITY CASCADE;
EXCEPTION
  WHEN UNDEFINED_TABLE THEN
    RAISE NOTICE 'Table public.messages does not exist. Skipping truncation.';
END $$;

DO $$ BEGIN
  TRUNCATE TABLE public.notifications RESTART IDENTITY CASCADE;
EXCEPTION
  WHEN UNDEFINED_TABLE THEN
    RAISE NOTICE 'Table public.notifications does not exist. Skipping truncation.';
END $$;

-- Note: This script does not truncate the 'profiles' table, as this
-- is managed by Supabase Auth and contains user information.
-- If you want to delete all users, you should do this from the
-- Supabase dashboard.

-- Important: If any of the above tables (e.g., public.conversations) are intended to exist
-- but are consistently reported as "does not exist", it indicates that the
-- database schema has not been fully applied. Please ensure you have run
-- all necessary schema migration scripts (e.g., notifications_messages_schema.sql)
-- against your database.