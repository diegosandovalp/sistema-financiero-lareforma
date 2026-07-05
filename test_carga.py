# test_carga.py
# PRUEBA SEGURA: carga el CSV de creditos a una tabla de prueba.
# No toca ninguna tabla real.

import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
import pandas as pd

# 1. Conexión
load_dotenv()
url = (
    f"postgresql+psycopg2://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}"
    f"@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
)
engine = create_engine(url)

# 2. Leer el CSV
archivo = "datos/Sistema_financiero_LaReforma - Registro_creditos.csv"
df = pd.read_csv(archivo)

# 2b. Normalizar nombres de columna a minúsculas (para que coincidan con Postgres)
df.columns = df.columns.str.lower()

print("CSV leído. Filas y columnas:", df.shape)
print("Columnas del CSV (ya en minúscula):", df.columns.tolist())