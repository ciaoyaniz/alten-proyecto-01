#!/usr/bin/env bash
set -euo pipefail

PG_VERSION=18

echo "[1/3] Repositorio oficial de PostgreSQL (PGDG)"
sudo apt-get update
sudo apt-get install -y postgresql-common ca-certificates
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y

echo "[2/3] PostgreSQL ${PG_VERSION}"
sudo apt-get install -y "postgresql-${PG_VERSION}"

echo "[3/3] Servicio en marcha y habilitado en el arranque"
sudo systemctl enable --now postgresql

pg_lsclusters
systemctl is-enabled postgresql

# Opciones configuradas:
# ----------------------
# set -euo pipefail -> para en el primer error
# PG_VERSION=18 -> la versión en un solo sitio
# postgresql-common -> trae el script oficial del repositorio PGDG
# apt.postgresql.org.sh -y -> añade clave y repositorio PGDG sin preguntar (Ubuntu 24.04 solo trae la 16)
# postgresql-18 -> servidor y psql; crea el cluster 18/main
# systemctl enable --now -> arranca ahora y en cada arranque
# pg_lsclusters -> tiene que salir 18 main online
# systemctl is-enabled -> tiene que salir enabled