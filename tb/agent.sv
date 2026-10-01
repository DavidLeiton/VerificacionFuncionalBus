// --- agent.sv --
class agent #(parameter bits = 16, parameter drvrs = 4);

  // 1. Declaración de los canales de comunicación (Buzones)
  mailbox #(trans_bus #(bits, drvrs)) tst_agnt_mbx;  // Entrada: Del Test hacia el Agente (comandos/control)
  mailbox #(trans_bus #(bits, drvrs)) agnt_drv_mbx;  // Salida: Hacia el Driver (para el hardware)
  mailbox #(trans_bus #(bits, drvrs)) agnt_sb_mbx;   // Salida: Hacia el Scoreboard 

  // Variable de control para saber cuántas transacciones generar.
  int num_transacciones = 10; 

  event fin_generacion; 

  // 2. Constructor
  function new(
    mailbox #(trans_bus #(bits, drvrs)) ta, 
    mailbox #(trans_bus #(bits, drvrs)) ad, 
    mailbox #(trans_bus #(bits, drvrs)) asb
  );
    this.tst_agnt_mbx = ta;
    this.agnt_drv_mbx = ad;
    this.agnt_sb_mbx  = asb;
  endfunction

  // 3. Tarea principal de ejecución (Actúa como Generador + Enrutador)
  task run();
    trans_bus #(bits, drvrs) tr_dirigido;

    $display("[%0t] [AGENTE] Iniciando generacion de %0d estimulos...", $time, num_transacciones);

     // drenar los casos de esquina dirigidos por el Test, si hay ---
    while (tst_agnt_mbx.try_get(tr_dirigido)) begin
      $display("[%0t] [AGENTE] Caso de esquina dirigido: origen=%0d destino=%0d tipo=%s retardo=%0d",
                $time, tr_dirigido.origen, tr_dirigido.destino, tr_dirigido.tipo.name(), tr_dirigido.retardo);
      agnt_drv_mbx.put(tr_dirigido);
      agnt_sb_mbx.put(tr_dirigido);
      #10;
    end


    for (int i = 0; i < num_transacciones; i++) begin
      trans_bus #(bits, drvrs) tr;
      
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
    -> fin_generacion;                // es seguro chequear pendientes
  
  endtask

endclass