/* PROPÓSITO: Evaluar la carga de deuda de la operación — cuánto se paga,
   cuánto se debe, y si los ingresos alcanzan a cubrirla (ratio de cobertura).
   Distingue problema de solvencia vs. problema de liquidez. */
/* ============================================================
   BLOQUE 2 — ENDEUDAMIENTO  |  Base: la_reforma
   Fuente: amortizaciones (detalle intereses vs capital)
   OJO: amortizaciones NO tiene columna 'anio'.
        El año se saca de 'fecha' con EXTRACT(YEAR FROM fecha).
   ============================================================ */
   -- Query 1: Costo financiero
SELECT
    SUM(salida_caja)   AS servicio_deuda_2026,   -- plata que sale por deuda
    SUM(intereses)     AS gasto_financiero_puro, -- solo el costo del dinero
    SUM(abono_capital) AS abono_capital_2026,    -- solo lo que baja la deuda
    MAX(salida_caja)   AS cuota_mas_alta
FROM amortizaciones
WHERE EXTRACT(YEAR FROM fecha) = 2026;

-- Query 2: Cuota más alta del año y el mes en que cae
SELECT
    EXTRACT(MONTH FROM fecha)::int AS mes,
    salida_caja                    AS cuota
FROM amortizaciones
WHERE EXTRACT(YEAR FROM fecha) = 2026
ORDER BY salida_caja DESC
LIMIT 1;

-- Query 3: Deuda pendiente: capital que aún falta por abonar desde hoy en adelante
SELECT
    SUM(abono_capital) AS deuda_pendiente,
    COUNT(*)           AS cuotas_pendientes
FROM amortizaciones
WHERE fecha >= CURRENT_DATE;	

-- Query 4:Deuda pendiente desglosada por año
SELECT
    EXTRACT(YEAR FROM fecha)::int AS anio,
    SUM(abono_capital)           AS capital_pendiente,
    COUNT(*)                     AS cuotas
FROM amortizaciones
WHERE fecha >= CURRENT_DATE
GROUP BY EXTRACT(YEAR FROM fecha)
ORDER BY anio;

-- Query 5: Ratio de cobertura: ¿los ingresos del año alcanzan para pagar la deuda del año?
SELECT
    (SELECT SUM(valor) FROM movimientos
      WHERE anio = 2026 AND tipo = 'Ingreso'
        AND escenario         IN ('Base','Fijo')
        AND estado_movimiento IN ('Proyectado','Fijo'))
    / NULLIF(
    (SELECT SUM(salida_caja) FROM amortizaciones
      WHERE EXTRACT(YEAR FROM fecha) = 2026), 0)
    AS ratio_cobertura;

/* Hallazgo Bloque 2:
   Ratio de cobertura 2026 = 5.36 → deuda del año sobradamente cubierta.
   Diciembre cierra en -261M: NO es problema de solvencia sino de liquidez.
   La cosecha entra toda en septiembre (+1.8M) y rescata la caja,
   pero oct-nov-dic (arranque ciclo siguiente) agotan ese colchón.
   Acción: refinanciar a fin de 2026, no reducir deuda total.
   NOTA ESTRATÉGICA: El ratio alto (5.36) confirma que la deuda NO es el
   cuello de botella real — lo son los costos de cultivo. El servicio de
   deuda del año es holgadamente cubierto por los ingresos. */
