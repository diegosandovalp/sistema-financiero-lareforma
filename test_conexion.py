# test_conexion.py
# Objetivo: confirmar que Python se conecta a la base la_reforma.
# No modifica nada, solo saluda y lee la versión de PostgreSQL.

import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# 1. Cargar las variables secretas desde el archivo .env
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

# 2. Construir la "dirección" de conexión y crear el motor
url = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(url)

# 3. Intentar conectarse y preguntar la versión de PostgreSQL
try:
    with engine.connect() as conexion:
        resultado = conexion.execute(text("SELECT version();"))
        version = resultado.fetchone()[0]
        print("✅ ¡Conexión exitosa!")
        print("PostgreSQL dice:", version)
except Exception as error:
    print("❌ Falló la conexión:")
    print(error)