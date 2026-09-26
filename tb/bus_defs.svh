`ifndef BUS_DEFS_SVH
`define BUS_DEFS_SVH

//=============================================================================
// bus_defs.svh
//
// Definiciones compartidas entre trans_bus.sv (Wilbert) y trans_sb.sv
// (tuyo), y cualquier otro archivo que las necesite (checker.sv,
// scoreboard.sv, monitor.sv). Van en un header aparte -- no dentro de una
// clase ni de un package -- precisamente para que cualquier archivo pueda
// hacer `include "bus_defs.svh" sin declarar el mismo enum dos veces (el
// `ifndef de arriba protege eso incluso si varios archivos lo incluyen).
//
// IMPORTANTE: trans_bus.sv tambien debe empezar con
//   `include "bus_defs.svh"
// para que 'tipo_pkt_e' este disponible ahi tambien.
//=============================================================================

// TODO-DUT: confirmar el ancho maximo real de payload (Test Plan: bits
// en {8,16,32}); 32 es el maximo, se usa como ancho de campo generico.
parameter int BITS_MAX = 32;

// Campo 'tipo' de trans_bus (Test Plan Seccion 5).
typedef enum {VALIDA, BROADCAST, INVALIDA} tipo_pkt_e;

// Campo 'resultado' de trans_sb (Test Plan Seccion 5).
typedef enum {COMPLETADO, PERDIDO, OVERFLOW, UNDERFLOW} resultado_e;

// Direccion de broadcast -- CONFIRMADA contra prll_intrfs_cntrl
// (Library.sv): compara los 8 bits altos de D_push contra 8'hFF.
parameter bit [7:0] BROADCAST_ADDR = 8'hFF;

`endif
