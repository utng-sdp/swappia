-- ==============================================================================
-- Migración: Creación de la tabla 'profiles' para Swappia
-- Issue #9: feat(auth): Implementación del Data Source remoto con Supabase Auth
-- Responsable: Pardo Zamarripa Juan Diego (1223100425)
-- ==============================================================================

-- 1. Crear tabla de perfiles vecinales vinculada a auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    colonia_comunidad TEXT NOT NULL,
    telefono TEXT NOT NULL,
    calificacion_acumulada NUMERIC(3, 2) DEFAULT 0.0 CHECK (calificacion_acumulada >= 0.0 AND calificacion_acumulada <= 5.0),
    total_calificaciones INTEGER DEFAULT 0 CHECK (total_calificaciones >= 0),
    foto_url TEXT,
    fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Comentarios explicativos sobre la tabla y campos
COMMENT ON TABLE public.profiles IS 'Tabla de perfiles de vecinos en Swappia vinculados a auth.users.';
COMMENT ON COLUMN public.profiles.id IS 'Identificador único del vecino, clave foránea hacia auth.users.id';
COMMENT ON COLUMN public.profiles.nombre IS 'Nombre completo o de pila del vecino';
COMMENT ON COLUMN public.profiles.colonia_comunidad IS 'Colonia o comunidad de Dolores Hidalgo donde reside el vecino';
COMMENT ON COLUMN public.profiles.telefono IS 'Número telefónico a 10 dígitos para contacto vecinal';
COMMENT ON COLUMN public.profiles.calificacion_acumulada IS 'Promedio de reputación vecinal (0.0 a 5.0 estrellas)';
COMMENT ON COLUMN public.profiles.total_calificaciones IS 'Total de evaluaciones recibidas en intercambios';
COMMENT ON COLUMN public.profiles.foto_url IS 'URL pública en Supabase Storage de la fotografía del vecino';
COMMENT ON COLUMN public.profiles.fecha_registro IS 'Fecha y hora de registro en UTC';

-- 2. Habilitar Seguridad a Nivel de Fila (Row Level Security - RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de acceso (RLS)
-- Permitir lectura de perfiles a cualquier usuario autenticado dentro de la comunidad
CREATE POLICY "Permitir lectura de perfiles a usuarios autenticados"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);

-- Permitir a un usuario insertar su propio perfil en el registro
CREATE POLICY "Permitir a usuarios insertar su propio perfil"
    ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Permitir a un usuario actualizar únicamente sus propios datos
CREATE POLICY "Permitir a usuarios actualizar su propio perfil"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 4. Función y Trigger de inserción automática desde auth.users
-- Permite que cuando Supabase Auth registre un usuario con metadata (signUp data),
-- se cree automáticamente su fila correspondiente en 'profiles'.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        nombre,
        colonia_comunidad,
        telefono,
        foto_url
    )
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'nombre', 'Vecino Swappia'),
        COALESCE(new.raw_user_meta_data->>'colonia_comunidad', 'Dolores Hidalgo'),
        COALESCE(new.raw_user_meta_data->>'telefono', ''),
        new.raw_user_meta_data->>'foto_url'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Disparador que se activa tras insertar un nuevo registro en auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
