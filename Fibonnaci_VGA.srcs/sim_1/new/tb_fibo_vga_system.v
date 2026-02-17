`timescale 1ns / 1ps

module tb_fibo_vga_system;

    // Clock and reset
    reg clk;
    reg btnr;
    
    // Inputs
    reg [7:0] sw;
    reg btnc;
    
    // Outputs
    wire [7:0] led;
    wire [3:0] vga_r, vga_g, vga_b;
    wire hsync, vsync;
    
    // Instantiate DUT
    fibo_vga_top dut (
        .clk(clk),
        .sw(sw),
        .btnc(btnc),
        .btnr(btnr),
        .led(led),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .hsync(hsync),
        .vsync(vsync)
    );
    
    // Clock generation (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;
    
    // VGA frame counter
    integer frame_count = 0;
    reg last_vsync = 1;
    
    always @(posedge clk) begin
        if (!last_vsync && vsync) begin
            frame_count = frame_count + 1;
            if (frame_count % 10 == 0)
                $display("Time %0t: Frame %0d rendered", $time, frame_count);
        end
        last_vsync = vsync;
    end
    
    // Test stimulus
    initial begin
        $display("=== VGA Fibonacci System Testbench ===");
        $display("Starting simulation...\n");
        
        // Initialize
        btnr = 1;
        btnc = 0;
        sw = 0;
        #100;
        btnr = 0;
        #100;
        
        $display("Test 1: Valid sequence (1, 1, 2) -> Expected: 3, 5, 8, 13");
        
        // Enter first number: 1
        sw = 8'd1;
        #20_000;  // Wait for debounce
        btnc = 1;
        #20_000;
        btnc = 0;
        $display("  Entered num1 = 1");
        #50_000;
        
        // Enter second number: 1
        sw = 8'd1;
        #20_000;
        btnc = 1;
        #20_000;
        btnc = 0;
        $display("  Entered num2 = 1");
        #50_000;
        
        // Enter third number: 2
        sw = 8'd2;
        #20_000;
        btnc = 1;
        #20_000;
        btnc = 0;
        $display("  Entered num3 = 2");
        
        // Wait for generation to complete
        $display("  Waiting for Fibonacci generation...");
        #500_000_000;  // Wait for 4 generations @ 10Hz = ~400ms
        
        $display("  Results displayed on VGA");
        $display("  LED status: %b", led);
        
        // Wait a few frames
        #100_000_000;
        
        $display("\nTest 2: Invalid sequence (1, 1, 3) -> Expected: ERR");
        
        // Reset
        btnr = 1;
        #1000;
        btnr = 0;
        #100_000;
        
        // Enter first number: 1
        sw = 8'd1;
        #20_000;
        btnc = 1;
        #20_000;
        btnc = 0;
        $display("  Entered num1 = 1");
        #50_000;
        
        // Enter second number: 1
        sw = 8'd1;
        #20_000;
        btnc = 1;
        #20_000;
        btnc = 0;
        $display("  Entered num2 = 1");
        #50_000;
        
        // Enter third number: 3 (invalid)
        sw = 8'd3;
        #20_000;
        btnc = 1;
        #20_000;
        btnc = 0;
        $display("  Entered num3 = 3");
        
        // Wait for error display
        #100_000_000;
        $display("  ERROR displayed on VGA");
        $display("  LED status: %b", led);
        
        // Wait a few more frames
        #100_000_000;
        
        $display("\n=== Simulation Complete ===");
        $display("Total frames rendered: %0d", frame_count);
        $display("Simulation time: %0t", $time);
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #2_000_000_000;  // 2 seconds max
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
