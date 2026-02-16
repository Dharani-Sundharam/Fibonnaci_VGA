`timescale 1ns / 1ps
//============================================================================
// Module:  top_fibonacci
// Purpose: Top-level wrapper. Wires FSM + Datapath + Debounce + UART.
//
// UART Output:
//   When a valid sequence is found and 4 values are generated, the UART
//   sends them as: "03 05 08 0D\r\n" (hex, space-separated).
//   If invalid, UART sends: "ERR\r\n"
//============================================================================

module top_fibonacci #(
    parameter DEBOUNCE_DELAY = 1_000_000
)(
    input  wire       clk,
    input  wire [7:0] sw,
    input  wire       btnc,
    input  wire       btnr,
    output wire [7:0] led,
    output wire       uart_txd,
    
    // VGA integration outputs (NEW)
    output wire       show_done,
    output wire       show_error,
    output wire       breathing_en,
    output wire [7:0] result0,
    output wire [7:0] result1,
    output wire [7:0] result2,
    output wire [7:0] result3,
    
    // OLED outputs
    output wire       oled_sclk,
    output wire       oled_sdin,
    output wire       oled_dc,
    output wire       oled_res,
    output wire       oled_vbat,
    output wire       oled_vdd
);

    // === Internal wires ===
    wire enter_pulse, rst;
    wire load_num1, load_num2, load_num3;
    wire init_gen, step_gen;
    wire valid, overflow;
    wire [2:0] gen_count;
    wire [7:0] gen_out;
    wire [7:0] result0_int, result1_int, result2_int, result3_int;
    wire breathing_en_int;
    wire [2:0] read_phase;
    wire show_gen, show_error_int, show_done_int;
    wire uart_send_results;
    wire breathing_led;

    // === Debouncers ===
    debounce #(.DELAY_CYCLES(DEBOUNCE_DELAY)) u_deb_enter (
        .clk(clk), .rst(1'b0), .btn_in(btnc), .btn_out(enter_pulse)
    );
    debounce #(.DELAY_CYCLES(DEBOUNCE_DELAY)) u_deb_reset (
        .clk(clk), .rst(1'b0), .btn_in(btnr), .btn_out(rst)
    );

    // === Breathing LED ===
    pwm_breathing u_breath (
        .clk(clk), .rst(rst), .enable(breathing_en_int), .led_out(breathing_led)
    );

    // === Datapath ===
    fibonacci_datapath u_dp (
        .clk(clk), .rst(rst),
        .sw_data({1'b0, sw[6:0]}),
        .load_num1(load_num1), .load_num2(load_num2), .load_num3(load_num3),
        .init_gen(init_gen), .step_gen(step_gen),
        .valid(valid), .overflow(overflow), .gen_count(gen_count), .gen_out(gen_out),
        .result0(result0_int), .result1(result1_int),
        .result2(result2_int), .result3(result3_int)
    );

    // === FSM ===
    fibonacci_fsm u_fsm (
        .clk(clk), .rst(rst), .enter(enter_pulse),
        .valid(valid), .gen_count(gen_count),
        .load_num1(load_num1), .load_num2(load_num2), .load_num3(load_num3),
        .init_gen(init_gen), .step_gen(step_gen),
        .breathing_en(breathing_en_int), .read_phase(read_phase),
        .show_gen(show_gen), .show_error(show_error_int), .show_done(show_done_int),
        .uart_send_results(uart_send_results)
    );

    // === LED Mux ===
    reg [7:0] led_reg;
    reg [24:0] blink_cnt;

    always @(posedge clk) begin
        if (rst) blink_cnt <= 0;
        else     blink_cnt <= blink_cnt + 1;
    end

    always @(*) begin
        led_reg = 8'b0;  // Default to off (prevents X values)
        
        if (show_error_int)
            led_reg = {8{blink_cnt[24]}};       // Blink all LEDs
        else if (show_gen)
            led_reg = gen_out;                   // Show Fibonacci value
        else if (read_phase > 0) begin
            case (read_phase)
                3'd1:    led_reg = 8'b0000_0001;
                3'd2:    led_reg = 8'b0000_0011;
                3'd3:    led_reg = 8'b0000_0111;
                default: led_reg = 8'b0000_0000;
            endcase
        end else if (breathing_en_int)
            led_reg = {breathing_led, 7'b0};
    end

    assign led = led_reg;
    
    // VGA integration outputs - connect internal signals to output ports
    assign show_done = show_done_int;       // From FSM
    assign show_error = show_error_int;     // From FSM
    assign breathing_en = breathing_en_int; // From FSM
    assign result0 = result0_int;           // From datapath
    assign result1 = result1_int;           // From datapath
    assign result2 = result2_int;           // From datapath
    assign result3 = result3_int;           // From datapath


    // =================================================================
    // UART TX — Send generated Fibonacci values (or "ERR")
    //
    // Format (valid):   "03 05 08 0D\r\n"
    // Format (invalid): "ERR\r\n"
    //
    // The UART is slow (9600 baud), so we use a simple state machine
    // that sends one byte at a time, waiting for each to complete.
    // =================================================================
    reg [7:0]  uart_byte;
    reg        uart_start;
    wire       uart_busy;

    uart_tx #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(115200),    // Faster for simulation and matches standard
        .PARITY_EN(1),         // Enable even parity
        .PARITY_ODD(0)         // 0 = even parity, 1 = odd parity
    ) u_uart (
        .clk(clk), .rst(rst),
        .tx_data(uart_byte), .tx_start(uart_start),
        .tx_out(uart_txd), .tx_busy(uart_busy)
    );

    // === OLED Controller ===
    // Map FSM state to display mode
    wire [2:0] oled_mode;
    assign oled_mode = show_error_int ? 3'd5 :      // ERROR mode
                       show_done_int  ? 3'd4 :       // DONE mode
                                        3'd0;        // IDLE mode
    
    oled_ctrl u_oled (
        .clk(clk),
        .rst(rst),
        .display_mode(oled_mode),
        .result0(result0_int),
        .result1(result1_int),
        .result2(result2_int),
        .result3(result3_int),
        .oled_sclk(oled_sclk),
        .oled_sdin(oled_sdin),
        .oled_dc(oled_dc),
        .oled_res(oled_res),
        .oled_vbat(oled_vbat),
        .oled_vdd(oled_vdd)
    );

    // Convert a 4-bit nibble to ASCII hex character
    function [7:0] hex_char;
        input [3:0] nibble;
        hex_char = (nibble < 10) ? (8'h30 + nibble) : (8'h41 + nibble - 10);
    endfunction

    // UART serializer state machine
    // Sends: [R0_hi][R0_lo][' '][R1_hi][R1_lo][' '][R2_hi][R2_lo][' '][R3_hi][R3_lo][CR][LF]
    // That's 12 bytes total for valid, or 5 bytes for "ERR\r\n"
    localparam U_IDLE = 5'd0;
    // States 1-12: send the 4 hex values with spaces
    // States 20-24: send "ERR\r\n"

    reg [4:0]  uart_state;
    reg        sent_flag;       // Prevent re-sending while in DONE

    // Store which result to send
    reg [7:0] send_buf [0:3];

    always @(posedge clk) begin
        if (rst) begin
            uart_state    <= U_IDLE;
            uart_start <= 1'b0;
            uart_byte  <= 8'd0;
            sent_flag  <= 1'b0;
        end else begin
            uart_start <= 1'b0;  // Default: clear start pulse

            case (uart_state)
                U_IDLE: begin
                    if (uart_send_results && !sent_flag) begin
                        // Capture the 4 results
                        send_buf[0] <= result0_int;
                        send_buf[1] <= result1_int;
                        send_buf[2] <= result2_int;
                        send_buf[3] <= result3_int;
                        sent_flag   <= 1'b1;
                        uart_state  <= 5'd1;
                    end
                    if (show_error_int && !sent_flag) begin
                        sent_flag  <= 1'b1;
                        uart_state <= 5'd20;
                    end
                    // Note: sent_flag only clears on reset, preventing retransmission
                end

                // Send result0
                5'd1: if (!uart_busy) begin
                    uart_byte  <= hex_char(send_buf[0][7:4]);
                    uart_start <= 1'b1;
                    uart_state <= 5'd2;
                end
                5'd2: if (!uart_busy && !uart_start) begin  // Wait for start pulse to be seen
                    uart_byte  <= hex_char(send_buf[0][3:0]);
                    uart_start <= 1'b1;
                    uart_state <= 5'd3;
                end
                5'd3: if (!uart_busy && !uart_start) begin
                    uart_byte  <= 8'h20;
                    uart_start <= 1'b1;
                    uart_state <= 5'd4;
                end

                // Send result1
                5'd4: if (!uart_busy && !uart_start) begin
                    uart_byte  <= hex_char(send_buf[1][7:4]);
                    uart_start <= 1'b1;
                    uart_state <= 5'd5;
                end
                5'd5: if (!uart_busy && !uart_start) begin
                    uart_byte  <= hex_char(send_buf[1][3:0]);
                    uart_start <= 1'b1;
                    uart_state <= 5'd6;
                end
                5'd6: if (!uart_busy && !uart_start) begin
                    uart_byte  <= 8'h20;
                    uart_start <= 1'b1;
                    uart_state <= 5'd7;
                end

                // Send result2
                5'd7: if (!uart_busy && !uart_start) begin
                    uart_byte  <= hex_char(send_buf[2][7:4]);
                    uart_start <= 1'b1;
                    uart_state <= 5'd8;
                end
                5'd8: if (!uart_busy && !uart_start) begin
                    uart_byte  <= hex_char(send_buf[2][3:0]);
                    uart_start <= 1'b1;
                    uart_state <= 5'd9;
                end
                5'd9: if (!uart_busy && !uart_start) begin
                    uart_byte  <= 8'h20;
                    uart_start <= 1'b1;
                    uart_state <= 5'd10;
                end

                // Send result3
                5'd10: if (!uart_busy && !uart_start) begin
                    uart_byte  <= hex_char(send_buf[3][7:4]);
                    uart_start <= 1'b1;
                    uart_state <= 5'd11;
                end
                5'd11: if (!uart_busy && !uart_start) begin
                    uart_byte  <= hex_char(send_buf[3][3:0]);
                    uart_start <= 1'b1;
                    uart_state <= 5'd12;
                end

                // CR LF
                5'd12: if (!uart_busy && !uart_start) begin
                    uart_byte  <= 8'h0D;
                    uart_start <= 1'b1;
                    uart_state <= 5'd13;
                end
                5'd13: if (!uart_busy && !uart_start) begin
                    uart_byte  <= 8'h0A;
                    uart_start <= 1'b1;
                    uart_state <= U_IDLE;
                end

                // ERROR: send "ERR\r\n"
                5'd20: if (!uart_busy) begin
                    uart_byte  <= "E";
                    uart_start <= 1'b1;
                    uart_state <= 5'd21;
                end
                5'd21: if (!uart_busy && !uart_start) begin
                    uart_byte  <= "R";
                    uart_start <= 1'b1;
                    uart_state <= 5'd22;
                end
                5'd22: if (!uart_busy && !uart_start) begin
                    uart_byte  <= "R";
                    uart_start <= 1'b1;
                    uart_state <= 5'd23;
                end
                5'd23: if (!uart_busy && !uart_start) begin
                    uart_byte  <= 8'h0D;
                    uart_start <= 1'b1;
                    uart_state <= 5'd24;
                end
                5'd24: if (!uart_busy && !uart_start) begin
                    uart_byte  <= 8'h0A;
                    uart_start <= 1'b1;
                    uart_state <= U_IDLE;
                end

                default: uart_state <= U_IDLE;
            endcase
        end
    end

endmodule
