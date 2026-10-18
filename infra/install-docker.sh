#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  echo "ERROR: ejecuta el script con tu usuario, no como root ni con sudo delante." >&2
  exit 1
fi

echo "[1/4] Dependencias y clave GPG de Docker"
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "[2/4] Repositorio oficial de Docker"
CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt-get update

echo "[3/4] Docker Engine, cliente, containerd y plugins"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

echo "[4/4] Usuario ${USER} en el grupo docker"
getent group docker > /dev/null || sudo groupadd docker
sudo usermod -aG docker "$USER"

sudo docker --version
sudo docker compose version
echo "Cierra la sesión y vuelve a entrar para usar docker sin sudo."
echo "En VS Code: Remote-SSH: Kill VS Code Server on Host... y vuelve a conectar."

# Opciones configuradas:
# ----------------------
# set -euo pipefail -> para en el primer error, variable sin definir o tubería que falla
# id -u -eq 0 -> no deja lanzarlo como root; añadiría a root al grupo docker
# >&2 y exit 1 -> error a la salida de errores y código distinto de 0
# echo "[N/4]" -> dice en qué bloque está si algo falla
# curl -fsSL -> -f falla con error HTTP, -sS sin progreso pero con errores, -L sigue redirecciones
# docker.asc -> clave GPG con la que Docker firma sus paquetes; chmod a+r para que apt la lea
# CODENAME -> versión de Ubuntu (noble) sacada de /etc/os-release
# sudo tee ... <<EOF -> escribe en /etc el texto hasta EOF; > /dev/null no lo repite en pantalla
# Types: deb / URIs -> paquetes compilados del repositorio oficial de Docker
# Suites / Components: stable -> rama de mi Ubuntu, solo versiones estables
# Architectures -> amd64, sacada con dpkg
# Signed-By -> solo acepta paquetes firmados con esa clave
# docker-ce, docker-ce-cli, containerd.io -> motor, cliente y ejecución de contenedores
# docker-buildx-plugin, docker-compose-plugin -> plugins de build y de docker compose
# systemctl enable --now docker -> arranca ahora y en cada arranque
# getent group docker || groupadd -> crea el grupo solo si no existe
# usermod -aG docker -> me añade al grupo; sin -a me quitaría de los demás, también de sudo
# Kill VS Code Server -> el grupo nuevo solo se carga en una sesión nueva