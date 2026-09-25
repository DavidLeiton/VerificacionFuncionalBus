
// CLASE HIJA: Objeto Emulador de FIFO

class fifo_emul #(parameter bits = 16, parameter drvrs = 4);
  int id; // Identificador de cuál dispositivo es este hijo 
  
  // Cola dinámica para almacenar los paquetes
  trans_bus #(bits, drvrs) cola_fifo[$];
  
  // Puntero a la interfaz virtual para manipular señales físicas del DUT
  virtual bus_if vif;

  // Constructor: Recibe el ID y la conexión física desde el Driver padre
  function new(int num_id, virtual bus_if vif_in);
    this.id = num_id;
    this.vif = vif_in;
  endfunction

  // Método para cargar paquete a la cola desde el generador/agente
  function void recibir_paquete(trans_bus #(bits, drvrs) tr);
    cola_fifo.push_back(tr); // Mete el elemento al final de la cola
  endfunction

  // Tarea independiente de este hijo para sacar datos e interactuar con los pines
  task run();
    trans_bus #(bits, drvrs) tr_actual;

    forever begin // Ciclo infinito escuchando el reloj
      // Esperar el flanco de reloj sincronizado por el clocking block
      @(vif.cb);
      
      // Si hay elementos en la cola, se procede a sacar 
      if (cola_fifo.size() > 0) begin
        tr_actual = cola_fifo.pop_front(); // Saca el primero de la cola (FIFO)
        
        // Evaluar y aplicar el retardo temporal del paquete antes de sacar
        if (tr_actual.retardo > 0) begin
          repeat(tr_actual.retardo) @(vif.cb);
        end

        // Lógica de pines del DUT 
        // Levantar la señal de 'pndng' para este id específico
        vif.cb.pndng[0][this.id] <= 1'b1;
        // Colocar el payload en 'D_push' de este id
        vif.cb.D_push[0][this.id] <= tr_actual.payload;

        // Dar el pulso de 'push'
        vif.cb.push[0][this.id] <= 1'b1;
        
        // Mantener el pulso durante exactamente 1 ciclo de reloj
        @(vif.cb); 
        
        // Apagar las señales tras enviar el dato para dejar el bus limpio
        vif.cb.push[0][this.id] <= 1'b0;
        vif.cb.pndng[0][this.id] <= 1'b0;
      end
    end
  endtask
endclass


// CLASE PADRE: Controlador del Manejador

class driver #(parameter bits = 16, parameter drvrs = 4);
  
  // Mailbox que recibe desde el Agente
  mailbox #(trans_bus #(bits, drvrs)) agnt_drv_mbx;
  
  // Arreglo dinámico de Hijos (Objetos emuladores de FIFO)
  fifo_emul #(bits, drvrs) hijos[];

  // El constructor ahora exige la interfaz virtual para poder distribuirla
  function new(mailbox #(trans_bus #(bits, drvrs)) ad, virtual bus_if vif_in);
    this.agnt_drv_mbx = ad;
    
    // Inicializamos el arreglo para que tenga exactamente la cantidad 
    // de dispositivos definidos por el parámetro 'drvrs'
    hijos = new[drvrs];
    
    // Inicializamos cada hijo pasándole su ID y la interfaz física
    foreach(hijos[i]) begin
      hijos[i] = new(i, vif_in);
    end
  endfunction

  task run();
    trans_bus #(bits, drvrs) tr_recibida;
    
    $display("[%0t] [DRIVER] Manejador iniciado. Emuladores creados: %0d", $time, drvrs);

    // Arrancar los sub-procesos de los hijos en paralelo
    foreach(hijos[i]) begin
      automatic int index = i; 
      fork
        hijos[index].run();
      join_none
    end

    // Tarea principal del Padre: Escuchar al agente y enrutar
    forever begin
      // Extrae la transacción del buzón (se queda esperando si está vacío)
      agnt_drv_mbx.get(tr_recibida);
      
      // Enrutamiento
      if (tr_recibida.origen >= 0 && tr_recibida.origen < drvrs) begin
        hijos[tr_recibida.origen].recibir_paquete(tr_recibida);
        // $display("[%0t] [DRIVER] Paquete enrutado al Hijo %0d", $time, tr_recibida.origen);
      end else begin
        $display("ERROR: [DRIVER] Origen %0d fuera de rango", tr_recibida.origen);
      end
    end
  endtask
  
endclass
