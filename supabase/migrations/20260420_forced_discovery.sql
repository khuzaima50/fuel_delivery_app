-- Migration: Enum Leakage
-- Finds valid values for the enums we found
DO $$
DECLARE
    info_text TEXT;
BEGIN
    SELECT 'FUEL: ' || string_agg(enumlabel, ', ') INTO info_text
    FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid WHERE t.typname = 'fuel_type';
    
    RAISE NOTICE 'RESULT: %', info_text;

    SELECT info_text || ' | PAY: ' || string_agg(enumlabel, ', ') INTO info_text
    FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid WHERE t.typname = 'payment_status';

    RAISE EXCEPTION 'ENUMS: %', info_text;
END $$;
