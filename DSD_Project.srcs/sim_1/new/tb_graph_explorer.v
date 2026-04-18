// Stimulus: N -> four 16-bit matrix slices (row-major 8×8) -> start -> target -> BFS/DFS.

`timescale 1ns / 1ps

module tb_graph_explorer;

    reg clk = 0;
    reg btnC = 0;
    reg [15:0] sw = 0;

    wire [15:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    wire [2:0] rgb;

    always #5 clk = ~clk;

    graph_explorer_top dut (
        .clk(clk),
        .btnC(btnC),
        .sw(sw),
        .led(led),
        .seg(seg),
        .an(an),
        .rgb(rgb)
    );

    task press;
        integer i;
        begin
            @(posedge clk);
            btnC = 1;
            for (i = 0; i < 2500000; i = i + 1)
                @(posedge clk);
            btnC = 0;
            for (i = 0; i < 2500000; i = i + 1)
                @(posedge clk);
        end
    endtask

    initial begin
        // 4 nodes; path 0->1; matrix first row bits for row0: connect 0->1
        sw = 16'd4;
        #100;
        press;
        // Slice 0: row0 = 0000_0010 (edge 0->1), rest 0
        sw = 16'b0000_0000_0000_0010;
        press;
        sw = 16'b0;
        press;
        sw = 16'b0;
        press;
        sw = 16'b0;
        press;
        sw = 16'd0;
        press;
        sw = 16'd1;
        press;
        sw = 16'd0;
        press;
        #5_000_000;
        $finish;
    end

endmodule
