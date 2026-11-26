-- ==============================================================================
-- Migración: Tabla 'exchanges' para propuestas de intercambio y Realtime
-- Issue #18: feat(backend): Tabla exchanges y patrón Factory para tipos de pago
-- ==============================================================================

-- 1. Asegurar columna 'estado' en public.offers para seguimiento de propuestas
ALTER TABLE public.offers
    ADD COLUMN IF NOT EXISTS estado TEXT NOT NULL DEFAULT 'disponible';

-- 2. Crear tabla de propuestas e intercambios entre vecinos
CREATE TABLE IF NOT EXISTS public.exchanges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    offer_id UUID NOT NULL REFERENCES public.offers(id) ON DELETE CASCADE,
    usuario_proponente_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    usuario_receptor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    modalidad TEXT NOT NULL DEFAULT 'trueque' CHECK (modalidad IN ('trueque', 'dinero', 'mixto')),
    propuesta TEXT NOT NULL CHECK (char_length(trim(propuesta)) >= 3),
    monto_efectivo NUMERIC(10, 2) CHECK (monto_efectivo IS NULL OR monto_efectivo >= 0),
    bien_ofrecido_id UUID REFERENCES public.offers(id) ON DELETE SET NULL,
    bien_ofrecido_titulo TEXT,
    estado TEXT NOT NULL DEFAULT 'pendiente_aceptacion'
        CHECK (estado IN ('pendiente_aceptacion', 'en_propuesta', 'aceptada', 'rechazada', 'cancelada', 'completada')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE public.exchanges IS 'Propuestas y acuerdos de intercambio (trueque, dinero o mixto) entre vecinos de Swappia.';
COMMENT ON COLUMN public.exchanges.modalidad IS 'Modalidad de pago acordada: trueque, dinero o mixto';
COMMENT ON COLUMN public.exchanges.monto_efectivo IS 'Compensación monetaria en MXN para acuerdos dinero o mixto';
COMMENT ON COLUMN public.exchanges.bien_ofrecido_id IS 'Identificador opcional de una publicación propia ofrecida a cambio';

-- Índices para consultas rápidas por oferta, participante y estado
CREATE INDEX IF NOT EXISTS idx_exchanges_offer ON public.exchanges(offer_id);
CREATE INDEX IF NOT EXISTS idx_exchanges_proponente ON public.exchanges(usuario_proponente_id);
CREATE INDEX IF NOT EXISTS idx_exchanges_receptor ON public.exchanges(usuario_receptor_id);
CREATE INDEX IF NOT EXISTS idx_exchanges_estado ON public.exchanges(estado, created_at DESC);

-- 3. Habilitar Row Level Security (RLS)
ALTER TABLE public.exchanges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir ver propuestas a participantes"
    ON public.exchanges
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = usuario_proponente_id
        OR auth.uid() = usuario_receptor_id
    );

CREATE POLICY "Permitir crear propuestas al proponente autenticado"
    ON public.exchanges
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = usuario_proponente_id);

CREATE POLICY "Permitir actualizar estado a participantes"
    ON public.exchanges
    FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = usuario_proponente_id
        OR auth.uid() = usuario_receptor_id
    )
    WITH CHECK (
        auth.uid() = usuario_proponente_id
        OR auth.uid() = usuario_receptor_id
    );

-- 4. Habilitar Supabase Realtime para notificaciones en vivo sobre exchanges
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
              AND schemaname = 'public'
              AND tablename = 'exchanges'
        ) THEN
            EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.exchanges;';
        END IF;
    END IF;
END $$;
