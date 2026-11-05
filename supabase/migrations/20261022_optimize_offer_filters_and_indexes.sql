-- ==============================================================================
-- Migración: Optimización de índices y filtros espaciales por colonia y categoría
-- Issue #15: feat(backend): Filtros espaciales por colonia y categoría en OffersRepository
-- Responsable: Pardo Zamarripa Juan Diego (1223100425)
-- ==============================================================================

-- 1. Índices compuestos en la tabla 'offers' para acelerar filtros hiperlocales
--    y ordenamiento por fecha de publicación descendente.
CREATE INDEX IF NOT EXISTS idx_offers_activa_colonia_fecha 
    ON public.offers (colonia_comunidad, fecha_publicacion DESC) 
    WHERE activa = true;

CREATE INDEX IF NOT EXISTS idx_offers_activa_categoria_fecha 
    ON public.offers (categoria, fecha_publicacion DESC) 
    WHERE activa = true;

CREATE INDEX IF NOT EXISTS idx_offers_activa_colonia_categoria_fecha 
    ON public.offers (colonia_comunidad, categoria, fecha_publicacion DESC) 
    WHERE activa = true;

-- 2. Compatibilidad con el esquema en español ('publicaciones') en caso de existir
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'publicaciones'
    ) THEN
        -- Índices compuestos para la tabla publicaciones
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_pub_activa_colonia_fecha 
                 ON public.publicaciones (colonia_comunidad, fecha_publicacion DESC) 
                 WHERE activa = true;';
                 
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_pub_activa_categoria_fecha 
                 ON public.publicaciones (categoria, fecha_publicacion DESC) 
                 WHERE activa = true;';
                 
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_pub_activa_colonia_categoria_fecha 
                 ON public.publicaciones (colonia_comunidad, categoria, fecha_publicacion DESC) 
                 WHERE activa = true;';
    END IF;
END $$;

-- 3. Función RPC opcional en PostgreSQL para consultas paginadas con filtros hiperlocales
CREATE OR REPLACE FUNCTION public.get_filtered_offers(
    p_colonia TEXT DEFAULT NULL,
    p_categoria TEXT DEFAULT NULL,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS SETOF public.offers
LANGUAGE sql
STABLE
AS $$
    SELECT *
    FROM public.offers
    WHERE activa = true
      AND (p_colonia IS NULL OR trim(p_colonia) = '' OR LOWER(colonia_comunidad) = LOWER(trim(p_colonia)))
      AND (p_categoria IS NULL OR trim(p_categoria) = '' OR LOWER(categoria) = LOWER(trim(p_categoria)))
    ORDER BY fecha_publicacion DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

COMMENT ON FUNCTION public.get_filtered_offers IS 'Función optimizada para recuperar publicaciones filtradas por colonia y/o categoría con paginación y ordenadas por fecha.';
