// Active-low 7-seg + active-low anodes; `tick` advances digit on refresh.

module seg7_driver (
    input  wire clk,
    input  wire rst,
    input  wire tick,
    input  wire [3:0] d0,
    input  wire [3:0] d1,
    input  wire [3:0] d2,
    input  wire [3:0] d3,
    output reg  [6:0] seg,
    output reg  [3:0] an
);
    reg [1:0] idx;

    function [6:0] hex2seg;
        input [3:0] h;
        begin
            case (h)
                4'h0: hex2seg = 7'b0111111;
                4'h1: hex2seg = 7'b0000110;
                4'h2: hex2seg = 7'b1011011;
                4'h3: hex2seg = 7'b1001111;
                4'h4: hex2seg = 7'b1100110;
                4'h5: hex2seg = 7'b1101101;
                4'h6: hex2seg = 7'b1111101;
                4'h7: hex2seg = 7'b0000111;
                4'h8: hex2seg = 7'b1111111;
                4'h9: hex2seg = 7'b1101111;
                4'hA: hex2seg = 7'b1110111;
                4'hB: hex2seg = 7'b1111100;
                4'hC: hex2seg = 7'b0111001;
                4'hD: hex2seg = 7'b1011110;
                4'hE: hex2seg = 7'b1111001;
                default: hex2seg = 7'b1110001; // F
            endcase
        end
    endfunction

    wire [3:0] cur = (idx == 2'd0) ? d0 :
                     (idx == 2'd1) ? d1 :
                     (idx == 2'd2) ? d2 : d3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            idx <= 0;
            seg <= 7'h7F;
            an  <= 4'b1111;
        end else begin
            if (tick)
                idx <= idx + 1'b1;
            seg <= ~hex2seg(cur);
            case (idx)
                2'd0: an <= 4'b1110;
                2'd1: an <= 4'b1101;
                2'd2: an <= 4'b1011;
                default: an <= 4'b0111;
            endcase
        end
    end
endmodule
