// --- Archivo: environment.sv ---
class environment #(parameter bits = 16, parameter drvrs = 4);
  
  // 1. Declaración de los componentes (Punteros)
  agent      #(bits, drvrs) agnt;
  driver     #(bits, drvrs) drv;
  monitor    #(bits, drvrs) mon;
  scoreboard #(bits, drvrs) sb;
  checker    #(bits, drvrs) chk;

  // 2. Creación de los buzones físicos (Las tuberías)
  // Nota que aquí sí usamos new() al momento de declararlos
  mailbox #(trans_bus #(bits, drvrs)) agnt_drv_mbx = new();
  mailbox #(trans_bus #(bits, drvrs)) agnt_sb_mbx  = new();
  mailbox #(trans_bus #(bits, drvrs)) mon_chkr_mbx = new();
  mailbox #(trans_sb  #(bits))        sb_chkr_mbx  = new();

  // 3. Constructor
  // El buzón tst_agnt_mbx viene desde arriba (desde el Test)
  function new(mailbox #(trans_bus #(bits, drvrs)) tst_agnt_mbx);
    // Inicializamos cada componente pasándole las tuberías correspondientes
    agnt = new(tst_agnt_mbx, agnt_drv_mbx, agnt_sb_mbx);
    drv  = new(agnt_drv_mbx);
    mon  = new(mon_chkr_mbx);
    sb   = new(agnt_sb_mbx, sb_chkr_mbx);
    chk  = new(mon_chkr_mbx, sb_chkr_mbx);
  endfunction

  // 4. Tarea de ejecución
  task run();
    $display("[%0t] [ENVIRONMENT] Arrancando todos los transactores...", $time);
    
    // fork...join_none arranca todas las tareas en paralelo sin bloquear el Test
    fork
      agnt.run();
      drv.run();
      mon.run();
      sb.run();
      chk.run();
    join_none
  endtask
endclass
