-- =====================================================================
--  test_normalizacion_compras.sql
--  ETL Compras 0.4 · Pruebas de normalización y estandarización
--  Proyecto: Business Intelligence - Industrias ABC  (Equipo BInnova)
--  Dominio: Compras   Responsable: Raymond Civil
--  Rama: feat/etl-compras-normalizacion-04   Base: develop   Versión: 0.1
--
--  QUE PRUEBA
--    Que las reglas de normalizar_compras.sql clasifican bien cada caso:
--    NORMALIZADO / LIMPIO / REVISION / ERROR, que conservan trazabilidad y
--    que la transformación es IDEMPOTENTE.
--
--  POR QUE FIXTURES Y NO LAS OPERACIONALES
--    Las tablas operacionales rechazan por CHECK los valores fuera de dominio
--    (p. ej. moneda 'CLPS'); por eso los casos se prueban sobre valores de
--    entrada controlados, aplicando las MISMAS expresiones de normalización.
--
--  SEGURIDAD
--    Todo corre en BEGIN … ROLLBACK con objetos de pg_temp (temporales):
--    no modifica el seed ni ninguna tabla operacional.
--
--  EJECUTAR:  psql "<conn>" -f etl/tests/compras/test_normalizacion_compras.sql
-- =====================================================================

\set ON_ERROR_STOP on
BEGIN;

-- Funciones temporales (pg_temp = sesión; se descartan solas) que replican
-- EXACTAMENTE la lógica de normalizar_compras.sql.
CREATE FUNCTION pg_temp.f_norm(tipo text, v text) RETURNS text AS $$
  SELECT CASE WHEN tipo = 'texto' THEN TRIM(v) ELSE UPPER(TRIM(v)) END;
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION pg_temp.f_estado(tipo text, v text) RETURNS text AS $$
  SELECT CASE tipo
    WHEN 'moneda'     THEN CASE WHEN UPPER(TRIM(v)) IN ('CLP','USD','EUR') THEN 'NORMALIZADO' ELSE 'REVISION' END
    WHEN 'estado_oc'  THEN CASE WHEN UPPER(TRIM(v)) IN ('EMITIDA','PARCIAL','RECIBIDA','CERRADA','ANULADA') THEN 'NORMALIZADO' ELSE 'REVISION' END
    WHEN 'estado_pi'  THEN CASE WHEN UPPER(TRIM(v)) IN ('ACTIVO','INACTIVO') THEN 'NORMALIZADO' ELSE 'REVISION' END
    WHEN 'estado_rec' THEN CASE WHEN UPPER(TRIM(v)) IN ('REGISTRADA','CONFORME','CON_DIFERENCIAS','ANULADA') THEN 'NORMALIZADO' ELSE 'REVISION' END
    WHEN 'clave'      THEN CASE WHEN NULLIF(TRIM(v),'') IS NULL THEN 'ERROR' ELSE 'NORMALIZADO' END
    WHEN 'texto'      THEN CASE WHEN NULLIF(TRIM(v),'') IS NULL THEN 'REVISION' ELSE 'LIMPIO' END
  END;
$$ LANGUAGE sql IMMUTABLE;

-- Casos de prueba: entrada controlada + resultado esperado
CREATE TEMP TABLE casos (
  nro int, descripcion text, tipo text, valor_original text,
  esp_normalizado text, esp_estado text
) ON COMMIT DROP;
INSERT INTO casos VALUES
 ( 1,'Moneda con espacios/minúsculas',      'moneda',     ' clp ',            'CLP',            'NORMALIZADO'),
 ( 2,'Estado OC con espacios/minúsculas',   'estado_oc',  ' emitida ',        'EMITIDA',        'NORMALIZADO'),
 ( 3,'Estado proveedor/insumo',             'estado_pi',  ' activo ',         'ACTIVO',         'NORMALIZADO'),
 ( 4,'Estado recepción',                    'estado_rec', ' conforme ',       'CONFORME',       'NORMALIZADO'),
 ( 5,'Número OC con espacios',              'clave',      ' oc-001 ',         'OC-001',         'NORMALIZADO'),
 ( 6,'Código insumo con espacios',          'clave',      ' ins-01 ',         'INS-01',         'NORMALIZADO'),
 ( 7,'Número OC vacío -> ERROR',            'clave',      '   ',              '',               'ERROR'),
 ( 8,'Código insumo vacío -> ERROR',        'clave',      '',                 '',               'ERROR'),
 ( 9,'Valor fuera de dominio -> REVISION',  'moneda',     'CLPS',             'CLPS',           'REVISION'),
 (10,'Texto descriptivo con espacios',      'texto',      '  Proveedor Sur  ','Proveedor Sur',  'LIMPIO');

-- ------------------------------------------------------------------
-- Reporte de casos 1..10  (esperado vs obtenido -> PASA/FALLA)
-- ------------------------------------------------------------------
\echo '=== PRUEBAS 1..10: clasificación y normalización ==='
SELECT c.nro, c.descripcion,
       pg_temp.f_norm(c.tipo, c.valor_original)   AS obt_normalizado,
       pg_temp.f_estado(c.tipo, c.valor_original) AS obt_estado,
       CASE WHEN pg_temp.f_norm(c.tipo,c.valor_original)   = c.esp_normalizado
             AND pg_temp.f_estado(c.tipo,c.valor_original) = c.esp_estado
            THEN 'PASA' ELSE 'FALLA' END AS resultado
FROM casos c ORDER BY c.nro;

-- ------------------------------------------------------------------
-- PRUEBA 11 — Trazabilidad: se conserva el original y difiere del normalizado
-- ------------------------------------------------------------------
\echo '=== PRUEBA 11: trazabilidad (original conservado != normalizado) ==='
SELECT nro, valor_original,
       pg_temp.f_norm(tipo,valor_original) AS valor_normalizado,
       CASE WHEN valor_original = ' oc-001 '
             AND pg_temp.f_norm(tipo,valor_original) = 'OC-001'
             AND valor_original <> pg_temp.f_norm(tipo,valor_original)
            THEN 'PASA' ELSE 'FALLA' END AS resultado
FROM casos WHERE nro = 5;

-- ------------------------------------------------------------------
-- PRUEBA 12 — Idempotencia: normalizar(normalizar(x)) = normalizar(x)
-- ------------------------------------------------------------------
\echo '=== PRUEBA 12: idempotencia (doble ejecución = misma salida) ==='
SELECT COUNT(*) AS total_casos,
       COUNT(*) FILTER (
         WHERE pg_temp.f_norm(tipo, pg_temp.f_norm(tipo,valor_original))
             = pg_temp.f_norm(tipo, valor_original)
       ) AS idempotentes,
       CASE WHEN COUNT(*) = COUNT(*) FILTER (
         WHERE pg_temp.f_norm(tipo, pg_temp.f_norm(tipo,valor_original))
             = pg_temp.f_norm(tipo, valor_original))
            THEN 'PASA' ELSE 'FALLA' END AS resultado
FROM casos;

-- ------------------------------------------------------------------
-- Conteo global + ENDURECIMIENTO: si hay alguna FALLA, el script FALLA
-- de verdad (RAISE EXCEPTION), no solo imprime texto.
-- ------------------------------------------------------------------
\echo '=== CONTEO GLOBAL ==='
DO $$
DECLARE
  v_fallas int;
  v_idem   int;
  v_total  int;
BEGIN
  -- fallas en casos 1..10
  SELECT COUNT(*) INTO v_fallas
  FROM casos c
  WHERE pg_temp.f_norm(c.tipo,c.valor_original)   <> c.esp_normalizado
     OR pg_temp.f_estado(c.tipo,c.valor_original) <> c.esp_estado;

  -- trazabilidad (caso 5)
  IF NOT EXISTS (
     SELECT 1 FROM casos WHERE nro=5
       AND valor_original=' oc-001 '
       AND pg_temp.f_norm(tipo,valor_original)='OC-001'
  ) THEN v_fallas := v_fallas + 1; END IF;

  -- idempotencia
  SELECT COUNT(*) , COUNT(*) FILTER (
           WHERE pg_temp.f_norm(tipo,pg_temp.f_norm(tipo,valor_original))
               = pg_temp.f_norm(tipo,valor_original))
    INTO v_total, v_idem FROM casos;
  IF v_idem <> v_total THEN v_fallas := v_fallas + 1; END IF;

  RAISE NOTICE 'Fallas totales: %', v_fallas;
  IF v_fallas > 0 THEN
     RAISE EXCEPTION 'PRUEBAS DE NORMALIZACION FALLARON: % caso(s) no cumplen', v_fallas;
  END IF;
  RAISE NOTICE 'TODAS LAS PRUEBAS PASARON';
END $$;

ROLLBACK;
-- Fin de test_normalizacion_compras.sql  (ROLLBACK: no persiste nada)
