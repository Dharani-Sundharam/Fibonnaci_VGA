`timescale 1ns / 1ps
//============================================================================
// Module:  top_vga
// Purpose: VGA controller with state-based display
//          Shows READY, results (4 values), or ERROR based on FSM state
//============================================================================

module top_vga (
    input  wire       clk,           // 100 MHz system clock
    input  wire       rst,           // Active-high reset
    
    // Control signals from FSM
    input  wire       show_ready,    // IDLE state - show "RDY"
    input  wire       show_done,     // DONE state - show 4 results
    input  wire       show_error,    // ERROR state - show "ERR"
    
    // Fibonacci results (all 4 generated values)
    input  wire [7:0] result0,       // First result
    input  wire [7:0] result1,       // Second result
    input  wire [7:0] result2,       // Third result
    input  wire [7:0] result3,       // Fourth result
    
    output wire [3:0] vga_r,         // VGA Red (4-bit)
    output wire [3:0] vga_g,         // VGA Green (4-bit)
    output wire [3:0] vga_b,         // VGA Blue (4-bit)
    output wire       vga_hsync,     // Horizontal sync
    output wire       vga_vsync      // Vertical sync
);

    // Clock enable for 25 MHz pixel clock
    wire clk_en_25mhz;
    
    clk_divider u_clk_div (
        .clk(clk),
        .rst(rst),
        .clk_en_25mhz(clk_en_25mhz)
    );
    
    // VGA sync signals
    wire video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    
    vga_sync u_vga_sync (
        .clk(clk),
        .rst(rst),
        .clk_en_25mhz(clk_en_25mhz),
        .h_sync(vga_hsync),
        .v_sync(vga_vsync),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );
    
    //========================================================================
    // Display Mode Selection
    //========================================================================
    reg [2:0] display_mode;
    
    always @(*) begin
        if (show_error)
            display_mode = 3'd2;      // ERROR mode
        else if (show_done)
            display_mode = 3'd1;      // RESULTS mode
        else
            display_mode = 3'd0;      // READY mode (default)
    end
    
    
    //========================================================================
    // Content Selection Based on Mode
    //========================================================================
    wire [7:0] display_val;
    wire [3:0] digit_100, digit_10, digit_1;
    
    // Mode 0 (READY): Show "RDY" using special encoding
    // Mode 1 (RESULTS): Show result0 (can cycle through all 4)
    // Mode 2 (ERROR): Show "ERR" using special encoding
    
    // For simplicity, show one result at a time
    // You can enhance this to show all 4 side-by-side
    assign display_val = show_done ? result3 : 8'd0;  // Show last result when done
    
    // Binary to decimal conversion
    assign digit_100 = display_val / 100;
    assign digit_10  = (display_val % 100) / 10;
    assign digit_1   = display_val % 10;
    
    //========================================================================
    // Display Layout
    //========================================================================
    localparam DIGIT_X_START = 210;
    localparam DIGIT_Y_START = 190;
    localparam DIGIT_WIDTH   = 60;
    localparam DIGIT_SPACING = 20;
    
    wire [9:0] pos_x_100 = DIGIT_X_START;
    wire [9:0] pos_x_10  = DIGIT_X_START + DIGIT_WIDTH + DIGIT_SPACING;
    wire [9:0] pos_x_1   = DIGIT_X_START + 2*(DIGIT_WIDTH + DIGIT_SPACING);
    wire [9:0] pos_y_all = DIGIT_Y_START;
    
    //========================================================================
    // Special Digit Mapping for Text Display
    //========================================================================
    // When in READY mode: display "RDY" (R=digit_100, D=digit_10, Y=digit_1)
    // When in ERROR mode: display "ERR" (E=digit_100, R=digit_10, R=digit_1)
    // Use invalid BCD values (>9) to trigger letter display
    
    wire [3:0] char_left, char_mid, char_right;
    
    assign char_left  = show_error ? 4'd10 :  // 'E'
                        show_ready ? 4'd11 :  // 'R'
                        digit_100;            // Number
    
    assign char_mid   = show_error ? 4'd11 :  // 'R'
                        show_ready ? 4'd12 :  // 'D'
                        digit_10;             // Number
    
    assign char_right = show_error ? 4'd11 :  // 'R'
                        show_ready ? 4'd13 :  // 'Y'
                        digit_1;              // Number
    
    //========================================================================
    // Digit/Character Renderers
    //========================================================================
    wire pixel_on_left, pixel_on_mid, pixel_on_right;
    
    digit_renderer u_char_left (
        .digit(char_left),
        .offset_x(pos_x_100),
        .offset_y(pos_y_all),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_on(pixel_on_left)
    );
    
    digit_renderer u_char_mid (
        .digit(char_mid),
        .offset_x(pos_x_10),
        .offset_y(pos_y_all),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_on(pixel_on_mid)
    );
    
    digit_renderer u_char_right (
        .digit(char_right),
        .offset_x(pos_x_1),
        .offset_y(pos_y_all),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_on(pixel_on_right)
    );
    
    //========================================================================
    // Startup Test Pattern - DISABLED FOR SIMULATION
    // (Enable for hardware by changing to 100_000_000 for 1 second)
    //========================================================================
    reg [31:0] startup_counter;
    wire startup_mode;
    
    always @(posedge clk) begin
        if (rst)
            startup_counter <= 32'd0;
        else if (startup_counter < 32'd0)  // DISABLED - set to 0 for simulation
            startup_counter <= startup_counter + 1;
    end
    
    assign startup_mode = (startup_counter < 32'd0);  // Always 0 (disabled)
    
    // Color bar pattern: 8 vertical bars (80 pixels each)
    wire [2:0] bar_index = pixel_x[9:7];  // Divide screen into 8 sections
    wire [11:0] test_pattern_color;
    
    assign test_pattern_color = (bar_index == 3'd0) ? 12'hFFF :  // White
                                (bar_index == 3'd1) ? 12'hFF0 :  // Yellow
                                (bar_index == 3'd2) ? 12'h0FF :  // Cyan
                                (bar_index == 3'd3) ? 12'h0F0 :  // Green
                                (bar_index == 3'd4) ? 12'hF0F :  // Magenta
                                (bar_index == 3'd5) ? 12'hF00 :  // Red
                                (bar_index == 3'd6) ? 12'h00F :  // Blue
                                                      12'h000;   // Black
    
    //========================================================================
    // Color Output - Startup pattern or normal display
    //========================================================================
    wire any_pixel_on = pixel_on_left | pixel_on_mid | pixel_on_right;
    
    // During startup: show color bars (respecting blanking)
    // After startup: show green digits on black
    assign vga_r = video_on ? (startup_mode ? test_pattern_color[11:8] : 4'h0) : 4'h0;
    assign vga_g = video_on ? (startup_mode ? test_pattern_color[7:4]  : (any_pixel_on ? 4'hF : 4'h0)) : 4'h0;
    assign vga_b = video_on ? (startup_mode ? test_pattern_color[3:0]  : 4'h0) : 4'h0;

endmodule

