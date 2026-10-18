#!/usr/bin/env bash
set -euo pipefail

APP_IP="${1:?Falta la IP de vm-docker-app. Uso: bash postgres/abrir-acceso-red.sh 192.168.60.60}"
PG_DIR=/etc/postgresql/18/main

if [[ ! -f postgres/lab1.conf ]]; then
  echo "ERROR: ejecuta el script desde ~/alten-proyecto-01, la raíz del repositorio." >&2
  exit 1
fi

echo "[1/3] Escucha: lab1.conf en conf.d"
sudo install -m 644 -o postgres -g postgres postgres/lab1.conf "${PG_DIR}/conf.d/lab1.conf"

echo "[2/3] Autenticación: regla de labapp en pg_hba.conf"
sudo sed -i '/# BEGIN lab1/,/# END lab1/d' "${PG_DIR}/pg_hba.conf"
sudo tee -a "${PG_DIR}/pg_hba.conf" > /dev/null <<HBA
# BEGIN lab1
host    labdb    labapp    ${APP_IP}/32    scram-sha-256
# END lab1
HBA
sudo systemctl restart postgresql

echo "[3/3] Cortafuegos: SSH abierto y 5432 solo desde ${APP_IP}"
sudo ufw allow 22/tcp
sudo ufw allow from "${APP_IP}" to any port 5432 proto tcp
sudo ufw --force enable

sudo ss -ltnp | grep 5432
sudo ufw status

# Opciones configuradas:
# ----------------------
# APP_IP="${1:?...}" -> la IP es el primer argumento; si falta, para con el texto de uso
# PG_DIR -> carpeta de configuración del cluster 18/main
# -f postgres/lab1.conf -> comprueba que lo lanzo desde la raíz del repositorio
# install -m 644 -o postgres -g postgres -> copia lab1.conf con dueño postgres
# sed -i '/BEGIN/,/END/d' -> borra mi bloque anterior para no duplicarlo
# tee -a -> añade al final; sin -a borraría el pg_hba.conf
# host labdb labapp IP/32 -> por red, solo esa base, ese usuario y esa IP
# scram-sha-256 -> contraseña cifrada
# restart y no reload -> listen_addresses solo se lee al arrancar
# ufw allow 22/tcp -> SSH abierto antes de activar ufw
# ufw allow from APP_IP ... 5432 -> el puerto solo para la aplicación
# ufw --force enable -> activa sin preguntar
# ss -ltnp | grep 5432 -> tiene que salir 0.0.0.0:5432