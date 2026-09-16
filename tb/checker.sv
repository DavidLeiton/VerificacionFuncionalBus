// --- Archivo: checker.sv ---
class checker #(parameter bits = 16, parameter drvrs = 4);

  // 1. Mailboxes de entrada
  // Realidad: Lo que el Monitor escuchó salir del hardware[cite: 4]
  mailbox #(trans_bus #(bits, drvrs)) mon_chkr_mbx; 
  
  // Expectativa: Lo que el Scoreboard registró que debía salir[cite: 4]
  mailbox #(trans_sb  #(bits))        sb_chkr_mbx;  

  // 2. Archivo para exportar datos (para tu script de GNUplot)
  int fd; 

  function new(
    mailbox #(trans_bus #(bits, drvrs)) mc, 
    mailbox #(trans_sb  #(bits))        sbc
  );
    this.mon_chkr_mbx = mc;
    this.sb_chkr_mbx  = sbc;
  endfunction

  // 3. Tarea principal
  task run();
    $display("[%0t] [CHECKER] Iniciando validacion...", $time);
    
    // Abrimos un archivo CSV para guardar los resultados
    // Asegúrate de que la carpeta 'results/' exista si corres esto localmente
    fd = $fopen("results/reporte_latencias.csv", "w");
    if (fd) begin
      $fdisplay(fd, "Dato,Tiempo_Envio,Tiempo_Recibido,Latencia,Resultado");
    end else begin
      $display("ERROR: No se pudo abrir el archivo CSV.");
    end

    forever begin
      trans_bus #(bits, drvrs) tr_real;
      trans_sb  #(bits)        tr_esperada;

      // A. Esperamos a que el Monitor nos avise que algo salió del DUT
      mon_chkr_mbx.get(tr_real);

      // B. Sacamos la transacción más antigua del Scoreboard
      // NOTA PARA EL PROYECTO: Si el bus round-robin altera el orden de entrega 
      // entre distintos dispositivos, aquí no podrías hacer un simple .get(). 
      // Tendrías que buscar dentro de una cola (queue) en el Checker cuál 
      // transacción hace "match" con el payload recibido.
      sb_chkr_mbx.get(tr_esperada);

      // C. Registrar el tiempo de llegada y calcular latencia[cite: 4]
      tr_esperada.t_recibido = $time;
      tr_esperada.calcular_latencia();

      // D. Comparación (El veredicto final)
      if (tr_real.payload == tr_esperada.dato_enviado) begin
        tr_esperada.resultado = tr_esperada.completado; // ¡Éxito![cite: 4]
        /* $display("[%0t] [CHECKER] MATCH OK! Dato: 0x%0h | Latencia: %0d", 
                 $time, tr_real.payload, tr_esperada.latencia); */
      end else begin
        // Aquí puedes manejar los casos de pérdida o corrupción de datos
        tr_esperada.resultado = tr_esperada.perdido; //[cite: 4]
        $display("ERROR: [CHECKER] Mismatch. Esperado: 0x%0h | Recibido: 0x%0h", 
                 tr_esperada.dato_enviado, tr_real.payload);
      end

      // E. Escribir el resultado en el archivo CSV
      if (fd) begin
        $fdisplay(fd, "%0h,%0d,%0d,%0d,%s", 
                  tr_esperada.dato_enviado, 
                  tr_esperada.t_envio, 
                  tr_esperada.t_recibido, 
                  tr_esperada.latencia, 
                  tr_esperada.resultado.name());
      end
    end
  endtask

  // Función para cerrar el archivo limpiamente al terminar la simulación
  function void wrap_up();
    if (fd) begin
      $fclose(fd);
      $display("[%0t] [CHECKER] Reporte CSV cerrado correctamente.", $time);
    end
  endfunction

endclass
