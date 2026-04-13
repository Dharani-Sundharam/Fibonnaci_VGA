`timescale 1ns / 1ps

// Binary to BCD converter for 8-bit values (0-255)
// Outputs 3 BCD digits: hundreds, tens, ones
module bin2bcd (
    input wire [7:0] binary,
    output reg [3:0] hundreds,
    output reg [3:0] tens,
    output reg [3:0] ones
);

    integer i;
    reg [19:0] shift_reg;
    
    always @(*) begin
        shift_reg = {12'b0, binary};
        
        // Double-dabble algorithm
        for (i = 0; i < 8; i = i + 1) begin
            // Check and add 3 to BCD digits >= 5
            if (shift_reg[11:8] >= 5)   shift_reg[11:8] = shift_reg[11:8] + 3;
            if (shift_reg[15:12] >= 5)  shift_reg[15:12] = shift_reg[15:12] + 3;
            if (shift_reg[19:16] >= 5)  shift_reg[19:16] = shift_reg[19:16] + 3;
            
            // Shift left
            shift_reg = shift_reg << 1;
        end
        
        hundreds = shift_reg[19:16];
        tens = shift_reg[15:12];
        ones = shift_reg[11:8];
    end

endmodule
