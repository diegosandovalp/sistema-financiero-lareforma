/* ============================================================
   ESQUEMA: labores_cultivo  |  Base: la_reforma
   ------------------------------------------------------------
   PROPÓSITO: Bitácora agronómica por lote. Registra cada labor
   de cada ciclo (siembra, fertilización, cosecha...) con su
   insumo y cantidad. Se conecta al nivel financiero (cultivos)
   vía id_cultivo, permitiendo cruzar gasto/ingreso por lote.
   ============================================================ */

CREATE TABLE labores_cultivo (
    labor_id           TEXT PRIMARY KEY,
    ciclo_id           TEXT NOT NULL,
    id_cultivo         TEXT NOT NULL,
    lote_id            TEXT NOT NULL,
    labor_tipo         TEXT NOT NULL,
    orden_ciclo        INT,
    dias_referencia    INT,
    fecha_programada   DATE,
    fecha_ejecucion    DATE,
    desviacion_dias    INT,
    insumo             TEXT,        -- admite NULL: no toda labor usa insumo
    unidad_base        TEXT,        -- admite NULL
    cantidad           NUMERIC,     -- admite NULL
    estado             TEXT,
    responsable        TEXT,
    condicion_cultivo  TEXT,
    observaciones      TEXT
);

-- Llave foránea: cada labor pertenece a un ciclo financiero existente
ALTER TABLE