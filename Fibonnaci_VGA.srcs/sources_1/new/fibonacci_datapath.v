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
    output wire gen_overflow,
    
    // Expose entered numbers for VGA display
    output wire [7:0] num1_out,
    output wire [7:0] num2_out,
    output wire [7:0] num3_out,
    
    // Value memory read port (for VGA)
    input wire [5:0] read_addr,
    output wire [15:0] read_data,
    output wire [6:0] value_count
);

    // Storage registers
    reg [7:0] num1, num2, num3;
    reg [15:0] gen_a, gen_b;
    reg [6:0] count;  // 0-64
    
    // Value memory: 64 slots x 16 bits
    reg [15:0] values [0:63];
    
    // Overflow detection
    wire [16:0] next_sum = {1'b0, gen_a} + {1'b0, gen_b};
    assign gen_overflow = next_sum[16];  // Overflow if bit 16 set
    
    // Validation logic
    assign valid = (num1 + num2 == num3);
    
    // Expose signals
    assign num1_out = num1;
    assign num2_out = num2;
    assign num3_out = num3;
    assign read_data = values[read_addr];
    assign value_count = count;
    
    integer i;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            num1 <= 0;
            num2 <= 0;
            num3 <= 0;
            gen_a <= 0;
            gen_b <= 0;
            count <= 0;
        end else begin
            // Load user inputs
            if (load_num1) num1 <= sw_data;
            if (load_num2) num2 <= sw_data;
            if (load_num3) num3 <= sw_data;
            
            // Initialize: store seed values
            if (init_gen) begin
                values[0] <= {8'b0, num1};
                values[1] <= {8'b0, num2};
                values[2] <= {8'b0, num3};
                gen_a <= {8'b0, num2};
                gen_b <= {8'b0, num3};
                count <= 3;
            end
            
            // Step generation: compute next Fibonacci value
            if (step_gen && !gen_overflow && count < 64) begin
                values[count] <= next_sum[15:0];
                gen_a <= gen_b;
                gen_b <= next_sum[15:0];
                count <= count + 1;
            end
        end
    end

endmodule
