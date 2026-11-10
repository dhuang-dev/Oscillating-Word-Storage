`default_nettype none

module join_ssd_top (
    input  logic        clk,
    input  logic        rst_n,

    // Async Display Domain (555 Timer simulation)
    input  logic        slow_clk,
    input  logic        slow_rst_n,

    // Mode Selector: 0 = Manual Pushbuttons/Switches, 1 = Host SPI Interface
    input  logic        input_mode_sel,

    // ANUAL / HARDWARE INTERFACE 
    input  logic [19:0] data_switches, // 4 x 5-bit character indices
    input  logic [2:0]  ram_address,
    input  logic        alu_zx, alu_nx, alu_zy, alu_ny, alu_f, alu_no,
    input  logic        btn_load_d,
    input  logic        btn_load_a,
    input  logic        btn_write_ram,
    input  logic        disp_mode,       // 0 = ALU, 1 = RAM

    // HOST SPI INTERFACE 
    input  logic        spi_sclk,
    input  logic        spi_cs_n,
    input  logic        spi_mosi,
    output logic        spi_miso,

    // OUTPUTS 
    output logic [6:0]  segments,
    output logic        zero_led,
    output logic        neg_led
);

    // 1. MANUAL CONTROLS: Debounced Pushbutton Strobes
    logic manual_load_d, manual_load_a, manual_write_ram;

    debounce_pulse u_db_d  (.clk(clk), .rst_n(rst_n), .btn_in(btn_load_d),    .pulse_out(manual_load_d));
    debounce_pulse u_db_a  (.clk(clk), .rst_n(rst_n), .btn_in(btn_load_a),    .pulse_out(manual_load_a));
    debounce_pulse u_db_wr (.clk(clk), .rst_n(rst_n), .btn_in(btn_write_ram), .pulse_out(manual_write_ram));

    // 2. SPI SLAVE INTERFACE
    logic [19:0] spi_data_out;
    logic        spi_write_d;
    logic        spi_write_a;
    logic        spi_write_ram;
    logic [2:0]  spi_ram_addr;
    logic        spi_disp_mode;

    spi_slave_20bit u_spi (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(spi_sclk),
        .cs_n(spi_cs_n),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .spi_data_out(spi_data_out),
        .spi_write_d(spi_write_d),
        .spi_write_a(spi_write_a),
        .spi_write_ram(spi_write_ram),
        .spi_ram_addr(spi_ram_addr),
        .spi_disp_mode(spi_disp_mode)
    );


    // 3. TOPOLOGY MUXING (Manual vs SPI Selection)
    logic [19:0] sel_data_word;
    logic        sel_load_d;
    logic        sel_load_a;
    logic        sel_write_ram;
    logic [2:0]  sel_ram_addr;
    logic        sel_disp_mode;

    assign sel_data_word = input_mode_sel ? spi_data_out  : data_switches;
    assign sel_load_d    = input_mode_sel ? spi_write_d   : manual_load_d;
    assign sel_load_a    = input_mode_sel ? spi_write_a   : manual_load_a;
    assign sel_write_ram = input_mode_sel ? spi_write_ram : manual_write_ram;
    assign sel_ram_addr  = input_mode_sel ? spi_ram_addr  : ram_address;
    assign sel_disp_mode = input_mode_sel ? spi_disp_mode : disp_mode;


    // 4. MAIN DATAPATH (Driven by Selected Control Signals)
    logic [19:0] d_reg_out, a_reg_out;

    register20 u_d_reg (.clk(clk), .rst_n(rst_n), .load(sel_load_d), .in(sel_data_word), .out(d_reg_out));
    register20 u_a_reg (.clk(clk), .rst_n(rst_n), .load(sel_load_a), .in(sel_data_word), .out(a_reg_out));

    // 20-bit ALU
    logic [19:0] alu_result;
    logic        alu_zr, alu_ng;

    alu20 u_alu (
        .x(d_reg_out), .y(a_reg_out),
        .zx(alu_zx), .nx(alu_nx), .zy(alu_zy), .ny(alu_ny), .f(alu_f), .no(alu_no),
        .out(alu_result), .zr(alu_zr), .ng(alu_ng)
    );

    assign zero_led = alu_zr;
    assign neg_led  = alu_ng;

    // 20-bit RAM8 Memory Array
    logic [19:0] ram_out;

    ram8_20bit u_ram (
        .clk(clk), .rst_n(rst_n),
        .address(sel_ram_addr),
        .load(sel_write_ram),
        .in(alu_result),
        .out(ram_out)
    );

    // Mux display target: ALU live output vs RAM contents
    logic [19:0] display_word;
    assign display_word = sel_disp_mode ? ram_out : alu_result;

    // 5. ASYNCHRONOUS CDC DISPLAY PATH
    logic [1:0] position_gray, position_gray_sync, position_bin_sync;

    // Position counter runs on slow_clk (555 timer domain)
    gray_position_counter u_pos (
        .slow_clk(slow_clk), .slow_rst_n(slow_rst_n), .position_gray(position_gray)
    );

    // 2FF CDC Synchronizer
    cdc_sync2 #(.WIDTH(2)) u_cdc (
        .clk(clk), .rst_n(rst_n), .async_in(position_gray), .sync_out(position_gray_sync)
    );

    // Gray -> Binary Conversion
    assign position_bin_sync[1] = position_gray_sync[1];
    assign position_bin_sync[0] = position_gray_sync[1] ^ position_gray_sync[0];

    // Mux 5-bit character slice & decode output segments
    logic [4:0] char_code;
    chunk_mux   u_mux (.word_in(display_word), .position(position_bin_sync), .char_code_out(char_code));
    char_decoder u_dec (.code(char_code), .segments(segments));

endmodule
`default_nettype wire