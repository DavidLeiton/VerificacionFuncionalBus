`include "bus_defs.svh"

//=============================================================================
// trans_sb  (Checker -> Scoreboard, Test Plan Seccion 5)
// Parametrizada con 'bits', igual que el ejemplo de la FIFO. Tiene
// sentido hacerlo asi porque 'bits' es un parametro de COMPILACION
// del DUT (nunca cambia a mitad de una simulacion) -- no es un campo
// que varie transaccion a transaccion, asi que atarlo al tipo de la
// clase no genera conflicto.
//
// CICLO DE VIDA (Camino B):
//   1) checker.sv construye el objeto en el instante exacto en que ya
//      sabe: que dato salio, en que dispositivo, cuando, y con que
//      resultado LOCAL (completado o underflow -- eso lo puede saber
//      con un solo evento, sin memoria del pasado).
//   2) t_envio y latencia NO los puede conocer el checker -- nunca vio
//      el envio original. Quedan en 0: no es un veredicto, es la
//      bandera honesta de "todavia pendiente".
//   3) scoreboard.sv, que si guardo el t_envio de cuando recibio el
//      trans_bus original, llama cerrar_con_envio() sobre ESTE MISMO
//      objeto en el momento del match. Ahi, y solo ahi, se calcula la
//      latencia -- en el unico lugar que tiene los dos tiempos.
//=============================================================================
class trans_sb #(parameter bits = 16);

  // "Que y a quien" -- lo unico que el checker puede saber sin ayuda.
  bit [bits-1:0] dato_enviado;  // dato observado (crudo, incluye el byte de direccion)
  int            destino;       // indice de dispositivo 0..drvrs-1 (ya decodificado)
  resultado_e    resultado;     // COMPLETADO / UNDERFLOW -- decidido por el checker

  // "Cuando" -- t_recibido lo pone el checker; t_envio y latencia
  // quedan pendientes hasta que scoreboard.sv los complete.
  time t_recibido;
  time t_envio;
  time latencia;

  //---------------------------------------------------------------------
  // Constructor: exige los 4 datos que el checker YA tiene en mano al
  // crear el objeto. No hay "relleno que se corrige despues" para
  // estos cuatro -- si todavia no los conoces, todavia no es momento
  // de construir el trans_sb.
  //---------------------------------------------------------------------
  function new(bit [bits-1:0] dato, int dest, time t_rx, resultado_e res);
    dato_enviado = dato;
    destino      = dest;
    t_recibido   = t_rx;
    resultado    = res;

    // Estos dos arrancan "vacios" a proposito -- no es una suposicion
    // sobre su valor, es que honestamente todavia no se conocen aqui.
    t_envio  = 0;
    latencia = 0;
  endfunction

  //---------------------------------------------------------------------
  // La llama UNICAMENTE scoreboard.sv, en el instante en que encuentra
  // el trans_bus pendiente que le corresponde a este trans_sb. Es la
  // unica funcion de la clase que puede calcular la latencia, porque
  // es la unica que recibe el segundo tiempo que faltaba.
  //---------------------------------------------------------------------
  function void cerrar_con_envio(time t_tx);
    t_envio  = t_tx;
    latencia = t_recibido - t_envio;
  endfunction

  //---------------------------------------------------------------------
  // Una linea al log de simulacion, solo para debug mientras
  // desarrollan. NO es el CSV real: el CSV de verdad (con $fopen/
  // $fwrite a un archivo) vive en scoreboard.sv, que es quien junta
  // esto con el trans_bus emparejado y con todas las demas filas del
  // reporte final.
  //---------------------------------------------------------------------
  function void print(string tag = "");
    $display("[%0t] %s dest=%0d dato=0x%0h t_env=%0t t_rx=%0t lat=%0t res=%s",
      $time, tag, destino, dato_enviado, t_envio, t_recibido, latencia, resultado.name());
  endfunction

endclass : trans_sb