-- ========================================================
-- MEJORA DE NOTIFICACIONES: NOMBRE Y PRIVACIDAD
-- ========================================================

CREATE OR REPLACE FUNCTION public.send_onesignal_notification()
RETURNS TRIGGER AS $$
DECLARE
  sender_name TEXT;
  notif_text TEXT;
BEGIN
  -- 1. Obtener el nombre de quien envía la notificación
  SELECT COALESCE(username, 'Alguien') INTO sender_name 
  FROM public.profiles 
  WHERE id = NEW.sender_id;

  -- 2. Configurar el texto según el tipo de notificación
  IF NEW.type = 'message' THEN
    -- Cambiamos el contenido del mensaje por la frase de privacidad
    notif_text := 'Tienes un mensaje de ' || sender_name;
  ELSE
    -- Para Likes y Followers, el texto ya viene como "le ha gustado tu..."
    -- Así que queda: "Juan le ha gustado tu publicación"
    notif_text := sender_name || ' ' || NEW.content;
  END IF;

  -- 3. Enviar a OneSignal
  PERFORM net.http_post(
    url := 'https://onesignal.com/api/v1/notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Basic os_v2_app_po76jzwc5banvfxlz7csrpfw4ym765qku7be4zm4xoegs7mlyyd5nrbf5w2lsedjl5tvwnri4hmulzvb3qi5guivug52xydq2jr2hza'
    ),
    body := jsonb_build_object(
      'app_id', '7bbfe4e6-c2e8-40da-96eb-cfc528bcb6e6',
      'include_external_user_ids', ARRAY[NEW.receiver_id::TEXT],
      'headings', jsonb_build_object('en', 'Venered Social'),
      'contents', jsonb_build_object('en', notif_text)
    )
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
