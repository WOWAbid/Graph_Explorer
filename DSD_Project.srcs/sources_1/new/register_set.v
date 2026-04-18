// Latched user parameters. Graph is ADJ_W bits loaded in 16-bit slices (graph_slice).

`default_nettype none

module register_set #(
    parameter integer LOG_N = 3,
    parameter integer ADJ_W = 64
) (
    input  wire clk,
    input  wire rst,

    input  wire [1:0]         graph_slice,
    input  wire                 we_graph,
    input  wire [15:0]          din_graph,

    input  wire                 we_start,
    input  wire [LOG_N-1:0]     din_start,

    input  wire                 we_target,
    input  wire [LOG_N-1:0]     din_target,

    input  wire                 we_mode,
    input  wire                 din_bfs,
    input  wire                 din_min,

    output reg  [ADJ_W-1:0]     latched_graph,
    output reg  [LOG_N-1:0]     latched_start,
    output reg  [LOG_N-1:0]     latched_target,
    output reg                  latched_bfs,
    output reg                  latched_min
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            latched_graph  <= {ADJ_W{1'b0}};
            latched_start  <= 0;
            latched_target <= 0;
            latched_bfs    <= 1'b1;
            latched_min    <= 1'b1;
        end else begin
            if (we_graph)
                latched_graph[graph_slice * 16 +: 16] <= din_graph;
            if (we_start)
                latched_start <= din_start;
            if (we_target)
                latched_target <= din_target;
            if (we_mode) begin
                latched_bfs <= din_bfs;
                latched_min <= din_min;
            end
        end
    end

endmodule

`default_nettype wire
