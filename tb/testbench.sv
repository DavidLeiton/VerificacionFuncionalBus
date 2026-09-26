// --- Archivo: testbench.sv ---
`timescale 1ns/1ps

`include "../src/Library.sv"
`include "bus_defs.svh"
`include "bus_if.sv"
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

  // Parámetros globales 
  parameter BITS = 16;
  parameter DRVRS = 4;
  parameter PCKG_SZ = 16;
  parameter BROADCAST = {8{1'b1}};

  logic clk;
  logic reset;

  // Instancia de la interfaz física
  bus_if vif(
    .clk(clk),
    .reset(reset)
  );

  // Instancia del DUT conectada a la interfaz
  bs_gnrtr_n_rbtr #(
    .bits(1),              
    .drvrs(DRVRS),
    .pckg_sz(PCKG_SZ),
    .broadcast(BROADCAST)
  ) DUT (
    .clk(vif.clk),
    .reset(vif.reset),
    .pndng(vif.pndng),
    .push(vif.push),
    .pop(vif.pop),
    .D_pop(vif.D_pop),
    .D_push(vif.D_push)
  );

  // Instancia del puntero de la clase Test
  test #(BITS, DRVRS) t0;

  // Generador de Reloj
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // Periodo de 10 unidades de tiempo
  end

  // Bloque principal de ejecución
  initial begin
    // Reset inicial del sistema
    reset = 1;
    #20 reset = 0;

    // Instanciar el Test pasándole la interfaz y arrancar la simulación
    t0 = new(vif);
    t0.run();
  end

endmodule

