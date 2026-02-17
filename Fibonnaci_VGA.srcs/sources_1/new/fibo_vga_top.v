`timescale 1ns / 1ps

module fibo_vga_top (
    input wire clk,              // 100MHz system clock
    input wire [7:0] sw,         // Switches for input
    input wire btnc,             // Enter button
    input wire btnr,             // Reset button
    output wire [7:0] led,       // LED outputs
    output wire [3:0] vga_r,     // VGA red
    output wire [3:0] vga_g,     // VGA green
    output wire [3:0] vga_b,     // VGA blue
    output wire hsync,           // VGA horizontal sync
    output wire vsync            // VGA vertical sync
);

    // Internal signals
    wire btn_enter_pulse, btn_reset;
    wire clk_25mhz_en;
    
    // FSM control signals
    wire load_num1, load_num2, load_num3;
    wire init_gen, step_gen;
    wire show_ready, show_done, show_error;
    wire show_read1, show_read2, show_read3;
    wire [1:0] progress_leds;
    
    // Datapath signals
    wire valid, gen_done;
    wire [15:0] result0, result1, result2, result3;  // 16-bit results
    wire [7:0] num1_out, num2_out, num3_out;
    
    // Debounce buttons
    debounce #(.DELAY_CYCLES(1_000_000)) debounce_enter (
        .clk(clk),
        .reset(btnr),
        .btn_in(btnc),
        .btn_pulse(btn_enter_pulse)
    );
    
    assign btn_reset = btnr;
    
    // Clock divider for VGA
    clk_divider clk_div (
        .clk(clk),
        .reset(btn_reset),
        .clk_25mhz_en(clk_25mhz_en)
    );
    
    // Fibonacci datapath
    fibonacci_datapath datapath (
        .clk(clk),
        .reset(btn_reset),
        .load_num1(load_num1),
        .load_num2(load_num2),
        .load_num3(load_num3),
        .init_gen(init_gen),
        .step_gen(step_gen),
        .sw_data(sw),
        .valid(valid),
        .gen_done(gen_done),
        .result0(result0),
        .result1(result1),
        .result2(result2),
        .result3(result3),
        .num1_out(num1_out),
        .num2_out(num2_out),
        .num3_out(num3_out)
    );
    
    // Fibonacci FSM
    fibonacci_fsm fsm (
        .clk(clk),
        .reset(btn_reset),
        .btn_enter(btn_enter_pulse),
        .valid(valid),
        .gen_done(gen_done),
        .load_num1(load_num1),
        .load_num2(load_num2),
        .load_num3(load_num3),
        .init_gen(init_gen),
        .step_gen(step_gen),
        .show_ready(show_ready),
        .show_done(show_done),
        .show_error(show_error),
        .show_read1(show_read1),
        .show_read2(show_read2),
        .show_read3(show_read3),
        .progress_leds(progress_leds)
    );
    
    // VGA controller
    top_vga vga_ctrl (
        .clk(clk),
        .reset(btn_reset),
        .clk_en(clk_25mhz_en),
        .show_ready(show_ready),
        .show_done(show_done),
        .show_error(show_error),
        .show_read1(show_read1),
        .show_read2(show_read2),
        .show_read3(show_read3),
        .result0(result0),
        .result1(result1),
        .result2(result2),
        .result3(result3),
        .num1(num1_out),
        .num2(num2_out),
        .num3(num3_out),
        .sw_live(sw),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .hsync(hsync),
        .vsync(vsync)
    );
    
    // LED outputs for debugging
    assign led[1:0] = progress_leds;
    assign led[2] = show_ready;
    assign led[3] = show_done;
    assign led[4] = show_error;
    assign led[7:5] = 3'b000;

endmodule
