//=============================================================================
// monitor.sv - Bloque MONITOR (observador pasivo del bus)
//
// Arquitectura: Padre (monitor) + `DRVRS Hijos (monitor_child), cada uno
// mirando el Bus Controller de un dispositivo. Los Hijos reportan a una
// mailbox interna; el Padre retransmite hacia checker.sv sin modificar nada.
//
// AJUSTAR antes de compilar: nombre de interfaz/señales (bus_if, pop,
// D_pop, pndng, reset) y macros DRVRS/PCKG_SZ para que coincidan con el
// resto del proyecto.
//=============================================================================

`ifndef MONITOR_SV
`define MONITOR_SV

`ifndef DRVRS
  `define DRVRS   4
`endif
`ifndef PCKG_SZ
  `define PCKG_SZ 16
`endif

// Interfaz esperada (ya debe existir en el proyecto, compartida con el
// Manejador):
//
//   interface bus_if (input bit clk);
//     logic                reset;
//     logic [`PCKG_SZ-1:0] D_pop [`DRVRS];
//     logic                pop   [`DRVRS];
//     logic                pndng [`DRVRS];
//     clocking mon_cb @(posedge clk);
//       input pop, D_pop, pndng;
//     endclocking
//   endinterface

//-----------------------------------------------------------------------------
// Observacion cruda: destino, dato, pndng y tiempo en el instante del pop.
// Camino B: se arma completa en el constructor y no se modifica despues.
//-----------------------------------------------------------------------------
class mon_obs;
  int                  bc_id;    // Hijo que capturo el evento (solo trazabilidad)
  logic [`PCKG_SZ-1:0] raw_data; // Dato crudo tal como salio de D_pop
  bit  [7:0]           dest;     // Destino: 8 bits altos de raw_data
  bit                  pndng;    // Estado de pndng en el mismo instante
  time                 t_obs;

  function new(int bc_id, logic [`PCKG_SZ-1:0] raw_data, bit pndng, time t_obs);
    this.bc_id    = bc_id;
    this.raw_data = raw_data;
    this.dest     = raw_data[`PCKG_SZ-1 -: 8];
    this.pndng    = pndng;
    this.t_obs    = t_obs;
  endfunction

  function string to_string();
    return $sformatf("[MON] t=%0t bc=%0d dest=%0h pndng=%0b data=%0h",
                      t_obs, bc_id, dest, pndng, raw_data);
  endfunction
endclass


//-----------------------------------------------------------------------------
// Hijo: observa un unico Bus Controller. No decide ni filtra nada, solo
// reporta el evento tal cual lo ve.
//-----------------------------------------------------------------------------
class monitor_child;
  virtual bus_if     vif;
  int                bc_id;
  mailbox #(mon_obs) mon2parent;

  function new(virtual bus_if vif, int bc_id, mailbox #(mon_obs) mon2parent);
    this.vif        = vif;
    this.bc_id      = bc_id;
    this.mon2parent = mon2parent;
  endfunction
    task automatic run();
    bit pop_d = 1'b0; // valor anterior de pop, para detectar flan      co de subida

    forever begin
      @(vif.cb); // pop, D_pop y pndng muestreados en el mismo   flanco

      if (vif.reset) begin
        pop_d = 1'b0;
        continue;
      end

      // SE AGREGA [0] a todas las lecturas de los pines físicos
      if (vif.cb.pop[0][bc_id] && !pop_d) begin
        mon_obs obs;
        obs = new(.bc_id    (bc_id),
                  .raw_data (vif.cb.D_pop[0][bc_id]),
                  .pndng    (vif.pndng[0][bc_id]),
                  .t_obs    ($time));
        mon2parent.put(obs);
      end

      pop_d = vif.cb.pop[0][bc_id];
    end
  endtask
endclass


//-----------------------------------------------------------------------------
// Padre: lanza los Hijos y retransmite sus observaciones hacia checker.sv.
//-----------------------------------------------------------------------------
class monitor;
  virtual bus_if     vif;
  mailbox #(mon_obs) mon2chk;      // hacia checker.sv
  mailbox #(mon_obs) internal_mbx; // Hijos -> Padre
  monitor_child      child[`DRVRS];

  function new(virtual bus_if vif, mailbox #(mon_obs) mon2chk);
    this.vif     = vif;
    this.mon2chk = mon2chk;
    internal_mbx = new();

    foreach (child[i])
      child[i] = new(.vif(vif), .bc_id(i), .mon2parent(internal_mbx));
  endfunction

  task automatic run();
    foreach (child[i]) begin
      automatic monitor_child c = child[i]; // evita compartir i entre forks
      fork
        c.run();
      join_none
    end
    relay();
  endtask

  // Unico punto de salida: relay sin modificar + log opcional.
  task automatic relay();
    mon_obs obs;
    forever begin
      internal_mbx.get(obs);
      `ifdef MON_DEBUG
        $display(obs.to_string());
      `endif
      mon2chk.put(obs);
    end
  endtask
endclass

`endif // MONITOR_SV

