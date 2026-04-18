// Integrates binary adjacency memory, queue/stack, and control unit.

`default_nettype none

module graph_engine (
    input  wire clk,
    input  wire rst,
    input  wire btn_pulse,
    input  wire [15:0] sw,

    output wire [15:0] visited_leds,
    output wire [15:0] result_dist,
    output wire        path_found,
    output wire        run_done,
    output wire        running,

    output wire [3:0] disp_d0,
    output wire [3:0] disp_d1,
    output wire [3:0] disp_d2,
    output wire [3:0] disp_d3,

    output wire [1:0] status_rgb
);

    localparam integer N         = 8;
    localparam integer LOG_N     = 3;
    localparam integer DEPTH     = 32;
    localparam integer ST_DATA_W = 32;
    localparam integer MAT_SLICES = 4;

    wire init_adj, adj_we;
    wire [$clog2(MAT_SLICES)-1:0] adj_slice;

    wire [LOG_N-1:0] edge_i, edge_j;
    wire edge_exists;

    wire clr_qs;
    wire q_push, q_pop, st_push, st_pop, st_poke;
    wire [LOG_N-1:0] q_wdata;
    wire [LOG_N-1:0] q_rdata;
    wire q_empty, q_full;
    wire [ST_DATA_W-1:0] st_wdata, st_rdata;
    wire st_empty;
    wire [$clog2(DEPTH+1)-1:0] unused_st_depth;

    memory_unit #(
        .N(N),
        .LOG_N(LOG_N),
        .DEPTH(DEPTH),
        .ST_DATA_W(ST_DATA_W),
        .SLICES(MAT_SLICES)
    ) u_mem (
        .clk(clk),
        .rst(rst),
        .clr_qs(clr_qs),
        .init_adj(init_adj),
        .adj_we(adj_we),
        .adj_slice(adj_slice),
        .adj_din(sw),
        .edge_i(edge_i),
        .edge_j(edge_j),
        .edge_exists(edge_exists),
        .q_push(q_push),
        .q_pop(q_pop),
        .q_wdata(q_wdata),
        .q_rdata(q_rdata),
        .q_empty(q_empty),
        .q_full(q_full),
        .st_push(st_push),
        .st_pop(st_pop),
        .st_poke(st_poke),
        .st_wdata(st_wdata),
        .st_rdata(st_rdata),
        .st_empty(st_empty),
        .st_depth(unused_st_depth)
    );

    control_unit #(
        .N(N),
        .LOG_N(LOG_N),
        .ST_DATA_W(ST_DATA_W),
        .DEPTH(DEPTH),
        .MAT_SLICES(MAT_SLICES)
    ) u_cu (
        .clk(clk),
        .rst(rst),
        .btn_pulse(btn_pulse),
        .sw(sw),
        .init_adj(init_adj),
        .adj_we(adj_we),
        .adj_slice(adj_slice),
        .edge_i(edge_i),
        .edge_j(edge_j),
        .edge_exists(edge_exists),
        .clr_qs(clr_qs),
        .q_push(q_push),
        .q_pop(q_pop),
        .q_wdata(q_wdata),
        .st_push(st_push),
        .st_pop(st_pop),
        .st_poke(st_poke),
        .st_wdata(st_wdata),
        .q_empty(q_empty),
        .q_full(q_full),
        .q_rdata(q_rdata),
        .st_empty(st_empty),
        .st_rdata(st_rdata),
        .visited_leds(visited_leds),
        .result_dist(result_dist),
        .path_found(path_found),
        .run_done(run_done),
        .running(running),
        .disp_d0(disp_d0),
        .disp_d1(disp_d1),
        .disp_d2(disp_d2),
        .disp_d3(disp_d3),
        .status_rgb(status_rgb)
    );

endmodule

`default_nettype wire
