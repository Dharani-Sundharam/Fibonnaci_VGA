`timescale 1ns / 1ps

module debounce #(
    parameter DELAY_CYCLES = 1_000_000  // 10ms @ 100MHz
)(
    input wire clk,
    input wire reset,
    input wire btn_in,
    output reg btn_pulse
);

    reg [19:0] counter;
    reg btn_sync_0, btn_sync_1;
    reg btn_state;

    // Synchronize button input
    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
    end

    // Debounce logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            btn_state <= 0;
            btn_pulse <= 0;
        end else begin
            btn_pulse <= 0;  // Default: no pulse
            
            if (btn_sync_1 != btn_state) begin
                // Button state changed, start counting
                if (counter < DELAY_CYCLES) begin
                    counter <= counter + 1;
                end else begin
                    // Stable for long enough
                    btn_state <= btn_sync_1;
                    counter <= 0;
                    // Generate pulse on rising edge
                    if (btn_sync_1 && !btn_state) begin
                        btn_pulse <= 1;
                    end
                end
            end else begin
                // Button stable, reset counter
                counter <= 0;
            end
        end
    end

endmodule
