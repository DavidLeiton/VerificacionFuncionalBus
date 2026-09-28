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
    env.agnt.num_transacciones = 200; //numero de transacciones   

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

     // Rafaga: 8 paquetes seguidos del dispositivo 0 al 1, sin espera.
    //     Cada payload es distinto a proposito: el scoreboard reconoce
    //     cada llegada por su dato, asi que no pueden repetirse.
    for (int k = 0; k < 8; k++) begin
      caso = new();
      caso.origen  = 0;
      caso.destino = 1;
      caso.tipo    = VALIDA;
      caso.payload = 16'(k + 1);
      caso.retardo = 0;
      tst_agnt_mbx.put(caso);
    end

    // (e) Contencion: tres dispositivos apuntando al mismo destino a la vez
    for (int o = 1; o <= 3; o++) begin
      caso = new();
      caso.origen  = o;
      caso.destino = 0;
      caso.tipo    = VALIDA;
      caso.payload = 16'hA0 + o;
      caso.retardo = 0;
      tst_agnt_mbx.put(caso);
    end
    


    // Arrancar el ambiente
    env.run();

     // caso de esquina UNDERFLOW ---
    // Observacion sintetica: pop en el dispositivo 1 con pndng=0.
    // raw_data=16'h0100 -> el byte alto (destino decodificado) es 1.
    begin
      mon_obs obs_underflow;
      obs_underflow = new(.bc_id(1), .evento(EVT_ENVIO),
                          .raw_data(16'h0100), .pndng(1'b0), .t_obs($time));
      env.mon_chkr_mbx.put(obs_underflow);
    end
    
    // 1) Esperar a que el Agente termine de generar TODO (dirigidos + aleatorios)
    //    antes de siquiera pensar en preguntar si algo esta pendiente.
    @(env.agnt.fin_generacion);
  
    // 2) Recien ahora, drenar lo que haya quedado en curso, con un tope
    //    de seguridad por si algo se atasca de verdad (starvation real).
    fork
      begin
        forever begin
          if (env.sb.pendientes_totales() == 0) break;
        #1000;
        end
      end
      begin
        #8000000;
      end
    join_any
    disable fork;

    env.sb.reportar_final(); 
    
    $display("=================================================");
    $display("[%0t] [TEST] Prueba finalizada.", $time);
    $display("=================================================");
    $finish; 
  endtask
endclass
