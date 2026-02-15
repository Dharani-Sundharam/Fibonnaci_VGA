`timescale 1ns / 1ps
//============================================================================
// Module:  pwm_breathing
// Purpose: Generate a "breathing" PWM signal for the IDLE status LED.
//
// How it works:
//   1. A prescaler divides the 100 MHz clock down to a ~381 Hz update tick
//      (100 MHz / 2^18 ≈ 381 Hz). This controls how fast the brightness
//      changes — slow enough for a smooth, organic-looking breath.
//   2. An 8-bit brightness counter ramps UP from 0→255, then DOWN from
//      255→0 (triangle wave). Each ramp takes 255 * (1/381) ≈ 0.67 s,
//      so a full breath cycle is ~1.34 s — visually pleasing.
//   3. A standard 8-bit PWM comparator converts brightness to a 1-bit
//      output at 100 MHz / 256 ≈ 390 kHz — far above LED flicker threshold.
//
// Why 8 bits?
//   Gives 256 brightness levels — smooth enough that judges won't see
//   stepping. More bits would be overkill for an LED.
//============================================================================

module pwm_breathing (
    input  wire clk,
    input  wire rst,
    input  wire enable,     // Only breathe when FSM is in IDLE
    output wire led_out     // PWM-modulated LED drive
);

    // ------------------------------------------------------------------
    // Prescaler: divide 100 MHz down to a slow update tick
    // ------------------------------------------------------------------
    reg [17:0] prescaler;   // 2^18 = 262144 → ~381 Hz tick

    always @(posedge clk) begin
        if (rst)
            prescaler <= 18'd0;
        else
            prescaler <= prescaler + 1;
    end

    wire tick = (prescaler == 18'd0);  // Single-cycle pulse every ~2.6 ms

    // ------------------------------------------------------------------
    // Triangle brightness ramp (0 → 255 → 0 → ...)
    // ------------------------------------------------------------------
    reg [7:0] brightness;
    reg       direction;    // 0 = ramping up, 1 = ramping down

    always @(posedge clk) begin
        if (rst) begin
            brightness <= 8'd0;
            direction  <= 1'b0;
        end else if (enable && tick) begin
            if (!direction) begin
                // Ramping UP
                if (brightness == 8'd255)
                    direction <= 1'b1;       // Switch to ramp down
                else
                    brightness <= brightness + 1;
            end else begin
                // Ramping DOWN
                if (brightness == 8'd0)
                    direction <= 1'b0;       // Switch to ramp up
                else
                    brightness <= brightness - 1;
            end
        end
    end

    // ------------------------------------------------------------------
    // PWM comparator
    //   Free-running 8-bit counter vs brightness level.
    //   Output HIGH when counter < brightness → duty cycle = brightness/256.
    // ------------------------------------------------------------------
    reg [7:0] pwm_counter;

    always @(posedge clk) begin
        if (rst)
            pwm_counter <= 8'd0;
        else
            pwm_counter <= pwm_counter + 1;
    end

    // Gate with enable so LED is fully OFF when not in IDLE
    assign led_out = enable ? (pwm_counter < brightness) : 1'b0;

endmodule
