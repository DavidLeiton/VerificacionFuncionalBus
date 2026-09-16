// --- Archivo: agent.sv ---
// Mantenemos los mismos parámetros del paquete para que los tamaños coincidan perfectamente.
class agent #(parameter bits = 16, parameter drvrs = 4);

  // 1. Declaración de los Mailboxes
  // tst_agnt_mbx: Por aquí el Test le podría decir al agente "genera 50 paquetes tipo broadcast".
  mailbox #(trans_bus #(bits, drvrs)) tst_agnt_mbx; 
  
  // agnt_drv_mbx: Por aquí mandamos la transacción para que el Driver la aplique en hardware.
  mailbox #(trans_bus #(bits, drvrs)) agnt_drv_mbx; 
  
  // agnt_sb_mbx: LA NUEVA CONEXIÓN. Mandamos la copia exacta al Scoreboard.
  mailbox #(trans_bus #(bits, drvrs)) agnt_sb_mbx;  

  // Variable de control para saber cuántas transacciones generar.
  // El Test de más alto nivel puede modificar esta variable antes de llamar al run().
  int num_transacciones = 10; 

  // 2. Constructor
  // Recibe los tres buzones físicos creados por el Environment y los conecta a sus punteros internos.
  function new(
    mailbox #(trans_bus #(bits, drvrs)) ta, 
    mailbox #(trans_bus #(bits, drvrs)) ad, 
    mailbox #(trans_bus #(bits, drvrs)) asb
  );
    this.tst_agnt_mbx = ta;
    this.agnt_drv_mbx = ad;
    this.agnt_sb_mbx  = asb;
  endfunction

  // 3. Tarea principal de ejecución
  task run();
    $display("[%0t] [AGENTE] Iniciando generacion de %0d estimulos...", $time, num_transacciones);

    for (int i = 0; i < num_transacciones; i++) begin
      // Declaramos el puntero a la transacción
      trans_bus #(bits, drvrs) tr;
      
      // A. Construir el objeto en memoria
      tr = new();
      
      // B. Aleatorizar los datos
      // Al llamar a tr.randomize(), SystemVerilog busca automáticamente las reglas 
      // 'constraint' que escribimos en trans_bus.sv y genera valores legales.
      if (!tr.randomize()) begin
        $display("ERROR: Fallo la aleatorizacion en la transaccion %0d", i);
      end
      
      // Opcional: imprimir en consola para hacer debugging a mano al principio.
      // tr.print();

      // C. Enviar las copias a las tuberías
      // ¡Ojo! Como en SystemVerilog pasamos por referencia (punteros), tanto el Driver 
      // como el Scoreboard van a recibir exactamente el mismo paquete.
      agnt_drv_mbx.put(tr); // Hacia el DUT
      agnt_sb_mbx.put(tr);  // Hacia la referencia dorada
      
      // Podemos agregar un pequeño retardo artificial entre generaciones
      #10; 
    end
    
    $display("[%0t] [AGENTE] Finalizada la generacion.", $time);
  endtask

endclass
