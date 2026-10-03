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
#   gnuplot -e "archivo='results/reporte_agregado.csv'; xmax=2000000" histograma_retardos.plt
#
# Variables que se pueden pasar con -e (todas opcionales):
#   archivo   -> CSV de entrada (por defecto: reporte_paquetes.csv)
#   binwidth  -> ancho de bin en unidades de tiempo (por defecto: se calcula
#                solo, apuntando a ~30 barras segun el rango visible)
#   xmax      -> recorta el eje X a [0, xmax]. Usalo cuando el CSV tenga
#                valores atipicos ya documentados aparte (p. ej. el caso
#                de reset a mitad de transaccion), para que no aplasten
#                la distribucion normal en una sola barra. El binwidth
#                automatico tambien se ajusta a este rango visible.
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

stats datos using 1 nooutput

# Si se paso 'xmax', recortamos el eje visible a [0, xmax] y el binwidth
# automatico (si tampoco se paso explicito) se calcula sobre ESE rango
# visible, no sobre el maximo real del archivo -- asi un puñado de
# valores atipicos ya documentados aparte no arruina la escala del resto.
if (exists("xmax")) {
  set xrange [0:xmax]
  rango_visible = xmax - STATS_min
} else {
  rango_visible = STATS_max - STATS_min
}

if (!exists("binwidth")) {
  binwidth = (rango_visible > 0) ? (rango_visible / 30.0) : 1000
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

print sprintf("Histograma generado en: %s  (archivo=%s, binwidth=%.0f, rango=[%s,%s])", \
              salida, archivo, binwidth, \
              (exists("xmax") ? "0" : sprintf("%.0f",STATS_min)), \
              (exists("xmax") ? sprintf("%.0f",xmax) : sprintf("%.0f",STATS_max)))