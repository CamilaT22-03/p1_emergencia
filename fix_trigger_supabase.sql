-- Script para corregir el problema del trigger en Supabase
-- Ejecutar este script en el SQL Editor de Supabase

-- 1. Eliminar cualquier trigger que pueda estar cambiando el estado a "cambio a trigger"
DO $$
DECLARE
    trigger_rec RECORD;
BEGIN
    FOR trigger_rec IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'emergencias'
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_rec.trigger_name || ' ON public.emergencias CASCADE;';
        RAISE NOTICE 'Eliminado trigger: %', trigger_rec.trigger_name;
    END LOOP;
END
$$;

-- 2. Eliminar funciones de trigger asociadas si existen
DROP FUNCTION IF EXISTS public.cambiar_estado_trigger() CASCADE;
DROP FUNCTION IF EXISTS public.actualizar_estado_emergencia() CASCADE;
DROP FUNCTION IF EXISTS public.on_emergencia_change() CASCADE;

-- 3. Asegurar que la columna estado tenga el valor por defecto correcto
ALTER TABLE public.emergencias ALTER COLUMN estado SET DEFAULT 'Pendiente';

-- 4. Corregir cualquier registro que tenga el estado "cambio a trigger"
UPDATE public.emergencias 
SET estado = 'Pendiente' 
WHERE estado = 'cambio a trigger' OR estado IS NULL;

-- 5. Verificar que no hay triggers activos
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'emergencias';

-- Mensaje de confirmación
SELECT 'Triggers eliminados y estado corregido' as resultado;
