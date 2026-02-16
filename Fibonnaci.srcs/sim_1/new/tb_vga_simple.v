`timescale 1ns / 1ps
//============================================================================
// Testbench: tb_vga_simple
// Purpose: Simple VGA test - just check if VGA outputs anything
//============================================================================

module tb_vga_simple;

    reg clk = 0;
    reg rst = 1;
    
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync;
    
    // Simple VGA instance - no Fibonacci
    top_vga uut (
        .clk(clk),
        .rst(rst),
        .show_ready(1'b1),     // Force READY mode
        .show_done(1'b0),
        .show_error(1'b0),
        .result0(8'd123),
        .result1(8'd45),
        .result2(8'd67),
        .result3(8'd89),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync)
    );
    
    // 100 MHz clock
    always #5 clk = ~clk;
    
    integer hsync_count = 0;
    integer vsync_count = 0;
    integer green_pixels = 0;
    
    // Count H-sync pulses
    reg prev_h = 1;
    always @(posedge clk) begin
        prev_h <= vga_hsync;
        if (prev_h == 0 && vga_hsync == 1)
            hsync_count <= hsync_count + 1;
    end
    
    // Count V-sync pulses  
    reg prev_v = 1;
    always @(posedge clk) begin
        prev_v <= vga_vsync;
        if (prev_v == 0 && vga_vsync == 1) begin
            vsync_count <= vsync_count + 1;
            $display("[%0t] Frame %0d complete. H-syncs: %0d, Green pixels: %0d", 
                     $time, vsync_count, hsync_count, green_pixels);
        end
    end
    
    // Count green pixels
    always @(posedge clk) begin
        if (vga_g != 0)
            green_pixels <= green_pixels + 1;
    end
    
    initial begin
        $display("=== Simple VGA Test ===\n");
        rst = 1;
        #100;
        rst = 0;
        $display("[%0t] Reset released", $time);
        
        // Wait for 2 frames
        #35_000_000;  // ~35ms = 2 frames at 60Hz
        
        $display("\n=== Results ===");
        $display("H-sync count: %0d (expect ~2*525 = 1050)", hsync_count);
        $display("V-sync count: %0d (expect 2)", vsync_count);
        $display("Green pixels: %0d (expect > 0 for 'RDY' text)", green_pixels);
        
        if (vsync_count >= 2) begin
            $display("[PASS] VGA timing works!");
        end else begin
            $display("[FAIL] VGA timing broken");
        end
        
        if (green_pixels > 0) begin
            $display("[PASS] VGA display works!");
        end else begin
            $display("[FAIL] No display output");
        end
        
        $finish;
    end
    
    // Timeout
    initial begin
        #50_000_000;
        $display("\n[WARNING] Timeout");
        $finish;
    end

endmodule
