`timescale 1ns / 1ps

//============================================================================
// Testbench: Three Test Cases
// - Case 1: Valid sequence (1, 1, 2) → expect 3, 5, 8, 13
// - Case 2: Invalid sequence (1, 1, 3) → expect ERROR
// - Case 3: Valid sequence (2, 3, 5) → expect 8, 13, 21, 34
//============================================================================

module tb_three_cases;
    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    
    // Inputs
    reg [7:0] sw = 0;
    reg btn_enter = 0;
    
    // Outputs
    wire [7:0] led;
    wire uart_txd;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync;
    wire oled_sclk, oled_sdin, oled_dc, oled_res, oled_vbat, oled_vdd;
    
    // Instantiate DUT with fast debounce for simulation
    fibonacci_vga_top #(.DEBOUNCE_DELAY(100)) uut (
        .clk(clk), .rst(rst), .sw(sw), .btn_enter(btn_enter), .led(led),
        .uart_txd(uart_txd),
        .oled_sclk(oled_sclk), .oled_sdin(oled_sdin), .oled_dc(oled_dc),
        .oled_res(oled_res), .oled_vbat(oled_vbat), .oled_vdd(oled_vdd),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync)
    );
    
    // 100 MHz clock
    always #5 clk = ~clk;
    
    // Monitor outputs
    integer uart_count = 0;
    integer oled_count = 0;
    integer vga_frames = 0;
    
    reg prev_uart = 1;
    reg prev_sclk = 0;
    reg prev_vsync = 1;
    
    always @(posedge clk) begin
        // Count UART start bits
        prev_uart <= uart_txd;
        if (prev_uart == 1 && uart_txd == 0)
            uart_count <= uart_count + 1;
        
        // Count OLED SPI clocks
        prev_sclk <= oled_sclk;
        if (prev_sclk == 0 && oled_sclk == 1)
            oled_count <= oled_count + 1;
        
        // Count VGA frames
        prev_vsync <= vga_vsync;
        if (prev_vsync == 0 && vga_vsync == 1)
            vga_frames <= vga_frames + 1;
    end
    
    // Task to enter a number
    task enter_number(input [7:0] num);
        begin
            sw = num;
            #10000;
            btn_enter = 1;
            #5000;
            btn_enter = 0;
            #50000;  // Wait for debounce
        end
    endtask
    
    // Task to check results
    task check_case(
        input [7:0] exp0, exp1, exp2, exp3,
        input expect_error,
        input [8*20:1] case_name
    );
        begin
            #200000;  // Wait 200us for processing
            
            $display("\n--- %s ---", case_name);
            
            if (expect_error) begin
                if (uut.show_error) begin
                    $display("  ✓ PASS: ERROR detected as expected");
                    $display("    LED blinking: %b", led[0]);
                end else begin
                    $display("  ✗ FAIL: Expected ERROR but got results");
                end
            end else begin
                $display("  Expected: %0d, %0d, %0d, %0d", exp0, exp1, exp2, exp3);
                $display("  Got:      %0d, %0d, %0d, %0d", 
                         uut.result0, uut.result1, uut.result2, uut.result3);
                
                if (uut.result0 == exp0 && uut.result1 == exp1 && 
                    uut.result2 == exp2 && uut.result3 == exp3) begin
                    $display("  ✓ PASS: Results correct!");
                    $display("    LED shows: %0d", led);
                end else begin
                    $display("  ✗ FAIL: Results incorrect");
                end
            end
            
            // Check outputs are active
            $display("  Outputs: UART=%0d bytes, OLED=%0d bits, VGA=%0d frames", 
                     uart_count, oled_count, vga_frames);
        end
    endtask
    
    // Main test
    initial begin
        $display("\n========================================");
        $display("Three Case Test");
        $display("========================================\n");
        
        // Reset
        rst = 1;
        #200;
        rst = 0;
        #10000;
        $display("System ready (breathing LED active)");
        
        //====================================================================
        // CASE 1: Valid sequence (1, 1, 2)
        //====================================================================
        $display("\n\n[CASE 1] Entering valid sequence: 1, 1, 2");
        $display("Expected output: 3, 5, 8, 13");
        
        enter_number(8'd1);
        $display("  Entered: 1");
        
        enter_number(8'd1);
        $display("  Entered: 1");
        
        enter_number(8'd2);
        $display("  Entered: 2");
        
        check_case(8'd3, 8'd5, 8'd8, 8'd13, 0, "CASE 1: 1,1,2");
        
        // Reset for next case
        rst = 1;
        #1000;
        rst = 0;
        #10000;
        uart_count = 0;
        
        //====================================================================
        // CASE 2: Invalid sequence (1, 1, 3)
        //====================================================================
        $display("\n\n[CASE 2] Entering invalid sequence: 1, 1, 3");
        $display("Expected output: ERROR");
        
        enter_number(8'd1);
        $display("  Entered: 1");
        
        enter_number(8'd1);
        $display("  Entered: 1");
        
        enter_number(8'd3);
        $display("  Entered: 3 (INVALID!)");
        
        check_case(8'd0, 8'd0, 8'd0, 8'd0, 1, "CASE 2: 1,1,3");
        
        // Reset for next case
        rst = 1;
        #1000;
        rst = 0;
        #10000;
        uart_count = 0;
        
        //====================================================================
        // CASE 3: Valid sequence (2, 3, 5)
        //====================================================================
        $display("\n\n[CASE 3] Entering valid sequence: 2, 3, 5");
        $display("Expected output: 8, 13, 21, 34");
        
        enter_number(8'd2);
        $display("  Entered: 2");
        
        enter_number(8'd3);
        $display("  Entered: 3");
        
        enter_number(8'd5);
        $display("  Entered: 5");
        
        check_case(8'd8, 8'd13, 8'd21, 8'd34, 0, "CASE 3: 2,3,5");
        
        //====================================================================
        // Final Summary
        //====================================================================
        $display("\n\n========================================");
        $display("Test Complete");
        $display("========================================");
        $display("All three cases executed:");
        $display("  1. Valid (1,1,2) → 3,5,8,13");
        $display("  2. Invalid (1,1,3) → ERROR");
        $display("  3. Valid (2,3,5) → 8,13,21,34");
        $display("\nTotal output activity:");
        $display("  UART bytes: %0d", uart_count);
        $display("  OLED bits: %0d", oled_count);
        $display("  VGA frames: %0d", vga_frames);
        $display("========================================\n");
        
        #100000;
        $finish;
    end
    
    // Timeout
    initial begin
        #5_000_000;  // 5ms max
        $display("\n[TIMEOUT] Test timeout");
        $finish;
    end

endmodule
