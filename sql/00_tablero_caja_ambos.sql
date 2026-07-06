/* ============================================================
   TABLERO DE CAJA — Herramienta operativa diaria
   Base: la_reforma  |  Vista: Base | Proyectado vs Ejecutado
   ------------------------------------------------------------
   PROPÓSITO: Comparar la evolución de caja mensual entre lo
   planeado (Proyectado) y lo real (Ejecutado), para detectar
   desviaciones de liquidez a lo largo del ciclo de cultivo.
   ------------------------------------------------------------
   FLUJO DE ACTUALIZACIÓN:
   Google Sheets → export CSV → etl.py (Python) → PostgreSQL → esta query
   ------------------------------------------------------------
   Lectura: caja_proy = plan | caja_ejec = realidad
            desviacion_caja < 0 -> gastando más / ingresando menos
   NOTA: COALESCE(...,0) convierte meses sin ingreso/egreso (NULL) en 0.
   ============================================================ */
   
-- Query 1: 
WITH mensual AS (
    SELECT
        mes,
        COALESCE(SUM(valor) FILTER (WHERE tipo='Ingreso'
              AND estado_movimiento IN ('Proyectado','Fijo')), 0) AS ing_proy,
        COALESCE(SUM(valor) FILTER (WHERE tipo='Ingreso'
              AND estado_movimiento IN ('Ejecutado','Fijo')), 0)  AS ing_ejec,
        COALESCE(SUM(valor) FILTER (WHERE tipo='Egreso'
              AND estado_movimiento IN ('Proyectado','Fijo')), 0) AS egr_proy,
        COALESCE(SUM(valor) FILTER (WHERE tipo='Egreso'
              AND estado_movimiento IN ('Ejecutado','Fijo')), 0)  AS egr_ejec
    FROM movimientos
    WHERE anio = 2026
      AND escenario IN ('Base','Fijo')
    GROUP BY mes
)
SELECT
    mes,
    (ing_proy - egr_proy)                            AS flujo_proy,
    (ing_ejec - egr_ejec)                            AS flujo_ejec,
    SUM(ing_proy - egr_proy) OVER (ORDER BY mes)     AS caja_proy,
    SUM(ing_ejec - egr_ejec) OVER (ORDER BY mes)     AS caja_ejec,
    SUM(ing_ejec - egr_ejec) OVER (ORDER BY mes)
      - SUM(ing_proy - egr_proy) OVER (ORDER BY mes) AS desviacion_caja
FROM mensual
ORDER BY mes;