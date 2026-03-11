# 🔧 Instrucciones para Aplicar Migraciones en Supabase

## ✅ Opción 1: Execution Directa en Supabase Dashboard (Recomendado)

### Pasos:
1. Abre https://app.supabase.com/projects
2. Selecciona tu proyecto **venered-social**
3. Ve a **SQL Editor** (esquina superior izquierda)
4. Haz click en **"New Query"**
5. Copia todo el contenido de este archivo: [`supabase/migrations/EXECUTE_THIS_IN_SUPABASE.sql`](./supabase/migrations/EXECUTE_THIS_IN_SUPABASE.sql)
6. Pégalo en el editor
7. Haz click en **"Run"** (botón azul, esquina superior derecha)
8. ✅ ¡Listo!

---

## 📋 Qué se aplicará

```sql
-- 1. Agregar columna message_status a mensajes
ALTER TABLE public.messages ADD COLUMN message_status TEXT DEFAULT 'pending';

-- 2. Crear tabla para rate limiting
CREATE TABLE public.rate_limit_attempts (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  action TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Índices para queries rápidas
CREATE INDEX idx_messages_status ON public.messages(sender_id, message_status);
CREATE INDEX idx_rate_limit_attempts_user_action ON public.rate_limit_attempts(user_id, action, created_at);

-- 4. RLS Policies para seguridad
ALTER TABLE public.rate_limit_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own rate limit attempts" ...
CREATE POLICY "Users can insert their own rate limit attempts" ...
```

---

## ⚠️ Verificación

Después de ejecutar, verifica que todo está bien:

```sql
-- Verificar que existe la columna message_status
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'messages' AND column_name = 'message_status';

-- Verificar que existe la tabla rate_limit_attempts
SELECT * FROM information_schema.tables 
WHERE table_name = 'rate_limit_attempts';
```

Si ambas consultas retornan resultados, ¡todo está perfecto! ✅

---

## 🚀 Features Habilitadas

Una vez aplicadas las migraciones:

✅ **Estados de Mensaje**: ✓ (enviado) y ✓✓ (leído)  
✅ **Typing Indicator**: "escribiendo..." en tiempo real  
✅ **Anti-Spam**: Máximo 10 mensajes/minuto y 50 posts/día  
✅ **Borradores**: Auto-guardado en storage local (SharedPreferences)  
✅ **Progreso**: Barra de carga durante subidas  

---

## 🆘 Si hay errores

Si ves un error tipo `"relation rate_limit_attempts already exists"`, simplemente ignóralo. Significa que la tabla ya existe de ejecuciones anteriores.

Si vez otro tipo de error, contactame con el mensaje de error exacto.
