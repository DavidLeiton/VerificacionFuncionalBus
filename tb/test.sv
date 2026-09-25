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
    $display("=================================================");
    $display("[%0t] [TEST] Iniciando Prueba de Bus (bits=%0d, drvrs=%0d)", $time, bits, drvrs);
    $display("=================================================");
    
    // Configurar el escenario
    env.agnt.num_transacciones = 50; //numero de transacciones   

    // Arrancar el ambiente
    env.run();
    
    // Control de finalización de prueba
    #10000;
    
    $display("=================================================");
    $display("[%0t] [TEST] Prueba finalizada.", $time);
    $display("=================================================");
    $finish; 
  endtask
endclass
