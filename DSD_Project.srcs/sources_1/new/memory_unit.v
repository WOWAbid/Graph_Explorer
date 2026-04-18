// Binary adjacency matrix (row-major, 8×8 = 64 bits in four 16-bit slices) + queue + stack.

`default_nettype none

module memory_unit #(
    parameter integer N           = 8,
    parameter integer LOG_N       = 3,
    parameter integer DEPTH         = 32,
    parameter integer ST_DATA_W     = 32,
    parameter integer SLICES        = 4
) (
    input  wire clk,
    input  wire rst,
    input  wire clr_qs,

    input  wire                     init_adj,
    input  wire                     adj_we,
    input  wire [$clog2(SLICES)-1:0] adj_slice,
    input  wire [15:0]              adj_din,

    input  wire [LOG_N-1:0]         edge_i,
    input  wire [LOG_N-1:0]         edge_j,
    output wire                     edge_exists,

    input  wire                 q_push,
    input  wire                 q_pop,
    input  wire [LOG_N-1:0]     q_wdata,
    output wire [LOG_N-1:0]     q_rdata,
    output wire                 q_empty,
    output wire                 q_full,

    input  wire                 st_push,
    input  wire                 st_pop,
    input  wire                 st_poke,
    input  wire [ST_DATA_W-1:0] st_wdata,
    output wire [ST_DATA_W-1:0] st_rdata,
    output wire                 st_empty,

    output wire [$clog2(DEPTH+1)-1:0] st_depth
);

    reg adj [0:N*N-1];
    integer t;
    integer bi;

    wire [5:0] idx = edge_i * N + edge_j;

    assign edge_exists = adj[idx];

    wire q_delete = 1'b0;
    queue #(
        .DEPTH(DEPTH),
        .DATA_W(LOG_N)
    ) u_q (
        .clk   (clk),
        .rst   (rst),
        .clr   (clr_qs),
        .push  (q_push),
        .pop   (q_pop),
        .delete(q_delete),
        .wdata (q_wdata),
        .rdata (q_rdata),
        .empty (q_empty),
        .full  (q_full)
    );

    wire st_delete = 1'b0;
    stack #(
        .DEPTH (DEPTH),
        .DATA_W(ST_DATA_W)
    ) u_st (
        .clk   (clk),
        .rst   (rst),
        .clr   (clr_qs),
        .push  (st_push),
        .pop   (st_pop),
        .poke  (st_poke),
        .delete(st_delete),
        .wdata (st_wdata),
        .rdata (st_rdata),
        .empty (st_empty),
        .depth (st_depth)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (t = 0; t < N * N; t = t + 1)
                adj[t] <= 1'b0;
        end else begin
            if (init_adj) begin
                for (t = 0; t < N * N; t = t + 1)
                    adj[t] <= 1'b0;
            end else if (adj_we) begin
                for (bi = 0; bi < 16; bi = bi + 1)
                    adj[adj_slice * 16 + bi] <= adj_din[bi];
            end
        end
    end

endmodule

`default_nettype wire
