# ===========================================
# histograma_retardos.plt
#
# Genera un histograma de los retardos de los paquetes que SÍ llegaron
# (resultado == COMPLETADO) a partir del reporte_paquetes.csv que escribe
# scoreboard::reportar_final().
#
# Uso:
#   gnuplot histograma_retardos.plt
#
# "reporte_paquetes.csv" debe existir en el mismo directorio desde
# donde se ejecuta este comando 
#
# Columnas del CSV (orden): t_envio,origen,destino,t_recibido,retraso,resultado
# =========================================================

set datafile separator ","
set terminal pngcairo size 900,600 enhanced font "Helvetica,12"
set output "histograma_retardos.png"

set title "Histograma de retardos de paquetes entregados (COMPLETADO)"
set xlabel "Retardo (unidades de tiempo de simulacion)"
set ylabel "Cantidad de paquetes"
set grid ytics

# --- AJUSTA ESTE VALOR según el rango real de "retraso" que veas en tu CSV.
# Con clk=10ns y retardo maximo de 20 ciclos (constraint c_retardo), el
# retraso de arbitraje deberia rondar entre 0 y unas pocas decenas de miles
# de "unidades de tiempo"
binwidth = 5000 #ajusta anchos
bin(x,width) = width*floor(x/width)

set boxwidth binwidth*0.9
set style fill solid 0.6
set key off

# El filtro "$6==\"COMPLETADO\"" descarta filas UNDERFLOW/PERDIDO, que no
# tienen un retraso real que tenga sentido graficar 
plot "< awk -F',' 'NR>1 && $6==\"COMPLETADO\" {print $5}' reporte_paquetes.csv" \
     using (bin($1,binwidth)):(1.0) smooth freq with boxes lc rgb "#4472C4"

print "Histograma generado en: histograma_retardos.png"
