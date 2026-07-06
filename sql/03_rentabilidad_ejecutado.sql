/* PROPÓSITO: Medir rentabilidad real ejecutada y observar tipo termómetro,
   cuánto del presupuesto se ha gastado a la fecha. Herramienta de
   seguimiento para saber si el gasto va adelantado o atrasado. */
/* ============================================================
   BLOQUE 3 — RENTABILIDAD (VISTA EJECUTADO)  |  Base: la_reforma
   Vista: Base + Ejecutado + Fijo
   OJO: mientras falten costos reales (agroquímicos, proveedores),
        egreso_ejecutado estará INCOMPLETO. Es un termómetro parcial:
        se lee contra la etapa del año, no como cifra final.
   ============================================================ */

-- Query 1: Ingreso, egreso, utilidad y margen del año — REALMENTE ejecutado
WITH base AS (
    SELECT tipo, valor
    FROM movimientos
    WHERE anio = 2026
      AND escenario         IN ('Base','Fijo')
      AND estado_movimiento IN ('Ejecutado','Fijo')   -- ← el cambio
)
SELECT
    SUM(valor) FILTER (WHERE tipo = 'Ingreso')                        AS ingreso_ejecutado,
    SUM(valor) FILTER (WHERE tipo = 'Egreso')                         AS egreso_ejecutado,
    SUM(valor) FILTER (WHERE tipo = 'Ingreso')
      - SUM(valor) FILTER (WHERE tipo = 'Egreso')                     AS utilidad_ejecutada,
    ROUND(
        (SUM(valor) FILTER (WHERE tipo = 'Ingreso')
       - SUM(valor) FILTER (WHERE tipo = 'Egreso'))
      / NULLIF(SUM(valor) FILTER (WHERE tipo = 'Ingreso'), 0) * 100, 2) AS margen_pct_ejecutado
FROM base;

-- Query 2: TERMÓMETRO: Proyectado vs Ejecutado + % de avance del gasto
WITH datos AS (
    SELECT
        SUM(valor) FILTER (WHERE tipo='Egreso'
              AND estado_movimiento IN ('Proyectado','Fijo')) AS egreso_proy,
        SUM(valor) FILTER (WHERE tipo='Egreso'
              AND estado_movimiento IN ('Ejecutado','Fijo'))  AS egreso_ejec,
        SUM(valor) FILTER (WHERE tipo='Ingreso'
              AND estado_movimiento IN ('Proyectado','Fijo')) AS ingreso_proy,
        SUM(valor) FILTER (WHERE tipo='Ingreso'
              AND estado_movimiento IN ('Ejecutado','Fijo'))  AS ingreso_ejec
    FROM movimientos
    WHERE anio = 2026 AND escenario IN ('Base','Fijo')
)
SELECT
    egreso_proy   AS egreso_presupuestado,
    egreso_ejec   AS egreso_real_hoy,
    ROUND(100.0 * egreso_ejec / NULLIF(egreso_proy, 0), 1) AS pct_gasto_ejecutado,
    ingreso_proy  AS ingreso_presupuestado,
    ingreso_ejec  AS ingreso_real_hoy,
    ROUND(100.0 * ingreso_ejec / NULLIF(ingreso_proy, 0), 1) AS pct_ingreso_ejecutado
FROM datos;
