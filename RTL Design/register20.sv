`default_nettype none

// 20-bit loadable register (holds 4 x 5-bit character indices)

module register20 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        load,
    input  logic [19:0] in,
    output logic [19:0] out
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out <= 20'b0;
        else if (load)
            out <= in;
    end
endmodule
