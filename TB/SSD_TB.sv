// verify pushing data_switches into D register correctly sets 20 bit letter string
// ALU correctly passes word straight to RAM
// Writing to RAM works and reading back word locations dispalys expected 7-segement codes as slow_clk toggles

`timescale 1ns/1ps

module join_ssd_tb;
    logic        clk = 0;
    logic        rst_n = 0;
    logic        slow_clk = 0;
    logic        slow_rst_n = 0;

    logic [19:0] data_switches = '0;
    logic [2:0]  ram_address = '0;
    logic        alu_zx, alu_nx, alu_zy, alu_ny, alu_f, alu_no;
    logic        btn_load_d = 0, btn_load_a = 0, btn_write_ram = 0;
    logic        disp_mode = 0;

    logic [6:0]  segments;
    logic        zero_led, neg_led;

    join_ssd_top DUT (.*);

    // Override debouncer STABLE_CYCLES for fast simulation
    defparam DUT.u_db_d.STABLE_CYCLES  = 2;
    defparam DUT.u_db_a.STABLE_CYCLES  = 2;
    defparam DUT.u_db_wr.STABLE_CYCLES = 2;

    // Fast Main Clock (100 MHz)
    always #5 clk = ~clk;

    // Slow Display Clock (10 MHz in sim, ~2 Hz in real HW)
    always #50 slow_clk = ~slow_clk;

    initial begin
        \$display("Starting JOIN v2 SystemVerilog Simulation...");

        // 1. Reset
        #20 rst_n = 1; slow_rst_n = 1;
        #20;

        // 2. Load "JOIN" word into D register
        // Letter indices: J=9, O=14, I=8, N=13
        // 20-bit concatenated binary: {13, 8, 14, 9} = {5'd13, 5'd8, 5'd14, 5'd9}
        data_switches = {5'd13, 5'd8, 5'd14, 5'd9};
        btn_load_d = 1;
        #50 btn_load_d = 0;
        #50;

        // 3. Set ALU to pass X (D register): zx=0, nx=0, zy=1, ny=1, f=0, no=0
        alu_zx = 0; alu_nx = 0; alu_zy = 1; alu_ny = 1; alu_f = 0; alu_no = 0;
        #40;

        // 4. Write word to RAM at Address 2
        ram_address = 3'd2;
        btn_write_ram = 1;
        #50 btn_write_ram = 0;
        #50;

        // 5. Turn on RAM Display Mode
        disp_mode = 1;

        // 6. Observe display cycling over slow_clk edges
        #1500;
        \$display("Simulation complete! Check display output segments in waveform view.");
        \$finish;
    end
endmodule
