// Active-high button → debounced level `out`

module debouncer #(
    parameter integer CLK_HZ      = 100_000_000,
    parameter integer MS_STABLE   = 20
) (
    input  wire clk,
    input  wire rst,
    input  wire in_async,
    output reg  out
);
    localparam integer MAX_C = (CLK_HZ / 1000) * MS_STABLE / 1000;
    localparam integer CW      = $clog2(MAX_C + 1);

    reg in_sync1, in_sync2, prev;
    reg [CW-1:0] cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_sync1 <= 1'b0;
            in_sync2 <= 1'b0;
            prev     <= 1'b0;
            cnt      <= 0;
            out      <= 1'b0;
        end else begin
            in_sync1 <= in_async;
            in_sync2 <= in_sync1;
            if (in_sync2 != prev) begin
                cnt  <= 0;
                prev <= in_sync2;
            end else if (cnt < MAX_C) begin
                cnt <= cnt + 1'b1;
            end else begin
                out <= prev;
            end
        end
    end
endmodule
