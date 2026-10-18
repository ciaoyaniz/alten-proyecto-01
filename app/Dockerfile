FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN useradd --no-create-home --uid 10001 appuser
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:3000/salud', timeout=4)"

CMD ["gunicorn", "--bind", "0.0.0.0:3000", "--workers", "1", "--threads", "4", "--access-logfile", "-", "--no-control-socket", "app:app"]

# Opciones configuradas:
# ----------------------
# FROM python:3.12-slim -> Python 3.12 sobre Debian reducido; versión fija, no latest
# PYTHONUNBUFFERED=1 -> los mensajes salen al momento en docker logs
# PYTHONDONTWRITEBYTECODE=1 -> no crea archivos .pyc
# WORKDIR /app -> carpeta de trabajo del contenedor
# COPY requirements.txt + pip install -> primero las librerías; Docker reutiliza la capa si solo cambia app.py
# --no-cache-dir -> pip no guarda lo descargado; imagen más pequeña
# useradd --no-create-home + USER appuser -> la app no corre como root
# EXPOSE 3000 -> documenta el puerto; lo publica Compose
# HEALTHCHECK -> /salud cada 30 s; 3 fallos = unhealthy (con Python: slim no trae curl)
# --bind 0.0.0.0:3000 -> escucha en todas las direcciones del contenedor
# --workers 1 --threads 4 -> un proceso; el SELECT de arranque sale una vez
# --access-logfile - -> cada petición a la consola
# --no-control-socket -> appuser no tiene carpeta personal donde crear el socket
# app:app -> archivo app.py, variable app