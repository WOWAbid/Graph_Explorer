// Increment, min/max compare, queue/stack empty flags (combinational helpers)

module graph_alu #(
    parameter integer W = 4
) (
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    input  wire [W-1:0] best,
    input  wire         min_mode,   // 1=min, 0=max
    output wire [W-1:0] inc_a,
    output wire         a_lt_best,
    output wire         a_gt_best,
    output wire         take_a_over_best
);
    assign inc_a = a + 1'b1;
    assign a_lt_best = (a < best);
    assign a_gt_best = (a > best);
    // For min path length: prefer smaller; for max: prefer larger
    assign take_a_over_best = min_mode ? a_lt_best : a_gt_best;
endmodule
