// --- Archivo: test.sv ---
class test #(parameter bits = 16, parameter drvrs = 4);
  
  // Puntero al ambiente
  environment #(bits, drvrs) env;
  
  // El buzón principal 
  mailbox #(trans_bus) tst_agnt_mbx = new();
  
  // Puntero a pines fisicos
  virtual bus_if vif;

  // Constructor
  function new(virtual bus_if vif);
    this.vif = vif;
    // Creamos el ambiente y le pasamos la interfaz y el buzón
    env = new(this.vif, tst_agnt_mbx);
  endfunction

  task run();
    trans_bus #(bits, drvrs) caso;


    $display("=================================================");
    $display("[%0t] [TEST] Iniciando Prueba de Bus (bits=%0d, drvrs=%0d)", $time, bits, drvrs);
    $display("=================================================");
    
    // Configurar el escenario
    env.agnt.num_transacciones = 50; //numero de transacciones   

    // Casos de esquina dirigidos ---
    caso = new();
    caso.origen  = 0;
    caso.destino = 255;
    caso.tipo    = BROADCAST;
    caso.payload = '1;
    caso.retardo = 0;
    tst_agnt_mbx.put(caso);

    caso = new();
    caso.origen  = 1;
    caso.destino = drvrs;
    caso.tipo    = INVALIDA;
    caso.payload = 16'hDEAD;
    caso.retardo = 0;
    tst_agnt_mbx.put(caso);

    caso = new();
    caso.origen  = 2;
    caso.destino = 0;
    caso.tipo    = VALIDA;
    caso.payload = 16'h0000;
    caso.retardo = 0;
    tst_agnt_mbx.put(caso);
    


    // Arrancar el ambiente
    env.run();
    
    // Control de finalización de prueba
    #10000;

    env.sb.reportar_final(); 
    
    $display("=================================================");
    $display("[%0t] [TEST] Prueba finalizada.", $time);
    $display("=================================================");
    $finish; 
  endtask
endclass
