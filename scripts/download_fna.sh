#!/usr/bin/env bash
set -e

# ================================
# CONFIGURACIÓN DEL PROYECTO
# ================================
# <<< REEMPLAZA ESTO >>>
APP_COMMAND="./run_parallel_job.sh"  # Comando que inicia tu lógica de render/cómputo paralela
OUTPUT_FILE="data/resultado_final.zip" # Nombre del archivo que generará tu APP_COMMAND y que subiremos
# ================================

MODE="${MODE:-full}"
DATA_DIR="data"
RELEASE_TAG="compare"
BASE_URL="https://github.com/AbelVV0/render-cloud/releases/download/$RELEASE_TAG"

echo "=== [SETUP] Preparando ambiente y $DATA_DIR ==="
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"
echo "=== MODO SELECCIONADO: $MODE ==="

# ================================
# URLs ACTUALIZADAS a tu RELEASE
# ================================
SAMPLE_GCA_URL="$BASE_URL/muestra_GCA.fna"
SAMPLE_GCF_URL="$BASE_URL/muestra_GCF.fna"
GCA_PART1_URL="$BASE_URL/GCA_000001405.29_GRCh38.p14_genomic.fna.001"
GCA_PART2_URL="$BASE_URL/GCA_000001405.29_GRCh38.p14_genomic.fna.002"
GCF_PART1_URL="$BASE_URL/GCF_000001405.40_GRCh38.p14_genomic.fna.001"
GCF_PART2_URL="$BASE_URL/GCF_000001405.40_GRCh38.p14_genomic.fna.002"


# ================================
# FUNCIÓN DE DESCARGA Y UNIÓN (MODO FULL)
# ================================
if [ "$MODE" = "full" ]; then
    echo "=== Descargando y uniendo archivos grandes ==="

    # Descargar y unir GCA
    echo "--- Descargando partes GCA ---"
    wget -c "$GCA_PART1_URL" -O GCA.part1
    wget -c "$GCA_PART2_URL" -O GCA.part2
    cat GCA.part1 GCA.part2 > archivo_GCA.fna
    rm GCA.part1 GCA.part2 

    # Descargar y unir GCF
    echo "--- Descargando partes GCF ---"
    wget -c "$GCF_PART1_URL" -O GCF.part1
    wget -c "$GCF_PART2_URL" -O GCF.part2
    cat GCF.part1 GCF.part2 > archivo_GCF.fna
    rm GCF.part1 GCF.part2

    echo "=== Reconstrucción completa. Datos listos. ==="
fi

# ================================
# EJECUCIÓN DEL PROGRAMA PRINCIPAL
# ================================
cd .. # Volver al directorio raíz del proyecto
if [ "$MODE" != "full" ] && [ "$MODE" != "samples" ]; then
    echo "[ERROR] MODO desconocido."
    exit 1
fi

echo "--- INICIANDO COMPUTACIÓN PARALELA: $APP_COMMAND ---"
# Ejecutar el trabajo principal
$APP_COMMAND

# ================================
# SUBIDA A GOOGLE DRIVE (Requiere Rclone)
# ================================
if [ -f "$OUTPUT_FILE" ]; then
    echo "--- Trabajo terminado. Subiendo $OUTPUT_FILE a Google Drive ---"
    
    # El comando 'rclone' espera que el Google Drive ya esté configurado
    # 'gdrive_render' debe ser el nombre del remote configurado en rclone
    # 'resultados/' es la carpeta de destino en tu Drive
    rclone copy "$OUTPUT_FILE" "gdrive_render:resultados/" 
    
    echo "--- Subida completa. ¡Adiós! ---"
else
    echo "--- Aviso: No se encontró el archivo de salida ($OUTPUT_FILE). Finalizando. ---"
fi

exit 0
