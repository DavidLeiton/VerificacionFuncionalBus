// --- Archivo: test.sv ---
class test #(parameter bits = 16, parameter drvrs = 4);
  
  // Puntero al ambiente
  environment #(bits, drvrs) env;
  
  // El buzón principal que conecta el Test con el Agente[cite: 4]
  mailbox #(trans_bus #(bits, drvrs)) tst_agnt_mbx = new();

  function new();
    // Creamos el ambiente y le pasamos el buzón
    env = new(tst_agnt_mbx);
  endfunction
  
  task run();
    $display("==================================================");
    $display("[%0t] [TEST] Iniciando Prueba de Bus (bits=%0d, drvrs=%0d)", $time, bits, drvrs);
    $display("==================================================");

    // 1. Configurar el escenario
    // Ejemplo: Para el "test_general_regresion", le decimos al agente que genere muchas transacciones[cite: 4]
    env.agnt.num_transacciones = 50; 

    // 2. Arrancar el ambiente
    env.run();

    // 3. Control de finalización de prueba
    // Como las tareas están en ciclos infinitos, le damos tiempo a la simulación 
    // para que termine de procesar las 50 transacciones. 
    // (Luego podrás hacer esto más dinámico esperando eventos o banderas).
    #10000; 
    
    // Cerramos el archivo CSV del Checker para que se guarde bien
    env.chk.wrap_up();
    
    $display("==================================================");
    $display("[%0t] [TEST] Prueba finalizada.", $time);
    $display("==================================================");
    $finish; // Detiene la simulación de SystemVerilog
  endtask
endclass
