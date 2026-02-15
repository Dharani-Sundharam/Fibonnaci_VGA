`timescale 1ns / 1ps
//============================================================================
// Module:  uart_tx
// Purpose: UART transmitter with parity support, 8-E-1 format.
//
// Protocol: 8-E-1 (8 data bits, Even parity, 1 stop bit)
//   [START=0] [D0] [D1] [D2] [D3] [D4] [D5] [D6] [D7] [PARITY] [STOP=1]
//
// Parameters:
//   CLK_FREQ    - System clock frequency (default 100 MHz)
//   BAUD_RATE   - Target baud rate (default 9600)
//   PARITY_EN   - Enable parity bit (default 1)
//   PARITY_ODD  - Use odd parity if 1, even parity if 0 (default 0)
//============================================================================

module uart_tx #(
    parameter CLK_FREQ   = 100_000_000,
    parameter BAUD_RATE  = 9600,
    parameter PARITY_EN  = 1,      // Enable parity
    parameter PARITY_ODD = 0       // 0=even, 1=odd
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] tx_data,    // Byte to transmit
    input  wire       tx_start,   // Pulse to begin transmission
    output reg        tx_out,     // Serial output line
    output reg        tx_busy     // HIGH while transmitting
);

    // Baud rate divider
    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;
    localparam DIV_W    = $clog2(BAUD_DIV + 1);

    // State encoding
    localparam S_IDLE   = 3'b000;
    localparam S_START  = 3'b001;
    localparam S_DATA   = 3'b010;
    localparam S_PARITY = 3'b011;
    localparam S_STOP   = 3'b100;

    reg [2:0]        state;
    reg [DIV_W-1:0]  baud_cnt;
    reg [2:0]        bit_idx;
    reg [7:0]        tx_shift;
    reg              parity_bit;

    // Baud tick generator
    wire baud_tick = (baud_cnt == BAUD_DIV - 1);

    always @(posedge clk) begin
        if (rst || state == S_IDLE)
            baud_cnt <= 0;
        else if (baud_tick)
            baud_cnt <= 0;
        else
            baud_cnt <= baud_cnt + 1;
    end

    // Calculate parity (even parity = XOR of all data bits)
    wire calc_parity = PARITY_ODD ? ~(^tx_data) : (^tx_data);

    // TX state machine
    always @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            tx_out     <= 1'b1;
            tx_busy    <= 1'b0;
            bit_idx    <= 3'd0;
            tx_shift   <= 8'd0;
            parity_bit <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    tx_out  <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        state      <= S_START;
                        tx_shift   <= tx_data;
                        parity_bit <= calc_parity;
                        tx_busy    <= 1'b1;
                    end
                end

                S_START: begin
                    tx_out <= 1'b0;  // Start bit
                    if (baud_tick)
                        state <= S_DATA;
                end

                S_DATA: begin
                    tx_out <= tx_shift[0];  // LSB first
                    if (baud_tick) begin
                        tx_shift <= {1'b0, tx_shift[7:1]};
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state   <= PARITY_EN ? S_PARITY : S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end
                end

                S_PARITY: begin
                    tx_out <= parity_bit;
                    if (baud_tick)
                        state <= S_STOP;
                end

                S_STOP: begin
                    tx_out <= 1'b1;  // Stop bit
                    if (baud_tick)
                        state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
