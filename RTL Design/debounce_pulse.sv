`default_nettype none

module debounce_pulse #(
    parameter integer STABLE_CYCLES = 200_000
) (
    input  logic clk,
    input  logic rst_n,
    input  logic btn_in,
    output logic pulse_out
);
    logic sync0, sync1, stable_level;
    logic [31:0] counter;
    logic prev_stable;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync0 <= 1'b0; sync1 <= 1'b0;
        end else begin
            sync0 <= btn_in;
            sync1 <= sync0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'd0; stable_level <= 1'b0;
        end else if (sync1 != stable_level) begin
            if (counter >= STABLE_CYCLES - 1) begin
                stable_level <= sync1;
                counter      <= 32'd0;
            end else begin
                counter <= counter + 1'b1;
            end
        end else begin
            counter <= 32'd0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_stable <= 1'b0; pulse_out <= 1'b0;
        end else begin
            prev_stable <= stable_level;
            pulse_out   <= stable_level & ~prev_stable;
        end
    end
endmodule
