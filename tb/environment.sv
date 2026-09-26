// --- Archivo: environment.sv ---
class environment #(parameter bits = 16, parameter drvrs = 4);
  
  // Declaración de los componentes (Punteros)
  agent      #(bits, drvrs) agnt;
  driver     #(bits, drvrs) drv;
  monitor                   mon;  // CORRECCIÓN: Se eliminaron los parámetros
  scoreboard #(drvrs)       sb;   
  checker    #(bits)        chk;  

  // Creación de los buzones físicos
  mailbox #(trans_bus) agnt_drv_mbx = new();
  mailbox #(trans_bus) agnt_sb_mbx  = new();
  mailbox #(mon_obs)   mon_chkr_mbx = new(); // CORRECCIÓN: Tipo actualizado a mon_obs
  mailbox #(trans_sb)  chkr_sb_mbx  = new(); 

  // El puntero a los pines físicos
  virtual bus_if vif;

  // 3. Constructor
  function new(virtual bus_if vif, mailbox #(trans_bus) tst_agnt_mbx);
    this.vif = vif;
    
    // Inicializamos cada componente 
    agnt = new(tst_agnt_mbx, agnt_drv_mbx, agnt_sb_mbx);
    drv  = new(agnt_drv_mbx, this.vif);      // CORRECCIÓN: Orden de buzón e interfaz invertido
    mon  = new(this.vif, mon_chkr_mbx);
    chk  = new(mon_chkr_mbx, chkr_sb_mbx); 
    sb   = new(agnt_sb_mbx, chkr_sb_mbx);
  endfunction

  // Tarea de ejecución
  task run();
    $display("[%0t] [ENVIRONMENT] Arrancando todos los transactores...", $time);
    
    // fork...join_none arranca todas las tareas en paralelo sin bloquear
    fork
      agnt.run();
      drv.run();
      mon.run();
      chk.run();
      sb.run(); // Inicia sus dos procesos de escucha en paralelo
    join_none
  endtask
endclass
