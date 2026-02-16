`timescale 1ns / 1ps

// Simple testbench to check UART and VGA signals
module tb_quick_check;
    reg clk = 0;
    reg rst = 1;
    reg [7:0] sw = 0;
    reg btn_enter = 0;
    
    wire [7:0] led;
    wire uart_txd;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync;
    wire oled_sclk, oled_sdin, oled_dc, oled_res, oled_vbat, oled_vdd;
    
    fibonacci_vga_top #(.DEBOUNCE_DELAY(100)) uut (
        .clk(clk), .rst(rst), .sw(sw), .btn_enter(btn_enter), .led(led),
        .uart_txd(uart_txd), .oled_sclk(oled_sclk), .oled_sdin(oled_sdin),
        .oled_dc(oled_dc), .oled_res(oled_res), .oled_vbat(oled_vbat), .oled_vdd(oled_vdd),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b), 
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync)
    );
    
    always #5 clk = ~clk;
    
    // Monitor internal FSM signals
    initial begin
        $display("Monitoring FSM and output signals...\n");
        forever begin
            #1000000;  // Every 1ms
            $display("[%0t] FSM state=%0d, uart_send=%b, show_done=%b, show_error=%b",
                     $time, 
                     uut.u_fibo_core.u_fsm.current_state,
                     uut.u_fibo_core.u_fsm.uart_send_results,
                     uut.show_done,
                     uut.show_error);
            $display("       VGA: R=%h G=%h B=%h, startup=%b, mode=%0d",
                     vga_r, vga_g, vga_b,
                     uut.u_vga.startup_mode,
                     uut.u_vga.display_mode);
            $display("       UART: txd=%b, sent_flag=%b", uart_txd, uut.u_fibo_core.sent_flag);
        end
    end
    
    initial begin
        rst = 1;
        #200;
        rst = 0;
        #50000;
        
        // Enter 1, 1, 2
        sw = 1; #2000; btn_enter = 1; #5000; btn_enter = 0; #50000;
        sw = 1; #2000; btn_enter = 1; #5000; btn_enter = 0; #50000;
        sw = 2; #2000; btn_enter = 1; #5000; btn_enter = 0;
        
        $display("\n==> Sequence entered, waiting for results...\n");
        
        #5_000_000;  // Wait 5ms
        
        $display("\n==> Final check:");
        $display("Results: %0d, %0d, %0d, %0d", 
                 uut.result0, uut.result1, uut.result2, uut.result3);
        $finish;
    end
    
    initial begin
        #10_000_000;
        $display("\nTimeout!");
        $finish;
    end
endmodule
