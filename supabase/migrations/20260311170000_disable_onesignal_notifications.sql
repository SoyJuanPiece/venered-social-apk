-- Disable legacy OneSignal push pipeline.
-- Project now uses Firebase Cloud Messaging (FCM).

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'notifications'
  ) THEN
    DROP TRIGGER IF EXISTS on_notification_send_onesignal ON public.notifications;
  END IF;
END
$$;

DROP FUNCTION IF EXISTS public.send_onesignal_notification();
