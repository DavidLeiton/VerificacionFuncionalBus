`include "bus_defs.svh"

//=============================================================================
// trans_sb  (Checker -> Scoreboard, Test Plan Seccion 5)
// Parametrizada con 'bits'.
// 'bits' es un parametro de COMPILACION
// del DUT (nunca cambia a mitad de una simulacion) 
// CICLO DE VIDA:
//   1) checker.sv construye el objeto cuando lo necesite 
//       sabe: que dato salio, en que dispositivo, cuando, y con que
//      resultado LOCAL (completado o underflow).
//   2) t_envio y latencia NO los puede conocer el checker (nunca ve el original) 
//   3) scoreboard.sv,  si guarda el t_envio de cuando recibio el
//      trans_bus original, llama cerrar_con_envio() sobre el mismo
//      objeto en el momento del match.
//=============================================================================
class trans_sb #(parameter bits = 16);

  // El checker sabe "Que y a quien"
  bit [bits-1:0] dato_enviado;  // dato observado (crudo, incluye el byte de direccion)
  int            destino;       // indice de dispositivo 0..drvrs-1 
  resultado_e    resultado;     // COMPLETADO / UNDERFLOW (checker decide)

  // t_recibido lo pone el checker;
  //  t_envio y latencia quedan para el scoreboard.sv
  time t_recibido;
  time t_envio;
  time latencia;

  //---------------------------------------------------------------------
  // Constructor: Hasta que checker tenga 4 campos construye trans_sb
  //---------------------------------------------------------------------
  function new(bit [bits-1:0] dato, int dest, time t_rx, resultado_e res);
    dato_enviado = dato;
    destino      = dest;
    t_recibido   = t_rx;
    resultado    = res;

    // Estos dos arrancan "vacios" 
    t_envio  = 0;
    latencia = 0;
    print("Creado");

  endfunction

  //---------------------------------------------------------------------
  // ESta funcion se llama cuando el scoreboard.sv, encuentra
  // el trans_bus pendiente que le corresponde a este trans_sb. 
  //---------------------------------------------------------------------
  function void cerrar_con_envio(time t_tx);
    t_envio  = t_tx;
    latencia = t_recibido - t_envio;

    print("cerrado"); 
  endfunction

  //---------------------------------------------------------------------
  // Una linea al log de simulacion, solo para debug 
  //---------------------------------------------------------------------
  function void print(string tag = "");
    $display("[%0t] %s dest=%0d dato=0x%0h t_env=%0t t_rx=%0t lat=%0t res=%s",
      $time, tag, destino, dato_enviado, t_envio, t_recibido, latencia, resultado.name());
  endfunction

endclass : trans_sb