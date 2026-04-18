`default_nettype none

module graph_explorer_top (
    input  wire clk,
    input  wire btnC,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire [2:0] rgb
);

    localparam integer CLK_HZ = 100_000_000;

    wire rst = 1'b0;

    wire btn_c_db;
    wire btn_pulse;

    wire tick_1k;
    wire [3:0] d0, d1, d2, d3;
    wire [1:0] st;
    wire [2:0] rgb_i;
    wire [15:0] unused_result;
    wire       unused_pf, unused_done, unused_run;

    debouncer #(.CLK_HZ(CLK_HZ)) u_deb (
        .clk(clk),
        .rst(rst),
        .in_async(btnC),
        .out(btn_c_db)
    );

    edge_detector u_ed (
        .clk(clk),
        .rst(rst),
        .level(btn_c_db),
        .pulse(btn_pulse)
    );

    clk_divider #(.TICK_DIV(CLK_HZ / 1000)) u_div (
        .clk(clk),
        .rst(rst),
        .tick(tick_1k)
    );

    graph_engine u_eng (
        .clk(clk),
        .rst(rst),
        .btn_pulse(btn_pulse),
        .sw(sw),
        .visited_leds(led),
        .result_dist(unused_result),
        .path_found(unused_pf),
        .run_done(unused_done),
        .running(unused_run),
        .disp_d0(d0),
        .disp_d1(d1),
        .disp_d2(d2),
        .disp_d3(d3),
        .status_rgb(st)
    );

    seg7_driver u_seg (
        .clk(clk),
        .rst(rst),
        .tick(tick_1k),
        .d0(d0),
        .d1(d1),
        .d2(d2),
        .d3(d3),
        .seg(seg),
        .an(an)
    );

    rgb_status u_rgb (
        .status(st),
        .rgb(rgb_i)
    );

    assign rgb = rgb_i;

endmodule

`default_nettype wire
