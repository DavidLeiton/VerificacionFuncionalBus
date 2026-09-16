// --- Archivo: testbench.sv ---
`timescale 1ns/1ps

// 1. Importar todos los archivos modulares
// El orden importa: primero los paquetes, luego los bloques, luego el test.
`include "trans_bus.sv"
`include "trans_sb.sv"
`include "agent.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "checker.sv"
`include "environment.sv"
`include "test.sv"

module testbench;

  // Parámetros globales para esta compilación
  parameter BITS  = 16;
  parameter DRVRS = 4;
  parameter PCKG_SZ = 16;
  parameter BROADCAST = {8{1'b1}};

  // 2. Señales físicas del reloj y reset
  logic clk;
  logic reset;

  // Señales físicas para conectar al DUT (arreglos multidimensionales)[cite: 1]
  logic pndng  [BITS-1:0][DRVRS-1:0];
  logic push   [BITS-1:0][DRVRS-1:0];
  logic pop    [BITS-1:0][DRVRS-1:0];
  logic [PCKG_SZ-1:0] D_pop  [BITS-1:0][DRVRS-1:0];
  logic [PCKG_SZ-1:0] D_push [BITS-1:0][DRVRS-1:0];

  // 3. Instancia de la clase Test
  test #(BITS, DRVRS) t0;

  // 4. Instancia del DUT (El hardware real)[cite: 1]
  bs_gnrtr_n_rbtr #(
    .bits(BITS),
    .drvrs(DRVRS),
    .pckg_sz(PCKG_SZ),
    .broadcast(BROADCAST)
  ) DUT (
    .clk(clk),
    .reset(reset),
    .pndng(pndng),
    .push(push),
    .pop(pop),
    .D_pop(D_pop),
    .D_push(D_push)
  );

  // 5. Generador de Reloj
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // Periodo de 10 unidades de tiempo
  end

  // 6. Bloque principal de ejecución
  initial begin
    // Reset inicial del sistema
    reset = 1;
    #20 reset = 0;
    
    // TODO: Aquí deberás instanciar una 'virtual interface' para pasarle 
    // todas estas señales lógicas al Driver y al Monitor.

    // Inicializar y correr el Test
    t0 = new();
    t0.run();
  end

endmodule
