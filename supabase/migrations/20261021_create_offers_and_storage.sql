-- ==============================================================================
-- Migración: Tabla 'offers' y bucket de Supabase Storage 'offer_images'
-- Issue #12: feat(backend): Tabla PostgreSQL de ofertas y bucket de Supabase Storage
-- Responsable: Pardo Zamarripa Juan Diego (1223100425)
-- ==============================================================================

-- 1. Crear tabla de publicaciones y ofertas de intercambio (bienes y servicios)
CREATE TABLE IF NOT EXISTS public.offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    titulo TEXT NOT NULL CHECK (char_length(trim(titulo)) >= 3),
    descripcion TEXT NOT NULL CHECK (char_length(trim(descripcion)) >= 5),
    categoria TEXT NOT NULL,
    colonia_comunidad TEXT NOT NULL,
    foto_url TEXT NOT NULL,
    modalidad TEXT NOT NULL DEFAULT 'trueque' CHECK (modalidad IN ('trueque', 'dinero', 'mixto')),
    lo_que_busca TEXT,
    precio_estimado NUMERIC(10, 2) CHECK (precio_estimado IS NULL OR precio_estimado >= 0),
    fecha_publicacion TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    activa BOOLEAN DEFAULT true NOT NULL
);

-- Comentarios descriptivos de la tabla y columnas
COMMENT ON TABLE public.offers IS 'Publicaciones de trueque, servicios y bienes entre vecinos de Dolores Hidalgo.';
COMMENT ON COLUMN public.offers.id IS 'Identificador único de la oferta (UUID)';
COMMENT ON COLUMN public.offers.usuario_id IS 'Identificador del vecino publicador (referencia a auth.users)';
COMMENT ON COLUMN public.offers.titulo IS 'Título descriptivo del bien u oficio ofrecido';
COMMENT ON COLUMN public.offers.descripcion IS 'Detalle del estado del bien o características del servicio';
COMMENT ON COLUMN public.offers.categoria IS 'Categoría del artículo u oficio (Herramientas, Alimentos, Oficios, etc.)';
COMMENT ON COLUMN public.offers.colonia_comunidad IS 'Colonia o comunidad de Dolores Hidalgo donde está disponible';
COMMENT ON COLUMN public.offers.foto_url IS 'URL pública en Supabase Storage de la fotografía del artículo u oficio';
COMMENT ON COLUMN public.offers.modalidad IS 'Tipo de acuerdo deseado: trueque, dinero o mixto';
COMMENT ON COLUMN public.offers.lo_que_busca IS 'Descripción de lo que el vecino solicita a cambio en trueque o mixto';
COMMENT ON COLUMN public.offers.precio_estimado IS 'Precio o valor estimado en pesos mexicanos';
COMMENT ON COLUMN public.offers.fecha_publicacion IS 'Fecha y hora de publicación en UTC';
COMMENT ON COLUMN public.offers.activa IS 'Indica si la oferta está disponible para intercambio';

-- Índices para optimizar búsquedas y filtrado hiperlocal
CREATE INDEX IF NOT EXISTS idx_offers_colonia ON public.offers(colonia_comunidad);
CREATE INDEX IF NOT EXISTS idx_offers_usuario ON public.offers(usuario_id);
CREATE INDEX IF NOT EXISTS idx_offers_activa_fecha ON public.offers(activa, fecha_publicacion DESC);
CREATE INDEX IF NOT EXISTS idx_offers_categoria ON public.offers(categoria);

-- 2. Habilitar Seguridad a Nivel de Fila (RLS) en offers
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;

-- Políticas de acceso para la tabla offers
-- Permitir lectura de ofertas activas a cualquier usuario (incluso visitantes)
CREATE POLICY "Permitir lectura publica de ofertas activas"
    ON public.offers
    FOR SELECT
    USING (activa = true);

-- Permitir a usuarios autenticados crear sus propias ofertas
CREATE POLICY "Permitir crear ofertas a usuarios autenticados"
    ON public.offers
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = usuario_id);

-- Permitir al propietario modificar sus propias ofertas
CREATE POLICY "Permitir modificar ofertas al propietario"
    ON public.offers
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = usuario_id)
    WITH CHECK (auth.uid() = usuario_id);

-- Permitir al propietario desactivar o eliminar su oferta
CREATE POLICY "Permitir eliminar ofertas al propietario"
    ON public.offers
    FOR DELETE
    TO authenticated
    USING (auth.uid() = usuario_id);

-- 3. Configuración del Bucket de Supabase Storage: offer_images
INSERT INTO storage.buckets (id, name, public)
VALUES ('offer_images', 'offer_images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Políticas de seguridad para storage.objects en el bucket offer_images
-- Lectura pública de fotografías de ofertas
CREATE POLICY "Permitir lectura publica de fotos de ofertas"
    ON storage.objects
    FOR SELECT
    USING (bucket_id = 'offer_images');

-- Subida permitida a usuarios autenticados
CREATE POLICY "Permitir subir fotos de ofertas a usuarios autenticados"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'offer_images');

-- Edición permitida al dueño del archivo
CREATE POLICY "Permitir actualizar fotos al propietario"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (bucket_id = 'offer_images' AND auth.uid() = owner);

-- Eliminación permitida al dueño del archivo
CREATE POLICY "Permitir eliminar fotos al propietario"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (bucket_id = 'offer_images' AND auth.uid() = owner);
