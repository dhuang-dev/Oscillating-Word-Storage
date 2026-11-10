`default_nettype none

// Nibble Mux -- Extracts one 5-bit character slice out of the 20-bit word.

module chunk_mux (
    input  logic [19:0] word_in,
    input  logic [1:0]  position,
    output logic [4:0]  char_code_out
);
    // Index slicing: pos 0 -> word[4:0], pos 1 -> word[9:5], etc.
    assign char_code_out = word_in[position*5 +: 5];
endmodule
