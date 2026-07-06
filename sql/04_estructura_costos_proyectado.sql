/* PROPÓSITO: Desglosar en qué se va el gasto del año por categoría,
   con su peso porcentual. Identifica las categorías que más pesan
   (aquí: fertilizantes o abonamientos, deuda vieja) para enfocar la gestión de costos. */
/* ============================================================
   BLOQUE 4 — ESTRUCTURA DE COSTOS  |  Base: la_reforma
   Vista: Base + Proyectado + Fijo
   Pregunta: ¿en qué se reparte el gasto del año?
   ============================================================ */

-- % de cada categoría sobre el egreso total del año
SELECT
    categoria,
    SUM(valor)                                             AS total_categoria,
    ROUND(100.0 * SUM(valor) / SUM(SUM(valor)) OVER (), 2) AS pct_del_total
FROM movimientos
WHERE anio = 2026
  AND tipo = 'Egreso'
  AND estado_movimiento IN ('Proyectado','Fijo')
  AND escenario         IN ('Base','Fijo')
GROUP BY categoria
ORDER BY total_categoria DESC;

-------------------------------------------------------

-- Estructura de costos AGRUPADA: top categorías + resto en "Otros menores"
WITH por_categoria AS (
    SELECT
        categoria,
        SUM(valor) AS total_categoria
    FROM movimientos
    WHERE anio = 2026
      AND tipo = 'Egreso'
      AND estado_movimiento IN ('Proyectado','Fijo')
      AND escenario         IN ('Base','Fijo')
    GROUP BY categoria
),
etiquetada AS (
    SELECT
        -- Si pesa < 1% del total, se renombra a 'Otros menores'
        CASE
            WHEN total_categoria < 0.01 * SUM(total_categoria) OVER ()
            THEN 'Otros menores'
            ELSE categoria
        END AS categoria_agrupada,
        total_categoria
    FROM por_categoria
)
SELECT
    categoria_agrupada                                          AS categoria,
    SUM(total_categoria)                                        AS total,
    ROUND(100.0 * SUM(total_categoria)
          / SUM(SUM(total_categoria)) OVER (), 2)              AS pct_del_total
FROM etiquetada
GROUP BY categoria_agrupada
ORDER BY total DESC;