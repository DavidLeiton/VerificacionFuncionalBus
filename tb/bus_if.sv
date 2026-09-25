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
  // Define cómo el software lee y escribe respecto al reloj del hardware
  clocking cb @(posedge clk);
    default input #1ns output #1ns; // Tiempos de preparación (setup) y retención (hold)
    
    // Las direcciones son desde la perspectiva del Testbench hacia el DUT:
    output pndng;
    output D_pop;
    
    // Lo que es 'output' en el DUT, aquí es 'input'
    input push;
    input pop;
    input D_push;
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
