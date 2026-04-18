// Rising-edge pulse (one cycle) from synchronous level input

module edge_detector (
    input  wire clk,
    input  wire rst,
    input  wire level,
    output reg  pulse
);
    reg d;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            d    <= 1'b0;
            pulse <= 1'b0;
        end else begin
            pulse <= level & ~d;
            d     <= level;
        end
    end
endmodule
