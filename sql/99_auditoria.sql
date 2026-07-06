-- AUDITORÍA 1: tipos de dato de cada columna en todas tus tablas
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;
--------------------------------------------------------------------------

-- AUDITORÍA 2a: ¿hay amortizaciones que apunten a un crédito inexistente?
SELECT DISTINCT a.id_credito
FROM amortizaciones a
LEFT JOIN creditos c ON a.id_credito = c.id_credito
WHERE c.id_credito IS NULL;

-- AUDITORÍA 2b: ¿costos_cultivo que apunten a un cultivo inexistente?
SELECT DISTINCT cc.id_cultivo
FROM costos_cultivo cc
LEFT JOIN cultivos c ON cc.id_cultivo = c.id_cultivo
WHERE c.id_cultivo IS NULL;

-- AUDITORÍA 2c: ¿facturas que apunten a un cultivo inexistente?
SELECT DISTINCT f.id_cultivo
FROM facturas f
LEFT JOIN cultivos c ON f.id_cultivo = c.id_cultivo
WHERE c.id_cultivo IS NULL;

-- AUDITORÍA 2d: ¿nomina_detalle que apunte a un empleado inexistente?
SELECT DISTINCT nd.id_empleado
FROM nomina_detalle nd
LEFT JOIN empleados e ON nd.id_empleado = e.id_empleado
WHERE e.id_empleado IS NULL;

-- AUDITORÍA 2e: ¿facturas sin cultivo asignado (id_cultivo vacío)?
SELECT COUNT(*) AS facturas_sin_cultivo
FROM facturas
WHERE id_cultivo IS NULL;
--------------------------------------------------------------------------

-- AUDITORÍA 3a: ¿hay id_credito duplicados en creditos?
SELECT
    id_credito,
    COUNT(*) AS veces
FROM creditos
GROUP BY id_credito
HAVING COUNT(*) > 1;

-- AUDITORÍA 3b: duplicados en cultivos
SELECT id_cultivo, COUNT(*) AS veces
FROM cultivos
GROUP BY id_cultivo
HAVING COUNT(*) > 1;

-- AUDITORÍA 3c: duplicados en empleados
SELECT id_empleado, COUNT(*) AS veces
FROM empleados
GROUP BY id_empleado
HAVING COUNT(*) > 1;

-- AUDITORÍA 3d: duplicados en facturas (aquí se ccomparten ID porque cada fila registra productos de una misma factura)
SELECT id_factura, COUNT(*) AS veces
FROM facturas
GROUP BY id_factura
HAVING COUNT(*) > 1;

-- AUDITORÍA 3e: duplicados en costos_cultivo
SELECT id_costo, COUNT(*) AS veces
FROM costos_cultivo
GROUP BY id_costo
HAVING COUNT(*) > 1;
-------------------------------------------------------------------------------------------------------------------------

-- AUDITORÍA 4a: filas de movimientos con columnas críticas vacías
SELECT
    COUNT(*) FILTER (WHERE valor IS NULL)             AS sin_valor,
    COUNT(*) FILTER (WHERE tipo IS NULL)              AS sin_tipo,
    COUNT(*) FILTER (WHERE estado_movimiento IS NULL) AS sin_estado_mov,
    COUNT(*) FILTER (WHERE escenario IS NULL)         AS sin_escenario,
    COUNT(*) FILTER (WHERE anio IS NULL)              AS sin_anio,
    COUNT(*) FILTER (WHERE mes IS NULL)               AS sin_mes
FROM movimientos;

-- AUDITORÍA 4b: vacíos críticos en movimientos_varios
SELECT
    COUNT(*) FILTER (WHERE valor IS NULL)             AS sin_valor,
    COUNT(*) FILTER (WHERE tipo IS NULL)              AS sin_tipo,
    COUNT(*) FILTER (WHERE estado_movimiento IS NULL) AS sin_estado_mov,
    COUNT(*) FILTER (WHERE origen IS NULL)            AS sin_origen,
    COUNT(*) FILTER (WHERE fecha IS NULL)             AS sin_fecha
FROM movimientos_varios;

-- AUDITORÍA 4c: vacíos críticos en amortizaciones (alimentan el servicio de deuda)
SELECT
    COUNT(*) FILTER (WHERE id_credito IS NULL)   AS sin_credito,
    COUNT(*) FILTER (WHERE fecha IS NULL)         AS sin_fecha,
    COUNT(*) FILTER (WHERE salida_caja IS NULL)   AS sin_salida,
    COUNT(*) FILTER (WHERE abono_capital IS NULL) AS sin_capital
FROM amortizaciones