// --- Archivo: trans_bus.sv ---
// Se parametriza la clase para que se adapte a las pruebas de 2, 4 u 8 dispositivos, 
// y a los distintos anchos de payload (8, 16, 32) según el Test Plan.
class trans_bus #(parameter bits = 16, parameter drvrs = 4);
  
  // 1. Definición de tipos enumerados
  // Esto hace que el código sea mucho más legible que usar puros números.
  typedef enum {valida, broadcast, invalida} tipo_e; //
  
  // 2. Variables aleatorias (rand)
  // Al usar 'rand', le decimos a SystemVerilog que cuando llamemos a la función 
  // tr.randomize(), el simulador debe asignarles valores al azar.
  rand int    origen;      // Dispositivo que envía (0 a drvrs-1)[cite: 4]
  rand int    destino;     // Dispositivo que recibe o broadcast[cite: 4]
  rand bit [bits-1:0] payload; // El dato real a transmitir[cite: 4]
  rand tipo_e tipo;        // El escenario que queremos probar[cite: 4]
  rand int    pckg_sz;     // Tamaño del paquete: 16, 32 o 64[cite: 4]
  rand int    retardo;     // Ciclos de espera antes de inyectar el paquete[cite: 4]

  // 3. Restricciones (Constraints)
  // Las reglas de oro para la aleatorización. Evitan que el simulador 
  // genere valores absurdos (como un retardo de un millón de ciclos o un origen inexistente).
  constraint c_origen  { origen >= 0; origen < drvrs; }
  
  // Si es un paquete válido, el destino debe estar entre 0 y drvrs-1. 
  // Además, evitamos que un dispositivo se envíe un paquete a sí mismo.
  constraint c_destino { 
    if (tipo == valida) {
      destino >= 0; destino < drvrs;
      destino != origen; 
    }
  }

  // Restringimos los tamaños de paquete a los valores específicos solicitados
  constraint c_pckg_sz { pckg_sz inside {16, 32, 64}; }

  // Restringimos el retardo a un valor razonable (ej. entre 0 y 20 ciclos)
  // para no hacer la simulación infinitamente larga.
  constraint c_retardo { retardo >= 0; retardo <= 20; }

  // 4. Funciones de utilidad (Opcional pero muy recomendado)
  // Una función para imprimir el contenido del paquete en la consola y facilitar el debugging.
  function void print();
    $display("--- TRANS_BUS ---");
    $display("Origen:  %0d | Destino: %0d", origen, destino);
    $display("Payload: 0x%0h | Tipo: %s", payload, tipo.name());
    $display("Tamanio: %0d | Retardo: %0d ciclos", pckg_sz, retardo);
    $display("-----------------");
  endfunction

endclass
