`timescale 1ns / 1ps
//============================================================================
// Testbench: tb_vga_system
// Purpose: Verify VGA display system functionality
//          Tests clock divider, sync timing, digit rendering, and FSM states
//============================================================================

module tb_vga_system;

    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    
    // Inputs
    reg [7:0] sw = 0;
    reg btn_enter = 0;
    
    // Outputs
    wire [7:0] led;
    wire uart_txd;
    wire oled_sclk, oled_sdin, oled_dc, oled_res, oled_vbat, oled_vdd;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync;
    
    // DUT - Device Under Test
    fibonacci_vga_top uut (
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .btn_enter(btn_enter),
        .led(led),
        .uart_txd(uart_txd),
        .oled_sclk(oled_sclk),
        .oled_sdin(oled_sdin),
        .oled_dc(oled_dc),
        .oled_res(oled_res),
        .oled_vbat(oled_vbat),
        .oled_vdd(oled_vdd),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync)
    );
    
    // 100 MHz clock generation
    always #5 clk = ~clk;  // 10ns period = 100 MHz
    
    // Monitor VGA sync signals
    integer h_count = 0;
    integer v_count = 0;
    integer frame_count = 0;
    
    // Variables for frame capture test (must be declared at module level)
    integer line, pixel;
    reg [11:0] pixel_color;
    
    // Track H-sync edges to count horizontal lines
    reg prev_hsync = 1;
    always @(posedge clk) begin
        prev_hsync <= vga_hsync;
        if (prev_hsync == 0 && vga_hsync == 1) begin  // Rising edge
            h_count <= h_count + 1;
        end
    end
    
    // Track V-sync edges to count frames
    reg prev_vsync = 1;
    always @(posedge clk) begin
        prev_vsync <= vga_vsync;
        if (prev_vsync == 0 && vga_vsync == 1) begin  // Rising edge
            v_count <= v_count + 1;
            frame_count <= frame_count + 1;
            $display("[TIME %0t] VGA Frame %0d completed", $time, frame_count);
        end
    end
    
    // Test sequence
    initial begin
        $display("==================================================");
        $display("VGA Display System Testbench");
        $display("Testing: Fibonacci + VGA Integration");
        $display("==================================================\n");
        
        // Initialize
        rst = 1;
        sw = 0;
        btn_enter = 0;
        #100;
        
        // Release reset
        rst = 0;
        $display("[%0t ns] Reset released", $time);
        
        //====================================================================
        // TEST 1: Check VGA Timing in IDLE State
        //====================================================================
        $display("\n--- TEST 1: VGA Timing Verification ---");
        #1_000_000;  // Wait 1ms for VGA to stabilize
        
        // Should show "RDY" in green on black
        $display("[%0t ns] Expected: VGA showing 'RDY' (IDLE state)", $time);
        $display("           VGA outputs: R=%h, G=%h, B=%h", vga_r, vga_g, vga_b);
        
        //====================================================================
        // TEST 2: Valid Fibonacci Sequence (3, 5, 8)
        //====================================================================
        $display("\n--- TEST 2: Valid Sequence (3, 5, 8) ---");
        
        // Enter 3
        #10_000;
        sw = 8'h03;
        #1_000;
        btn_enter = 1;
        #20_000;
        btn_enter = 0;
        $display("[%0t ns] Entered first number: 3", $time);
        #100_000;
        
        // Enter 5
        sw = 8'h05;
        #1_000;
        btn_enter = 1;
        #20_000;
        btn_enter = 0;
        $display("[%0t ns] Entered second number: 5", $time);
        #100_000;
        
        // Enter 8
        sw = 8'h08;
        #1_000;
        btn_enter = 1;
        #20_000;
        btn_enter = 0;
        $display("[%0t ns] Entered third number: 8 (Valid!)", $time);
        
        // Wait for generation and UART transmission
        #500_000;
        
        $display("[%0t ns] Expected: VGA showing result value", $time);
        $display("           LED value: %d (should show last result)", led);
        $display("           VGA outputs: R=%h, G=%h, B=%h", vga_r, vga_g, vga_b);
        
        //====================================================================
        // TEST 3: Invalid Fibonacci Sequence (3, 5, 9)
        //====================================================================
        $display("\n--- TEST 3: Invalid Sequence (3, 5, 9) ---");
        
        // Reset
        rst = 1;
        #100;
        rst = 0;
        #100_000;
        
        // Enter 3
        sw = 8'h03;
        #1_000;
        btn_enter = 1;
        #20_000;
        btn_enter = 0;
        #100_000;
        
        // Enter 5
        sw = 8'h05;
        #1_000;
        btn_enter = 1;
        #20_000;
        btn_enter = 0;
        #100_000;
        
        // Enter 9 (INVALID)
        sw = 8'h09;
        #1_000;
        btn_enter = 1;
        #20_000;
        btn_enter = 0;
        $display("[%0t ns] Entered third number: 9 (INVALID!)", $time);
        
        #200_000;
        
        $display("[%0t ns] Expected: VGA showing 'ERR'", $time);
        $display("           VGA outputs: R=%h, G=%h, B=%h", vga_r, vga_g, vga_b);
        
        //====================================================================
        // TEST 4: VGA Timing Check
        //====================================================================
        $display("\n--- TEST 4: VGA Sync Timing ---");
        $display("H-sync pulses counted: %d", h_count);
        $display("V-sync pulses counted: %d", v_count);
        $display("Frames rendered: %d", frame_count);
        
        if (frame_count >= 1) begin
            $display("[PASS] VGA timing appears correct (at least 1 frame rendered)");
        end else begin
            $display("[FAIL] VGA timing issue - no frames detected");
        end
        
        //====================================================================
        // TEST 5: Frame Capture (one complete frame)
        //====================================================================
        $display("\n--- TEST 5: Capturing One VGA Frame ---");
        
        // Wait for start of a new frame (V-sync rising edge)
        @(posedge vga_vsync);
        $display("[%0t ns] Frame capture started", $time);
        
        // Capture first 10 lines of pixel data
        for (line = 0; line < 10; line = line + 1) begin
            @(posedge vga_hsync);  // Wait for new line
            #10_000;  // Sample a few pixels into the line
            pixel_color = {vga_r, vga_g, vga_b};
            if (pixel_color != 12'h000) begin
                $display("  Line %0d: Non-black pixel detected (RGB=%h)", line, pixel_color);
            end
        end
        
        //====================================================================
        // Summary
        //====================================================================
        $display("\n==================================================");
        $display("Testbench Summary");
        $display("==================================================");
        $display("Tests completed:");
        $display("  [DONE] VGA timing (H/V sync)");
        $display("  [DONE] IDLE state display");
        $display("  [DONE] Valid sequence handling");
        $display("  [DONE] Invalid sequence handling");
        $display("  [DONE] Frame rendering");
        $display("\nTotal simulation time: %0t ns", $time);
        $display("Total frames: %d", frame_count);
        $display("==================================================\n");
        
        #100_000;
        $finish;
    end
    
    // Timeout watchdog (10ms max simulation)
    initial begin
        #10_000_000;
        $display("\n[WARNING] Simulation timeout after 10ms");
        $display("   Frames rendered: %d", frame_count);
    end
    
    // Optional: Save waveform for detailed analysis
    initial begin
        $dumpfile("vga_test.vcd");
        $dumpvars(0, tb_vga_system);
    end
    
    // Monitor critical signals
    always @(posedge clk) begin
        // Check for illegal VGA color during blanking
        if (!uut.u_vga.video_on) begin
            if (vga_r != 0 || vga_g != 0 || vga_b != 0) begin
                $display("[ERROR] at %0t: Non-zero color during blanking! R=%h G=%h B=%h", 
                         $time, vga_r, vga_g, vga_b);
            end
        end
    end

endmodule
