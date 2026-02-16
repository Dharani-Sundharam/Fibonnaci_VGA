`timescale 1ns / 1ps
//============================================================================
// Module:  fibonacci_vga_top
// Purpose: Integration of Fibonacci core with VGA display
//          Shows Fibonacci results on VGA monitor (green on black)
//============================================================================

module fibonacci_vga_top #(
    parameter DEBOUNCE_DELAY = 1_000_000
)(
    // System
    input  wire       clk,           // 100 MHz (Y9)
    input  wire       rst,           // Reset button
    
    // Fibonacci inputs (from original design)
    input  wire [7:0] sw,            // Switches
    input  wire       btn_enter,     // Enter button
    
    // Fibonacci outputs (LEDs, UART, OLED - keep existing)
    output wire [7:0] led,
    output wire       uart_txd,
    output wire       oled_sclk,
    output wire       oled_sdin,
    output wire       oled_dc,
    output wire       oled_res,
    output wire       oled_vbat,
    output wire       oled_vdd,
    
    // VGA outputs (NEW)
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       vga_hsync,
    output wire       vga_vsync
);

    // Internal signals from Fibonacci core
    wire show_done, show_error, breathing_en;
    wire [7:0] result0, result1, result2, result3;
    
    // Create show_ready signal (idle = breathing LED active, not done/error)
    wire show_ready = breathing_en & ~show_done & ~show_error;
    
    // Instantiate existing Fibonacci core (now with VGA outputs exposed)
    top_fibonacci #(
        .DEBOUNCE_DELAY(DEBOUNCE_DELAY)
    ) u_fibo_core (
        .clk(clk),
        .btnr(rst),
        .btnc(btn_enter),
        .sw(sw),
        .led(led),
        .uart_txd(uart_txd),
        // VGA integration signals
        .show_done(show_done),
        .show_error(show_error),
        .breathing_en(breathing_en),
        .result0(result0),
        .result1(result1),
        .result2(result2),
        .result3(result3),
        // OLED outputs
        .oled_sclk(oled_sclk),
        .oled_sdin(oled_sdin),
        .oled_dc(oled_dc),
        .oled_res(oled_res),
        .oled_vbat(oled_vbat),
        .oled_vdd(oled_vdd)
    );
    
    // Instantiate VGA display
    top_vga u_vga (
        .clk(clk),
        .rst(rst),
        .show_ready(show_ready),
        .show_done(show_done),
        .show_error(show_error),
        .result0(result0),
        .result1(result1),
        .result2(result2),
        .result3(result3),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync)
    );

endmodule
