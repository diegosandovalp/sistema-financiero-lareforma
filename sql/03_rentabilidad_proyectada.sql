/* ============================================================
   BLOQUE 3 — RENTABILIDAD (VISTA PROYECTADA)  |  Base: la_reforma
   Vista: Base + Proyectado + Fijo (regla de oro del doble eje)
   Gemelo de 03_rentabilidad_ejecutado. ÚNICO cambio real:
     estado_movimiento IN ('Proyectado','Fijo')  ← vs 'Ejecutado'
   ------------------------------------------------------------
   PROPÓSITO: Medir la rentabilidad PRESUPUESTADA del año —
   ingreso, egreso, utilidad y margen esperados según el plan.
   Es la línea base contra la que se compara lo ejecutado.
   ============================================================ */

-- Query 1: Ingreso, egreso, utilidad y margen del año — PROYECTADO (plan)
WITH base AS (
    SELECT tipo, valor
    FROM movimientos
    WHERE anio = 2026
      AND escenario         IN ('Base','Fijo')
      AND estado_movimiento IN ('Proyectado','Fijo')
)
SELECT
    SUM(valor) FILTER (WHERE tipo = 'Ingreso')                        AS ingreso_proyectado,
    SUM(valor) FILTER (WHERE tipo = 'Egreso')                         AS egreso_proyectado,
    SUM(valor) FILTER (WHERE tipo = 'Ingreso')
      - SUM(valor) FILTER (WHERE tipo = 'Egreso')                     AS utilidad_proyectada,
    ROUND(
        (SUM(valor) FILTER (WHERE tipo = 'Ingreso')
       - SUM(valor) FILTER (WHERE tipo = 'Egreso'))
      / NULLIF(SUM(valor) FILTER (WHERE tipo = 'Ingreso'), 0) * 100, 2) AS margen_pct_proyectado
FROM base;