#!/usr/bin/env bash
set -e

echo "=== [DOWNLOAD] Preparando carpeta data ==="
mkdir -p data
cd data

# ================================
# SELECCIÓN DE MODO
# ================================
MODE="${MODE:-samples}"   # default = samples
echo "=== MODO SELECCIONADO: $MODE ==="

# ================================
# URLs (ACTUALÍZALAS CON TU RELEASE)
# ================================

# Archivos de prueba (pequeños)
SAMPLE_GCA_URL="https://github.com/NicoJRM/proyecto-adn-cloud/releases/download/v1.0.0/muestra_GCA.fna"
SAMPLE_GCF_URL="https://github.com/NicoJRM/proyecto-adn-cloud/releases/download/v1.0.0/muestra_GCF.fna"

# Archivo completo dividido en partes (< 2GB cada una)
GCA_PART1_URL="https://github.com/NicoJRM/proyecto-adn-cloud/releases/download/v1.0.0/GCA_000001405.29_GRCh38.p14_genomic.fna.001"
GCA_PART2_URL="https://github.com/NicoJRM/proyecto-adn-cloud/releases/download/v1.0.0/GCA_000001405.29_GRCh38.p14_genomic.fna.002"

GCF_PART1_URL="https://github.com/NicoJRM/proyecto-adn-cloud/releases/download/v1.0.0/GCF_000001405.40_GRCh38.p14_genomic.fna.001"
GCF_PART2_URL="https://github.com/NicoJRM/proyecto-adn-cloud/releases/download/v1.0.0/GCF_000001405.40_GRCh38.p14_genomic.fna.002"



# ================================
# DESCARGA MODO "samples"
# ================================
if [ "$MODE" = "samples" ]; then
    echo "=== Descargando archivos PEQUEÑOS de prueba ==="

    wget -c "$SAMPLE_GCA_URL" -O muestra_GCA.fna
    wget -c "$SAMPLE_GCF_URL" -O muestra_GCF.fna

    echo "=== Archivos pequeños listos ==="
    exit 0
fi


# ================================
# DESCARGA MODO "full"
# ================================
if [ "$MODE" = "full" ]; then
    echo "=== Descargando archivos grandes divididos ==="

    # Descargar partes GCA
    wget -c "$GCA_PART1_URL" -O GCA.part1
    wget -c "$GCA_PART2_URL" -O GCA.part2

    # Unir
    echo "=== Reconstruyendo archivo GCA ==="
    cat GCA.part1 GCA.part2 > archivo_GCA.fna

    # Descargar partes GCF
    wget -c "$GCF_PART1_URL" -O GCF.part1
    wget -c "$GCF_PART2_URL" -O GCF.part2

    # Unir
    echo "=== Reconstruyendo archivo GCF ==="
    cat GCF.part1 GCF.part2 > archivo_GCF.fna

    echo "=== Reconstrucción completa ==="
    exit 0
fi

echo "[ERROR] MODO desconocido. Usa: MODE=samples o MODE=full"
exit 1
