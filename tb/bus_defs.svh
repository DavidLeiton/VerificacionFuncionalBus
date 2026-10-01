`ifndef BUS_DEFS_SVH
`define BUS_DEFS_SVH

//=============================================================================
// bus_defs.svh
//
// trans_bus.sv tambien debe empezar con
//   `include "bus_defs.svh"
// para que 'tipo_pkt_e' este disponible ahi tambien.
//=============================================================================

//ancho maximo real de payload (Test Plan: bits
// en {8,16,32}); 32 es el maximo, se usa como ancho de campo generico.
parameter int BITS_MAX = 32;

// Campo 'tipo' de trans_bus
typedef enum {VALIDA, BROADCAST, INVALIDA} tipo_pkt_e;

// Campo 'resultado' de trans_sb (Test Plan Sec 5).
typedef enum {COMPLETADO, PERDIDO, OVERFLOW, UNDERFLOW} resultado_e;

//dice que es algo que llego o se mando
typedef enum { EVT_ENVIO, EVT_LLEGADA } evento_mon_e;

// Direccion de broadcast  Confirma contra prll_intrfs_cntrl
// (Library.sv): compara los 8 bits altos de D_push contra 8'hFF.
parameter bit [7:0] BROADCAST_ADDR = 8'hFF;

`endif
