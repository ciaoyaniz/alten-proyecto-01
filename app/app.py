import logging
import os
from decimal import Decimal

import psycopg2
import psycopg2.extras
from flask import Flask, jsonify

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("lab1")

app = Flask(__name__)
app.json.ensure_ascii = False

DB = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": int(os.environ.get("DB_PORT", "5432")),
    "dbname": os.environ.get("DB_NAME", "labdb"),
    "user": os.environ.get("DB_USER", "labapp"),
    "password": os.environ.get("DB_PASSWORD"),
    "connect_timeout": 5,
    "application_name": "lab-postgres-app",
}

CONSULTA = "SELECT id, nombre, precio FROM productos ORDER BY id"


def consultar(sql):
    if not DB["password"]:
        raise RuntimeError("Falta la variable DB_PASSWORD (revisa el archivo .env)")
    conn = psycopg2.connect(**DB)
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(sql)
            filas = cur.fetchall()
    finally:
        conn.close()
    return [{k: float(v) if isinstance(v, Decimal) else v for k, v in f.items()} for f in filas]


def select_de_arranque():
    try:
        filas = consultar(CONSULTA)
        log.info("Conectado a %s:%s/%s como %s", DB["host"], DB["port"], DB["dbname"], DB["user"])
        log.info("Resultado del SELECT (%d filas):", len(filas))
        for f in filas:
            log.info("  %s | %s | %.2f", f["id"], f["nombre"], f["precio"])
    except Exception as error:
        log.error("No se pudo consultar PostgreSQL al arrancar: %s", str(error).strip())


@app.get("/")
def index():
    return jsonify(
        aplicacion="lab-postgres-app",
        base_de_datos=f'{DB["host"]}:{DB["port"]}/{DB["dbname"]}',
        endpoints=["/productos", "/salud"],
    )


@app.get("/productos")
def productos():
    try:
        return jsonify(consultar(CONSULTA))
    except Exception as error:
        log.error("Error en /productos: %s", str(error).strip())
        return jsonify(error="No se pudo consultar la base de datos"), 503


@app.get("/salud")
def salud():
    try:
        consultar("SELECT 1 AS ok")
        return jsonify(estado="ok")
    except Exception as error:
        log.error("Error en /salud: %s", str(error).strip())
        return jsonify(estado="error"), 503


select_de_arranque()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)

# Opciones configuradas:
# ----------------------
# psycopg2 -> conector de Python con PostgreSQL
# logging.basicConfig -> cada mensaje con fecha y nivel; se ve con docker logs
# ensure_ascii = False -> tildes y eñes tal cual en el JSON
# os.environ.get(VAR, defecto) -> lee una variable de entorno; usa el defecto si no existe
# DB_PASSWORD -> sin valor por defecto para que no acabe en el repositorio
# connect_timeout: 5 -> si PostgreSQL no contesta, error a los 5 segundos
# application_name -> nombre de la conexión dentro de PostgreSQL
# consultar() -> abre, consulta y cierra siempre (finally); Decimal a float para el JSON
# RealDictCursor -> cada fila como diccionario
# select_de_arranque() -> SELECT al arrancar y filas al log; si falla, la app sigue en marcha
# GET /productos -> filas en JSON o 503; el detalle solo al log (lleva IP y usuario)
# GET /salud -> SELECT 1 para el HEALTHCHECK del Dockerfile
# host="0.0.0.0" -> escucha en todas las IP de la VM