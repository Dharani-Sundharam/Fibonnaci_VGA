`timescale 1ns / 1ps

module top_vga (
    input wire clk,
    input wire reset,
    input wire clk_en,
    
    // Display mode inputs
    input wire show_ready,
    input wire show_done,
    input wire show_error,
    input wire show_read1,
    input wire show_read2,
    input wire show_read3,
    
    // Result data (16-bit for large Fibonacci numbers)
    input wire [15:0] result0,
    input wire [15:0] result1,
    input wire [15:0] result2,
    input wire [15:0] result3,
    
    // Current input values
    input wire [7:0] num1,
    input wire [7:0] num2,
    input wire [7:0] num3,
    input wire [7:0] sw_live,
    
    // VGA outputs
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire hsync,
    output wire vsync
);

    // VGA sync
    wire video_on;
    wire [9:0] pixel_x, pixel_y;
    
    vga_sync sync_inst (
        .clk(clk), .reset(reset), .clk_en(clk_en),
        .hsync(hsync), .vsync(vsync),
        .video_on(video_on),
        .pixel_x(pixel_x), .pixel_y(pixel_y)
    );
    
    // Layout constants
    localparam CENTER_Y = 216;
    localparam CHAR_WIDTH = 32;
    localparam DIGIT_SPACING = 34;  // Spacing between digits
    localparam NUM_SPACING = 55;    // Spacing between numbers
    
    // BCD converters
    wire [3:0] sw_h, sw_t, sw_o;
    wire [3:0] n1_h, n1_t, n1_o;
    wire [3:0] n2_h, n2_t, n2_o;
    wire [3:0] n3_h, n3_t, n3_o;
    // 16-bit results need 5 digits: ten_thousands, thousands, hundreds, tens, ones
    wire [3:0] r0_tt, r0_th, r0_h, r0_t, r0_o;
    wire [3:0] r1_tt, r1_th, r1_h, r1_t, r1_o;
    wire [3:0] r2_tt, r2_th, r2_h, r2_t, r2_o;
    wire [3:0] r3_tt, r3_th, r3_h, r3_t, r3_o;
    
    bin2bcd bcd_sw   (.binary(sw_live), .hundreds(sw_h), .tens(sw_t), .ones(sw_o));
    bin2bcd bcd_num1 (.binary(num1),    .hundreds(n1_h), .tens(n1_t), .ones(n1_o));
    bin2bcd bcd_num2 (.binary(num2),    .hundreds(n2_h), .tens(n2_t), .ones(n2_o));
    bin2bcd bcd_num3 (.binary(num3),    .hundreds(n3_h), .tens(n3_t), .ones(n3_o));
    bin2bcd16 bcd_res0 (.binary(result0), .ten_thousands(r0_tt), .thousands(r0_th), .hundreds(r0_h), .tens(r0_t), .ones(r0_o));
    bin2bcd16 bcd_res1 (.binary(result1), .ten_thousands(r1_tt), .thousands(r1_th), .hundreds(r1_h), .tens(r1_t), .ones(r1_o));
    bin2bcd16 bcd_res2 (.binary(result2), .ten_thousands(r2_tt), .thousands(r2_th), .hundreds(r2_h), .tens(r2_t), .ones(r2_o));
    bin2bcd16 bcd_res3 (.binary(result3), .ten_thousands(r3_tt), .thousands(r3_th), .hundreds(r3_h), .tens(r3_t), .ones(r3_o));
    
    // Up to 16 digit slots for displaying numbers
    wire [3:0] dr[0:15], dg[0:15], db[0:15];
    wire dp[0:15];
    reg [7:0] dval[0:15];
    reg [9:0] dx[0:15];
    reg [3:0] dcr[0:15], dcg[0:15], dcb[0:15];  // Colors
    
    // Generate digit renderers
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : digit_gen
            digit_renderer digit_inst (
                .pixel_x(pixel_x), .pixel_y(pixel_y),
                .char_x(dx[i]), .char_y(CENTER_Y),
                .value(dval[i]),
                .color_r(dcr[i]), .color_g(dcg[i]), .color_b(dcb[i]),
                .r(dr[i]), .g(dg[i]), .b(db[i]), .pixel_on(dp[i])
            );
        end
    endgenerate
    
    // Display logic
    integer j;
    always @(*) begin
        // Clear all
        for (j = 0; j < 16; j = j + 1) begin
            dval[j] = 0;
            dx[j] = 0;
            dcr[j] = 0; dcg[j] = 0; dcb[j] = 0;
        end
        
        if (show_ready) begin
            // "READY" in Blue (0,0,F)
            dval[0] = 8'h52; dx[0] = 224; dcr[0] = 0; dcg[0] = 0; dcb[0] = 15;
            dval[1] = 8'h45; dx[1] = 264; dcr[1] = 0; dcg[1] = 0; dcb[1] = 15;
            dval[2] = 8'h41; dx[2] = 304; dcr[2] = 0; dcg[2] = 0; dcb[2] = 15;
            dval[3] = 8'h44; dx[3] = 344; dcr[3] = 0; dcg[3] = 0; dcb[3] = 15;
            dval[4] = 8'h59; dx[4] = 384; dcr[4] = 0; dcg[4] = 0; dcb[4] = 15;
        end
        else if (show_error) begin
            // "ERROR" in Red (F,0,0)
            dval[0] = 8'h45; dx[0] = 224; dcr[0] = 15; dcg[0] = 0; dcb[0] = 0;
            dval[1] = 8'h52; dx[1] = 264; dcr[1] = 15; dcg[1] = 0; dcb[1] = 0;
            dval[2] = 8'h52; dx[2] = 304; dcr[2] = 15; dcg[2] = 0; dcb[2] = 0;
            dval[3] = 8'h4F; dx[3] = 344; dcr[3] = 15; dcg[3] = 0; dcb[3] = 0;
            dval[4] = 8'h52; dx[4] = 384; dcr[4] = 15; dcg[4] = 0; dcb[4] = 0;
        end
        else if (show_read1) begin
            // Display sw_live in Green (0,F,0) - centered 3 digits
            dval[0] = sw_h; dx[0] = 270; dcr[0] = 0; dcg[0] = 15; dcb[0] = 0;
            dval[1] = sw_t; dx[1] = 304; dcr[1] = 0; dcg[1] = 15; dcb[1] = 0;
            dval[2] = sw_o; dx[2] = 338; dcr[2] = 0; dcg[2] = 15; dcb[2] = 0;
        end
        else if (show_read2) begin
            // num1 (Green) + sw_live (Cyan 0,F,F)
            dval[0] = n1_h; dx[0] = 200; dcr[0] = 0; dcg[0] = 15; dcb[0] = 0;
            dval[1] = n1_t; dx[1] = 234; dcr[1] = 0; dcg[1] = 15; dcb[1] = 0;
            dval[2] = n1_o; dx[2] = 268; dcr[2] = 0; dcg[2] = 15; dcb[2] = 0;
            
            dval[3] = sw_h; dx[3] = 323; dcr[3] = 0; dcg[3] = 15; dcb[3] = 15;
            dval[4] = sw_t; dx[4] = 357; dcr[4] = 0; dcg[4] = 15; dcb[4] = 15;
            dval[5] = sw_o; dx[5] = 391; dcr[5] = 0; dcg[5] = 15; dcb[5] = 15;
        end
        else if (show_read3) begin
            // num1 (Green), num2 (Cyan), sw_live (Yellow F,F,0)
            dval[0] = n1_h; dx[0] = 150; dcr[0] = 0; dcg[0] = 15; dcb[0] = 0;
            dval[1] = n1_t; dx[1] = 184; dcr[1] = 0; dcg[1] = 15; dcb[1] = 0;
            dval[2] = n1_o; dx[2] = 218; dcr[2] = 0; dcg[2] = 15; dcb[2] = 0;
            
            dval[3] = n2_h; dx[3] = 268; dcr[3] = 0; dcg[3] = 15; dcb[3] = 15;
            dval[4] = n2_t; dx[4] = 302; dcr[4] = 0; dcg[4] = 15; dcb[4] = 15;
            dval[5] = n2_o; dx[5] = 336; dcr[5] = 0; dcg[5] = 15; dcb[5] = 15;
            
            dval[6] = sw_h; dx[6] = 386; dcr[6] = 15; dcg[6] = 15; dcb[6] = 0;
            dval[7] = sw_t; dx[7] = 420; dcr[7] = 15; dcg[7] = 15; dcb[7] = 0;
            dval[8] = sw_o; dx[8] = 454; dcr[8] = 15; dcg[8] = 15; dcb[8] = 0;
        end
        else if (show_done) begin
            // 4 result numbers in White (F,F,F) - 5 digits each
            dval[0] = r0_tt; dx[0] = 50;  dcr[0] = 15; dcg[0] = 15; dcb[0] = 15;
            dval[1] = r0_th; dx[1] = 84;  dcr[1] = 15; dcg[1] = 15; dcb[1] = 15;
            dval[2] = r0_h;  dx[2] = 118; dcr[2] = 15; dcg[2] = 15; dcb[2] = 15;
            dval[3] = r0_t;  dx[3] = 152; dcr[3] = 15; dcg[3] = 15; dcb[3] = 15;
            dval[4] = r0_o;  dx[4] = 186; dcr[4] = 15; dcg[4] = 15; dcb[4] = 15;
            
            dval[5] = r1_tt; dx[5] = 231; dcr[5] = 15; dcg[5] = 15; dcb[5] = 15;
            dval[6] = r1_th; dx[6] = 265; dcr[6] = 15; dcg[6] = 15; dcb[6] = 15;
            dval[7] = r1_h;  dx[7] = 299; dcr[7] = 15; dcg[7] = 15; dcb[7] = 15;
            dval[8] = r1_t;  dx[8] = 333; dcr[8] = 15; dcg[8] = 15; dcb[8] = 15;
            dval[9] = r1_o;  dx[9] = 367; dcr[9] = 15; dcg[9] = 15; dcb[9] = 15;
            
            dval[10] = r2_tt; dx[10] = 412; dcr[10] = 15; dcg[10] = 15; dcb[10] = 15;
            dval[11] = r2_th; dx[11] = 446; dcr[11] = 15; dcg[11] = 15; dcb[11] = 15;
            dval[12] = r2_h;  dx[12] = 480; dcr[12] = 15; dcg[12] = 15; dcb[12] = 15;
            dval[13] = r2_t;  dx[13] = 514; dcr[13] = 15; dcg[13] = 15; dcb[13] = 15;
            dval[14] = r2_o;  dx[14] = 548; dcr[14] = 15; dcg[14] = 15; dcb[14] = 15;
            
            // Result 3 would go off screen, so we skip it or use smaller font
            // For now, display it partially or reduce spacing
        end
    end
    
    // Combine outputs
    reg [3:0] final_r, final_g, final_b;
    always @(*) begin
        final_r = 0; final_g = 0; final_b = 0;
        for (j = 0; j < 16; j = j + 1) begin
            if (dp[j]) begin
                final_r = dr[j];
                final_g = dg[j];
                final_b = db[j];
            end
        end
    end
    
    assign vga_r = video_on ? final_r : 4'h0;
    assign vga_g = video_on ? final_g : 4'h0;
    assign vga_b = video_on ? final_b : 4'h0;

endmodule
