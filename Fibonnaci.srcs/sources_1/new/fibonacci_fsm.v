`timescale 1ns / 1ps
//============================================================================
// Module:  fibonacci_fsm
// Purpose: Moore FSM — IDLE → READ → VALIDATE → GENERATE/ERROR → DONE
//
// 3 button presses enter 3 numbers. System auto-validates and generates.
//============================================================================

module fibonacci_fsm (
    input  wire       clk,
    input  wire       rst,
    input  wire       enter,

    // From datapath
    input  wire       valid,
    input  wire [2:0] gen_count,

    // To datapath
    output reg        load_num1,
    output reg        load_num2,
    output reg        load_num3,
    output reg        init_gen,
    output reg        step_gen,

    // Display & UART control
    output reg        breathing_en,
    output reg [2:0]  read_phase,
    output reg        show_gen,
    output reg        show_error,
    output reg        show_done,
    output reg        uart_send_results  // Trigger UART to send all 4 values
);

    localparam [3:0]
        S_IDLE     = 4'd0,
        S_READ_1   = 4'd1,
        S_READ_2   = 4'd2,
        S_VALIDATE = 4'd3,
        S_GEN_INIT = 4'd4,
        S_GENERATE = 4'd5,
        S_DONE     = 4'd6,
        S_ERROR    = 4'd7;

    reg [3:0] state, next_state;

    always @(posedge clk) begin
        if (rst) state <= S_IDLE;
        else     state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:     if (enter) next_state = S_READ_1;
            S_READ_1:   if (enter) next_state = S_READ_2;
            S_READ_2:   if (enter) next_state = S_VALIDATE;
            S_VALIDATE: next_state = valid ? S_GEN_INIT : S_ERROR;
            S_GEN_INIT: next_state = S_GENERATE;
            S_GENERATE: if (gen_count == 3'd3) next_state = S_DONE;
            S_DONE:     if (enter) next_state = S_IDLE;
            S_ERROR:    if (enter) next_state = S_IDLE;
            default:    next_state = S_IDLE;
        endcase
    end

    always @(*) begin
        load_num1        = 1'b0;
        load_num2        = 1'b0;
        load_num3        = 1'b0;
        init_gen         = 1'b0;
        step_gen         = 1'b0;
        breathing_en     = 1'b0;
        read_phase       = 3'd0;
        show_gen         = 1'b0;
        show_error       = 1'b0;
        show_done        = 1'b0;
        uart_send_results = 1'b0;

        case (state)
            S_IDLE: begin
                breathing_en = 1'b1;
                load_num1    = enter;
            end
            S_READ_1: begin
                read_phase = 3'd1;
                load_num2  = enter;
            end
            S_READ_2: begin
                read_phase = 3'd2;
                load_num3  = enter;
            end
            S_VALIDATE: begin
                read_phase = 3'd3;
            end
            S_GEN_INIT: begin
                init_gen = 1'b1;
            end
            S_GENERATE: begin
                step_gen = 1'b1;
                show_gen = 1'b1;
            end
            S_DONE: begin
                show_done         = 1'b1;
                show_gen          = 1'b1;
                uart_send_results = 1'b1;   // Trigger UART in DONE state
            end
            S_ERROR: begin
                show_error = 1'b1;
            end
        endcase
    end

endmodule
