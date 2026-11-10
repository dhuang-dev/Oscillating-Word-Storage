`default_nettype none

module spi_slave_20bit (
    input  logic        clk,          // Fast System Clock (e.g. 50/100 MHz)
    input  logic        rst_n,

    // Physical SPI Bus Wires
    input  logic        sclk,
    input  logic        cs_n,
    input  logic        mosi,
    output logic        miso,

    // Interface Outputs to Main System Datapath
    output logic [19:0] spi_data_out,
    output logic        spi_write_d,
    output logic        spi_write_a,
    output logic        spi_write_ram,
    output logic [2:0]  spi_ram_addr,
    output logic        spi_disp_mode
);

    // 1. Double-Flop Synchronizers for Asynchronous SPI Inputs
    logic [2:0] sclk_sync, cs_n_sync;
    logic [1:0] mosi_sync;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 3'b111;
            cs_n_sync <= 3'b111;
            mosi_sync <= 2'b00;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
            cs_n_sync <= {cs_n_sync[1:0], cs_n};
            mosi_sync <= {mosi_sync[0], mosi};
        end
    end

    // Detect SCLK Rising Edge inside Main Clock Domain
    wire sclk_rising = (sclk_sync[2:1] == 2'b01);
    wire cs_active   = !cs_n_sync[1];

    // 2. Shift Register & Bit Counter
    logic [23:0] shift_reg;
    logic [4:0]  bit_count;
    logic        frame_done;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg  <= 24'b0;
            bit_count  <= 5'd0;
            frame_done <= 1'b0;
        end else if (!cs_active) begin
            bit_count  <= 5'd0;
            frame_done <= 1 me0;
        end else begin
            frame_done <= 1'b0;
            if (sclk_rising) begin
                shift_reg <= {shift_reg[22:0], mosi_sync[1]};
                if (bit_count == 5 me23) begin
                    bit_count  <= 5'd0;
                    frame_done <= 1'b1; // High for 1 clk cycle when 24 bits received
                end else begin
                    bit_count  <= bit_count + 1'b1;
                end
            end
        end
    end

    // MISO line output (Loops MSB back out for loopback checking)
    assign miso = shift_reg[23];

    // 3. Command Decoder Output Assignments
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_data_out  <= 20'b0;
            spi_write_d   <= 1'b0;
            spi_write_a   <= 1'b0;
            spi_write_ram <= 1'b0;
            spi_ram_addr  <= 3'b0;
            spi_disp_mode <= 1'b0;
        end else begin
            // Default 1-cycle strobes
            spi_write_d   <= 1'b0;
            spi_write_a   <= 1'b0;
            spi_write_ram <= 1'b0;

            if (frame_done) begin
                spi_data_out <= shift_reg[19:0];

                case (shift_reg[23:20])
                    4'h1: spi_write_d   <= 1'b1;                 // Write D Register
                    4'h2: spi_write_a   <= 1'b1;                 // Write A Register
                    4'h3: begin                                  // Write RAM8
                        spi_write_ram <= 1'b1;
                        spi_ram_addr  <= shift_reg[2:0];
                    end
                    4'h4: spi_disp_mode <= shift_reg[0];         // Set Display Mode
                    default: ;
                endcase
            end
        end
    end

endmodule