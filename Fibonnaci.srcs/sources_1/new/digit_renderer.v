`timescale 1ns / 1ps
//============================================================================
// Module:  digit_renderer
// Purpose: Render a single BCD digit (0-9) using 7-segment display logic
//          No font ROM - pure combinational logic
//============================================================================

module digit_renderer (
    input  wire [3:0] digit,       // BCD digit (0-9)
    input  wire [9:0] offset_x,    // Top-left X position
    input  wire [9:0] offset_y,    // Top-left Y position
    input  wire [9:0] pixel_x,     // Current pixel X
    input  wire [9:0] pixel_y,     // Current pixel Y
    output wire       pixel_on     // HIGH if pixel is part of digit
);

    // Digit dimensions: 60 pixels wide × 100 pixels tall
    localparam DIGIT_WIDTH  = 60;
    localparam DIGIT_HEIGHT = 100;
    
    // Calculate relative position within digit box
    wire signed [10:0] rel_x = pixel_x - offset_x;
    wire signed [10:0] rel_y = pixel_y - offset_y;
    
    // Check if pixel is within digit bounds
    wire in_bounds = (rel_x >= 0) && (rel_x < DIGIT_WIDTH) &&
                     (rel_y >= 0) && (rel_y < DIGIT_HEIGHT);
    
    // 7-Segment decoder: BCD → segment enable bits [a,b,c,d,e,f,g]
    //     AAA
    //    F   B
    //     GGG
    //    E   C
    //     DDD
    
    // Extended to support letters: 10=E, 11=R, 12=D, 13=Y
    
    reg [6:0] segments;  // {a,b,c,d,e,f,g}
    
    always @(*) begin
        case (digit)
            4'd0: segments = 7'b1111110;  // 0: a,b,c,d,e,f
            4'd1: segments = 7'b0110000;  // 1: b,c
            4'd2: segments = 7'b1101101;  // 2: a,b,d,e,g
            4'd3: segments = 7'b1111001;  // 3: a,b,c,d,g
            4'd4: segments = 7'b0110011;  // 4: b,c,f,g
            4'd5: segments = 7'b1011011;  // 5: a,c,d,f,g
            4'd6: segments = 7'b1011111;  // 6: a,c,d,e,f,g
            4'd7: segments = 7'b1110000;  // 7: a,b,c
            4'd8: segments = 7'b1111111;  // 8: all segments
            4'd9: segments = 7'b1111011;  // 9: a,b,c,d,f,g
            4'd10: segments = 7'b1001111; // E: a,d,e,f,g
            4'd11: segments = 7'b0000101; // R: e,f (simplified)
            4'd12: segments = 7'b0111101; // D: b,c,d,e,g (simplified)
            4'd13: segments = 7'b0111011; // Y: b,c,d,f,g
            default: segments = 7'b0000000;  // Blank for invalid
        endcase
    end
    
    // Segment geometry definitions (within 60×100 box)
    // Segment A: Horizontal top
    wire seg_a_on = segments[6] && 
                    (rel_x >= 10 && rel_x < 50) && 
                    (rel_y >= 0  && rel_y < 10);
    
    // Segment B: Vertical right-top
    wire seg_b_on = segments[5] && 
                    (rel_x >= 50 && rel_x < 60) && 
                    (rel_y >= 10 && rel_y < 45);
    
    // Segment C: Vertical right-bottom
    wire seg_c_on = segments[4] && 
                    (rel_x >= 50 && rel_x < 60) && 
                    (rel_y >= 55 && rel_y < 90);
    
    // Segment D: Horizontal bottom
    wire seg_d_on = segments[3] && 
                    (rel_x >= 10 && rel_x < 50 ) && 
                    (rel_y >= 90 && rel_y < 100);
    
    // Segment E: Vertical left-bottom
    wire seg_e_on = segments[2] && 
                    (rel_x >= 0  && rel_x < 10) && 
                    (rel_y >= 55 && rel_y < 90);
    
    // Segment F: Vertical left-top
    wire seg_f_on = segments[1] && 
                    (rel_x >= 0  && rel_x < 10) && 
                    (rel_y >= 10 && rel_y < 45);
    
    // Segment G: Horizontal middle
    wire seg_g_on = segments[0] && 
                    (rel_x >= 10 && rel_x < 50) && 
                    (rel_y >= 45 && rel_y < 55);
    
    // Combine all segments
    wire any_segment = seg_a_on | seg_b_on | seg_c_on | seg_d_on | 
                       seg_e_on | seg_f_on | seg_g_on;
    
    assign pixel_on = in_bounds && any_segment;

endmodule
