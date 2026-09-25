//-----------------------------------------------------------------
// Proyecto     : Proyecto 1 - Verificacion de bus con arbitraje round-robin
// Bloque       : checker (Monitor -> Checker -> Scoreboard)
//
// Descripcion:
//   Proceso que traduce observaciones crudas del monitor en veredictos
//   locales (trans_sb), sin comparar contra la transaccion originalmente
//   enviada. Clasifica cada lectura del DUT como COMPLETADO o UNDERFLOW
//   en funcion unicamente del estado instantaneo de 'pndng'.
//
// Responsabilidades:
//   - Recibir observaciones crudas (obs_cruda_t) desde monitor.sv.
//   - Emitir un veredicto local por observacion, sin estado entre
//     llamadas (stateless).
//   - Construir un trans_sb por cada observacion y publicarlo hacia
//     scoreboard.sv.

//------------------------------------------------------------------

`include "bus_defs.svh"

//------------------------------------------------------------
// Clase: checker #(bits)
//
// Parametrizada con 'bits' para calzar con trans_sb#(bits): 'bits' es un
// parametro de compilacion (fijo para toda la corrida), por lo que
// trans_sb#(8) y trans_sb#(16) son tipos distintos para el compilador.
//---------------------------------------------------------------------
class checker #(parameter bits = 16);

  typedef trans_sb#(bits) trans_sb_t;

  // Canales de comunicacion 
  mailbox #(obs_cruda_t) mon_chkr_mbx;   // entrada : monitor.sv -> checker
  mailbox #(trans_sb_t)  chkr_sb_mbx;    // salida  : checker    -> scoreboard.sv

  //---------------------------------------------------------
  // Funcion : new
  // Enlaza el checker a sus mailboxes de entrada/salida.
  // Argumentos:
  //   mon_mbx - canal de entrada, observaciones crudas del monitor
  //   sb_mbx  - canal de salida, veredictos hacia el scoreboard
  //-------------------------------------------------------------
  function new(mailbox #(obs_cruda_t) mon_mbx, mailbox #(trans_sb_t) sb_mbx);
    mon_chkr_mbx = mon_mbx;
    chkr_sb_mbx  = sb_mbx;
  endfunction

  //--------------------------------------------------
  // Tarea : run
  // Bucle principal del proceso. Bloquea en mon_chkr_mbx.get() hasta
  // recibir una observacion, la clasifica y publica el trans_sb
  // resultante. Debe ejecutarse en un proceso forkeado (fork/join_none).
  //-----------------------------------------------------------
  task run();
    obs_cruda_t   obs;
    resultado_e   res;
    trans_sb_t    veredicto;

    forever begin
      mon_chkr_mbx.get(obs);

      // Clasificacion local, sin estado: 'pndng_en_evento' refleja el
      // estado del DUT en el mismo ciclo del pop, por lo que no se
      // requiere historial de eventos anteriores.
      res = obs.pndng_en_evento ? COMPLETADO : UNDERFLOW;

      // trans_sb nace completo con los datos disponibles en este punto;
      // t_envio/latencia quedan pendientes hasta que scoreboard.sv
      // ejecute cerrar_con_envio().
      veredicto = new(obs.dato_crudo, obs.destino, obs.t_recibido, res);

      chkr_sb_mbx.put(veredicto);
    end
  endtask

endclass : checker
