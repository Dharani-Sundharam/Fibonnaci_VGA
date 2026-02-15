`timescale 1ns / 1ps
//============================================================================
// Module:  fibonacci_datapath
// Purpose: Registers, adders, comparator for the Fibonacci Validator & Gen.
//
// Stores 3 user-entered numbers, validates them, generates next 4,
// and buffers all 4 generated values for UART output.
//============================================================================

module fibonacci_datapath (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  sw_data,      // Switch value

    // Control from FSM
    input  wire        load_num1,
    input  wire        load_num2,
    input  wire        load_num3,
    input  wire        init_gen,
    input  wire        step_gen,

    // Status to FSM
    output wire        valid,
    output reg         overflow,      // Overflow flag
    output wire [2:0]  gen_count,

    // Data outputs
    output wire [7:0]  gen_out,       // Current generated value (LEDs)
    output wire [7:0]  result0,       // All 4 generated values (UART)
    output wire [7:0]  result1,
    output wire [7:0]  result2,
    output wire [7:0]  result3
);

    // === Input registers ===
    reg [7:0] num1, num2, num3;

    always @(posedge clk) begin
        if (rst) begin
            num1 <= 8'd0;
            num2 <= 8'd0;
            num3 <= 8'd0;
        end else begin
            if (load_num1) num1 <= sw_data;
            if (load_num2) num2 <= sw_data;
            if (load_num3) num3 <= sw_data;
        end
    end

    // === Validator (combinational) ===
    assign valid = (num1 + num2 == num3);

    // === Generator ===
    reg [7:0] gen_a, gen_b, gen_result;
    reg [2:0] gen_cnt;

    // Buffer to store all 4 generated values
    reg [7:0] gen_buf [0:3];

    always @(posedge clk) begin
        if (rst) begin
            gen_a      <= 8'd0;
            gen_b      <= 8'd0;
            gen_result <= 8'd0;
            gen_cnt    <= 3'd0;
        end else if (init_gen) begin
            gen_a      <= num2;
            gen_b      <= num3;
            gen_result <= 8'd0;
            gen_cnt    <= 3'd0;
        end else if (step_gen) begin
            // Detect overflow (9-bit addition)
            if ((gen_a + gen_b) > 8'd255) begin
                overflow <= 1'b1;
                gen_result <= 8'd255;  // Clamp to max
                gen_buf[gen_cnt] <= 8'd255;
                gen_a <= gen_b;
                gen_b <= 8'd255;
            end else begin
                overflow <= 1'b0;
                gen_result <= gen_a + gen_b;
                gen_buf[gen_cnt] <= gen_a + gen_b;
                gen_a <= gen_b;
                gen_b <= gen_a + gen_b;
            end
            gen_cnt <= gen_cnt + 1;
        end
    end

    assign gen_out   = gen_result;
    assign gen_count = gen_cnt;
    assign result0   = gen_buf[0];
    assign result1   = gen_buf[1];
    assign result2   = gen_buf[2];
    assign result3   = gen_buf[3];

endmodule
