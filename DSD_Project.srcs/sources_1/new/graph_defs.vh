// Graph Explorer — shared sizing (optional `include)

`ifndef GRAPH_DEFS_VH
`define GRAPH_DEFS_VH

// 8-node graph: 64-bit adjacency loaded as four 16-bit slices on switches.
`define N_NODES       8
`define LOG_N         3
`define ADJ_BITS      64
`define MEM_DEPTH     32
`define STACK_ENTRY_W 24

`endif
