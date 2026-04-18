// Tick pulse every TICK_DIV cycles (for 7-seg refresh)

module clk_divider #(
    parameter integer TICK_DIV = 100_000 // 1 kHz from 100 MHz
) (
    input  wire clk,
    input  wire rst,
    output reg  tick
);
    reg [$clog2(TICK_DIV)-1:0] cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt  <= 0;
            tick <= 1'b0;
        end else begin
            tick <= 1'b0;
            if (cnt == TICK_DIV - 1) begin
                cnt  <= 0;
                tick <= 1'b1;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
