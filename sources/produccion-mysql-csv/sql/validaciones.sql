USE industrias_abc_produccion;

-- ============================================================
-- 1. VALIDACIÓN DE EXISTENCIA DE TABLAS
-- ============================================================

SELECT
    CASE
        WHEN COUNT(*) = 3 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado,
    COUNT(*) AS tablas_encontradas
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN (
      'productos',
      'ordenes_produccion',
      'consumo_insumos'
  );

SELECT
    table_name,
    CASE
        WHEN table_name IS NOT NULL THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN (
      'productos',
      'ordenes_produccion',
      'consumo_insumos'
  )
ORDER BY table_name;

-- ============================================================
-- 2. VALIDACIÓN DE CANTIDAD DE REGISTROS
-- ============================================================

SELECT
    'productos' AS tabla,
    COUNT(*) AS registros,
    CASE
        WHEN COUNT(*) > 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM productos

UNION ALL

SELECT
    'ordenes_produccion',
    COUNT(*),
    CASE
        WHEN COUNT(*) > 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM ordenes_produccion

UNION ALL

SELECT
    'consumo_insumos',
    COUNT(*),
    CASE
        WHEN COUNT(*) > 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM consumo_insumos;

-- ============================================================
-- 3. VALIDACIÓN DE CLAVES PRIMARIAS
-- ============================================================

SELECT
    'productos' AS tabla,
    COUNT(*) AS registros,
    COUNT(DISTINCT producto_id) AS ids_distintos,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT producto_id)
        THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM productos

UNION ALL

SELECT
    'ordenes_produccion',
    COUNT(*),
    COUNT(DISTINCT orden_produccion_id),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT orden_produccion_id)
        THEN 'OK'
        ELSE 'ERROR'
    END
FROM ordenes_produccion

UNION ALL

SELECT
    'consumo_insumos',
    COUNT(*),
    COUNT(DISTINCT consumo_id),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT consumo_id)
        THEN 'OK'
        ELSE 'ERROR'
    END
FROM consumo_insumos;

-- ============================================================
-- 4. VALIDACIÓN DE VALORES NULL EN PK
-- ============================================================

SELECT
    'productos.producto_id' AS campo,
    COUNT(*) AS valores_null,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM productos
WHERE producto_id IS NULL

UNION ALL

SELECT
    'ordenes_produccion.orden_produccion_id',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM ordenes_produccion
WHERE orden_produccion_id IS NULL

UNION ALL

SELECT
    'consumo_insumos.consumo_id',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM consumo_insumos
WHERE consumo_id IS NULL;

-- ============================================================
-- 5. VALIDACIÓN DE UNICIDAD
-- ============================================================

-- codigo_producto
SELECT
    'codigo_producto' AS validacion,
    COUNT(*) AS duplicados,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM (
    SELECT codigo_producto
    FROM productos
    GROUP BY codigo_producto
    HAVING COUNT(*) > 1
) AS duplicados_productos;

-- numero_orden
SELECT
    'numero_orden' AS validacion,
    COUNT(*) AS duplicados,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM (
    SELECT numero_orden
    FROM ordenes_produccion
    GROUP BY numero_orden
    HAVING COUNT(*) > 1
) AS duplicados_ordenes;

-- ============================================================
-- 6. VALIDACIÓN DE FK:
--    ordenes_produccion.producto_id
--    -> productos.producto_id
-- ============================================================

SELECT
    COUNT(*) AS referencias_invalidas,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM ordenes_produccion op
LEFT JOIN productos p
    ON op.producto_id = p.producto_id
WHERE p.producto_id IS NULL;

-- Detalle de referencias inválidas, si existen
SELECT
    op.orden_produccion_id,
    op.numero_orden,
    op.producto_id
FROM ordenes_produccion op
LEFT JOIN productos p
    ON op.producto_id = p.producto_id
WHERE p.producto_id IS NULL;

-- ============================================================
-- 7. VALIDACIÓN DE FK:
--    consumo_insumos.orden_produccion_id
--    -> ordenes_produccion.orden_produccion_id
-- ============================================================

SELECT
    COUNT(*) AS referencias_invalidas,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM consumo_insumos ci
LEFT JOIN ordenes_produccion op
    ON ci.orden_produccion_id = op.orden_produccion_id
WHERE op.orden_produccion_id IS NULL;

-- Detalle de referencias inválidas, si existen
SELECT
    ci.consumo_id,
    ci.orden_produccion_id,
    ci.insumo_id
FROM consumo_insumos ci
LEFT JOIN ordenes_produccion op
    ON ci.orden_produccion_id = op.orden_produccion_id
WHERE op.orden_produccion_id IS NULL;

-- ============================================================
-- 8. VALIDACIÓN DE CANTIDADES NO NEGATIVAS
-- ============================================================

-- cantidad_planificada de órdenes
SELECT
    'ordenes_produccion.cantidad_planificada' AS validacion,
    COUNT(*) AS errores,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM ordenes_produccion
WHERE cantidad_planificada < 0

UNION ALL

-- cantidad_producida
SELECT
    'ordenes_produccion.cantidad_producida',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM ordenes_produccion
WHERE cantidad_producida < 0

UNION ALL

-- cantidad_rechazada
SELECT
    'ordenes_produccion.cantidad_rechazada',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM ordenes_produccion
WHERE cantidad_rechazada < 0

UNION ALL

-- cantidad_planificada de consumos
SELECT
    'consumo_insumos.cantidad_planificada',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM consumo_insumos
WHERE cantidad_planificada < 0

UNION ALL

-- cantidad_consumida
SELECT
    'consumo_insumos.cantidad_consumida',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM consumo_insumos
WHERE cantidad_consumida < 0;

-- ============================================================
-- 9. VALIDACIÓN:
--    cantidad_rechazada <= cantidad_producida
-- ============================================================

SELECT
    COUNT(*) AS errores,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM ordenes_produccion
WHERE cantidad_rechazada > cantidad_producida;

-- Detalle
SELECT
    orden_produccion_id,
    numero_orden,
    cantidad_producida,
    cantidad_rechazada
FROM ordenes_produccion
WHERE cantidad_rechazada > cantidad_producida;

-- ============================================================
-- 10. VALIDACIÓN:
--     fecha_termino >= fecha_inicio
-- ============================================================

SELECT
    COUNT(*) AS errores,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM ordenes_produccion
WHERE fecha_termino IS NOT NULL
  AND fecha_termino < fecha_inicio;

-- Detalle
SELECT
    orden_produccion_id,
    numero_orden,
    fecha_inicio,
    fecha_termino
FROM ordenes_produccion
WHERE fecha_termino IS NOT NULL
  AND fecha_termino < fecha_inicio;

-- ============================================================
-- 11. VALIDACIÓN:
--     fecha_consumo >= fecha_inicio
-- ============================================================

SELECT
    COUNT(*) AS errores,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM consumo_insumos ci
INNER JOIN ordenes_produccion op
    ON ci.orden_produccion_id = op.orden_produccion_id
WHERE ci.fecha_consumo < op.fecha_inicio;

-- Detalle
SELECT
    ci.consumo_id,
    ci.orden_produccion_id,
    ci.fecha_consumo,
    op.fecha_inicio,
    op.fecha_termino
FROM consumo_insumos ci
INNER JOIN ordenes_produccion op
    ON ci.orden_produccion_id = op.orden_produccion_id
WHERE ci.fecha_consumo < op.fecha_inicio;

-- ============================================================
-- 12. VALIDACIÓN:
--     fecha_consumo <= fecha_termino
--     cuando la orden ya tiene fecha de término
-- ============================================================

SELECT
    COUNT(*) AS errores,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM consumo_insumos ci
INNER JOIN ordenes_produccion op
    ON ci.orden_produccion_id = op.orden_produccion_id
WHERE op.fecha_termino IS NOT NULL
  AND ci.fecha_consumo > op.fecha_termino;

-- Detalle
SELECT
    ci.consumo_id,
    ci.orden_produccion_id,
    ci.fecha_consumo,
    op.fecha_inicio,
    op.fecha_termino
FROM consumo_insumos ci
INNER JOIN ordenes_produccion op
    ON ci.orden_produccion_id = op.orden_produccion_id
WHERE op.fecha_termino IS NOT NULL
  AND ci.fecha_consumo > op.fecha_termino;

-- ============================================================
-- 13. VALIDACIÓN DE DATOS OBLIGATORIOS
-- ============================================================

SELECT
    'productos' AS tabla,
    COUNT(*) AS errores,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM productos
WHERE codigo_producto IS NULL
   OR nombre_producto IS NULL
   OR categoria IS NULL
   OR unidad_medida IS NULL

UNION ALL

SELECT
    'ordenes_produccion',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM ordenes_produccion
WHERE numero_orden IS NULL
   OR producto_id IS NULL
   OR fecha_inicio IS NULL
   OR cantidad_planificada IS NULL
   OR cantidad_producida IS NULL
   OR cantidad_rechazada IS NULL
   OR estado IS NULL
   OR centro_costo_id IS NULL

UNION ALL

SELECT
    'consumo_insumos',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM consumo_insumos
WHERE orden_produccion_id IS NULL
   OR insumo_id IS NULL
   OR cantidad_planificada IS NULL
   OR cantidad_consumida IS NULL
   OR fecha_consumo IS NULL;

-- ============================================================
-- 14. VALIDACIÓN DE COBERTURA DE ÓRDENES
--     Comprueba que existan órdenes con y sin consumo.
--     Es informativa, no necesariamente un error.
-- ============================================================

SELECT
    COUNT(*) AS ordenes_sin_consumo,
    CASE
        WHEN COUNT(*) >= 0 THEN 'INFO'
    END AS resultado
FROM ordenes_produccion op
LEFT JOIN consumo_insumos ci
    ON op.orden_produccion_id = ci.orden_produccion_id
WHERE ci.consumo_id IS NULL;

-- ============================================================
-- 15. VALIDACIÓN DE REFERENCIAS LÓGICAS EXTERNAS
-- ============================================================
--
-- insumo_id y centro_costo_id NO deben validarse mediante JOIN
-- contra tablas externas porque este modelo no incorpora esas
-- tablas ni FK físicas.
--
-- Se valida solamente que los identificadores estén informados.

SELECT
    'consumo_insumos.insumo_id' AS referencia,
    COUNT(*) AS valores_null,
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END AS resultado
FROM consumo_insumos
WHERE insumo_id IS NULL

UNION ALL

SELECT
    'ordenes_produccion.centro_costo_id',
    COUNT(*),
    CASE
        WHEN COUNT(*) = 0 THEN 'OK'
        ELSE 'ERROR'
    END
FROM ordenes_produccion
WHERE centro_costo_id IS NULL;

-- ============================================================
-- 16. VALIDACIÓN DE ESTRUCTURA DE COLUMNAS
-- ============================================================

SELECT
    table_name,
    COUNT(*) AS cantidad_columnas
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name IN (
      'productos',
      'ordenes_produccion',
      'consumo_insumos'
  )
GROUP BY table_name
ORDER BY table_name;

-- ============================================================
-- 17. VALIDACIÓN DE CLAVES FORÁNEAS FÍSICAS
-- ============================================================

SELECT
    constraint_name,
    table_name,
    column_name,
    referenced_table_name,
    referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema = DATABASE()
  AND table_name IN (
      'productos',
      'ordenes_produccion',
      'consumo_insumos'
  )
  AND referenced_table_name IS NOT NULL
ORDER BY table_name, constraint_name;

-- Resultado esperado:
--
-- fk_ordenes_produccion_producto
--   ordenes_produccion.producto_id
--   -> productos.producto_id
--
-- fk_consumo_insumos_orden
--   consumo_insumos.orden_produccion_id
--   -> ordenes_produccion.orden_produccion_id

-- ============================================================
-- 18. VALIDACIÓN DE ÍNDICES
-- ============================================================

SELECT
    table_name,
    index_name,
    column_name,
    non_unique
FROM information_schema.statistics
WHERE table_schema = DATABASE()
  AND table_name IN (
      'productos',
      'ordenes_produccion',
      'consumo_insumos'
  )
ORDER BY table_name, index_name, seq_in_index;

-- ============================================================
-- 19. RESUMEN FINAL DE VALIDACIONES DE NEGOCIO
-- ============================================================

SELECT
    'FK producto válida' AS validacion,
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM ordenes_produccion op
            LEFT JOIN productos p
                ON op.producto_id = p.producto_id
            WHERE p.producto_id IS NULL
        )
        THEN 'OK'
        ELSE 'ERROR'
    END AS resultado

UNION ALL

SELECT
    'FK orden de consumo válida',
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM consumo_insumos ci
            LEFT JOIN ordenes_produccion op
                ON ci.orden_produccion_id = op.orden_produccion_id
            WHERE op.orden_produccion_id IS NULL
        )
        THEN 'OK'
        ELSE 'ERROR'
    END

UNION ALL

SELECT
    'Cantidades no negativas',
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM ordenes_produccion
            WHERE cantidad_planificada < 0
               OR cantidad_producida < 0
               OR cantidad_rechazada < 0
        )
        AND NOT EXISTS (
            SELECT 1
            FROM consumo_insumos
            WHERE cantidad_planificada < 0
               OR cantidad_consumida < 0
        )
        THEN 'OK'
        ELSE 'ERROR'
    END

UNION ALL

SELECT
    'Rechazo no supera producción',
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM ordenes_produccion
            WHERE cantidad_rechazada > cantidad_producida
        )
        THEN 'OK'
        ELSE 'ERROR'
    END

UNION ALL

SELECT
    'Fecha término válida',
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM ordenes_produccion
            WHERE fecha_termino IS NOT NULL
              AND fecha_termino < fecha_inicio
        )
        THEN 'OK'
        ELSE 'ERROR'
    END

UNION ALL

SELECT
    'Fecha de consumo válida',
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM consumo_insumos ci
            INNER JOIN ordenes_produccion op
                ON ci.orden_produccion_id = op.orden_produccion_id
            WHERE ci.fecha_consumo < op.fecha_inicio
               OR (
                    op.fecha_termino IS NOT NULL
                    AND ci.fecha_consumo > op.fecha_termino
               )
        )
        THEN 'OK'
        ELSE 'ERROR'
    END;

-- ============================================================
-- FIN DE validaciones.sql
-- ============================================================