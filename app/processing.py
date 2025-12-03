import math
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from itertools import islice
import multiprocessing as mp
from tqdm import tqdm
import os

# =====================
# CONFIGURACIÓN GLOBAL
# =====================

MODE = os.getenv("MODE", "samples")

if MODE == "samples":
    FILE_1_PATH = "data/muestra_GCA.fna"
    FILE_2_PATH = "data/muestra_GCF.fna"
else:
    FILE_1_PATH = "data/archivo_GCA.fna"
    FILE_2_PATH = "data/archivo_GCF.fna"

OUTPUT_FILE_PATH = "output/resultado_adn.txt"

# Selecciona la tarea a ejecutar
TASK_ID = "10h"

WORK_UNIT_SIZE_LINES = 5000
CPU_WORKERS = 2


# =====================
# FUNCIONES AUXILIARES
# =====================

def count_data_lines(filename: str) -> int:
    print(f"[INFO] Contando líneas de datos en: {filename}")
    line_count = 0
    with open(filename, "r", encoding="ascii", errors="ignore") as f:
        for line in f:
            if not line.startswith(">"):
                line_count += 1
    print(f"[INFO] {filename} tiene {line_count} líneas de datos.")
    return line_count


def read_line_chunk(filename: str, start_line: int, num_lines: int):
    lines = []
    with open(filename, "r", encoding="ascii", errors="ignore") as f:
        data_lines_iterator = filter(lambda line: not line.startswith(">"), f)
        chunk_iterator = islice(data_lines_iterator, start_line, start_line + num_lines)
        for line in chunk_iterator:
            lines.append(line.strip())
    return lines


# =====================
# WORKER CPU
# =====================

def cpu_worker(work_unit):
    unit_id, start_line, num_lines, file1, file2, task_id = work_unit

    lines_f1 = read_line_chunk(file1, start_line, num_lines)
    lines_f2 = read_line_chunk(file2, start_line, num_lines)

    min_len = min(len(lines_f1), len(lines_f2))
    if min_len == 0:
        return ""

    valid_chars_prev = {'a', 'g', 'b', 't'}
    result_string = []

    for i in range(min_len):
        line1 = lines_f1[i]
        line2 = lines_f2[i]
        comparison = []

        if task_id == 'prev':
            for c1, c2 in zip(line1, line2):
                c1_lower = c1.lower()
                if (c1_lower in valid_chars_prev and
                    c1_lower == c2.lower() and
                    c1 != c2):
                    comparison.append('*')
                else:
                    comparison.append('.')

        elif task_id == '7h':
            for c1, c2 in zip(line1, line2):
                comparison.append('*' if c1 == c2 else '.')

        elif task_id == '8h':
            for c1, c2 in zip(line1, line2):
                comparison.append('*' if c1 != c2 else '.')

        elif task_id == '9h':
            for c1, c2 in zip(line1, line2):
                comparison.append(chr((ord(c1) + ord(c2)) % 128))

        elif task_id == '10h':
            for c1, c2 in zip(line1, line2):
                comparison.append(chr(abs(ord(c1) - ord(c2)) % 128))

        elif task_id == '11h':
            for c1, c2 in zip(line1, line2):
                comparison.append(c1)
                comparison.append(c2)

        else:
            return f"ERROR: Task ID '{task_id}' desconocido."

        result_line = f"{start_line + i + 1}{''.join(comparison)}"
        result_string.append(result_line)

    return "\n".join(result_string) + "\n"


# =====================
# ORQUESTADOR
# =====================

def run_processing():
    start_time = time.time()

    print("===== INICIANDO PROCESO ADN EN CPU (CLOUD READY) =====")
    print(f"===== TAREA SELECCIONADA: {TASK_ID} =====")

    lines_f1 = count_data_lines(FILE_1_PATH)
    lines_f2 = count_data_lines(FILE_2_PATH)
    total_lines = min(lines_f1, lines_f2)

    if total_lines == 0:
        print("[ERROR] No hay líneas de datos para procesar.")
        return

    print(f"[INFO] Se procesarán {total_lines} líneas en total.")

    work_units = []
    for i in range(0, total_lines, WORK_UNIT_SIZE_LINES):
        start = i
        count = min(WORK_UNIT_SIZE_LINES, total_lines - start)
        work_units.append(
            (len(work_units), start, count, FILE_1_PATH, FILE_2_PATH, TASK_ID)
        )

    print(f"[INFO] Trabajo dividido en {len(work_units)} unidades.")

    from os import makedirs
    makedirs("output", exist_ok=True)
    with open(OUTPUT_FILE_PATH, "w") as f:
        f.write("")

    with ProcessPoolExecutor(max_workers=CPU_WORKERS) as executor:
        futures = [executor.submit(cpu_worker, unit) for unit in work_units]

        print("===== PROCESANDO =====")
        for future in tqdm(as_completed(futures), total=len(futures), desc="Progreso"):
            try:
                result = future.result()
                if result:
                    with open(OUTPUT_FILE_PATH, "a") as f:
                        f.write(result)
            except Exception as e:
                print(f"[ERROR] Una unidad falló: {e}")

    total_time = time.time() - start_time

    print("===== PROCESO COMPLETADO =====")
    print(f"[INFO] Archivo de resultados: {OUTPUT_FILE_PATH}")
    print(f"[INFO] Tiempo total: {total_time:.2f} s")

    # ======================================================
    # NUEVO → MOSTRAR EJEMPLO DEL RESULTADO EN CONSOLA
    # ======================================================
    print("\n===== VISTA PREVIA DEL ARCHIVO =====")

    try:
        with open(OUTPUT_FILE_PATH, "r", encoding="ascii", errors="ignore") as f:
            lines = f.readlines()

        print("\n--- Primeras 10 líneas ---")
        for l in lines[:10]:
            print(l.strip())

        print("\n--- Últimas 10 líneas ---")
        for l in lines[-10:]:
            print(l.strip())

        print("===== FIN DE LA VISTA PREVIA =====\n")

    except Exception as e:
        print(f"[ERROR] No se pudo leer el archivo de salida: {e}")


if __name__ == "__main__":
    mp.set_start_method("spawn", force=True)
    run_processing()
