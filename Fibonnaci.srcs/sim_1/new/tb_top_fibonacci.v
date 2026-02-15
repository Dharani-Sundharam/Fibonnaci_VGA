`timescale 1ns / 1ps
//============================================================================
// Testbench: tb_top_fibonacci
//
// Minimal testbench template with core simulation infrastructure.
// Add your own test scenarios in the initial block below.
//
// Run in Vivado:  restart ; run all
//============================================================================

module tb_top_fibonacci;

    // === Parameters ===
    localparam DEBOUNCE_DELAY = 1;      // Fast debounce for simulation
    localparam CLK_PERIOD = 10;         // 100 MHz → 10 ns period
    localparam CLKS_PER_BIT = 100_000_000 / 9600;  // UART: 10,417 cycles/bit

    // === DUT Signals ===
    reg        clk;
    reg  [7:0] sw;
    reg        btnc, btnr;
    wire [7:0] led;
    wire       uart_txd;

    // === DUT Instantiation ===
    top_fibonacci #(
        .DEBOUNCE_DELAY(DEBOUNCE_DELAY)
    ) uut (
        .clk(clk),
        .sw(sw),
        .btnc(btnc),
        .btnr(btnr),
        .led(led),
        .uart_txd(uart_txd)
    );

    // === Clock Generation (100 MHz) ===
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =====================================================================
    // UART Monitor — Decodes uart_txd and prints to console
    // =====================================================================
    reg [7:0] uart_rx_byte;
    reg [3:0] uart_rx_bit_index;
    reg [15:0] uart_rx_timer;
    reg [1:0] uart_rx_state;

    localparam UART_IDLE  = 2'd0;
    localparam UART_START = 2'd1;
    localparam UART_DATA  = 2'd2;
    localparam UART_STOP  = 2'd3;

    // Edge detection for start bit
    reg uart_txd_prev;
    
    initial begin
        uart_rx_state = UART_IDLE;
        uart_rx_byte = 0;
        uart_rx_bit_index = 0;
        uart_rx_timer = 0;
        uart_txd_prev = 1;
    end

    always @(posedge clk) begin
        uart_txd_prev <= uart_txd;  // Track previous value
        
        case (uart_rx_state)
            UART_IDLE: begin
                uart_rx_timer <= 0;
                // Detect falling edge: previous=1, current=0
                if (uart_txd_prev == 1 && uart_txd == 0) begin
                    uart_rx_state <= UART_START;
                end
            end

            UART_START: begin
                if (uart_rx_timer == (CLKS_PER_BIT / 2)) begin
                    // We're now at the middle of the start bit
                    uart_rx_timer <= 0;
                    uart_rx_bit_index <= 0;
                    uart_rx_state <= UART_DATA;
                end else
                    uart_rx_timer <= uart_rx_timer + 1;
            end

            UART_DATA: begin
                if (uart_rx_timer == CLKS_PER_BIT - 1) begin
                    uart_rx_byte[uart_rx_bit_index] <= uart_txd;  // Capture bit
                    uart_rx_timer <= 0;
                    if (uart_rx_bit_index == 7)
                        uart_rx_state <= UART_STOP;
                    else
                        uart_rx_bit_index <= uart_rx_bit_index + 1;
                end else
                    uart_rx_timer <= uart_rx_timer + 1;
            end

            UART_STOP: begin
                if (uart_rx_timer == CLKS_PER_BIT - 1) begin
                    // Byte received - print to console
                    if (uart_rx_byte >= 32 && uart_rx_byte < 127)
                        $write("%c", uart_rx_byte);  // Printable ASCII
                    else if (uart_rx_byte == 8'h0D)
                        $display("");  // CR → newline
                    else
                        $write("[0x%02h]", uart_rx_byte);  // Non-printable (hex)
                    
                    uart_rx_state <= UART_IDLE;
                    uart_rx_timer <= 0;
                end else
                    uart_rx_timer <= uart_rx_timer + 1;
            end
        endcase
    end

    // =====================================================================
    // Helper Tasks
    // =====================================================================

    // Press the enter button (BTNC)
    task press_enter;
        begin
            btnc = 1;
            #(5 * CLK_PERIOD);
            btnc = 0;
            #(10 * CLK_PERIOD);
        end
    endtask

    // Press the reset button (BTNR)
    task press_reset;
        begin
            btnr = 1;
            #(5 * CLK_PERIOD);
            btnr = 0;
            #(10 * CLK_PERIOD);
        end
    endtask

    // Wait for N clock cycles
    task wait_cycles;
        input integer n;
        begin
            #(n * CLK_PERIOD);
        end
    endtask

    // =====================================================================
    // Test Sequence — ADD YOUR TEST SCENARIOS HERE
    // =====================================================================
    initial begin
        // Initialize all inputs
        sw = 0;
        btnc = 0;
        btnr = 0;

        $display("============================================================");
        $display("  Fibonacci Validator & Generator");
        $display("  UART Output:");
        $display("============================================================\n");

        // Initial reset (clears all registers from 'x' state)
        wait_cycles(3);
        press_reset;
        wait_cycles(20);

        // ─────────────────────────────────────────────────────────────────
        // Test: Valid sequence 1, 1, 2 → 3, 5, 8, 13
        // ─────────────────────────────────────────────────────────────────
        
        sw = 8'd1;   press_enter;   // num1 = 1
        sw = 8'd1;   press_enter;   // num2 = 1
        sw = 8'd2;   press_enter;   // num3 = 2
        wait_cycles(30);

        // ─────────────────────────────────────────────────────────────────

        // Wait for UART transmission to complete (~13.5 ms)
        wait_cycles(1_500_000);
        
        $display("\n============================================================");
        $display("  Simulation complete.");
        $display("============================================================\n");

        $finish;
    end

    // === Waveform Dump (for Vivado viewer) ===
    initial begin
        $dumpfile("tb_top_fibonacci.vcd");
        $dumpvars(0, tb_top_fibonacci);
    end

endmodule
