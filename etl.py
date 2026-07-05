# etl.py
# ETL completo: carga los 9 CSV de La Reforma a PostgreSQL.
# Método: reemplazar todo (TRUNCATE + cargar), respetando llaves foráneas.
# La tabla 'cultivos' NO se toca (es nativa de PostgreSQL).

import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
import pandas as pd

# ----------------------------------------------------------------------
# 1. CONEXIÓN
# ----------------------------------------------------------------------
load_dotenv()
url = (
    f"postgresql+psycopg2://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}"
    f"@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
)
engine = create_engine(url)

# ----------------------------------------------------------------------
# 2. DICCIONARIO: archivo CSV -> tabla en PostgreSQL
# ----------------------------------------------------------------------
MAPEO_TABLAS = {
    "Flujo_caja_LaReforma - Movimientos.csv":                        "movimientos",
    "Sistema_financiero_LaReforma - Consolidado_creditos.csv":       "amortizaciones",
    "Sistema_financiero_LaReforma - Registro_creditos.csv":          "creditos",
    "Sistema_financiero_LaReforma - Facturas_proveedores.csv":       "facturas",
    "Sistema_financiero_LaReforma - Movimientos_varios.csv":         "movimientos_varios",
    "Sistema_proyeccion_LaReforma - Costos_cultivo.csv":             "costos_cultivo",
    "Sistema_nomina_LaReforma - Nomina_empleados.csv":               "empleados",
    "Sistema_nomina_LaReforma - Nomina_base.csv":                    "nomina_detalle",
    "Sistema_nomina_LaReforma - Nomina_provisiones_acumuladas.csv":  "nomina_provisiones",
}

# ----------------------------------------------------------------------
# 3. ORDEN según llaves foráneas
#    Padres primero, hijas después (para CARGAR).
#    Para VACIAR se usa el orden inverso.
# ----------------------------------------------------------------------
ORDEN_CARGA = [
    # --- PADRES (independientes) ---
    "creditos",
    "empleados",
    "movimientos",
    "movimientos_varios",
    # --- HIJAS (dependen de un padre) ---
    "amortizaciones",       # -> creditos
    "facturas",             # -> cultivos
    "costos_cultivo",       # -> cultivos
    "nomina_detalle",       # -> empleados
    "nomina_provisiones",   # -> empleados
]

# Invertir el diccionario: tabla -> archivo (para buscar el CSV de cada tabla)
TABLA_A_ARCHIVO = {tabla: archivo for archivo, tabla in MAPEO_TABLAS.items()}

# ----------------------------------------------------------------------
# 4. RONDA 1: VACIAR todas las tablas (orden inverso: hijas primero)
# ----------------------------------------------------------------------
print("=== VACIANDO TABLAS (hijas -> padres) ===")
with engine.begin() as conexion:
    for tabla in reversed(ORDEN_CARGA):
        conexion.execute(text(f"TRUNCATE TABLE {tabla} CASCADE;"))
        print(f"  Vaciada: {tabla}")

# ----------------------------------------------------------------------
# 5. RONDA 2: CARGAR cada CSV (padres -> hijas)
# ----------------------------------------------------------------------
from sqlalchemy import inspect
inspector = inspect(engine)

print("\n=== CARGANDO CSV (padres -> hijas) ===")
for tabla in ORDEN_CARGA:
    archivo = TABLA_A_ARCHIVO[tabla]
    ruta = f"datos/{archivo}"

    # Extract: leer el CSV
    df = pd.read_csv(ruta)

    # Transform 1: nombres de columna a minúscula
    df.columns = df.columns.str.lower()

    # Transform 2: quedarse SOLO con las columnas que la tabla realmente tiene
    columnas_tabla = [col["name"] for col in inspector.get_columns(tabla)]
    columnas_validas = [c for c in df.columns if c in columnas_tabla]
    df = df[columnas_validas]

    # Load: cargar a PostgreSQL
    df.to_sql(tabla, engine, if_exists="append", index=False)

    print(f"  Cargada: {tabla}  ({df.shape[0]} filas, {len(columnas_validas)} columnas)")

print("\n✅ ETL COMPLETADO. Todas las tablas actualizadas.")