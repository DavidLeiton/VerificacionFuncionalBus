# ===========================================
# histograma_retardos.plt
#
# Genera un histograma de los retardos de los paquetes que SI llegaron
# (resultado == COMPLETADO) a partir de un reporte_*.csv escrito por
# scoreboard::reportar_final().
#
# Uso simple (usa los valores por defecto, igual que antes):
#   gnuplot histograma_retardos.plt
#
# Uso parametrizado (pasando variables por -e, sin tocar este archivo):
#   gnuplot -e "archivo='results/reporte_pckgsz32.csv'" histograma_retardos.plt
#   gnuplot -e "archivo='results/reporte_drvrs8.csv'; binwidth=150000" histograma_retardos.plt
#   gnuplot -e "archivo='results/reporte_seed3.csv'; salida='hist_seed3.png'; titulo='Semilla 3'" histograma_retardos.plt
#
# Variables que se pueden pasar con -e (todas opcionales):
#   archivo   -> CSV de entrada (por defecto: reporte_paquetes.csv)
#   binwidth  -> ancho de bin en unidades de tiempo (por defecto: se calcula
#                solo, apuntando a ~30 barras segun el rango real de datos)
#   salida    -> nombre del PNG de salida (por defecto: histograma_retardos.png)
#   titulo    -> titulo del grafico
#
# Columnas del CSV (orden): t_envio,origen,destino,t_recibido,retraso,resultado
# =========================================================

if (!exists("archivo")) archivo = "reporte_paquetes.csv"
if (!exists("salida"))  salida  = "histograma_retardos.png"
if (!exists("titulo"))  titulo  = "Histograma de retardos de paquetes entregados (COMPLETADO)"

set datafile separator ","
set terminal pngcairo size 900,600 enhanced font "Helvetica,12"
set output salida

# Comando que filtra solo las filas COMPLETADO y extrae la columna "retraso"
# (columna 5) del archivo que se haya indicado en 'archivo'.
datos = sprintf("< awk -F',' 'NR>1 && $6==\"COMPLETADO\" {print $5}' %s", archivo)

# Si no se paso 'binwidth' explicitamente por -e, se calcula uno automatico
# apuntando a ~30 barras, segun el rango real de "retraso" en ESTE archivo.
# Asi, el mismo script sirve para pckg_sz=16 (retardos de ~1.5M) y para
# pckg_sz=64 o drvrs=8 (retardos varias veces mas grandes) sin tener que
# editar nada a mano.
if (!exists("binwidth")) {
  stats datos using 1 nooutput
  rango = STATS_max - STATS_min
  binwidth = (rango > 0) ? (rango / 30.0) : 1000
}

bin(x,width) = width*floor(x/width)

set title titulo
set xlabel "Retardo (unidades de tiempo de simulacion)"
set ylabel "Cantidad de paquetes"
set grid ytics
set boxwidth binwidth*0.9
set style fill solid 0.6
set key off

plot datos using (bin($1,binwidth)):(1.0) smooth freq with boxes lc rgb "#4472C4"

print sprintf("Histograma generado en: %s  (archivo=%s, binwidth=%.0f)", salida, archivo, binwidth)
