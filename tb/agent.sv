// --- Archivo: agent.sv ---
class agent #(parameter bits = 16, parameter drvrs = 4);

  // 1. Declaración de los canales de comunicación (Buzones)
  mailbox #(trans_bus) tst_agnt_mbx;  // Entrada: Del Test hacia el Agente (comandos/control)
  mailbox #(trans_bus) agnt_drv_mbx;  // Salida: Hacia el Driver (para inyectar en hardware)
  mailbox #(trans_bus) agnt_sb_mbx;   // Salida: Hacia el Scoreboard (copia dorada)

  // Variable de control para saber cuántas transacciones generar.
  int num_transacciones = 10; 

  // 2. Constructor
  function new(
    mailbox #(trans_bus) ta, 
    mailbox #(trans_bus) ad, 
    mailbox #(trans_bus) asb
  );
    this.tst_agnt_mbx = ta;
    this.agnt_drv_mbx = ad;
    this.agnt_sb_mbx  = asb;
  endfunction

  // 3. Tarea principal de ejecución (Actúa como Generador + Enrutador)
  task run();
    $display("[%0t] [AGENTE] Iniciando generacion de %0d estimulos...", $time, num_transacciones);

    for (int i = 0; i < num_transacciones; i++) begin
      trans_bus tr;
      
      // A. Construir el objeto en memoria
      tr = new();
      
      // B. Aleatorizar los datos
      if (!tr.randomize()) begin
        $display("ERROR: Fallo la aleatorizacion en la transaccion %0d", i);
      end

      // C. Repartir la intención (pasa el mismo puntero a ambos bloques)
      agnt_drv_mbx.put(tr); // Al Driver para mover los pines
      agnt_sb_mbx.put(tr);  // Al Scoreboard para registro de pendientes
      
      // Retardo artificial entre generaciones
      #10; 
    end
    
    $display("[%0t] [AGENTE] Finalizada la generacion.", $time);
  endtask

endclass
