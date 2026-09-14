\set ON_ERROR_STOP on

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    IF to_regclass('dw.fact_contabilidad') IS NULL THEN
        RAISE EXCEPTION 'Falta dw.fact_contabilidad';
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM pg_constraint
    WHERE conrelid = 'dw.fact_contabilidad'::regclass
      AND contype = 'f';

    IF v_count <> 4 THEN
        RAISE EXCEPTION 'FACT_CONTABILIDAD debe tener 4 FK; encontradas %', v_count;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM pg_constraint
    WHERE conrelid = 'dw.fact_contabilidad'::regclass
      AND contype = 'u';

    IF v_count < 1 THEN
        RAISE EXCEPTION 'FACT_CONTABILIDAD debe proteger movimiento_id_origen';
    END IF;
END $$;

\echo 'TEST OK: FACT_CONTABILIDAD, FK y unicidad del grano verificadas.'
