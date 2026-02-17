`timescale 1ns / 1ps

module fibonacci_fsm (
    input wire clk,
    input wire reset,
    input wire btn_enter,
    
    // From datapath
    input wire valid,
    input wire gen_done,
    
    // Control outputs to datapath
    output reg load_num1,
    output reg load_num2,
    output reg load_num3,
    output reg init_gen,
    output reg step_gen,
    
    // Display control outputs
    output reg show_ready,
    output reg show_done,
    output reg show_error,
    output reg show_read1,
    output reg show_read2,
    output reg show_read3,
    output reg [1:0] progress_leds
);

    // State encoding
    localparam IDLE     = 4'd0;
    localparam READ_1   = 4'd1;
    localparam READ_2   = 4'd2;
    localparam READ_3     = 4'd3;
    localparam LATCH_3    = 4'd4;  // Load num3
    localparam WAIT_VALID = 4'd5;  // Wait one cycle for num3 to settle
    localparam VALIDATE   = 4'd6;  // Check validity
    localparam GENERATE   = 4'd7;
    localparam ERROR      = 4'd8;
    localparam DONE       = 4'd9;
    
    reg [3:0] state, next_state;
    reg [26:0] gen_timer;
    
    // State register
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (btn_enter) next_state = READ_1;
            
            READ_1: if (btn_enter) next_state = READ_2;
            
            READ_2: if (btn_enter) next_state = READ_3;
            
            READ_3: if (btn_enter) next_state = LATCH_3;

            LATCH_3: next_state = WAIT_VALID;
            
            WAIT_VALID: next_state = VALIDATE;
            
            VALIDATE: next_state = valid ? GENERATE : ERROR;
            
            GENERATE: if (gen_done) next_state = DONE;
            
            ERROR: if (btn_enter) next_state = IDLE;
            
            DONE: if (btn_enter) next_state = IDLE;
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic (Moore machine)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // ... (reset logic unchanged)
        end else begin
            // Default: clear pulses
            load_num1 <= 0;
            load_num2 <= 0;
            load_num3 <= 0;
            init_gen <= 0;
            step_gen <= 0;
            
            case (state)
                IDLE: begin
                    show_ready <= 1;
                    show_done <= 0;
                    show_error <= 0;
                    show_read1 <= 0;
                    show_read2 <= 0;
                    show_read3 <= 0;
                    progress_leds <= 0;
                    gen_timer <= 0;
                end
                
                READ_1: begin
                    show_ready <= 0;
                    show_read1 <= 1;
                    show_read2 <= 0;
                    show_read3 <= 0;
                    progress_leds <= 2'b01;
                    if (btn_enter) load_num1 <= 1;
                end
                
                READ_2: begin
                    show_read1 <= 0;
                    show_read2 <= 1;
                    show_read3 <= 0;
                    progress_leds <= 2'b10;
                    if (btn_enter) load_num2 <= 1;
                end
                
                READ_3: begin
                    show_read1 <= 0;
                    show_read2 <= 0;
                    show_read3 <= 1;
                    progress_leds <= 2'b11;
                    // Move load_num3 to LATCH_3 for safety or keep here?
                    // If we keep here, it latches at end of READ_3
                    // But READ_3 transitions on btn_enter. 
                    // Let's do it in LATCH_3 state to be 100% sure.
                end

                LATCH_3: begin
                    show_read3 <= 1; // Keep showing input
                    load_num3 <= 1;
                end
                
                WAIT_VALID: begin
                    show_read3 <= 1; // Keep showing input while waiting
                end
                
                VALIDATE: begin
                    show_read1 <= 0;
                    show_read2 <= 0;
                    show_read3 <= 0;
                    init_gen <= 1;
                end
                
                GENERATE: begin
                    // Generate at ~10Hz for visibility
                    if (gen_timer < 10_000_000) begin
                        gen_timer <= gen_timer + 1;
                    end else begin
                        gen_timer <= 0;
                        step_gen <= 1;
                    end
                end
                
                ERROR: begin
                    show_error <= 1;
                    show_ready <= 0;
                end
                
                DONE: begin
                    show_done <= 1;
                    show_ready <= 0;
                end
            endcase
        end
    end

endmodule
