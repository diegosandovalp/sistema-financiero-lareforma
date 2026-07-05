# leer_tabla.py
# Objetivo: leer una tabla de la_reforma y traerla a Python como DataFrame.

import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
import pandas as pd

# 1. Cargar credenciales y crear el motor (igual que antes)
load_dotenv()
url = (
    f"postgresql+psycopg2://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}"
    f"@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
)
engine = create_engine(url)

# 2. Leer la tabla creditos completa a un DataFrame de pandas
df = pd.read_sql("SELECT * FROM creditos", engine)

# 3. Explorar lo que trajimos
print("Número de filas y columnas:", df.shape)
print("\nPrimeras 5 filas:")
print(df.head())
print("\nColumnas:")
print(df.columns.tolist())