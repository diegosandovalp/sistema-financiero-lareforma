/* PROPÓSITO: Medir la salud de liquidez del año — punto más bajo de caja,
   cuándo ocurre, y cuántos meses hay en déficit. Clave para anticipar
   necesidades de financiación en el ciclo de cultivo. */
/* ============================================================
   BLOQUE 1 — LIQUIDEZ (VISTA PROYECTADO) |  Base: la_reforma
   Vista: Base + Proyectado + Fijo 
   OJO: 'mes' es texto en formato 'AAAA-MM' (ej. '2026-12'),
        NO es un número 1-12. Por eso no se castea a int.
   ============================================================ */
-- Query 1: Resumen liquidez del año
WITH flujo_mensual AS (
    -- Etapa 1: ingreso - egreso por cada mes (CASE WHEN suma condicional)
    SELECT
        mes,
        SUM(CASE WHEN tipo = 'Ingreso' THEN valor ELSE 0 END)
      - SUM(CASE WHEN tipo = 'Egreso'  THEN valor ELSE 0 END) AS flujo_neto
    FROM movimientos
    WHERE anio = 2026
      AND estado_movimiento IN ('Proyectado','Fijo')   -- Eje 2
      AND escenario         IN ('Base','Fijo')          -- Eje 1
    GROUP BY mes
),
caja AS (
    -- Etapa 2: saldo acumulado corriendo mes a mes (window function)
    -- El formato 'AAAA-MM' ordena bien alfabéticamente = cronológico
    SELECT
        mes,
        flujo_neto,
        SUM(flujo_neto) OVER (ORDER BY mes) AS caja_acumulada
    FROM flujo_mensual
)
-- Etapa 3: los 5 KPIs. MIN/MAX/COUNT = agregados;
-- los (SELECT...) entre paréntesis = subconsultas escalares.
SELECT
    MIN(caja_acumulada)                                        AS caja_minima,
    (SELECT mes FROM caja ORDER BY caja_acumulada ASC LIMIT 1) AS mes_caja_minima,
    COUNT(*) FILTER (WHERE flujo_neto < 0)                     AS meses_flujo_negativo,
    (SELECT caja_acumulada FROM caja WHERE mes = '2026-12')    AS caja_cierre_diciembre,
    MAX(caja_acumulada)                                        AS caja_maxima
FROM caja;

-- Query 2: Radiografía mes a mes
WITH flujo_mensual AS (
    SELECT
        mes,
        SUM(CASE WHEN tipo = 'Ingreso' THEN valor ELSE 0 END) AS ingresos,
        SUM(CASE WHEN tipo = 'Egreso'  THEN valor ELSE 0 END) AS egresos,
        SUM(CASE WHEN tipo = 'Ingreso' THEN valor ELSE 0 END)
      - SUM(CASE WHEN tipo = 'Egreso'  THEN valor ELSE 0 END) AS flujo_neto
    FROM movimientos
    WHERE anio = 2026
      AND estado_movimiento IN ('Proyectado','Fijo')
      AND escenario         IN ('Base','Fijo')
    GROUP BY mes
)
SELECT
    mes,
    ingresos,
    egresos,
    flujo_neto,
    SUM(flujo_neto) OVER (ORDER BY mes) AS caja_acumulada
FROM flujo_mensual
ORDER BY mes;