`default_nettype none

// RAM8 -- Eight 20-bit words (stores 8 full 4-letter words)

module ram8_20bit (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [2:0]  address,
    input  logic        load,
    input  logic [19:0] in,
    output logic [19:0] out
);
    logic [19:0] mem [0:7];
    integer i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i++) mem[i] <= 20'b0;
        end else if (load) begin
            mem[address] <= in;
        end
    end

    assign out = mem[address];
endmodule
