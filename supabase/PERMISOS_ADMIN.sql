-- ========================================================
-- PERMISOS PARA QUE ADMINS GESTIONEN ROLES
-- ========================================================

-- Política: Los administradores pueden actualizar cualquier perfil
DROP POLICY IF EXISTS "Admins pueden gestionar perfiles" ON public.profiles;
CREATE POLICY "Admins pueden gestionar perfiles" ON public.profiles 
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
