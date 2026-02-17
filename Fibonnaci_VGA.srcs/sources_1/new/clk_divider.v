`timescale 1ns / 1ps

module clk_divider (
    input wire clk,          // 100MHz input
    input wire reset,
    output reg clk_25mhz_en  // 25MHz enable output
);

    reg [1:0] counter;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_25mhz_en <= 0;
        end else begin
            if (counter == 3) begin
                counter <= 0;
                clk_25mhz_en <= 1;
            end else begin
                counter <= counter + 1;
                clk_25mhz_en <= 0;
            end
        end
    end

endmodule
