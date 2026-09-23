// --- Archivo: trans_sb.sv ---

class trans_sb #(parameter bits = 16);

  // Definición de tipos enumerados para el resultado
  // Indica el estado final de este paquete tras pasar por el Checker.
  typedef enum {completado, perdido, overflow, underflow} res_e; ]

  // Variables de seguimiento 
  bit [bits-1:0] dato_enviado; // El payload que se espera ver a la salida
  int t_envio;                 // Marca de tiempo ($time) cuando el Driver inyectó el dato
  int t_recibido;              // Marca de tiempo ($time) cuando el Monitor vio salir el dato
  int latencia;                // Diferencia entre t_recibido y t_envio
  res_e resultado;             // El veredicto del Checker

  // Constructor
  
  function new();
    // Inicializamos con valores por defecto
    dato_enviado = 0;
    t_envio      = 0;
    t_recibido   = 0;
    latencia     = 0;
    // Hasta que no se demuestre lo contrario, asumimos que está perdido
    resultado    = perdido; 
  endfunction

  // Función de cálculo de métricas
  function void calcular_latencia();
    latencia = t_recibido - t_envio; 
  endfunction

  // Función de utilidad para generar el reporte
  // Muy útil para luego exportar estos datos al archivo CSV para GNUplot.
  function void print_csv();
    // Imprime en formato: Dato,Tiempo_Envio,Tiempo_Recibido,Latencia,Resultado
    $display("%0h,%0d,%0d,%0d,%s", dato_enviado, t_envio, t_recibido, latencia, resultado.name());
  endfunction

endclass
