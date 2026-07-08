# etl.py
# ETL completo: carga los 9 CSV de La Reforma a PostgreSQL.
# Método: reemplazar todo (TRUNCATE + cargar), respetando llaves foráneas.
# La tabla 'cultivos' NO se toca (es nativa de PostgreSQL).

import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text, inspect
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

CARPETA_DATOS = "datos"

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
    "Sistema_cultivo_LaReforma - Labores_cultivo.csv":               "labores_cultivo",
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
    "labores_cultivo",      # -> cultivos (por id_cultivo)
]

# Invertir el diccionario: tabla -> archivo
TABLA_A_ARCHIVO = {tabla: archivo for archivo, tabla in MAPEO_TABLAS.items()}

# ----------------------------------------------------------------------
# 0. VERIFICACIÓN PREVIA: ¿existen todos los CSV antes de tocar la base?
#    Si falta alguno, avisamos y NO vaciamos nada (evita dejar la base a medias).
# ----------------------------------------------------------------------
print("=== VERIFICANDO ARCHIVOS CSV ===")
faltantes = []
for tabla in ORDEN_CARGA:
    archivo = TABLA_A_ARCHIVO[tabla]
    ruta = os.path.join(CARPETA_DATOS, archivo)
    if not os.path.exists(ruta):
        faltantes.append(archivo)
        print(f"  ❌ FALTA: {archivo}")
    else:
        print(f"  ✓ {archivo}")

if faltantes:
    print(f"\n⛔ Faltan {len(faltantes)} archivo(s). No se cargó nada.")
    print("   Revisa la carpeta 'datos/' y vuelve a intentar.")
    exit()  # detiene el script antes de tocar la base

# ----------------------------------------------------------------------
# CONTEO ANTES: cuántas filas hay en cada tabla actualmente
# ----------------------------------------------------------------------
inspector = inspect(engine)

def contar_filas(tabla):
    with engine.connect() as con:
        resultado = con.execute(text(f"SELECT COUNT(*) FROM {tabla};"))
        return resultado.scalar()

print("\n=== CONTEO ANTES ===")
conteo_antes = {}
for tabla in ORDEN_CARGA:
    conteo_antes[tabla] = contar_filas(tabla)
    print(f"  {tabla}: {conteo_antes[tabla]} filas")

# ----------------------------------------------------------------------
# RONDA 1: VACIAR todas las tablas (orden inverso: hijas primero)
# ----------------------------------------------------------------------
print("\n=== VACIANDO TABLAS (hijas -> padres) ===")
with engine.begin() as conexion:
    for tabla in reversed(ORDEN_CARGA):
        conexion.execute(text(f"TRUNCATE TABLE {tabla} CASCADE;"))
        print(f"  Vaciada: {tabla}")

# ----------------------------------------------------------------------
# RONDA 2: CARGAR cada CSV (padres -> hijas)
# ----------------------------------------------------------------------
print("\n=== CARGANDO CSV (padres -> hijas) ===")
for tabla in ORDEN_CARGA:
    archivo = TABLA_A_ARCHIVO[tabla]
    ruta = os.path.join(CARPETA_DATOS, archivo)

    try:
        # Extract
        df = pd.read_csv(ruta)
        # Transform 1: columnas a minúscula
        df.columns = df.columns.str.lower()
        # Transform 2: solo columnas que la tabla realmente tiene
        columnas_tabla = [col["name"] for col in inspector.get_columns(tabla)]
        columnas_validas = [c for c in df.columns if c in columnas_tabla]
        df = df[columnas_validas]
        # Load
        df.to_sql(tabla, engine, if_exists="append", index=False)
        print(f"  Cargada: {tabla}  ({df.shape[0]} filas, {len(columnas_validas)} columnas)")
    except Exception as e:
        print(f"  ❌ ERROR cargando {tabla}: {e}")

# ----------------------------------------------------------------------
# CONTEO DESPUÉS + RESUMEN: comparar antes vs después
# ----------------------------------------------------------------------
print("\n=== RESUMEN (antes -> después) ===")
for tabla in ORDEN_CARGA:
    despues = contar_filas(tabla)
    antes = conteo_antes[tabla]
    flecha = "✓" if despues > 0 else "⚠"
    print(f"  {flecha} {tabla}: {antes} -> {despues} filas")

print("\n✅ ETL COMPLETADO.")