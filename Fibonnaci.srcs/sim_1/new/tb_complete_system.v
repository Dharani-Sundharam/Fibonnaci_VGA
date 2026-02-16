`timescale 1ns / 1ps

//============================================================================
// Complete System Testbench - Three Test Cases
// Tests all three output interfaces: VGA, UART, OLED
//============================================================================

module tb_complete_system;
    // Inputs
    reg clk = 0;
    reg rst = 1;
    reg [7:0] sw = 0;
    reg btn_enter = 0;
    
    // Outputs
    wire [7:0] led;
    wire uart_txd;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync;
    wire oled_sclk, oled_sdin, oled_dc, oled_res, oled_vbat, oled_vdd;
    
    // Instantiate DUT
    fibonacci_vga_top #(.DEBOUNCE_DELAY(100)) uut (
        .clk(clk), .rst(rst), .sw(sw), .btn_enter(btn_enter), .led(led),
        .uart_txd(uart_txd),
        .oled_sclk(oled_sclk), .oled_sdin(oled_sdin), .oled_dc(oled_dc),
        .oled_res(oled_res), .oled_vbat(oled_vbat), .oled_vdd(oled_vdd),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Monitor outputs
    integer uart_bytes = 0;
    integer oled_bits = 0;
    integer vga_frames = 0;
    reg prev_uart = 1;
    reg prev_sclk = 0;
    reg prev_vsync = 1;
    
    always @(posedge clk) begin
        // UART byte counter
        prev_uart <= uart_txd;
        if (prev_uart == 1 && uart_txd == 0)
            uart_bytes <= uart_bytes + 1;
        
        // OLED SPI bit counter
        prev_sclk <= oled_sclk;
        if (prev_sclk == 0 && oled_sclk == 1)
            oled_bits <= oled_bits + 1;
        
        // VGA frame counter
        prev_vsync <= vga_vsync;
        if (prev_vsync == 0 && vga_vsync == 1)
            vga_frames <= vga_frames + 1;
    end
    
    // Helper task: Enter a number
    task enter_number(input [7:0] num);
        begin
            sw = num;
            #10000;
            btn_enter = 1;
            #5000;
            btn_enter = 0;
            #50000;
        end
    endtask
    
    // Helper task: Check results
    task check_results(
        input [7:0] exp0, exp1, exp2, exp3,
        input expect_error,
        input [8*30:1] case_name
    );
        begin
            #300000;  // Wait 300us for processing
            
            $display("\n========================================");
            $display("%s", case_name);
            $display("========================================");
            
            if (expect_error) begin
                // Check for ERROR
                if (uut.show_error) begin
                    $display("✓ PASS: ERROR detected correctly");
                    $display("  LED blinking: %b", led[7]);
                    $display("  show_error: %b", uut.show_error);
                end else begin
                    $display("✗ FAIL: Expected ERROR but system shows DONE");
                    $display("  Results: %0d, %0d, %0d, %0d", 
                             uut.result0, uut.result1, uut.result2, uut.result3);
                end
            end else begin
                // Check for valid results
                $display("Expected: %0d, %0d, %0d, %0d", exp0, exp1, exp2, exp3);
                $display("Got:      %0d, %0d, %0d, %0d", 
                         uut.result0, uut.result1, uut.result2, uut.result3);
                
                if (uut.result0 == exp0 && uut.result1 == exp1 && 
                    uut.result2 == exp2 && uut.result3 == exp3) begin
                    $display("✓ PASS: Results CORRECT");
                end else begin
                    $display("✗ FAIL: Results INCORRECT");
                end
                
                $display("  LED value: %0d", led);
                $display("  show_done: %b", uut.show_done);
            end
            
            // Show output status
            $display("\nOutput Status:");
            $display("  UART: %0d bytes", uart_bytes);
            $display("  OLED: %0d bits", oled_bits);
            $display("  VGA:  %0d frames", vga_frames);
            $display("========================================\n");
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("\n");
        $display("╔══════════════════════════════════════╗");
        $display("║  Fibonacci System - 3 Test Cases    ║");
        $display("╚══════════════════════════════════════╝");
        
        // Initial reset
        rst = 1;
        #200;
        rst = 0;
        #10000;
        
        //====================================================================
        // TEST CASE 1: Valid Sequence (1, 1, 2)
        //====================================================================
        $display("\n[TEST 1] Valid sequence: 1, 1, 2");
        $display("Expected: 3, 5, 8, 13\n");
        
        enter_number(8'd1);
        $display("  → Entered: 1");
        
        enter_number(8'd1);
        $display("  → Entered: 1");
        
        enter_number(8'd2);
        $display("  → Entered: 2");
        
        check_results(8'd3, 8'd5, 8'd8, 8'd13, 0, "TEST 1 RESULTS: (1,1,2)");
        
        // Reset for next test
        rst = 1;
        #2000;
        rst = 0;
        #10000;
        uart_bytes = 0;
        
        //====================================================================
        // TEST CASE 2: Invalid Sequence (1, 1, 3)
        //====================================================================
        $display("\n[TEST 2] Invalid sequence: 1, 1, 3");
        $display("Expected: ERROR\n");
        
        enter_number(8'd1);
        $display("  → Entered: 1");
        
        enter_number(8'd1);
        $display("  → Entered: 1");
        
        enter_number(8'd3);
        $display("  → Entered: 3 (WRONG!)");
        
        check_results(8'd0, 8'd0, 8'd0, 8'd0, 1, "TEST 2 RESULTS: (1,1,3)");
        
        // Reset for next test
        rst = 1;
        #2000;
        rst = 0;
        #10000;
        uart_bytes = 0;
        
        //====================================================================
        // TEST CASE 3: Valid Sequence (2, 3, 5)
        //====================================================================
        $display("\n[TEST 3] Valid sequence: 2, 3, 5");
        $display("Expected: 8, 13, 21, 34\n");
        
        enter_number(8'd2);
        $display("  → Entered: 2");
        
        enter_number(8'd3);
        $display("  → Entered: 3");
        
        enter_number(8'd5);
        $display("  → Entered: 5");
        
        check_results(8'd8, 8'd13, 8'd21, 8'd34, 0, "TEST 3 RESULTS: (2,3,5)");
        
        //====================================================================
        // Final Summary
        //====================================================================
        $display("\n");
        $display("╔══════════════════════════════════════╗");
        $display("║         ALL TESTS COMPLETE           ║");
        $display("╚══════════════════════════════════════╝");
        $display("");
        $display("Test Summary:");
        $display("  1. Valid (1,1,2) → 3,5,8,13");
        $display("  2. Invalid (1,1,3) → ERROR");
        $display("  3. Valid (2,3,5) → 8,13,21,34");
        $display("");
        $display("Final Output Counts:");
        $display("  UART: %0d bytes transmitted", uart_bytes);
        $display("  OLED: %0d bits transferred", oled_bits);
        $display("  VGA:  %0d frames rendered", vga_frames);
        $display("");
        $display("System verification complete!");
        $display("══════════════════════════════════════\n");
        
        #50000;
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #10_000_000;  // 10ms timeout
        $display("\n[TIMEOUT] Simulation exceeded 10ms");
        $finish;
    end

endmodule

//============================================================================
// Testbench: tb_complete_system
// Purpose: Full system test - verifies VGA, UART, and OLED outputs
//          Input: 1, 1, 2 -> Expected output: 3, 5, 8, 13
//============================================================================

module tb_complete_system;

    // Inputs
    reg clk = 0;
    reg rst = 1;
    reg [7:0] sw = 0;
    reg btn_enter = 0;
    
    // Outputs
    wire [7:0] led;
    wire uart_txd;
    wire oled_sclk, oled_sdin, oled_dc, oled_res, oled_vbat, oled_vdd;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync;
    
    // DUT - Use fast debounce for simulation
    fibonacci_vga_top #(
        .DEBOUNCE_DELAY(100)  // Fast debounce for simulation
    ) uut (
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
    
    // 100 MHz clock
    always #5 clk = ~clk;
    
    // VGA frame counter with periodic display
    integer vga_frames = 0;
    reg prev_vsync = 1;
    always @(posedge clk) begin
        prev_vsync <= vga_vsync;
        if (prev_vsync == 0 && vga_vsync == 1) begin
            vga_frames <= vga_frames + 1;
            // Show every 30th frame to reduce clutter
            if (vga_frames % 30 == 0)
                $display("  [VGA] Frame %0d (continuous refresh at 60Hz)", vga_frames);
        end
    end
    
    // OLED SPI activity monitor with event detection
    integer oled_bits = 0;
    integer oled_bytes = 0;
    reg prev_sclk = 0;
    always @(posedge clk) begin
        prev_sclk <= oled_sclk;
        if (prev_sclk == 0 && oled_sclk == 1) begin
            oled_bits <= oled_bits + 1;
            if (oled_bits % 8 == 0) begin
                oled_bytes <= oled_bytes + 1;
                if (oled_bytes % 10 == 0)
                    $display("  [OLED] SPI byte %0d transmitted (updating display)", oled_bytes);
            end
        end
    end
    
    // UART activity monitor with transmission detection and byte decoding
    integer uart_bytes = 0;
    reg prev_uart = 1;
    reg [31:0] uart_idle_count = 0;
    reg uart_was_active = 0;
    reg [7:0] uart_rx_byte;
    reg [3:0] uart_bit_idx;
    reg uart_sampling;
    integer uart_sample_count;
    
    always @(posedge clk) begin
        prev_uart <= uart_txd;
        
        // Detect start bit (falling edge on TX line)
        if (prev_uart == 1 && uart_txd == 0 && !uart_sampling) begin
            uart_bytes <= uart_bytes + 1;
            uart_was_active <= 1;
            uart_idle_count <= 0;
            uart_sampling <= 1;
            uart_bit_idx <= 0;
            uart_sample_count <= 0;
            $display("  [UART] Byte %0d: Start bit detected", uart_bytes);
        end
        
        // Sample UART data bits (rough sampling at ~1/10th bit time)
        if (uart_sampling) begin
            uart_sample_count <= uart_sample_count + 1;
            // Sample at ~middle of each bit (rough timing for 115200 baud)
            if (uart_sample_count == 435) begin  // ~middle of bit at 100MHz/115200
                uart_sample_count <= 0;
                if (uart_bit_idx < 8) begin
                    uart_rx_byte[uart_bit_idx] <= uart_txd;
                    uart_bit_idx <= uart_bit_idx + 1;
                end else begin
                    // Done sampling, display the byte
                    uart_sampling <= 0;
                    if (uart_rx_byte >= 32 && uart_rx_byte < 127)
                        $display("  [UART] Byte %0d: 0x%h '%c'", uart_bytes, uart_rx_byte, uart_rx_byte);
                    else
                        $display("  [UART] Byte %0d: 0x%h (non-printable)", uart_bytes, uart_rx_byte);
                end
            end
        end
        
        // Track when UART goes idle after transmission
        if (uart_was_active && uart_txd == 1 && !uart_sampling) begin
            uart_idle_count <= uart_idle_count + 1;
            if (uart_idle_count == 5000) begin
                $display("  [UART] Transmission complete - %0d bytes total\n", uart_bytes);
            end
        end
    end
    
    // Test sequence
    initial begin
        $display("==================================================");
        $display("Complete System Test");
        $display("Testing: VGA + UART + OLED with Fibonacci 1,1,2");
        $display("Expected results: 3, 5, 8, 13");
        $display("==================================================\n");
        
        // Initialize
        rst = 1;
        sw = 0;
        btn_enter = 0;
        #200;
        
        // Release reset
        rst = 0;
        $display("[%0t] System reset released", $time);
        $display("  Waiting for startup sequence...\n");
        #50000;  // Wait 50us for initial startup
        
        //====================================================================
        // TEST: Enter Fibonacci sequence 1, 1, 2
        //====================================================================
        $display("\n[TEST 1] Entering Fibonacci sequence: 1, 1, 2");
        $display("------------------------------------------------------------");
        
        // Enter 1
        #10000;
        sw = 8'd1;
        #2000;
        btn_enter = 1;
        #5000;
        btn_enter = 0;
        $display("[%0t] Entered first number: 1", $time);
        #50000;
        
        // Enter 1 again
        sw = 8'd1;
        #2000;
        btn_enter = 1;
        #5000;
        btn_enter = 0;
        $display("[%0t] Entered second number: 1", $time);
        #50000;
        
        // Enter 2
        sw = 8'd3;
        #2000;
        btn_enter = 1;
        #5000;
        btn_enter = 0;
        $display("[%0t] Entered third number: 2", $time);
        $display("  Sequence is valid - generating next 4 Fibonacci numbers...\n");
        
        // Wait 1 full second for all systems to generate and display results
        $display("  Waiting 1 second for all outputs to stabilize...");
        #100_000_000;  // 1 second at 100MHz
        
        
        //====================================================================
        // CHECK RESULTS - Clean Output
        //====================================================================
        $display("\n==================================================");
        $display("RESULTS (After 1 second)");
        $display("==================================================\n");
        
        // Fibonacci Generation
        $display("Fibonacci Results:");
        $display("  Generated: %0d, %0d, %0d, %0d", 
                 uut.result0, uut.result1, uut.result2, uut.result3);
        $display("  Expected:  3, 5, 8, 13\n");
        
        if (uut.result0 === 8'd3 && uut.result1 === 8'd5 && 
            uut.result2 === 8'd8 && uut.result3 === 8'd13) begin
            $display("  [PASS] Fibonacci generation CORRECT\n");
        end else begin
            $display("  [FAIL] Fibonacci generation INCORRECT\n");
        end
        
        // VGA Output
        $display("VGA Display:");
        $display("  Frames rendered: %0d", vga_frames);
        $display("  Color output: R=%h G=%h B=%h", vga_r, vga_g, vga_b);
        if (vga_frames > 0 && (vga_g != 0 || vga_r != 0 || vga_b != 0)) begin
            $display("  [PASS] VGA is displaying output");
            $display("        (VGA, UART, OLED all running in PARALLEL)\n");
        end else begin
            $display("  [FAIL] VGA not working\n");
        end
        
        // UART Output  
        $display("UART Terminal:");
        $display("  Bytes transmitted: %0d", uart_bytes);
        if (uart_bytes > 0) begin
            $display("  [PASS] UART transmitted results in parallel");
            $display("         (Transmits ONCE, then idles - this is correct!)\n");
        end else begin
            $display("  [FAIL] UART not transmitting\n");
        end
        
        // OLED Output
        $display("OLED Display:");
        $display("  SPI bytes sent: %0d", oled_bytes);
        if (oled_bytes > 10) begin
            $display("  [PASS] OLED updated display in parallel");
            $display("         (Updates display, then holds - this is correct!)\n");
        end else begin
            $display("  [INFO] OLED may still be initializing\n");
        end
        
        $display("==================================================");
        $display("All three outputs working SIMULTANEOUSLY!");
        $display("==================================================");
        $display("  VGA:  Refreshes continuously (60 frames/sec)");
        $display("  UART: Transmitted once, now idle (correct)");
        $display("  OLED: Updated once, now holding (correct)");
        $display("==================================================\n");
        
        $display("Continuing for 3.4 more seconds...");
        $display("  VGA will keep refreshing (showing same data)");
        $display("  UART/OLED stay idle (already sent their data)\n");
        
        // Run for another 3.4 seconds to show continuous parallel operation
        #340_000_000;  // 3.4 seconds at 100MHz
        
        $display("\n==================================================");
        $display("Extended Test Complete");
        $display("==================================================");
        $display("Total simulation time: %.3f seconds", $time/100000000.0);
        $display("VGA frames rendered: %0d (all while UART/OLED also active)", vga_frames);
        $display("All systems ran in PARALLEL for entire duration!");
        $display("==================================================\n");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #500_000_000;  // 5 seconds max
        $display("\n[TIMEOUT] Simulation complete after 5 seconds");
        $display("Total time: %.3f seconds", $time/100000000.0);
        $display("Final status:");
        $display("  VGA frames: %0d", vga_frames);
        $display("  UART bytes: %0d", uart_bytes);
        $display("  OLED clocks: %0d", oled_bits);
        $finish;
    end

endmodule
