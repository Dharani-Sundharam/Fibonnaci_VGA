`timescale 1ns / 1ps
//============================================================================
// Module:  clk_divider
// Purpose: Generate 25 MHz enable pulse from 100 MHz system clock
//          For VGA 640x480 @ 60Hz pixel clock
//============================================================================

module clk_divider (
    input  wire clk,           // 100 MHz system clock
    input  wire rst,           // Active-high reset
    output wire clk_en_25mhz   // 25 MHz enable pulse
);

    // Counter: 0, 1, 2, 3, then repeat
    // Enable pulse when counter = 0
    // Frequency: 100MHz / 4 = 25MHz
    
    reg [1:0] counter;
    
    always @(posedge clk) begin
        if (rst)
            counter <= 2'b00;
        else
            counter <= counter + 1'b1;  // Auto wraps at 3→0
    end
    
    // Generate enable pulse every 4 clock cycles
    assign clk_en_25mhz = (counter == 2'b00);
    
    // Debug: Report enable generation
    initial $display("VGA Clock Divider instantiated");

endmodule
