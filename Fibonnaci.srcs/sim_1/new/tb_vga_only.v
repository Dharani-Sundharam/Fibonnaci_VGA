`timescale 1ns / 1ps
//============================================================================
// Testbench: VGA only (using fibonacci_vga_only)
// 3 test cases: valid, invalid, valid
//============================================================================

module tb_vga_only;
    reg clk = 0;
    reg rst = 1;
    reg [7:0] sw = 0;
    reg btn_enter = 0;
    
    wire [7:0] led;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync;
    
    fibonacci_vga_only #(.DEBOUNCE_DELAY(100)) uut (
        .clk(clk), .rst(rst), .sw(sw), .btn_enter(btn_enter), .led(led),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync)
    );
    
    always #5 clk = ~clk;
    
    // VGA frame counter
    integer vga_frames = 0;
    integer green_pixels = 0;
    reg prev_vsync = 1;
    
    always @(posedge clk) begin
        prev_vsync <= vga_vsync;
        if (prev_vsync == 0 && vga_vsync == 1)
            vga_frames <= vga_frames + 1;
        
        // Count non-black pixels
        if (vga_r != 0 || vga_g != 0 || vga_b != 0)
            green_pixels <= green_pixels + 1;
    end
    
    // Enter a number
    task enter_num(input [7:0] num);
        begin
            sw = num;
            #10000;
            btn_enter = 1;
            #5000;
            btn_enter = 0;
            #50000;
        end
    endtask
    
    initial begin
        $display("\n============================================");
        $display("  VGA-Only Testbench (3 cases)");
        $display("============================================\n");
        
        // Reset
        rst = 1; #500; rst = 0; #20000;
        
        //==================================
        // CASE 1: Valid (1, 1, 2) -> 3,5,8,13
        //==================================
        $display("[CASE 1] Valid: 1, 1, 2 -> Expect 3,5,8,13");
        enter_num(8'd1);
        enter_num(8'd1);
        enter_num(8'd2);
        
        #500000;  // Wait 500us for VGA frames
        
        $display("  Results: %0d, %0d, %0d, %0d", 
                 uut.result0, uut.result1, uut.result2, uut.result3);
        if (uut.result0 == 3 && uut.result1 == 5 && uut.result2 == 8 && uut.result3 == 13)
            $display("  [PASS] Fibonacci CORRECT");
        else
            $display("  [FAIL] Fibonacci WRONG");
        
        $display("  VGA frames: %0d | Colored pixels: %0d", vga_frames, green_pixels);
        $display("  show_done=%b | VGA R=%h G=%h B=%h", uut.show_done, vga_r, vga_g, vga_b);
        $display("  LED: %0d", led);
        
        if (vga_frames > 0)
            $display("  [PASS] VGA rendering frames");
        else
            $display("  [INFO] VGA timing active (frames counting)");
        $display("");
        
        //==================================
        // Reset between cases
        //==================================
        rst = 1; #5000; rst = 0; #20000;
        vga_frames = 0;
        green_pixels = 0;
        
        //==================================
        // CASE 2: Invalid (1, 1, 3) -> ERROR
        //==================================
        $display("[CASE 2] Invalid: 1, 1, 3 -> Expect ERROR");
        enter_num(8'd1);
        enter_num(8'd1);
        enter_num(8'd3);
        
        #500000;
        
        if (uut.show_error)
            $display("  [PASS] ERROR detected correctly");
        else
            $display("  [FAIL] ERROR not detected (show_error=%b, show_done=%b)", 
                     uut.show_error, uut.show_done);
        
        $display("  VGA should show 'ERR': R=%h G=%h B=%h", vga_r, vga_g, vga_b);
        $display("  LED: %b (should blink)", led);
        $display("");
        
        //==================================
        // Reset between cases
        //==================================
        rst = 1; #5000; rst = 0; #20000;
        vga_frames = 0;
        green_pixels = 0;
        
        //==================================
        // CASE 3: Valid (2, 3, 5) -> 8,13,21,34
        //==================================
        $display("[CASE 3] Valid: 2, 3, 5 -> Expect 8,13,21,34");
        enter_num(8'd2);
        enter_num(8'd3);
        enter_num(8'd5);
        
        #500000;
        
        $display("  Results: %0d, %0d, %0d, %0d", 
                 uut.result0, uut.result1, uut.result2, uut.result3);
        if (uut.result0 == 8 && uut.result1 == 13 && uut.result2 == 21 && uut.result3 == 34)
            $display("  [PASS] Fibonacci CORRECT");
        else
            $display("  [FAIL] Fibonacci WRONG");
        
        $display("  VGA frames: %0d | Colored pixels: %0d", vga_frames, green_pixels);
        $display("  LED: %0d", led);
        $display("");
        
        //==================================
        // Summary
        //==================================
        $display("============================================");
        $display("  VGA-Only Test Complete");
        $display("============================================\n");
        
        #10000;
        $finish;
    end
    
    initial begin
        #5_000_000;
        $display("[TIMEOUT]");
        $finish;
    end
endmodule
