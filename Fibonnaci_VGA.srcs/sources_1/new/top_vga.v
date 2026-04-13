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
    input wire show_generating,
    
    // Value memory interface (from datapath)
    input wire [6:0] value_count,
    input wire [15:0] read_data,
    output wire [5:0] read_addr,
    
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
    
    // =============================================
    // GRID MODE: Scrolling display of all values
    // 4 columns x 10 rows, 160px x 48px per cell
    // =============================================
    
    // Grid position from pixel coordinates
    wire [1:0] grid_col = (pixel_x >= 480) ? 2'd3 :
                           (pixel_x >= 320) ? 2'd2 :
                           (pixel_x >= 160) ? 2'd1 : 2'd0;

    wire [9:0] col_base = (grid_col == 2'd3) ? 10'd480 :
                           (grid_col == 2'd2) ? 10'd320 :
                           (grid_col == 2'd1) ? 10'd160 : 10'd0;
    wire [9:0] cell_x = pixel_x - col_base;
    
    // Row layout: 64px per row (48px char + 16px gap), 7 rows fit in 448px
    wire [3:0] grid_row = (pixel_y >= 384) ? 4'd6 :
                           (pixel_y >= 320) ? 4'd5 :
                           (pixel_y >= 256) ? 4'd4 :
                           (pixel_y >= 192) ? 4'd3 :
                           (pixel_y >= 128) ? 4'd2 :
                           (pixel_y >= 64)  ? 4'd1 : 4'd0;

    wire [9:0] row_base = (grid_row == 4'd6) ? 10'd384 :
                           (grid_row == 4'd5) ? 10'd320 :
                           (grid_row == 4'd4) ? 10'd256 :
                           (grid_row == 4'd3) ? 10'd192 :
                           (grid_row == 4'd2) ? 10'd128 :
                           (grid_row == 4'd1) ? 10'd64  : 10'd0;
    wire [9:0] cell_y = pixel_y - row_base;
    
    // Pixel is in the 16px gap between rows (not in character area)
    wire in_row_gap = (cell_y >= 48);
    
    // Scrolling offset: 4 cols x 7 rows = 28 visible
    wire [6:0] visible_start = (value_count > 28) ? (value_count - 7'd28) : 7'd0;
    
    // Value index for current cell
    wire [6:0] val_idx = visible_start + {1'b0, grid_row[2:0], grid_col};
    
    // Read address to datapath memory
    assign read_addr = val_idx[5:0];
    
    // Check if this cell has a valid value
    wire cell_valid = (val_idx < value_count) && (val_idx < 64);
    
    // BCD conversion of current cell's value
    wire [3:0] bcd_tt, bcd_th, bcd_h, bcd_t, bcd_o;
    bin2bcd16 grid_bcd (
        .binary(read_data),
        .ten_thousands(bcd_tt),
        .thousands(bcd_th),
        .hundreds(bcd_h),
        .tens(bcd_t),
        .ones(bcd_o)
    );
    
    // Leading zero suppression: determine number of significant digits
    wire [2:0] num_digits = (read_data >= 10000) ? 3'd5 :
                            (read_data >= 1000)  ? 3'd4 :
                            (read_data >= 100)   ? 3'd3 :
                            (read_data >= 10)    ? 3'd2 : 3'd1;
    
    // Character position within cell (32px per char)
    wire [2:0] digit_pos = (cell_x >= 128) ? 3'd4 :
                            (cell_x >= 96)  ? 3'd3 :
                            (cell_x >= 64)  ? 3'd2 :
                            (cell_x >= 32)  ? 3'd1 : 3'd0;
    wire digit_active = (digit_pos < num_digits);
    
    // Map displayed position to BCD digit (left-aligned)
    // digit_pos 0 = most significant displayed digit
    wire [2:0] bcd_idx = (num_digits - 1) - digit_pos;
    reg [3:0] grid_digit;
    always @(*) begin
        case (bcd_idx)
            3'd4: grid_digit = bcd_tt;
            3'd3: grid_digit = bcd_th;
            3'd2: grid_digit = bcd_h;
            3'd1: grid_digit = bcd_t;
            default: grid_digit = bcd_o;
        endcase
    end
    
    // Segment rendering for grid digit (16x24 base, 2x scaled to 32x48)
    wire [4:0] rel_x = cell_x[5:1] - {digit_pos, 4'b0};  // Relative to char start
    wire [4:0] rel_y = cell_y[5:1];
    
    // Wait — cell_x is already relative to cell. digit start = digit_pos * 32.
    // So relative X within character = cell_x - digit_pos * 32
    // In 2x scaling: rel_x for segment = (cell_x - digit_pos*32) / 2
    wire [9:0] char_start_x = {digit_pos, 5'b0};  // digit_pos * 32
    wire [5:0] raw_rx = cell_x[5:0] - char_start_x[5:0];
    wire [4:0] seg_rx = raw_rx[5:1];  // Divide by 2 for 16px base
    wire [4:0] seg_ry = cell_y[5:1];  // Divide by 2 for 24px base
    
    // Bounds check: within a 32x48 character
    wire in_char_bounds = (cell_x >= char_start_x) && (cell_x < char_start_x + 32) && (cell_y < 48);
    
    // 7-segment patterns
    reg [6:0] grid_segments;
    always @(*) begin
        case (grid_digit)
            4'd0: grid_segments = 7'b0111111;
            4'd1: grid_segments = 7'b0000110;
            4'd2: grid_segments = 7'b1011011;
            4'd3: grid_segments = 7'b1001111;
            4'd4: grid_segments = 7'b1100110;
            4'd5: grid_segments = 7'b1101101;
            4'd6: grid_segments = 7'b1111101;
            4'd7: grid_segments = 7'b0000111;
            4'd8: grid_segments = 7'b1111111;
            4'd9: grid_segments = 7'b1101111;
            default: grid_segments = 7'b0000000;
        endcase
    end
    
    // Segment geometry (16x24 grid)
    wire seg_a = (seg_ry < 3)                    && (seg_rx >= 3 && seg_rx < 13);
    wire seg_f = (seg_ry >= 3 && seg_ry < 11)    && (seg_rx >= 3 && seg_rx < 6);
    wire seg_b = (seg_ry >= 3 && seg_ry < 11)    && (seg_rx >= 10 && seg_rx < 13);
    wire seg_g = (seg_ry >= 11 && seg_ry < 14)   && (seg_rx >= 3 && seg_rx < 13);
    wire seg_e = (seg_ry >= 13 && seg_ry < 21)   && (seg_rx >= 3 && seg_rx < 6);
    wire seg_c = (seg_ry >= 13 && seg_ry < 21)   && (seg_rx >= 10 && seg_rx < 13);
    wire seg_d = (seg_ry >= 21)                   && (seg_rx >= 3 && seg_rx < 13);
    
    wire grid_pixel_on = in_char_bounds && !in_row_gap && digit_active && cell_valid && (
        (seg_a && grid_segments[0]) ||
        (seg_b && grid_segments[1]) ||
        (seg_c && grid_segments[2]) ||
        (seg_d && grid_segments[3]) ||
        (seg_e && grid_segments[4]) ||
        (seg_f && grid_segments[5]) ||
        (seg_g && grid_segments[6])
    );
    
    // Grid color: first 3 = seed colors, rest = white
    reg [3:0] grid_r, grid_g, grid_b;
    always @(*) begin
        if (val_idx == 0) begin
            // Seed 1: Green
            grid_r = 0; grid_g = 15; grid_b = 0;
        end else if (val_idx == 1) begin
            // Seed 2: Cyan
            grid_r = 0; grid_g = 15; grid_b = 15;
        end else if (val_idx == 2) begin
            // Seed 3: Yellow
            grid_r = 15; grid_g = 15; grid_b = 0;
        end else begin
            // Generated: White
            grid_r = 15; grid_g = 15; grid_b = 15;
        end
    end
    
    // =============================================
    // TEXT MODE: READY / ERROR / Input display
    // Uses digit_renderer instances
    // =============================================
    
    wire text_mode = show_ready || show_error || show_read1 || show_read2 || show_read3;
    
    localparam CENTER_Y = 216;
    localparam CHAR_SPACING = 40;
    localparam WORD_X0 = 224;
    
    // Text renderers (9 instances for text modes)
    wire [3:0] tr[0:8], tg[0:8], tb[0:8];
    wire tp[0:8];
    reg [7:0] tval[0:8];
    reg [9:0] tx[0:8];
    reg [3:0] tcr[0:8], tcg[0:8], tcb[0:8];
    
    // BCD for input display
    wire [3:0] sw_h, sw_t, sw_o;
    wire [3:0] n1_h, n1_t, n1_o;
    wire [3:0] n2_h, n2_t, n2_o;
    
    bin2bcd bcd_sw   (.binary(sw_live), .hundreds(sw_h), .tens(sw_t), .ones(sw_o));
    bin2bcd bcd_num1 (.binary(num1),    .hundreds(n1_h), .tens(n1_t), .ones(n1_o));
    bin2bcd bcd_num2 (.binary(num2),    .hundreds(n2_h), .tens(n2_t), .ones(n2_o));
    
    genvar gi;
    generate
        for (gi = 0; gi < 9; gi = gi + 1) begin : text_gen
            digit_renderer text_inst (
                .pixel_x(pixel_x), .pixel_y(pixel_y),
                .char_x(tx[gi]), .char_y(CENTER_Y),
                .value(tval[gi]),
                .color_r(tcr[gi]), .color_g(tcg[gi]), .color_b(tcb[gi]),
                .r(tr[gi]), .g(tg[gi]), .b(tb[gi]), .pixel_on(tp[gi])
            );
        end
    endgenerate
    
    // Text display logic
    integer j;
    always @(*) begin
        for (j = 0; j < 9; j = j + 1) begin
            tval[j] = 0; tx[j] = 0;
            tcr[j] = 0; tcg[j] = 0; tcb[j] = 0;
        end
        
        if (show_ready) begin
            // "READY" in Blue
            tval[0] = 8'h52; tx[0] = WORD_X0;                tcr[0] = 4; tcg[0] = 4; tcb[0] = 15;
            tval[1] = 8'h45; tx[1] = WORD_X0 + CHAR_SPACING;   tcr[1] = 4; tcg[1] = 4; tcb[1] = 15;
            tval[2] = 8'h41; tx[2] = WORD_X0 + 2*CHAR_SPACING; tcr[2] = 4; tcg[2] = 4; tcb[2] = 15;
            tval[3] = 8'h44; tx[3] = WORD_X0 + 3*CHAR_SPACING; tcr[3] = 4; tcg[3] = 4; tcb[3] = 15;
            tval[4] = 8'h59; tx[4] = WORD_X0 + 4*CHAR_SPACING; tcr[4] = 4; tcg[4] = 4; tcb[4] = 15;
        end
        else if (show_error) begin
            // "ERROR" in Red
            tval[0] = 8'h45; tx[0] = WORD_X0;                tcr[0] = 15; tcg[0] = 2; tcb[0] = 2;
            tval[1] = 8'h52; tx[1] = WORD_X0 + CHAR_SPACING;   tcr[1] = 15; tcg[1] = 2; tcb[1] = 2;
            tval[2] = 8'h52; tx[2] = WORD_X0 + 2*CHAR_SPACING; tcr[2] = 15; tcg[2] = 2; tcb[2] = 2;
            tval[3] = 8'h4F; tx[3] = WORD_X0 + 3*CHAR_SPACING; tcr[3] = 15; tcg[3] = 2; tcb[3] = 2;
            tval[4] = 8'h52; tx[4] = WORD_X0 + 4*CHAR_SPACING; tcr[4] = 15; tcg[4] = 2; tcb[4] = 2;
        end
        else if (show_read1) begin
            // Live input in Green (3 digits)
            tval[0] = sw_h; tx[0] = 270; tcr[0] = 0; tcg[0] = 15; tcb[0] = 0;
            tval[1] = sw_t; tx[1] = 304; tcr[1] = 0; tcg[1] = 15; tcb[1] = 0;
            tval[2] = sw_o; tx[2] = 338; tcr[2] = 0; tcg[2] = 15; tcb[2] = 0;
        end
        else if (show_read2) begin
            // num1 (Green) + live (Cyan)
            tval[0] = n1_h; tx[0] = 200; tcr[0] = 0; tcg[0] = 15; tcb[0] = 0;
            tval[1] = n1_t; tx[1] = 234; tcr[1] = 0; tcg[1] = 15; tcb[1] = 0;
            tval[2] = n1_o; tx[2] = 268; tcr[2] = 0; tcg[2] = 15; tcb[2] = 0;
            tval[3] = sw_h; tx[3] = 323; tcr[3] = 0; tcg[3] = 15; tcb[3] = 15;
            tval[4] = sw_t; tx[4] = 357; tcr[4] = 0; tcg[4] = 15; tcb[4] = 15;
            tval[5] = sw_o; tx[5] = 391; tcr[5] = 0; tcg[5] = 15; tcb[5] = 15;
        end
        else if (show_read3) begin
            // num1 (Green), num2 (Cyan), live (Yellow)
            tval[0] = n1_h; tx[0] = 150; tcr[0] = 0; tcg[0] = 15; tcb[0] = 0;
            tval[1] = n1_t; tx[1] = 184; tcr[1] = 0; tcg[1] = 15; tcb[1] = 0;
            tval[2] = n1_o; tx[2] = 218; tcr[2] = 0; tcg[2] = 15; tcb[2] = 0;
            tval[3] = n2_h; tx[3] = 268; tcr[3] = 0; tcg[3] = 15; tcb[3] = 15;
            tval[4] = n2_t; tx[4] = 302; tcr[4] = 0; tcg[4] = 15; tcb[4] = 15;
            tval[5] = n2_o; tx[5] = 336; tcr[5] = 0; tcg[5] = 15; tcb[5] = 15;
            tval[6] = sw_h; tx[6] = 386; tcr[6] = 15; tcg[6] = 15; tcb[6] = 0;
            tval[7] = sw_t; tx[7] = 420; tcr[7] = 15; tcg[7] = 15; tcb[7] = 0;
            tval[8] = sw_o; tx[8] = 454; tcr[8] = 15; tcg[8] = 15; tcb[8] = 0;
        end
    end
    
    // Combine text renderers
    reg [3:0] text_r, text_g, text_b;
    reg text_on;
    always @(*) begin
        text_r = 0; text_g = 0; text_b = 0; text_on = 0;
        for (j = 0; j < 9; j = j + 1) begin
            if (tp[j]) begin
                text_r = tr[j]; text_g = tg[j]; text_b = tb[j];
                text_on = 1;
            end
        end
    end
    
    // =============================================
    // Final output mux
    // =============================================
    wire grid_mode = show_generating || show_done;
    
    assign vga_r = !video_on ? 4'h0 :
                   (grid_mode && grid_pixel_on) ? grid_r :
                   (text_mode && text_on) ? text_r : 4'h0;
    assign vga_g = !video_on ? 4'h0 :
                   (grid_mode && grid_pixel_on) ? grid_g :
                   (text_mode && text_on) ? text_g : 4'h0;
    assign vga_b = !video_on ? 4'h0 :
                   (grid_mode && grid_pixel_on) ? grid_b :
                   (text_mode && text_on) ? text_b : 4'h0;

endmodule
