# Imagen base ligera de Python
FROM python:3.11-slim

# Evita problemas con stdout y bytecode
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Carpeta principal dentro del contenedor
WORKDIR /app

# Necesario para descargar archivos grandes (wget)
RUN apt-get update && apt-get install -y --no-install-recommends wget \
    && rm -rf /var/lib/apt/lists/*

# Copiar e instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el resto del proyecto al contenedor
COPY . .

# Asegurar que el script .sh es ejecutable
RUN chmod +x scripts/download_fna.sh

# Comando principal del contenedor:
# 1) Descargar los archivos .fna
# 2) Ejecutar el procesamiento de ADN
CMD ["bash", "-c", "MODE=${MODE:-samples} ./scripts/download_fna.sh && python -u app/main.py"]


