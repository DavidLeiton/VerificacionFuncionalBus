// --- Archivo: trans_bus.sv ---
// Se incluye el archivo de definiciones globales para reconocer tipo_pkt_e
`include "bus_defs.svh"

// Se parametriza la clase para que se adapte a las pruebas de 2, 4 u 8 dispositivos, 
// y a los distintos anchos de payload (8, 16, 32) según el Test Plan.
class trans_bus #(parameter bits = 16, parameter drvrs = 4);
  
  // Variables aleatorias (rand)
  rand int            origen;      // Dispositivo que envía (0 a drvrs-1)
  rand int            destino;     // Dispositivo que recibe o broadcast
  rand bit [bits-1:0] payload;     // El dato real a transmitir
  rand tipo_pkt_e     tipo;        // El escenario que queremos probar (usa enum global)
  rand int            pckg_sz;     // Tamaño del paquete: 16, 32 o 64
  rand int            retardo;     // Ciclos de espera antes de inyectar el paquete

  time t_envio;                    // Variable requerida por el Scoreboard para latencias

  // (Constraints)
  constraint c_origen  { origen >= 0; origen < drvrs; }
  
  // Si es un paquete válido, el destino debe estar entre 0 y drvrs-1. 
  // Además, evitamos que un dispositivo se envíe un paquete a sí mismo.
  constraint c_destino { 
    if (tipo == VALIDA) {
      destino >= 0; 
      destino < drvrs;
      destino != origen; 
    }
    
    if (tipo == BROADCAST) {
      destino == 255; 
    }
    
    if (tipo == INVALIDA) {
      destino >= drvrs; 
      destino != 255;   
    }
  }

  // Tamaño de paquetes solicitados
  constraint c_pckg_sz { pckg_sz inside {16, 32, 64}; }

  // Restringimos el retardo a un valor razonable (ej. entre 0 y 20 ciclos)
  // para no hacer la simulación infinitamente larga.
  // ATENCIÓN: VER ESTA RESTRICCIÓN
  constraint c_retardo { retardo >= 0; retardo <= 20; }

  // Constructor
  function new();
    this.payload = 0;
    this.retardo = 0;
    this.t_envio = 0; // Inicializamos el tiempo en 0
  endfunction

  // Impresión
  function void print();
    $display("--- TRANS_BUS ---");
    $display("Origen:  %0d | Destino: %0d", origen, destino);
    $display("Payload: 0x%0h | Tipo: %s", payload, tipo.name());
    $display("Tamanio: %0d | Retardo: %0d ciclos | t_envio: %0t", pckg_sz, retardo, t_envio);
    $display("-----------------");
  endfunction

  function trans_bus #(bits, drvrs) copy();
    trans_bus #(bits, drvrs) clon;
    clon = new(); // Construye un nuevo objeto en la memoria 

    clon.origen  = this.origen;
    clon.destino = this.destino;
    clon.payload = this.payload;
    clon.tipo    = this.tipo;
    clon.pckg_sz = this.pckg_sz;
    clon.retardo = this.retardo;
    clon.t_envio = this.t_envio; // Aseguramos copiar el tiempo de envío

    return clon; // Retorna paquete clonado
  endfunction

  function bit compare(trans_bus #(bits, drvrs) otro);
    // Revisamos que el objeto 'otro' no esté vacío
    if (otro == null) return 0;

    // Comparamos los campos clave
    if (this.payload != otro.payload) return 0;
    if (this.destino != otro.destino) return 0;
    if (this.origen  != otro.origen)  return 0;

    return 1; // Si pasa todos los filtros, son iguales
  endfunction

endclass : trans_bus
