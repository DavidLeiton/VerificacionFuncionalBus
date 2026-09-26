//-----------------------------------------------------------------
// Proyecto     : Proyecto 1 - Verificacion de bus con arbitraje round-robin
// Bloque       : checker (Monitor -> Checker -> Scoreboard)
//------------------------------------------------------------------

`include "bus_defs.svh"

class checker #(parameter bits = 16);

  typedef trans_sb#(bits) trans_sb_t;

  // Canales de comunicacion: Cambiamos obs_cruda_t por mon_obs
  mailbox #(mon_obs)    mon_chkr_mbx;   // entrada : monitor.sv -> checker
  mailbox #(trans_sb_t) chkr_sb_mbx;    // salida  : checker    -> scoreboard.sv

  // Constructor
  function new(mailbox #(mon_obs) mon_mbx, mailbox #(trans_sb_t) sb_mbx);
    mon_chkr_mbx = mon_mbx;
    chkr_sb_mbx  = sb_mbx;
  endfunction

  // Tarea de ejecución
  task run();
    mon_obs       obs; // Usamos la clase definida por el Monitor de David
    resultado_e   res;
    trans_sb_t    veredicto;

    forever begin
      mon_chkr_mbx.get(obs);

      // Adaptamos la lectura a las propiedades de mon_obs
      res = obs.pndng ? COMPLETADO : UNDERFLOW;

      // El constructor usa las propiedades correctas: raw_data, dest, t_obs
      veredicto = new(obs.raw_data, obs.dest, obs.t_obs, res);

      chkr_sb_mbx.put(veredicto);
    end
  endtask

endclass : checker
