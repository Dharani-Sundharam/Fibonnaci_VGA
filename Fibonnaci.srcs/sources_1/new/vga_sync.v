`timescale 1ns / 1ps
//============================================================================
// Module:  vga_sync
// Purpose: VGA synchronization generator for 640x480 @ 60Hz
//          Generates H/V sync signals and pixel coordinates
//============================================================================

module vga_sync (
    input  wire       clk,           // 100 MHz system clock
    input  wire       rst,           // Active-high reset
    input  wire       clk_en_25mhz,  // 25 MHz enable pulse
    
    output reg        h_sync,        // Horizontal sync (active-low)
    output reg        v_sync,        // Vertical sync (active-low)
    output wire       video_on,      // HIGH in display region
    output wire [9:0] pixel_x,       // Current X coordinate (0-799)
    output wire [9:0] pixel_y        // Current Y coordinate (0-524)
);

    // VGA 640x480 @ 60Hz timing parameters
    // Horizontal timing (pixels)
    localparam H_DISPLAY    = 640;  // Display region
    localparam H_FRONT      = 16;   // Front porch
    localparam H_SYNC_PULSE = 96;   // Sync pulse width
    localparam H_BACK       = 48;   // Back porch
    localparam H_TOTAL      = 800;  // Total line time
    
    // Vertical timing (lines)
    localparam V_DISPLAY    = 480;  // Display region
    localparam V_FRONT      = 10;   // Front porch
    localparam V_SYNC_PULSE = 2;    // Sync pulse width
    localparam V_BACK       = 33;   // Back porch
    localparam V_TOTAL      = 525;  // Total frame time
    
    // Sync pulse boundaries (active-low)
    localparam H_SYNC_START = H_DISPLAY + H_FRONT;
    localparam H_SYNC_END   = H_DISPLAY + H_FRONT + H_SYNC_PULSE;
    localparam V_SYNC_START = V_DISPLAY + V_FRONT;
    localparam V_SYNC_END   = V_DISPLAY + V_FRONT + V_SYNC_PULSE;
    
    // Counters
    reg [9:0] h_count;
    reg [9:0] v_count;
    
    // Horizontal counter
    always @(posedge clk) begin
        if (rst) begin
            h_count <= 10'd0;
        end else if (clk_en_25mhz) begin
            if (h_count == H_TOTAL - 1)
                h_count <= 10'd0;
            else
                h_count <= h_count + 1'b1;
        end
    end
    
    // Vertical counter
    always @(posedge clk) begin
        if (rst) begin
            v_count <= 10'd0;
        end else if (clk_en_25mhz) begin
            if (h_count == H_TOTAL - 1) begin
                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1'b1;
            end
        end
    end
    
    // Generate sync pulses (active-low)
    always @(posedge clk) begin
        if (rst) begin
            h_sync <= 1'b1;
            v_sync <= 1'b1;
        end else begin
            h_sync <= ~((h_count >= H_SYNC_START) && (h_count < H_SYNC_END));
            v_sync <= ~((v_count >= V_SYNC_START) && (v_count < V_SYNC_END));
        end
    end
    
    // Video enable signal (HIGH during display region)
    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);
    
    // Output current pixel coordinates
    assign pixel_x = h_count;
    assign pixel_y = v_count;

endmodule
