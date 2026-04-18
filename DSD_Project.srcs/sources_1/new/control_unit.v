// Flow: N -> 4×16-bit adjacency matrix slices -> start -> target -> mode (BFS/DFS) -> hop count on 7-seg.
// Matrix row-major: slice0 = bits [15:0], slice1 = [31:16], ... of the 8×8 binary adjacency.

`default_nettype none

module control_unit #(
    parameter integer N          = 8,
    parameter integer LOG_N      = 3,
    parameter integer ST_DATA_W  = 32,
    parameter integer DEPTH      = 32,
    parameter integer MAT_SLICES = 4
) (
    input  wire clk,
    input  wire rst,
    input  wire btn_pulse,
    input  wire [15:0] sw,

    output reg  init_adj,
    output reg  adj_we,
    output reg  [$clog2(MAT_SLICES)-1:0] adj_slice,

    output reg  [LOG_N-1:0] edge_i,
    output reg  [LOG_N-1:0] edge_j,
    input  wire edge_exists,

    output reg  clr_qs,
    output reg  q_push,
    output reg  q_pop,
    output reg  [LOG_N-1:0] q_wdata,

    output reg  st_push,
    output reg  st_pop,
    output reg  st_poke,
    output reg  [ST_DATA_W-1:0] st_wdata,

    input  wire q_empty,
    input  wire q_full,
    input  wire [LOG_N-1:0] q_rdata,

    input  wire st_empty,
    input  wire [ST_DATA_W-1:0] st_rdata,

    output reg  [15:0] visited_leds,
    output reg  [15:0] result_dist,
    output reg  path_found,
    output reg  run_done,
    output reg  running,

    output reg  [3:0] disp_d0,
    output reg  [3:0] disp_d1,
    output reg  [3:0] disp_d2,
    output reg  [3:0] disp_d3,

    output reg  [1:0] status_rgb
);

    localparam integer P_N      = 0;
    localparam integer P_MATRIX = 1;
    localparam integer P_START  = 2;
    localparam integer P_TGT    = 3;
    localparam integer P_MODE   = 4;
    localparam integer P_RUN    = 5;
    localparam integer P_DONE   = 6;

    localparam [15:0] INF16 = 16'hFFFF;

    localparam integer BFS_INIT  = 0;
    localparam integer BFS_ENQ   = 1;
    localparam integer BFS_MAIN  = 2;
    localparam integer BFS_U     = 3;
    localparam integer BFS_NB    = 4;

    localparam integer DFS_CLR  = 0;
    localparam integer DFS_PUSH = 1;
    localparam integer DFS_LOOP = 2;
    localparam integer DFS_TOP  = 3;
    localparam integer DFS_POKE = 4;
    localparam integer DFS_PCH  = 5;

    reg [2:0] phase;
    reg [3:0] run_sub;

    reg [15:0] num_nodes;
    reg [$clog2(MAT_SLICES)-1:0] mat_slice;

    reg [LOG_N-1:0] lat_start, lat_target;
    reg want_dfs;

    reg [15:0] dist [0:N-1];
    reg [N-1:0] seen_bfs;

    reg [LOG_N-1:0] bfs_u;
    reg [LOG_N-1:0] bfs_k;

    reg dfs_do_push;
    reg [LOG_N-1:0] dfs_nbr;

    wire [LOG_N-1:0] st_u   = st_rdata[2:0];
    wire [LOG_N:0] st_k     = st_rdata[6:3];
    wire [N-1:0] st_vis     = st_rdata[14:7];
    wire [15:0] st_hops     = st_rdata[30:15];

    function [ST_DATA_W-1:0] pack_st;
        input [LOG_N-1:0] u;
        input [LOG_N:0] k;
        input [N-1:0] vis;
        input [15:0] hops;
        begin
            pack_st = {{(ST_DATA_W-31){1'b0}}, hops, vis, k, u};
        end
    endfunction

    integer ii;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase <= P_N;
            run_sub <= BFS_INIT;
            init_adj <= 0;
            adj_we <= 0;
            clr_qs <= 0;
            q_push <= 0;
            q_pop <= 0;
            st_push <= 0;
            st_pop <= 0;
            st_poke <= 0;
            num_nodes <= 0;
            mat_slice <= 0;
            visited_leds <= 0;
            result_dist <= 0;
            path_found <= 0;
            run_done <= 0;
            running <= 0;
            status_rgb <= 0;
            disp_d0 <= 4'h0;
            disp_d1 <= 4'h0;
            disp_d2 <= 4'h0;
            disp_d3 <= 4'h0;
            want_dfs <= 0;
            dfs_do_push <= 0;
            dfs_nbr <= 0;
            bfs_u <= 0;
            bfs_k <= 0;
            seen_bfs <= 0;
        end else begin
            init_adj <= 0;
            adj_we <= 0;
            clr_qs <= 0;
            q_push <= 0;
            q_pop <= 0;
            st_push <= 0;
            st_pop <= 0;
            st_poke <= 0;

            case (phase)
                P_N: begin
                    status_rgb <= 2'b00;
                    disp_d3 <= sw[15:12];
                    disp_d2 <= sw[11:8];
                    disp_d1 <= sw[7:4];
                    disp_d0 <= sw[3:0];
                    if (btn_pulse) begin
                        if (sw > 16'd0 && sw <= N) begin
                            num_nodes <= sw;
                            init_adj <= 1'b1;
                            mat_slice <= 0;
                            phase <= P_MATRIX;
                        end
                    end
                end

                P_MATRIX: begin
                    disp_d3 <= sw[15:12];
                    disp_d2 <= sw[11:8];
                    disp_d1 <= sw[7:4];
                    disp_d0 <= sw[3:0];
                    if (btn_pulse) begin
                        adj_we <= 1'b1;
                        adj_slice <= mat_slice;
                        if (mat_slice == MAT_SLICES - 1)
                            phase <= P_START;
                        else
                            mat_slice <= mat_slice + 1'b1;
                    end
                end

                P_START: begin
                    disp_d3 <= sw[15:12];
                    disp_d2 <= sw[11:8];
                    disp_d1 <= sw[7:4];
                    disp_d0 <= sw[3:0];
                    if (btn_pulse) begin
                        if (sw[LOG_N-1:0] < num_nodes)
                            lat_start <= sw[LOG_N-1:0];
                        else
                            lat_start <= {LOG_N{1'b0}};
                        phase <= P_TGT;
                    end
                end

                P_TGT: begin
                    disp_d3 <= sw[15:12];
                    disp_d2 <= sw[11:8];
                    disp_d1 <= sw[7:4];
                    disp_d0 <= sw[3:0];
                    if (btn_pulse) begin
                        if (sw[LOG_N-1:0] < num_nodes)
                            lat_target <= sw[LOG_N-1:0];
                        else
                            lat_target <= {LOG_N{1'b0}};
                        phase <= P_MODE;
                    end
                end

                P_MODE: begin
                    disp_d3 <= 4'h0;
                    disp_d2 <= 4'h0;
                    disp_d1 <= 4'h0;
                    disp_d0 <= {3'b000, sw[0]};
                    if (btn_pulse) begin
                        want_dfs <= sw[0];
                        if (lat_start == lat_target) begin
                            result_dist <= 16'd0;
                            path_found <= 1;
                            run_done <= 1;
                            phase <= P_DONE;
                            status_rgb <= 2'b10;
                        end else begin
                            phase <= P_RUN;
                            running <= 1;
                            run_sub <= sw[0] ? DFS_CLR : BFS_INIT;
                        end
                    end
                end

                P_RUN: begin
                    status_rgb <= 2'b01;
                    visited_leds <= want_dfs ? {{(16-N){1'b0}}, st_vis}
                        : {{(16-N){1'b0}}, seen_bfs};

                    if (!want_dfs) begin
                        case (run_sub)
                            BFS_INIT: begin
                                for (ii = 0; ii < N; ii = ii + 1)
                                    dist[ii] <= INF16;
                                seen_bfs <= {N{1'b0}};
                                clr_qs <= 1;
                                run_sub <= BFS_ENQ;
                            end
                            BFS_ENQ: begin
                                dist[lat_start] <= 16'd0;
                                seen_bfs[lat_start] <= 1'b1;
                                q_push <= 1'b1;
                                q_wdata <= lat_start;
                                run_sub <= BFS_MAIN;
                            end
                            BFS_MAIN: begin
                                if (q_empty) begin
                                    path_found <= 0;
                                    result_dist <= INF16;
                                    run_done <= 1;
                                    running <= 0;
                                    phase <= P_DONE;
                                    status_rgb <= 2'b11;
                                    run_sub <= BFS_INIT;
                                end else begin
                                    bfs_u <= q_rdata;
                                    q_pop <= 1'b1;
                                    run_sub <= BFS_U;
                                end
                            end
                            BFS_U: begin
                                if (bfs_u == lat_target) begin
                                    path_found <= 1;
                                    result_dist <= dist[bfs_u];
                                    run_done <= 1;
                                    running <= 0;
                                    phase <= P_DONE;
                                    status_rgb <= 2'b10;
                                    run_sub <= BFS_INIT;
                                end else begin
                                    bfs_k <= 0;
                                    edge_i <= bfs_u;
                                    edge_j <= 0;
                                    run_sub <= BFS_NB;
                                end
                            end
                            BFS_NB: begin
                                if (edge_exists && dist[bfs_k] == INF16) begin
                                    dist[bfs_k] <= dist[bfs_u] + 16'd1;
                                    seen_bfs[bfs_k] <= 1'b1;
                                    q_push <= 1'b1;
                                    q_wdata <= bfs_k;
                                end
                                if (bfs_k == num_nodes - 16'd1) begin
                                    run_sub <= BFS_MAIN;
                                end else begin
                                    bfs_k <= bfs_k + 1'b1;
                                    edge_i <= bfs_u;
                                    edge_j <= bfs_k + 1'b1;
                                end
                            end
                            default: run_sub <= BFS_INIT;
                        endcase
                    end else begin
                        case (run_sub)
                            DFS_CLR: begin
                                clr_qs <= 1;
                                run_sub <= DFS_PUSH;
                            end
                            DFS_PUSH: begin
                                st_push <= 1;
                                st_wdata <= pack_st(lat_start, {(LOG_N+1){1'b0}},
                                    ({{(N-1){1'b0}}, 1'b1} << lat_start), 16'd0);
                                run_sub <= DFS_LOOP;
                            end
                            DFS_LOOP: begin
                                if (st_empty) begin
                                    path_found <= 0;
                                    result_dist <= INF16;
                                    run_done <= 1;
                                    running <= 0;
                                    phase <= P_DONE;
                                    status_rgb <= 2'b11;
                                end else
                                    run_sub <= DFS_TOP;
                            end
                            DFS_TOP: begin
                                if (st_u == lat_target) begin
                                    path_found <= 1;
                                    result_dist <= st_hops;
                                    run_done <= 1;
                                    running <= 0;
                                    phase <= P_DONE;
                                    status_rgb <= 2'b10;
                                    st_pop <= 1;
                                end else if (st_k >= num_nodes || st_k >= N) begin
                                    st_pop <= 1;
                                    run_sub <= DFS_LOOP;
                                end else begin
                                    edge_i <= st_u;
                                    edge_j <= st_k[LOG_N-1:0];
                                    dfs_nbr <= st_k[LOG_N-1:0];
                                    dfs_do_push <= edge_exists &&
                                        !((st_vis >> st_k[LOG_N-1:0]) & 1'b1);
                                    run_sub <= DFS_POKE;
                                end
                            end
                            DFS_POKE: begin
                                st_poke <= 1;
                                st_wdata <= pack_st(st_u, st_k + 1'b1, st_vis, st_hops);
                                run_sub <= DFS_PCH;
                            end
                            DFS_PCH: begin
                                if (dfs_do_push) begin
                                    st_push <= 1;
                                    st_wdata <= pack_st(dfs_nbr, {(LOG_N+1){1'b0}},
                                        st_vis | ({{(N-1){1'b0}}, 1'b1} << dfs_nbr),
                                        st_hops + 16'd1);
                                end
                                run_sub <= DFS_LOOP;
                            end
                            default: run_sub <= DFS_LOOP;
                        endcase
                    end
                end

                P_DONE: begin
                    running <= 0;
                    if (path_found && result_dist != INF16) begin
                        disp_d3 <= result_dist[15:12];
                        disp_d2 <= result_dist[11:8];
                        disp_d1 <= result_dist[7:4];
                        disp_d0 <= result_dist[3:0];
                    end else begin
                        disp_d3 <= 4'hF;
                        disp_d2 <= 4'hF;
                        disp_d1 <= 4'hF;
                        disp_d0 <= 4'hF;
                    end
                    if (btn_pulse) begin
                        phase <= P_N;
                        run_sub <= BFS_INIT;
                        path_found <= 0;
                        run_done <= 0;
                    end
                end

                default: phase <= P_N;
            endcase
        end
    end

endmodule

`default_nettype wire
