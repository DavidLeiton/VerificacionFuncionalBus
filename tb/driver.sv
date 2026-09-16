// --- Archivo: driver.sv ---

// ============================================================================
// CLASE HIJA: Objeto Emulador de FIFO
// Representa la interfaz de un solo dispositivo conectado al bus.
// ============================================================================
class fifo_emul #(parameter bits = 16, parameter drvrs = 4);
  int id; // Identificador de cuál dispositivo es este hijo (ej. Hijo 0, Hijo 1...)

  // LA REGLA DEL PROYECTO: Usar Queues.
  // En SystemVerilog, el símbolo [$] declara una cola dinámica.
  trans_bus #(bits, drvrs) cola_fifo[$]; 
  
  // TODO: Aquí deberás agregar el puntero a la "virtual interface" 
  // para poder manipular las señales físicas (clk, push, D_push, pndng) del DUT.
  // virtual bus_if vif;

  function new(int num_id);
    this.id = num_id;
  endfunction

  // Función que el Padre llama para meter un paquete a la cola de este hijo
  function void recibir_paquete(trans_bus #(bits, drvrs) tr);
    cola_fifo.push_back(tr); // push_back mete el elemento al final de la cola
  endfunction

  // Tarea independiente de este hijo para sacar datos e interactuar con los pines
  task run();
    trans_bus #(bits, drvrs) tr_actual;
    
    forever begin // Ciclo infinito escuchando el reloj
      // TODO: Aquí debes esperar el flanco de reloj (ej. @(posedge vif.clk))
      
      // Si hay elementos en la cola, y es el momento de enviarlo (evaluando tr_actual.retardo)
      if (cola_fifo.size() > 0) begin
        tr_actual = cola_fifo.pop_front(); // Saca el primero de la cola (FIFO)
        
        // TODO: Lógica de pines del DUT.
        // 1. Levantar la señal de 'pndng' para este id.
        // 2. Colocar tr_actual.payload en 'D_push' de este id.
        // 3. Dar el pulso de 'push' en el momento correcto.
      end
      
      #5; // Retardo temporal para simular el reloj mientras no tengas la virtual interface
    end
  endtask
endclass


// ============================================================================
// CLASE PADRE: Controlador del Manejador
// ============================================================================
class driver #(parameter bits = 16, parameter drvrs = 4);
  
  // Mailbox que recibe desde el Agente
  mailbox #(trans_bus #(bits, drvrs)) agnt_drv_mbx;
  
  // Arreglo dinámico de Hijos (Objetos emuladores de FIFO)[cite: 1]
  fifo_emul #(bits, drvrs) hijos[];

  function new(mailbox #(trans_bus #(bits, drvrs)) ad);
    this.agnt_drv_mbx = ad;
    
    // Inicializamos el arreglo para que tenga exactamente la cantidad 
    // de dispositivos definidos por el parámetro 'drvrs'
    hijos = new[drvrs];
    
    // Inicializamos cada hijo pasándole su ID (0, 1, 2, 3...)
    foreach(hijos[i]) begin
      hijos[i] = new(i);
    end
  endfunction

  task run();
    trans_bus #(bits, drvrs) tr_recibida;
    
    $display("[%0t] [DRIVER] Manejador iniciado. Emuladores creados: %0d", $time, drvrs);

    // 1. Arrancar los sub-procesos de los hijos en paralelo
    foreach(hijos[i]) begin
      // Usamos una variable local (automatic) para que el fork no confunda los índices
      automatic int index = i; 
      fork
        hijos[index].run();
      join_none
    end

    // 2. Tarea principal del Padre: Escuchar al agente y enrutar
    forever begin
      // Extrae la transacción del buzón (se queda esperando si está vacío)
      agnt_drv_mbx.get(tr_recibida);
      
      // Enrutamiento: Mira el campo 'origen'[cite: 4] de la transacción
      // y la mete en la cola del hijo correspondiente.
      if (tr_recibida.origen >= 0 && tr_recibida.origen < drvrs) begin
        hijos[tr_recibida.origen].recibir_paquete(tr_recibida);
        // $display("[%0t] [DRIVER] Paquete enrutado al Hijo %0d", $time, tr_recibida.origen);
      end else begin
        $display("ERROR: [DRIVER] Origen %0d fuera de rango", tr_recibida.origen);
      end
    end
  endtask
  
endclass
