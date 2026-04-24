-- Migration: Schema Discovery
-- Run this in the SQL Editor to find the required columns and enum values
DO $$
DECLARE
    col_record RECORD;
    enum_record RECORD;
BEGIN
    RAISE NOTICE '--- ORDERS TABLE COLUMNS ---';
    FOR col_record IN 
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'orders'
    LOOP
        RAISE NOTICE 'Column: %, Type: %, Nullable: %', col_record.column_name, col_record.data_type, col_record.is_nullable;
    END LOOP;

    RAISE NOTICE '--- FUEL_TYPE ENUM VALUES ---';
    -- Try to find the enum values if it is a user-defined type
    FOR enum_record IN
        SELECT e.enumlabel
        FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        WHERE t.typname = 'fuel_type'
    LOOP
        RAISE NOTICE 'Fuel Value: %', enum_record.enumlabel;
    END LOOP;
END $$;
