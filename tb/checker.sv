//-----------------------------------------------------------------
// Proyecto     : Proyecto 1 - Verificacion de bus con arbitraje round-robin
// Bloque       : checker (Monitor -> Checker -> Scoreboard)
//------------------------------------------------------------------

`include "bus_defs.svh"

class checker #(parameter bits = 16, parameter drvrs = 4);

  typedef trans_sb#(bits) trans_sb_t;

  // Canales de comunicacion: Cambiamos obs_cruda_t por mon_obs
  mailbox #(mon_obs)    mon_chkr_mbx;   // entrada : monitor.sv -> checker
  mailbox #(trans_sb_t) chkr_sb_mbx;    // salida  : checker    -> scoreboard.sv

  protected int ganador_actual   = -1;
  protected int ganador_anterior = -1;

  covergroup cg_arbitraje;
  option.per_instance = 1;
  cp_actual:   coverpoint ganador_actual   { bins dispositivo[] = {[0:drvrs-1]}; }
  cp_anterior: coverpoint ganador_anterior { bins dispositivo[] = {[0:drvrs-1]}; }
  cx_rotacion: cross cp_actual, cp_anterior;
  endgroup

  // Constructor
  function new(mailbox #(mon_obs) mon_mbx, mailbox #(trans_sb_t) sb_mbx);
    mon_chkr_mbx = mon_mbx;
    chkr_sb_mbx  = sb_mbx;
    cg_arbitraje = new();
  endfunction

  // Tarea de ejecución
  task run();
    mon_obs       obs; // Usamos la clase definida por el Monitor de David
    resultado_e   res;
    trans_sb_t    veredicto;

    forever begin
      mon_chkr_mbx.get(obs);

      if (obs.evento == EVT_ENVIO) begin

        ganador_anterior = ganador_actual;
        ganador_actual   = obs.bc_id;
        if (ganador_anterior != -1)
          cg_arbitraje.sample();
      
        if (!obs.pndng) begin
          veredicto = new(obs.raw_data, obs.dest, obs.t_obs, UNDERFLOW);
          chkr_sb_mbx.put(veredicto);
        end

        // Un envio normal (pndng=1) ya no se reporta aca: su
        // confirmacion real ahora llega por EVT_LLEGADA. Este lado
        // solo nos interesa para detectar la violacion de protocolo.


        if (!obs.pndng) begin
          res = UNDERFLOW;
          veredicto = new(obs.raw_data, obs.dest, obs.t_obs, res);
          chkr_sb_mbx.put(veredicto);
        end
      end
      else begin // EVT_LLEGADA
        res = COMPLETADO;
        veredicto = new(obs.raw_data, obs.dest, obs.t_obs, res);
        chkr_sb_mbx.put(veredicto);
      end
    end
  endtask

endclass : checker
