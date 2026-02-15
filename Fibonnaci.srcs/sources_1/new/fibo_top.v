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
    output wire       uart_txd
);

    // === Internal wires ===
    wire enter_pulse, rst;
    wire load_num1, load_num2, load_num3;
    wire init_gen, step_gen;
    wire valid;
    wire [2:0] gen_count;
    wire [7:0] gen_out;
    wire [7:0] result0, result1, result2, result3;
    wire breathing_en;
    wire [2:0] read_phase;
    wire show_gen, show_error, show_done;
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
        .clk(clk), .rst(rst), .enable(breathing_en), .led_out(breathing_led)
    );

    // === Datapath ===
    fibonacci_datapath u_dp (
        .clk(clk), .rst(rst),
        .sw_data({1'b0, sw[6:0]}),
        .load_num1(load_num1), .load_num2(load_num2), .load_num3(load_num3),
        .init_gen(init_gen), .step_gen(step_gen),
        .valid(valid), .gen_count(gen_count), .gen_out(gen_out),
        .result0(result0), .result1(result1),
        .result2(result2), .result3(result3)
    );

    // === FSM ===
    fibonacci_fsm u_fsm (
        .clk(clk), .rst(rst), .enter(enter_pulse),
        .valid(valid), .gen_count(gen_count),
        .load_num1(load_num1), .load_num2(load_num2), .load_num3(load_num3),
        .init_gen(init_gen), .step_gen(step_gen),
        .breathing_en(breathing_en), .read_phase(read_phase),
        .show_gen(show_gen), .show_error(show_error), .show_done(show_done),
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
        if (show_error)
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
        end else if (breathing_en)
            led_reg = {breathing_led, 7'b0};
        else
            led_reg = 8'b0;
    end

    assign led = led_reg;

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

    uart_tx u_uart (
        .clk(clk), .rst(rst),
        .tx_data(uart_byte), .tx_start(uart_start),
        .tx_out(uart_txd), .tx_busy(uart_busy)
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
                        send_buf[0] <= result0;
                        send_buf[1] <= result1;
                        send_buf[2] <= result2;
                        send_buf[3] <= result3;
                        sent_flag   <= 1'b1;
                        uart_state  <= 5'd1;
                    end
                    if (show_error && !sent_flag) begin
                        sent_flag  <= 1'b1;
                        uart_state <= 5'd20;
                    end
                    if (breathing_en)
                        sent_flag <= 1'b0;
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
