CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Inserta una nueva fila en public.profiles con el id y un username.
  -- Si el username no se proporciona en los metadatos, se generará uno por defecto usando el ID del usuario.
  INSERT INTO public.profiles (id, username)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'username', 'user-' || new.id::text)
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
