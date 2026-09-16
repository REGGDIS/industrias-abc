-- @control {"name": "conteos", "mode": "counts"}
SELECT
    'areas' AS entidad,
    (SELECT COUNT(*) FROM areas) AS cant_source,
    (SELECT COUNT(*) FROM stg_contabilidad_areas_clean) AS cant_staging,
    (SELECT COUNT(*) FROM areas) - (SELECT COUNT(*) FROM stg_contabilidad_areas_clean) AS diferencia
UNION ALL
SELECT
    'centros_costo' AS entidad,
    (SELECT COUNT(*) FROM centros_costo) AS cant_source,
    (SELECT COUNT(*) FROM stg_contabilidad_centros_costo_clean) AS cant_staging,
    (SELECT COUNT(*) FROM centros_costo) - (SELECT COUNT(*) FROM stg_contabilidad_centros_costo_clean) AS diferencia
UNION ALL
SELECT
    'cuentas_contables' AS entidad,
    (SELECT COUNT(*) FROM cuentas_contables) AS cant_source,
    (SELECT COUNT(*) FROM stg_contabilidad_cuentas_contables_clean) AS cant_staging,
    (SELECT COUNT(*) FROM cuentas_contables) - (SELECT COUNT(*) FROM stg_contabilidad_cuentas_contables_clean) AS diferencia
UNION ALL
SELECT
    'movimientos_contables' AS entidad,
    (SELECT COUNT(*) FROM movimientos_contables) AS cant_source,
    (SELECT COUNT(*) FROM stg_contabilidad_movimientos_contables_clean) AS cant_staging,
    (SELECT COUNT(*) FROM movimientos_contables) - (SELECT COUNT(*) FROM stg_contabilidad_movimientos_contables_clean) AS diferencia;

-- @control {"name": "sumas", "mode": "sums"}
SELECT
    (SELECT COALESCE(SUM(debe), 0) FROM movimientos_contables) AS source_total_debe,
    (SELECT COALESCE(SUM(debe), 0) FROM stg_contabilidad_movimientos_contables_clean) AS staging_total_debe,
    (SELECT COALESCE(SUM(debe), 0) FROM movimientos_contables) - (SELECT COALESCE(SUM(debe), 0) FROM stg_contabilidad_movimientos_contables_clean) AS diff_debe,
    (SELECT COALESCE(SUM(haber), 0) FROM movimientos_contables) AS source_total_haber,
    (SELECT COALESCE(SUM(haber), 0) FROM stg_contabilidad_movimientos_contables_clean) AS staging_total_haber,
    (SELECT COALESCE(SUM(haber), 0) FROM movimientos_contables) - (SELECT COALESCE(SUM(haber), 0) FROM stg_contabilidad_movimientos_contables_clean) AS diff_haber;

-- @control {"name": "cuadratura", "mode": "balance"}
SELECT
    COALESCE(SUM(debe), 0) AS total_debe_staging,
    COALESCE(SUM(haber), 0) AS total_haber_staging,
    COALESCE(SUM(debe), 0) - COALESCE(SUM(haber), 0) AS cuadratura_staging,
    CASE
        WHEN COALESCE(SUM(debe), 0) - COALESCE(SUM(haber), 0) = 0 THEN 'OK: BALANCE CUADRADO'
        ELSE 'ERROR: DESCUADRE CONTABLE'
    END AS estado_cuadratura
FROM stg_contabilidad_movimientos_contables_clean;

-- @control {"name": "codigo_area_duplicado", "entity": "areas", "key": "codigo_area"}
SELECT codigo_area, COUNT(*) AS repeticiones
FROM stg_contabilidad_areas_clean
GROUP BY codigo_area
HAVING COUNT(*) > 1;

-- @control {"name": "codigo_centro_duplicado", "entity": "centros_costo", "key": "codigo"}
SELECT codigo, COUNT(*) AS repeticiones
FROM stg_contabilidad_centros_costo_clean
GROUP BY codigo
HAVING COUNT(*) > 1;

-- @control {"name": "codigo_cuenta_duplicado", "entity": "cuentas_contables", "key": "codigo_cuenta"}
SELECT codigo_cuenta, COUNT(*) AS repeticiones
FROM stg_contabilidad_cuentas_contables_clean
GROUP BY codigo_cuenta
HAVING COUNT(*) > 1;

-- @control {"name": "cuenta_huerfana", "entity": "movimientos_contables", "key": "movimiento_id"}
SELECT m.movimiento_id, m.cuenta_id
FROM stg_contabilidad_movimientos_contables_clean m
LEFT JOIN stg_contabilidad_cuentas_contables_clean c ON m.cuenta_id = c.cuenta_id
WHERE c.cuenta_id IS NULL;

-- @control {"name": "centro_huerfano", "entity": "movimientos_contables", "key": "movimiento_id"}
SELECT m.movimiento_id, m.centro_costo_id
FROM stg_contabilidad_movimientos_contables_clean m
LEFT JOIN stg_contabilidad_centros_costo_clean cc ON m.centro_costo_id = cc.centro_costo_id
WHERE cc.centro_costo_id IS NULL;

-- @control {"name": "area_multiples_centros", "entity": "centros_costo", "key": "area_id"}
SELECT area_id, COUNT(*) AS total_centros_asociados
FROM stg_contabilidad_centros_costo_clean
GROUP BY area_id
HAVING COUNT(*) > 1;

-- @control {"name": "padre_inexistente", "entity": "cuentas_contables", "key": "cuenta_id"}
SELECT hijo.cuenta_id, hijo.codigo_cuenta, hijo.cuenta_padre_id
FROM stg_contabilidad_cuentas_contables_clean hijo
LEFT JOIN stg_contabilidad_cuentas_contables_clean padre ON hijo.cuenta_padre_id = padre.cuenta_id
WHERE hijo.cuenta_padre_id IS NOT NULL
  AND padre.cuenta_id IS NULL;

-- @control {"name": "reglas_contables", "entity": "movimientos_contables", "key": "movimiento_id"}
SELECT *
FROM stg_contabilidad_movimientos_contables_clean
WHERE debe < 0
   OR haber < 0
   OR (debe = 0 AND haber = 0)
   OR (debe > 0 AND haber > 0)
   OR tipo_cambio <= 0;

-- @control {"name": "estado_centro", "entity": "centros_costo", "key": "centro_costo_id"}
SELECT centro_costo_id, codigo, estado
FROM stg_contabilidad_centros_costo_clean
WHERE estado NOT IN ('ACTIVO', 'INACTIVO') OR estado IS NULL;

-- @control {"name": "estado_cuenta", "entity": "cuentas_contables", "key": "cuenta_id"}
SELECT cuenta_id, codigo_cuenta, estado
FROM stg_contabilidad_cuentas_contables_clean
WHERE estado NOT IN ('ACTIVA', 'INACTIVA') OR estado IS NULL;

-- @control {"name": "moneda", "entity": "movimientos_contables", "key": "moneda"}
SELECT DISTINCT moneda
FROM stg_contabilidad_movimientos_contables_clean
WHERE moneda IS NULL
   OR LENGTH(moneda) = 0
   OR moneda <> TRIM(moneda);

-- @control {"name": "area_inexistente", "entity": "centros_costo", "key": "centro_costo_id"}
SELECT
    cc.centro_costo_id,
    cc.codigo,
    cc.area_id
FROM stg_contabilidad_centros_costo_clean cc
LEFT JOIN stg_contabilidad_areas_clean a
    ON cc.area_id = a.area_id
WHERE a.area_id IS NULL;

-- @control {"name": "preservacion_moneda", "entity": "movimientos_contables", "key": "movimiento_id"}
SELECT
    s.movimiento_id,
    s.moneda AS moneda_source,
    c.moneda AS moneda_staging
FROM movimientos_contables s
JOIN stg_contabilidad_movimientos_contables_clean c
    ON c.movimiento_id = s.movimiento_id
WHERE UPPER(TRIM(s.moneda)) IS DISTINCT FROM c.moneda;

-- @control {"name": "preservacion_documento", "entity": "movimientos_contables", "key": "movimiento_id"}
SELECT
    s.movimiento_id,
    s.documento_tipo AS documento_tipo_source,
    c.documento_tipo AS documento_tipo_staging
FROM movimientos_contables s
JOIN stg_contabilidad_movimientos_contables_clean c
    ON c.movimiento_id = s.movimiento_id
WHERE UPPER(TRIM(s.documento_tipo))
      IS DISTINCT FROM c.documento_tipo
   OR c.documento_tipo IS NULL
   OR c.documento_tipo = '';

-- @control {"name": "obligatorios_areas", "entity": "areas", "key": "area_id"}
SELECT area_id FROM stg_contabilidad_areas_clean WHERE area_id IS NULL OR BTRIM(area_id::text) = '' OR codigo_area IS NULL OR BTRIM(codigo_area::text) = '' OR nombre_area IS NULL OR BTRIM(nombre_area::text) = '';

-- @control {"name": "preservacion_areas", "entity": "areas", "key": "area_id"}
(SELECT area_id FROM areas EXCEPT ALL SELECT area_id FROM stg_contabilidad_areas_clean)
UNION ALL
(SELECT area_id FROM stg_contabilidad_areas_clean EXCEPT ALL SELECT area_id FROM areas);

-- @control {"name": "obligatorios_centros_costo", "entity": "centros_costo", "key": "centro_costo_id"}
SELECT centro_costo_id FROM stg_contabilidad_centros_costo_clean WHERE centro_costo_id IS NULL OR BTRIM(centro_costo_id::text) = '' OR codigo IS NULL OR BTRIM(codigo::text) = '' OR nombre IS NULL OR BTRIM(nombre::text) = '' OR area_id IS NULL OR BTRIM(area_id::text) = '' OR estado IS NULL OR BTRIM(estado::text) = '';

-- @control {"name": "preservacion_centros_costo", "entity": "centros_costo", "key": "centro_costo_id"}
(SELECT centro_costo_id,area_id FROM centros_costo EXCEPT ALL SELECT centro_costo_id,area_id FROM stg_contabilidad_centros_costo_clean)
UNION ALL
(SELECT centro_costo_id,area_id FROM stg_contabilidad_centros_costo_clean EXCEPT ALL SELECT centro_costo_id,area_id FROM centros_costo);

-- @control {"name": "obligatorios_cuentas_contables", "entity": "cuentas_contables", "key": "cuenta_id"}
SELECT cuenta_id FROM stg_contabilidad_cuentas_contables_clean WHERE cuenta_id IS NULL OR BTRIM(cuenta_id::text) = '' OR codigo_cuenta IS NULL OR BTRIM(codigo_cuenta::text) = '' OR nombre_cuenta IS NULL OR BTRIM(nombre_cuenta::text) = '' OR tipo_cuenta IS NULL OR BTRIM(tipo_cuenta::text) = '' OR grupo IS NULL OR BTRIM(grupo::text) = '' OR nivel IS NULL OR BTRIM(nivel::text) = '' OR estado IS NULL OR BTRIM(estado::text) = '' OR nivel <= 0;

-- @control {"name": "preservacion_cuentas_contables", "entity": "cuentas_contables", "key": "cuenta_id"}
(SELECT cuenta_id,nivel,cuenta_padre_id FROM cuentas_contables EXCEPT ALL SELECT cuenta_id,nivel,cuenta_padre_id FROM stg_contabilidad_cuentas_contables_clean)
UNION ALL
(SELECT cuenta_id,nivel,cuenta_padre_id FROM stg_contabilidad_cuentas_contables_clean EXCEPT ALL SELECT cuenta_id,nivel,cuenta_padre_id FROM cuentas_contables);

-- @control {"name": "obligatorios_movimientos_contables", "entity": "movimientos_contables", "key": "movimiento_id"}
SELECT movimiento_id FROM stg_contabilidad_movimientos_contables_clean WHERE movimiento_id IS NULL OR BTRIM(movimiento_id::text) = '' OR fecha IS NULL OR BTRIM(fecha::text) = '' OR cuenta_id IS NULL OR BTRIM(cuenta_id::text) = '' OR centro_costo_id IS NULL OR BTRIM(centro_costo_id::text) = '' OR documento_tipo IS NULL OR BTRIM(documento_tipo::text) = '' OR documento_numero IS NULL OR BTRIM(documento_numero::text) = '' OR descripcion IS NULL OR BTRIM(descripcion::text) = '' OR debe IS NULL OR BTRIM(debe::text) = '' OR haber IS NULL OR BTRIM(haber::text) = '' OR moneda IS NULL OR BTRIM(moneda::text) = '' OR tipo_cambio IS NULL OR BTRIM(tipo_cambio::text) = '';

-- @control {"name": "preservacion_movimientos_contables", "entity": "movimientos_contables", "key": "movimiento_id"}
(SELECT movimiento_id,fecha,cuenta_id,centro_costo_id,debe,haber,tipo_cambio FROM movimientos_contables EXCEPT ALL SELECT movimiento_id,fecha,cuenta_id,centro_costo_id,debe,haber,tipo_cambio FROM stg_contabilidad_movimientos_contables_clean)
UNION ALL
(SELECT movimiento_id,fecha,cuenta_id,centro_costo_id,debe,haber,tipo_cambio FROM stg_contabilidad_movimientos_contables_clean EXCEPT ALL SELECT movimiento_id,fecha,cuenta_id,centro_costo_id,debe,haber,tipo_cambio FROM movimientos_contables);
