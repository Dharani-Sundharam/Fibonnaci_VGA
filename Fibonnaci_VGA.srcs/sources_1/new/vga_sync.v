`timescale 1ns / 1ps

module vga_sync (
    input wire clk,
    input wire reset,
    input wire clk_en,       // 25MHz enable
    output reg hsync,
    output reg vsync,
    output wire video_on,
    output reg [9:0] pixel_x,
    output reg [9:0] pixel_y
);

    // VGA 640x480 @ 60Hz timing parameters
    localparam H_DISPLAY    = 640;
    localparam H_FRONT      = 16;
    localparam H_SYNC       = 96;
    localparam H_BACK       = 48;
    localparam H_TOTAL      = 800;
    
    localparam V_DISPLAY    = 480;
    localparam V_FRONT      = 10;
    localparam V_SYNC       = 2;
    localparam V_BACK       = 33;
    localparam V_TOTAL      = 525;
    
    // Counters
    reg [9:0] h_count;
    reg [9:0] v_count;
    
    // Video on when in visible region
    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);
    
    // Pixel coordinates (only valid when video_on)
    always @(*) begin
        pixel_x = h_count;
        pixel_y = v_count;
    end
    
    // Horizontal counter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count <= 0;
        end else if (clk_en) begin
            if (h_count == H_TOTAL - 1)
                h_count <= 0;
            else
                h_count <= h_count + 1;
        end
    end
    
    // Vertical counter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            v_count <= 0;
        end else if (clk_en) begin
            if (h_count == H_TOTAL - 1) begin
                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end
        end
    end
    
    // Sync signals (active low)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hsync <= 1;
            vsync <= 1;
        end else if (clk_en) begin
            hsync <= ~((h_count >= H_DISPLAY + H_FRONT) && 
                       (h_count < H_DISPLAY + H_FRONT + H_SYNC));
            vsync <= ~((v_count >= V_DISPLAY + V_FRONT) && 
                       (v_count < V_DISPLAY + V_FRONT + V_SYNC));
        end
    end

endmodule
