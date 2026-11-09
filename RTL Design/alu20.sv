`default_nettype none
// 20-bit Datapath ALU -- processes 4 concatenated 5-bit character codes.

module alu20 (
    input  logic [19:0] x,
    input  logic [19:0] y,
    input  logic        zx, nx, zy, ny, f, no,
    output logic [19:0] out,
    output logic        zr,
    output logic        ng
);
    logic [19:0] x1, y1, x2, y2, pre_out, post_out;
    logic [20:0] pre_out // 21-bit intermeditae logic to capture carry if needed to prevent overflow
    logic [19:0] post_out

    assign x1 = zx ? 20'b0 : x;
    assign x2 = nx ? ~x1   : x1;
    assign y1 = zy ? 20'b0 : y;
    assign y2 = ny ? ~y1   : y1;

    assign pre_out  = f ? ({1'b0, x2} + {1'b0, y2}) : {1'b0, (x2 & y2)};
    
    assign post_out = no ? ~pre_out[19:0] : pre_out[19:0];
    assign carry_out = f ? pre_out[20] : 1'b0; //Carry out with addition
        
    assign out = post_out;
    assign zr  = (out == 20'b0);
    assign ng  = out[19];
endmodule
