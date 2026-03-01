-- ========================================================
-- SISTEMA DE ESTADOS DE VENEZUELA Y RESTRICCIÓN DE 7 DÍAS
-- ========================================================

-- 1. Añadir columnas a perfiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS estado TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS last_state_change TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. Función para validar el cambio de estado (Regla de los 7 días)
CREATE OR REPLACE FUNCTION public.check_state_change_limit()
RETURNS TRIGGER AS $$
BEGIN
  -- Solo si el estado está cambiando y ya tenía un estado previo
  IF OLD.estado IS NOT NULL AND OLD.estado IS DISTINCT FROM NEW.estado THEN
    -- Verificar si han pasado 7 días desde el último cambio
    IF OLD.last_state_change > (NOW() - INTERVAL '7 days') THEN
      RAISE EXCEPTION 'Solo puedes cambiar tu estado una vez cada 7 días. Inténtalo más tarde.';
    END IF;
    
    -- Si el cambio es permitido, actualizamos la fecha del último cambio
    NEW.last_state_change := NOW();
  END IF;
  
  -- Si es la primera vez que se pone el estado (OLD.estado es NULL), se permite sin checar los 7 días
  IF OLD.estado IS NULL AND NEW.estado IS NOT NULL THEN
    NEW.last_state_change := NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger para aplicar la restricción
DROP TRIGGER IF EXISTS on_state_change_limit ON public.profiles;
CREATE TRIGGER on_state_change_limit
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.check_state_change_limit();
