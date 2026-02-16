`timescale 1ns / 1ps
//============================================================================
// Module:  fibonacci_vga_only
// Purpose: Top-level for VGA-only display of Fibonacci results.
//          No UART or OLED - just Fibonacci core + VGA output.
//============================================================================

module fibonacci_vga_only #(
    parameter DEBOUNCE_DELAY = 1_000_000
)(
    input  wire       clk,           // 100 MHz
    input  wire       rst,           // Reset (active high)
    input  wire [7:0] sw,            // Switches for input
    input  wire       btn_enter,     // Enter button
    
    output wire [7:0] led,           // LEDs
    
    // VGA outputs
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       vga_hsync,
    output wire       vga_vsync
);

    // === Internal signals ===
    wire enter_pulse, rst_clean;
    wire load_num1, load_num2, load_num3;
    wire init_gen, step_gen;
    wire valid, overflow;
    wire [2:0] gen_count;
    wire [7:0] gen_out;
    wire [7:0] result0, result1, result2, result3;
    wire breathing_en;
    wire [2:0] read_phase;
    wire show_gen, show_error, show_done;
    wire uart_send_results;  // unused here
    wire breathing_led;

    // === Debouncers ===
    debounce #(.DELAY_CYCLES(DEBOUNCE_DELAY)) u_deb_enter (
        .clk(clk), .rst(1'b0), .btn_in(btn_enter), .btn_out(enter_pulse)
    );
    debounce #(.DELAY_CYCLES(DEBOUNCE_DELAY)) u_deb_reset (
        .clk(clk), .rst(1'b0), .btn_in(rst), .btn_out(rst_clean)
    );

    // === Breathing LED ===
    pwm_breathing u_breath (
        .clk(clk), .rst(rst_clean), .enable(breathing_en), .led_out(breathing_led)
    );

    // === Datapath ===
    fibonacci_datapath u_dp (
        .clk(clk), .rst(rst_clean),
        .sw_data({1'b0, sw[6:0]}),
        .load_num1(load_num1), .load_num2(load_num2), .load_num3(load_num3),
        .init_gen(init_gen), .step_gen(step_gen),
        .valid(valid), .overflow(overflow), .gen_count(gen_count), .gen_out(gen_out),
        .result0(result0), .result1(result1),
        .result2(result2), .result3(result3)
    );

    // === FSM ===
    fibonacci_fsm u_fsm (
        .clk(clk), .rst(rst_clean), .enter(enter_pulse),
        .valid(valid), .gen_count(gen_count),
        .load_num1(load_num1), .load_num2(load_num2), .load_num3(load_num3),
        .init_gen(init_gen), .step_gen(step_gen),
        .breathing_en(breathing_en), .read_phase(read_phase),
        .show_gen(show_gen), .show_error(show_error), .show_done(show_done),
        .uart_send_results(uart_send_results)
    );

    // === LED Mux ===
    reg [24:0] blink_cnt;
    always @(posedge clk) begin
        if (rst_clean) blink_cnt <= 0;
        else           blink_cnt <= blink_cnt + 1;
    end

    reg [7:0] led_reg;
    always @(*) begin
        led_reg = 8'b0;
        if (show_error)
            led_reg = {8{blink_cnt[24]}};
        else if (show_gen)
            led_reg = gen_out;
        else if (read_phase > 0) begin
            case (read_phase)
                3'd1:    led_reg = 8'b0000_0001;
                3'd2:    led_reg = 8'b0000_0011;
                3'd3:    led_reg = 8'b0000_0111;
                default: led_reg = 8'b0000_0000;
            endcase
        end else if (breathing_en)
            led_reg = {breathing_led, 7'b0};
    end
    assign led = led_reg;

    // === VGA Display ===
    wire show_ready = breathing_en & ~show_done & ~show_error;
    
    top_vga u_vga (
        .clk(clk),
        .rst(rst_clean),
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
