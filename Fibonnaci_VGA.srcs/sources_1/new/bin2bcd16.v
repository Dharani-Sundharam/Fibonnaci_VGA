`timescale 1ns / 1ps

// Binary to BCD converter for 16-bit values (0-65535)
// Outputs 5 BCD digits: ten_thousands, thousands, hundreds, tens, ones
module bin2bcd16 (
    input wire [15:0] binary,
    output reg [3:0] ten_thousands,
    output reg [3:0] thousands,
    output reg [3:0] hundreds,
    output reg [3:0] tens,
    output reg [3:0] ones
);

    integer i;
    reg [35:0] shift_reg;
    
    always @(*) begin
        shift_reg = {20'b0, binary};
        
        // Double-dabble algorithm for 16-bit
        for (i = 0; i < 16; i = i + 1) begin
            // Check and add 3 to BCD digits >= 5
            if (shift_reg[19:16] >= 5)  shift_reg[19:16] = shift_reg[19:16] + 3;
            if (shift_reg[23:20] >= 5)  shift_reg[23:20] = shift_reg[23:20] + 3;
            if (shift_reg[27:24] >= 5)  shift_reg[27:24] = shift_reg[27:24] + 3;
            if (shift_reg[31:28] >= 5)  shift_reg[31:28] = shift_reg[31:28] + 3;
            if (shift_reg[35:32] >= 5)  shift_reg[35:32] = shift_reg[35:32] + 3;
            
            // Shift left
            shift_reg = shift_reg << 1;
        end
        
        ten_thousands = shift_reg[35:32];
        thousands = shift_reg[31:28];
        hundreds = shift_reg[27:24];
        tens = shift_reg[23:20];
        ones = shift_reg[19:16];
    end

endmodule
