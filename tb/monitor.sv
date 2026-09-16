// --- Archivo: monitor.sv ---
// Parametrizado igual que el resto para mantener la consistencia
class monitor #(parameter bits = 16, parameter drvrs = 4);

  // 1. Mailbox de salida
  // mon_chkr_mbx: Por aquí se envía el paquete observado en el hardware hacia el Checker.
  mailbox #(trans_bus #(bits, drvrs)) mon_chkr_mbx;
  
  // TODO: Declarar virtual interface al DUT
  // virtual bus_if vif;

  // 2. Constructor
  function new(mailbox #(trans_bus #(bits, drvrs)) mc);
    this.mon_chkr_mbx = mc;
  endfunction

  // 3. Tarea principal
  task run();
    $display("[%0t] [MONITOR] Iniciando observacion del DUT...", $time);

    forever begin
      // Puntero para la transacción que vamos a reconstruir
      trans_bus #(bits, drvrs) tr_observada;
      
      // TODO: Esperar el flanco de reloj de la interfaz virtual
      // @(posedge vif.clk);

      // Aquí deberás implementar la lógica para escanear todos los puertos de salida.
      // Como hay varios 'drvrs', tienes que revisar cuál de ellos tiene un dato válido.
      for (int i = 0; i < drvrs; i++) begin
        
        // TODO: Lógica física. Ejemplo conceptual:
        // Si la señal 'pop' del dispositivo 'i' está en alto, significa que 
        // ese dispositivo acaba de leer un dato del bus.
        /*
        if (vif.pop[i] == 1'b1) begin
          // 1. Instanciamos el objeto
          tr_observada = new();
          
          // 2. Llenamos los datos basándonos en los pines físicos
          // El destino es el dispositivo 'i' que acaba de hacer pop.
          tr_observada.destino = i; 
          
          // El payload es el valor del cable D_pop en ese instante[cite: 4]
          tr_observada.payload = vif.D_pop[i]; 
          
          // NOTA: Dependiendo de tu protocolo, el 'origen' podría venir dentro 
          // de los bits del payload, o el Checker tendrá que inferirlo.

          // 3. Enviamos el paquete al Checker
          mon_chkr_mbx.put(tr_observada);
          
          $display("[%0t] [MONITOR] Paquete detectado en disp %0d. Enviando a Checker.", $time, i);
        end
        */
      end // Fin del for

      #5; // Retardo temporal simulando el reloj (remover cuando uses la interfaz virtual)
    end
  endtask

endclass
