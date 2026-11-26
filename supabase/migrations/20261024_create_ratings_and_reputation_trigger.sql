-- ==============================================================================
-- Migración: Tabla 'ratings' y Trigger de Recálculo Automático de Reputación
-- Issue #21: feat(backend): Tabla de calificaciones y trigger de reputación vecinal
-- ==============================================================================

-- 1. Asegurar columna 'rating_avg' en public.profiles para compatibilidad con consultas
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS rating_avg NUMERIC(3, 2) DEFAULT 0.0
    CHECK (rating_avg >= 0.0 AND rating_avg <= 5.0);

-- 2. Crear tabla de calificaciones vecinales
CREATE TABLE IF NOT EXISTS public.ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluador_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    evaluado_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    intercambio_id UUID REFERENCES public.exchanges(id) ON DELETE SET NULL,
    estrellas INTEGER NOT NULL CHECK (estrellas >= 1 AND estrellas <= 5),
    comentario TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT chk_no_self_rating CHECK (evaluador_id <> evaluado_id)
);

COMMENT ON TABLE public.ratings IS 'Calificaciones de reputación vecinal (1 a 5 estrellas) tras concretar intercambios.';
COMMENT ON COLUMN public.ratings.evaluador_id IS 'Vecino que emite la calificación';
COMMENT ON COLUMN public.ratings.evaluado_id IS 'Vecino que recibe la calificación';
COMMENT ON COLUMN public.ratings.intercambio_id IS 'Referencia opcional al acuerdo de intercambio evaluado';
COMMENT ON COLUMN public.ratings.estrellas IS 'Puntuación entera de 1 a 5 estrellas';

CREATE INDEX IF NOT EXISTS idx_ratings_evaluado ON public.ratings(evaluado_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ratings_evaluador ON public.ratings(evaluador_id);
CREATE INDEX IF NOT EXISTS idx_ratings_intercambio ON public.ratings(intercambio_id);

-- 3. Habilitar Row Level Security (RLS)
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir lectura de calificaciones a usuarios autenticados"
    ON public.ratings
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Permitir insertar calificaciones al evaluador autenticado"
    ON public.ratings
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = evaluador_id AND evaluador_id <> evaluado_id);

-- 4. Función y Trigger para recalcular promedio de reputación en public.profiles
CREATE OR REPLACE FUNCTION public.recalculate_user_rating()
RETURNS TRIGGER AS $$
DECLARE
    target_user_id UUID;
    avg_score NUMERIC(3, 2);
    total_count INTEGER;
BEGIN
    target_user_id := COALESCE(NEW.evaluado_id, OLD.evaluado_id);

    SELECT
        COALESCE(ROUND(AVG(estrellas)::numeric, 2), 0.0),
        COUNT(*)::integer
    INTO avg_score, total_count
    FROM public.ratings
    WHERE evaluado_id = target_user_id;

    UPDATE public.profiles
    SET
        rating_avg = avg_score,
        calificacion_acumulada = avg_score,
        total_calificaciones = total_count
    WHERE id = target_user_id;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_ratings_recalculate_reputation ON public.ratings;
CREATE TRIGGER trg_ratings_recalculate_reputation
    AFTER INSERT OR UPDATE OR DELETE ON public.ratings
    FOR EACH ROW EXECUTE FUNCTION public.recalculate_user_rating();
