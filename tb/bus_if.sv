interface bus_if #(
  parameter bits = 1,
  parameter drvrs = 4,
  parameter pckg_sz = 16,
  parameter broadcast = {8{1'b1}}
) (
  input clk // Reloj del sistema 
);

 
  // Entradas y salidas exactas del DUT declaradas como logic para manipulación 
  logic reset;
  logic pndng [bits-1:0][drvrs-1:0];
  logic push  [bits-1:0][drvrs-1:0];
  logic pop   [bits-1:0][drvrs-1:0];
  
  logic [pckg_sz-1:0] D_pop  [bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_push [bits-1:0][drvrs-1:0];

  //Temporización del cloking block (cb)
  clocking cb @(posedge clk);
    default input #1ns output #1ns; // Tiempos de preparacion (setup) y retencion (hold)

    // Lo que genera el DUT, el Testbench lo recibe (input)
    input pndng;
    input D_pop;

    // Lo que genera el Testbench, el DUT lo recibe (output)
    output push;
    output pop;
    output D_push;
  endclocking

  
  //USO DE LA DIRECTIVA MODPORTS 
  
  modport drv (
    clocking cb,
    output reset
  );

  
  modport mon (
    input clk,
    input reset,
    input pndng,
    input push,
    input pop,
    input D_pop,
    input D_push
  );

endinterface
