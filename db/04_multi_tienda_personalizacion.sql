-- Ejecutar una sola vez en Supabase SQL Editor.
-- Market queda marcado como existente y no se fuerza su personalización.
ALTER TABLE public.tiendas
    ADD COLUMN IF NOT EXISTS configuracion_completada BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE public.tiendas
SET configuracion_completada = TRUE
WHERE id = 'market';

-- Categorías válidas por tienda; se aplican en la aplicación Java.
-- Los productos existentes no se eliminan ni se modifican.
