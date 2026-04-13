`timescale 1ns / 1ps

module digit_renderer (
    input wire [9:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [9:0] char_x,
    input wire [9:0] char_y,
    input wire [7:0] value,
    input wire [3:0] color_r,  // Color input
    input wire [3:0] color_g,
    input wire [3:0] color_b,
    output reg [3:0] r,
    output reg [3:0] g,
    output reg [3:0] b,
    output reg pixel_on
);

    // 2x Scaled Dimensions
    localparam CHAR_WIDTH = 32;
    localparam CHAR_HEIGHT = 48;
    
    // Check bounds
    wire in_char = (pixel_x >= char_x) && (pixel_x < char_x + CHAR_WIDTH) &&
                   (pixel_y >= char_y) && (pixel_y < char_y + CHAR_HEIGHT);

    // Map coordinates to 16x24 grid
    wire [5:0] raw_dx = pixel_x - char_x;
    wire [5:0] raw_dy = pixel_y - char_y;
    wire [4:0] rel_x = raw_dx[5:1];
    wire [4:0] rel_y = raw_dy[5:1];
    
    // Segment Patterns
    reg [6:0] segments;
    always @(*) begin
        case (value)
            8'd0: segments = 7'b0111111;
            8'd1: segments = 7'b0000110;
            8'd2: segments = 7'b1011011;
            8'd3: segments = 7'b1001111;
            8'd4: segments = 7'b1100110;
            8'd5: segments = 7'b1101101;
            8'd6: segments = 7'b1111101;
            8'd7: segments = 7'b0000111;
            8'd8: segments = 7'b1111111;
            8'd9: segments = 7'b1101111;
            // Letters
            8'h41: segments = 7'b1110111; // 'A'
            8'h44: segments = 7'b0111111; // 'D'
            8'h45: segments = 7'b1111001; // 'E'
            8'h4F: segments = 7'b0111111; // 'O'
            8'h52: segments = 7'b1110011; // 'R'
            8'h59: segments = 7'b0000000; // 'Y'
            default: segments = 7'b0000000;
        endcase
    end
    
    // Segments
    wire seg_a = (rel_y < 3)                 && (rel_x >= 3 && rel_x < 13);
    wire seg_f = (rel_y >= 3 && rel_y < 11)  && (rel_x >= 3 && rel_x < 6);
    wire seg_b = (rel_y >= 3 && rel_y < 11)  && (rel_x >= 10 && rel_x < 13);
    wire seg_g = (rel_y >= 11 && rel_y < 14) && (rel_x >= 3 && rel_x < 13);
    wire seg_e = (rel_y >= 13 && rel_y < 21) && (rel_x >= 3 && rel_x < 6);
    wire seg_c = (rel_y >= 13 && rel_y < 21) && (rel_x >= 10 && rel_x < 13);
    wire seg_d = (rel_y >= 21)               && (rel_x >= 3 && rel_x < 13);
    
    // Custom 'R' leg
    wire r_leg = (value == 8'h52) && (
        (rel_x >= 7 && rel_x <= 8 && rel_y >= 14 && rel_y <= 16) ||
        (rel_x >= 9 && rel_x <= 10 && rel_y >= 17 && rel_y <= 19) ||
        (rel_x >= 11 && rel_x <= 12 && rel_y >= 20 && rel_y <= 23)
    );

    // Custom 'Y'
    wire y_custom = (value == 8'h59) && (
        (rel_x >= 3 && rel_x < 6 && rel_y < 11) ||
        (rel_x >= 10 && rel_x < 13 && rel_y < 11) ||
        (rel_x >= 5 && rel_x < 11 && rel_y >= 11 && rel_y < 14) ||
        (rel_x >= 7 && rel_x < 10 && rel_y >= 14 && rel_y < 24)
    );

    wire segment_on = (
        (seg_a && segments[0]) ||
        (seg_b && segments[1]) ||
        (seg_c && segments[2]) ||
        (seg_d && segments[3]) ||
        (seg_e && segments[4]) ||
        (seg_f && segments[5]) ||
        (seg_g && segments[6]) ||
        r_leg || 
        y_custom
    );
    
    always @(*) begin
        if (in_char && segment_on) begin
            r = color_r;
            g = color_g;
            b = color_b;
            pixel_on = 1;
        end else begin
            r = 0; g = 0; b = 0; pixel_on = 0;
        end
    end

endmodule
