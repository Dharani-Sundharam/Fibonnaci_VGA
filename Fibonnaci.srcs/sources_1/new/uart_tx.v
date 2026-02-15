`timescale 1ns / 1ps
//============================================================================
// Module:  uart_tx
// Purpose: Simple UART transmitter, 8-N-1, parameterizable baud rate.
//
// Why UART?
//   The ZedBoard's onboard USB-UART is wired to the PS (ARM) side, which
//   we can't use in a pure-PL design. Instead, we route TX to Pmod JA1
//   (pin Y11) so judges can see the latency count on a serial terminal.
//
// Protocol: 8-N-1
//   [START=0] [D0] [D1] [D2] [D3] [D4] [D5] [D6] [D7] [STOP=1]
//
// Parameter:
//   CLK_FREQ  - System clock frequency (default 100 MHz)
//   BAUD_RATE - Target baud rate (default 9600)
//============================================================================

module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] tx_data,    // Byte to transmit
    input  wire       tx_start,   // Pulse to begin transmission
    output reg        tx_out,     // Serial output line (active-low start bit)
    output reg        tx_busy     // HIGH while transmitting
);

    // Baud rate divider: number of clock cycles per UART bit
    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;  // 10417 for 100M/9600
    localparam DIV_W    = $clog2(BAUD_DIV + 1);

    // State encoding
    localparam S_IDLE  = 2'b00;
    localparam S_START = 2'b01;
    localparam S_DATA  = 2'b10;
    localparam S_STOP  = 2'b11;

    reg [1:0]        state;
    reg [DIV_W-1:0]  baud_cnt;    // Counts clocks per bit
    reg [2:0]        bit_idx;     // Which data bit (0-7)
    reg [7:0]        tx_shift;    // Shift register holding current byte

    // ------------------------------------------------------------------
    // Baud tick generator
    // ------------------------------------------------------------------
    wire baud_tick = (baud_cnt == BAUD_DIV - 1);

    always @(posedge clk) begin
        if (rst || state == S_IDLE)
            baud_cnt <= 0;
        else if (baud_tick)
            baud_cnt <= 0;
        else
            baud_cnt <= baud_cnt + 1;
    end

    // ------------------------------------------------------------------
    // TX state machine
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            tx_out   <= 1'b1;     // Line idles HIGH
            tx_busy  <= 1'b0;
            bit_idx  <= 3'd0;
            tx_shift <= 8'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    tx_out  <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        state    <= S_START;
                        tx_shift <= tx_data;
                        tx_busy  <= 1'b1;
                    end
                end

                S_START: begin
                    tx_out <= 1'b0;         // Start bit = LOW
                    if (baud_tick)
                        state <= S_DATA;
                end

                S_DATA: begin
                    tx_out <= tx_shift[0];  // LSB first
                    if (baud_tick) begin
                        tx_shift <= {1'b0, tx_shift[7:1]};  // Shift right
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state   <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end
                end

                S_STOP: begin
                    tx_out <= 1'b1;         // Stop bit = HIGH
                    if (baud_tick)
                        state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
