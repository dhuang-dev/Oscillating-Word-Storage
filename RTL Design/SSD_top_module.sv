`default_nettype none

// TOP MODULE -- 20-bit Datapath with Gray Code CDC Display Path

module join_ssd_top (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        slow_clk,
    input  logic        slow_rst_n,

    input  logic [19:0] data_switches, // 4 x 5-bit character indices
    input  logic [2:0]  ram_address,
    input  logic        alu_zx, alu_nx, alu_zy, alu_ny, alu_f, alu_no,

    input  logic        btn_load_d,
    input  logic        btn_load_a,
    input  logic        btn_write_ram,

    input  logic        disp_mode,

    output logic [6:0]  segments,
    output logic        zero_led,
    output logic        neg_led
);
    // Control pulses (clk domain)
    logic load_d_pulse, load_a_pulse, write_ram_pulse;

    debounce_pulse u_db_d  (.clk, .rst_n, .btn_in(btn_load_d),    .pulse_out(load_d_pulse));
    debounce_pulse u_db_a  (.clk, .rst_n, .btn_in(btn_load_a),    .pulse_out(load_a_pulse));
    debounce_pulse u_db_wr (.clk, .rst_n, .btn_in(btn_write_ram), .pulse_out(write_ram_pulse));

    // Registers
    logic [19:0] d_reg_out, a_reg_out;

    register20 u_d_reg (.clk, .rst_n, .load(load_d_pulse), .in(data_switches), .out(d_reg_out));
    register20 u_a_reg (.clk, .rst_n, .load(load_a_pulse), .in(data_switches), .out(a_reg_out));

    // ALU
    logic [19:0] alu_result;
    logic        alu_zr, alu_ng;

    alu20 u_alu (
        .x(d_reg_out), .y(a_reg_out),
        .zx(alu_zx), .nx(alu_nx), .zy(alu_zy), .ny(alu_ny), .f(alu_f), .no(alu_no),
        .out(alu_result), .zr(alu_zr), .ng(alu_ng)
    );

    assign zero_led = alu_zr;
    assign neg_led  = alu_ng;

    // RAM8 (20-bit wide)
    logic [19:0] ram_out;

    ram8_20bit u_ram (
        .clk, .rst_n,
        .address(ram_address), .load(write_ram_pulse), .in(alu_result),
        .out(ram_out)
    );

    logic [19:0] display_word;
    assign display_word = disp_mode ? ram_out : alu_result;

    // Cross-Clock Domain Path
    logic [1:0] position_gray;
    gray_position_counter u_pos (
        .slow_clk(slow_clk), .slow_rst_n(slow_rst_n), .position_gray(position_gray)
    );

    logic [1:0] position_gray_sync;
    cdc_sync2 #(.WIDTH(2)) u_cdc (
        .clk, .rst_n, .async_in(position_gray), .sync_out(position_gray_sync)
    );

    // Convert Gray -> Binary
    logic [1:0] position_bin_sync;
    assign position_bin_sync[1] = position_gray_sync[1];
    assign position_bin_sync[0] = position_gray_sync[1] ^ position_gray_sync[0];

    // Mux & Segment Decoder
    logic [4:0] char_code;
    chunk_mux   u_mux (.word_in(display_word), .position(position_bin_sync), .char_code_out(char_code));
    char_decoder u_dec (.code(char_code), .segments(segments));

endmodule
`default_nettype wire
