`timescale 1ns / 1ps

module fibonacci_datapath (
    input wire clk,
    input wire reset,
    
    // Control signals from FSM
    input wire load_num1,
    input wire load_num2,
    input wire load_num3,
    input wire init_gen,
    input wire step_gen,
    
    // Data inputs
    input wire [7:0] sw_data,
    
    // Outputs to FSM
    output wire valid,
    output wire gen_done,
    
    // Outputs to VGA (16-bit for large Fibonacci numbers)
    output reg [15:0] result0,
    output reg [15:0] result1,
    output reg [15:0] result2,
    output reg [15:0] result3,
    
    // Expose entered numbers for VGA display
    output wire [7:0] num1_out,
    output wire [7:0] num2_out,
    output wire [7:0] num3_out
);

    // Storage registers
    reg [7:0] num1, num2, num3;
    reg [15:0] gen_a, gen_b;  // 16-bit for Fibonacci generation
    reg [2:0] gen_count;
    
    // Validation logic
    assign valid = (num1 + num2 == num3);
    
    // Expose inputs for VGA display
    assign num1_out = num1;
    assign num2_out = num2;
    assign num3_out = num3;
    assign gen_done = (gen_count >= 4);
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            num1 <= 0;
            num2 <= 0;
            num3 <= 0;
            gen_a <= 0;
            gen_b <= 0;
            gen_count <= 0;
            result0 <= 0;
            result1 <= 0;
            result2 <= 0;
            result3 <= 0;
        end else begin
            // Load user inputs
            if (load_num1) num1 <= sw_data;
            if (load_num2) num2 <= sw_data;
            if (load_num3) num3 <= sw_data;
            
            // Initialize generation
            if (init_gen) begin
                gen_a <= num2;
                gen_b <= num3;
                gen_count <= 0;
                result0 <= 0;
                result1 <= 0;
                result2 <= 0;
                result3 <= 0;
            end
            
            // Step generation
            if (step_gen && !gen_done) begin
                case (gen_count)
                    0: result0 <= gen_a + gen_b;
                    1: result1 <= gen_a + gen_b;
                    2: result2 <= gen_a + gen_b;
                    3: result3 <= gen_a + gen_b;
                endcase
                gen_a <= gen_b;
                gen_b <= gen_a + gen_b;
                gen_count <= gen_count + 1;
            end
        end
    end

endmodule
