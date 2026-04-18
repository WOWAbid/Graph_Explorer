// rgb[2]=red, rgb[1]=green, rgb[0]=blue (matches basys3_pins.xdc comments)

module rgb_status (
    input  wire [1:0] status,
    output wire [2:0] rgb
);
    // status: 00 idle, 01 running, 10 ok, 11 error / no path
    assign rgb = (status == 2'b01) ? 3'b001 :
                 (status == 2'b10) ? 3'b010 :
                 (status == 2'b11) ? 3'b100 : 3'b000;
endmodule
