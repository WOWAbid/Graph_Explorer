// LIFO stack: separate reusable data structure (DFS path frames).
// Operations: clear, push, pop, poke (update top without pop), delete (same as pop — remove TOS).

`default_nettype none

module stack #(
    parameter integer DEPTH   = 32,
    parameter integer DATA_W  = 24
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     clr,
    input  wire                     push,
    input  wire                     pop,
    input  wire                     poke,
    input  wire                     delete,
    input  wire [DATA_W-1:0]        wdata,
    output wire [DATA_W-1:0]        rdata,
    output wire                     empty,
    output wire [$clog2(DEPTH+1)-1:0] depth
);

    localparam integer SP_W = $clog2(DEPTH + 1);

    reg [DATA_W-1:0] mem [0:DEPTH-1];
    reg [SP_W-1:0] sp;
    integer qi;
    wire do_pop = pop | delete;

    assign rdata = (sp > 0) ? mem[sp - 1] : {DATA_W{1'b0}};
    assign empty = (sp == 0);
    assign depth = sp[$clog2(DEPTH+1)-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sp <= 0;
            for (qi = 0; qi < DEPTH; qi = qi + 1)
                mem[qi] <= {DATA_W{1'b0}};
        end else if (clr) begin
            sp <= 0;
        end else begin
            if (poke && sp > 0)
                mem[sp - 1] <= wdata;
            if (push && sp < DEPTH) begin
                mem[sp] <= wdata;
                sp <= sp + 1'b1;
            end
            if (do_pop && sp > 0)
                sp <= sp - 1'b1;
        end
    end

endmodule

`default_nettype wire
