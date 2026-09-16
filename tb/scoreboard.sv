// --- Archivo: scoreboard.sv ---
class scoreboard #(parameter bits = 16, parameter drvrs = 4);

  // 1. Mailboxes
  // Recibe la transacción cruda directamente desde el Agente (la copia exacta)
  mailbox #(trans_bus #(bits, drvrs)) agnt_sb_mbx; 
  
  // Envía la transacción analítica (expectativa) hacia el Checker
  mailbox #(trans_sb  #(bits))        sb_chkr_mbx; 

  // 2. Constructor
  function new(
    mailbox #(trans_bus #(bits, drvrs)) asb, 
    mailbox #(trans_sb  #(bits))        sbc
  );
    this.agnt_sb_mbx = asb;
    this.sb_chkr_mbx = sbc;
  endfunction

  // 3. Tarea principal
  task run();
    $display("[%0t] [SCOREBOARD] Iniciando registro de expectativas...", $time);
    
    forever begin
      trans_bus #(bits, drvrs) tr_recibida; // Lo que manda el Agente
      trans_sb  #(bits)        tr_esperada; // Lo que vamos a construir

      // A. Esperar a que el Agente genere un paquete y tomarlo del buzón
      agnt_sb_mbx.get(tr_recibida);

      // B. Crear el paquete de expectativa analítica
      tr_esperada = new();

      // C. Llenar los datos de expectativa
      // Lo que el Agente generó en el payload, es exactamente lo que esperamos 
      // que el Checker encuentre a la salida[cite: 4].
      tr_esperada.dato_enviado = tr_recibida.payload; 
      
      // Registramos el momento exacto en el que esta transacción fue creada/enviada.
      // Esto será fundamental luego para que el Checker calcule la latencia[cite: 4].
      tr_esperada.t_envio      = $time; 

      // D. Enviar la expectativa al Checker
      // Al hacer 'put', este buzón actúa como nuestra "memoria FIFO" de expectativas.
      // El Checker irá sacando estos paquetes conforme el Monitor le reporte salidas.
      sb_chkr_mbx.put(tr_esperada);

      /* Opcional: Para debuggear al inicio
      $display("[%0t] [SCOREBOARD] Expectativa registrada - Esperando payload: 0x%0h hacia el disp %0d", 
               $time, tr_esperada.dato_enviado, tr_recibida.destino);
      */
    end
  endtask

endclass
