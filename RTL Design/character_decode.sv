`default_nettype none

// 5-bit Full Alphabet 7-Segment Decoder (A-Z + custom symbols)
// Active-Low output: {g, f, e, d, c, b, a}
// Common ANODE, all LEDs shared positive voltage anode (VDD)
// segment lights up when pin is logic 0 (GND)

module char_decoder (
    input  logic [4:0] code,
    output logic [6:0] segments
);
    always_comb begin
        case (code)
            5'd0:  segments = 7'b0001000; // A
            5'd1:  segments = 7'b0000011; // b
            5'd2:  segments = 7'b1000110; // C
            5'd3:  segments = 7'b0100001; // d
            5'd4:  segments = 7'b0000110; // E
            5'd5:  segments = 7'b0001110; // F
            5'd6:  segments = 7'b0100010; // G
            5'd7:  segments = 7'b0001001; // H
            5'd8:  segments = 7'b1001111; // I
            5'd9:  segments = 7'b0010001; // J
            5'd10: segments = 7'b0000101; // K
            5'd11: segments = 7'b1000111; // L
            5'd12: segments = 7'b0101000; // M
            5'd13: segments = 7'b1011010; // n
            5'd14: segments = 7'b1111110; // O
            5'd15: segments = 7'b0001100; // P
            5'd16: segments = 7'b0011000; // q
            5'd17: segments = 7'b1011101; // r
            5'd18: segments = 7'b0100100; // S
            5'd19: segments = 7'b0000111; // t
            5'd20: segments = 7'b1000001; // U
            5'd21: segments = 7'b1100001; // v
            5'd22: segments = 7'b1010100; // W
            5'd23: segments = 7'b0011001; // X
            5'd24: segments = 7'b0010011; // y
            5'd25: segments = 7'b0100101; // Z
            default: segments = 7'b1111111; // Display Off
        endcase
    end
endmodule
