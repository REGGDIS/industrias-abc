\set ON_ERROR_STOP on

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    IF to_regclass('dw.dim_cuenta_contable') IS NULL THEN
        RAISE EXCEPTION 'Falta dw.dim_cuenta_contable';
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM dw.dim_cuenta_contable
    WHERE cuenta_key = 0
      AND codigo_cuenta = 'DESCONOCIDO';

    IF v_count <> 1 THEN
        RAISE EXCEPTION 'Miembro 0 de DIM_CUENTA_CONTABLE inválido';
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM pg_constraint
    WHERE conrelid = 'dw.dim_cuenta_contable'::regclass
      AND contype = 'u';

    IF v_count < 1 THEN
        RAISE EXCEPTION 'DIM_CUENTA_CONTABLE debe tener UNIQUE para la business key';
    END IF;
END $$;

\echo 'TEST OK: DIM_CUENTA_CONTABLE, business key y miembro desconocido verificados.'
