# anonimizar.py
# Crea una copia ANONIMIZADA de los CSV para el portafolio.
# LEE de datos/ (real, no lo modifica) y ESCRIBE en datos_demo/ (nuevo).
# Tus datos reales quedan intactos.

import os
import pandas as pd
from faker import Faker

fake = Faker("es_CO")  # nombres/empresas con estilo colombiano
Faker.seed(42)         # semilla fija = resultados reproducibles

CARPETA_ORIGEN = "datos"
CARPETA_DESTINO = "datos_demo"
os.makedirs(CARPETA_DESTINO, exist_ok=True)

# ----------------------------------------------------------------------
# DICCIONARIOS MAESTROS: garantizan consistencia entre tablas.
# Un mismo valor real -> siempre el mismo ficticio, en todas partes.
# ----------------------------------------------------------------------
mapa_personas = {}
mapa_empresas = {}
mapa_bancos = {}
mapa_id_credito = {}
contador_id = [1001]  # lista para poder modificar dentro de la función

BANCOS_FICTICIOS = ["Banco Norte", "Banco Central", "Banco del Valle",
                    "Banco Andino", "Banco Sur"]

def anon_persona(valor):
    if pd.isna(valor) or str(valor).strip() == "":
        return valor
    if valor not in mapa_personas:
        mapa_personas[valor] = fake.name()
    return mapa_personas[valor]

def anon_empresa(valor):
    if pd.isna(valor) or str(valor).strip() == "":
        return valor
    if valor not in mapa_empresas:
        mapa_empresas[valor] = fake.company()
    return mapa_empresas[valor]

def anon_banco(valor):
    if pd.isna(valor) or str(valor).strip() == "":
        return valor
    if valor not in mapa_bancos:
        idx = len(mapa_bancos) % len(BANCOS_FICTICIOS)
        mapa_bancos[valor] = BANCOS_FICTICIOS[idx]
    return mapa_bancos[valor]

def anon_id_credito(valor):
    if pd.isna(valor):
        return valor
    if valor not in mapa_id_credito:
        mapa_id_credito[valor] = str(contador_id[0])
        contador_id[0] += 1
    return mapa_id_credito[valor]

def anon_nombre_hoja(valor):
    # Reconstruye 'Amort_Banco_ID' usando los mapas ya existentes,
    # para no filtrar los 4 dígitos reales del crédito.
    if pd.isna(valor) or str(valor).strip() == "":
        return valor
    # El id_credito real son los últimos 4 dígitos del nombre original
    partes = str(valor).split("_")
    id_real = partes[-1]  # el número al final
    # Convertir el id_real al id anonimizado (reutiliza el mapa maestro)
    try:
        id_real_num = int(id_real)
    except ValueError:
        return valor
    id_anon = mapa_id_credito.get(id_real_num, "0000")
    return f"Amort_Banco_{id_anon}"

def anon_documento(valor):
    if pd.isna(valor) or str(valor).strip() == "":
        return valor
    return fake.random_number(digits=10, fix_len=True)

def anon_cuenta(valor):
    if pd.isna(valor) or str(valor).strip() == "":
        return valor
    return fake.random_number(digits=11, fix_len=True)

# ----------------------------------------------------------------------
# CONFIGURACIÓN: qué columnas anonimizar en cada archivo, y con qué función.
# La clave es el nombre del ARCHIVO CSV; el valor es {columna: funcion}.
# ----------------------------------------------------------------------
CONFIG = {
    "Sistema_nomina_LaReforma - Nomina_empleados.csv": {
        "Nombres": anon_persona, "Apellidos": anon_persona,
        "Nombre_completo": anon_persona, "Documento": anon_documento,
        "Cuenta_bancaria": anon_cuenta, "Banco_asociado": anon_banco,
    },
    "Sistema_nomina_LaReforma - Nomina_base.csv": {
        "Nombre_empleado": anon_persona,
    },
    "Sistema_nomina_LaReforma - Nomina_provisiones_acumuladas.csv": {
        "Persona": anon_persona,
    },
    "Sistema_financiero_LaReforma - Registro_creditos.csv": {
        "Titular": anon_persona, "Banco": anon_banco,
        "ID_Credito": anon_id_credito,
        "Nombre_hoja_amortizacion": anon_nombre_hoja,
    },
    "Sistema_financiero_LaReforma - Consolidado_creditos.csv": {
        "Banco": anon_banco, "ID_Credito": anon_id_credito,
    },
    "Sistema_financiero_LaReforma - Facturas_proveedores.csv": {
        "Proveedor": anon_empresa, "Titular_factura": anon_persona,
    },
    "Sistema_financiero_LaReforma - Movimientos_varios.csv": {
        "Responsable": anon_persona, "Destinatario_o_emisor": anon_persona,
    },
}

# ----------------------------------------------------------------------
# PROCESO: recorrer TODOS los CSV de datos/.
# Si el archivo está en CONFIG, anonimiza esas columnas.
# Si no, lo copia tal cual (movimientos, costos_cultivo, etc.).
# ----------------------------------------------------------------------
# IMPORTANTE: creditos se procesa ANTES que amortizaciones,
# para que el mapa de id_credito ya exista y se reutilice.
ORDEN = [
    "Sistema_financiero_LaReforma - Registro_creditos.csv",       # primero (crea mapa id)
    "Sistema_financiero_LaReforma - Consolidado_creditos.csv",    # reutiliza mapa id
]

todos = os.listdir(CARPETA_ORIGEN)
# poner los del orden primero, luego el resto
archivos = ORDEN + [a for a in todos if a not in ORDEN]

for archivo in archivos:
    if not archivo.endswith(".csv"):
        continue
    ruta_origen = os.path.join(CARPETA_ORIGEN, archivo)
    df = pd.read_csv(ruta_origen)

    if archivo in CONFIG:
        for columna, funcion in CONFIG[archivo].items():
            if columna in df.columns:
                df[columna] = df[columna].apply(funcion)
                print(f"  {archivo}: anonimizada '{columna}'")
            else:
                print(f"  ⚠ {archivo}: no se encontró columna '{columna}'")

    ruta_destino = os.path.join(CARPETA_DESTINO, archivo)
    df.to_csv(ruta_destino, index=False)
    print(f"✓ Guardado: {archivo}")

print("\n✅ Copia anonimizada creada en 'datos_demo/'. Tus datos reales en 'datos/' NO se tocaron.")