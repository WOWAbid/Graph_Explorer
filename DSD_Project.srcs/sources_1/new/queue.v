// FIFO queue: separate reusable data structure (BFS frontier).
// Operations: clear, push (enqueue), pop (dequeue), delete (same as pop — remove front element).

`default_nettype none

module queue #(
    parameter integer DEPTH  = 32,
    parameter integer DATA_W = 3
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     clr,
    input  wire                     push,
    input  wire                     pop,
    input  wire                     delete,
    input  wire [DATA_W-1:0]        wdata,
    output wire [DATA_W-1:0]        rdata,
    output wire                     empty,
    output wire                     full
);

    localparam integer PTR_W = $clog2(DEPTH);
    localparam integer CNT_W = $clog2(DEPTH + 1);

    reg [DATA_W-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] head, tail;
    reg [CNT_W-1:0] count;

    integer qi;
    wire do_pop = pop | delete;

    assign rdata = mem[head];
    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            head  <= {PTR_W{1'b0}};
            tail  <= {PTR_W{1'b0}};
            count <= {CNT_W{1'b0}};
            for (qi = 0; qi < DEPTH; qi = qi + 1)
                mem[qi] <= {DATA_W{1'b0}};
        end else if (clr) begin
            head  <= {PTR_W{1'b0}};
            tail  <= {PTR_W{1'b0}};
            count <= {CNT_W{1'b0}};
        end else begin
            if (push && !full) begin
                mem[tail] <= wdata;
                if (tail == (DEPTH - 1))
                    tail <= {PTR_W{1'b0}};
                else
                    tail <= tail + 1'b1;
                count <= count + 1'b1;
            end else if (do_pop && !empty) begin
                if (head == (DEPTH - 1))
                    head <= {PTR_W{1'b0}};
                else
                    head <= head + 1'b1;
                count <= count - 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
