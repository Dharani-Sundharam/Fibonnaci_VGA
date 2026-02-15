`timescale 1ns / 1ps
//============================================================================
// Module:  debounce
// Purpose: Counter-based button debouncer with parameterizable delay.
//          Outputs a single-clock-cycle pulse on the rising edge of the
//          debounced signal.
//
// Why this approach?
//   Mechanical push-buttons bounce for ~5-20 ms. We sample the raw input
//   with a free-running counter. Only when the input has been stable HIGH
//   for DELAY_CYCLES consecutive clocks do we register it as pressed.
//   This avoids false triggers and is the gold-standard for FPGA debouncing.
//
// Parameter:
//   DELAY_CYCLES - Number of clock cycles the button must be stable.
//                  Default 1_000_000 = 10 ms @ 100 MHz.
//                  Override to a small value (e.g. 10) in simulation.
//============================================================================

module debounce #(
    parameter DELAY_CYCLES = 1_000_000   // 10 ms @ 100 MHz
)(
    input  wire clk,
    input  wire rst,        // Active-high synchronous reset
    input  wire btn_in,     // Raw noisy button input
    output reg  btn_out     // Clean single-cycle pulse
);

    // Counter width: ceil(log2(DELAY_CYCLES))
    localparam CNT_WIDTH = $clog2(DELAY_CYCLES + 1);

    reg [CNT_WIDTH-1:0] count;
    reg                 btn_stable;  // Debounced level (not pulse)

    // ------------------------------------------------------------------
    // Debounce counter logic
    //   - Count up while button is held; reset count when released.
    //   - Assert btn_stable once counter saturates.
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            count      <= 0;
            btn_stable <= 1'b0;
        end else if (btn_in) begin
            if (count < DELAY_CYCLES)
                count <= count + 1;
            else
                btn_stable <= 1'b1;
        end else begin
            count      <= 0;
            btn_stable <= 1'b0;
        end
    end

    // ------------------------------------------------------------------
    // Rising-edge detector: produce a single-cycle pulse
    // ------------------------------------------------------------------
    reg btn_stable_d;  // Delayed version for edge detection

    always @(posedge clk) begin
        if (rst) begin
            btn_stable_d <= 1'b0;
            btn_out      <= 1'b0;
        end else begin
            btn_stable_d <= btn_stable;
            btn_out      <= btn_stable & ~btn_stable_d;  // Rising edge
        end
    end

endmodule
