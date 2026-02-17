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
    
    // 100MHz clock
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Simulate button press (short pulse instead of waiting for debounce)
    task press_btn;
    begin
        btnc = 1; #100;
        btnc = 0; #100;
    end
    endtask
    
    initial begin
        // Initialize
        btnr = 1; sw = 0; btnc = 0;
        #1000;
        btnr = 0;
        #1000;
        
        // Enter num1 = 1
        sw = 8'd1;
        #100;
        press_btn;
        #500;
        
        // Enter num2 = 1
        sw = 8'd1;
        #100;
        press_btn;
        #500;
        
        // Enter num3 = 2
        sw = 8'd2;
        #100;
        press_btn;
        #500;
        
        // Wait for validation and a few generation steps
        // In simulation, gen_timer counts to 100M which is too slow
        // Just let it run for a bit to verify no crashes
        #50000;
        
        $display("=== Simulation Complete ===");
        $display("Value count: %d", dut.value_count);
        $display("LED state: %b", led);
        $display("show_generating: %b", dut.show_generating);
        $display("gen_overflow: %b", dut.gen_overflow);
        
        $finish;
    end

endmodule
