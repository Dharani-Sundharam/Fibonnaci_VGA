`timescale 1ns / 1ps
//==============================================================================
// OLED Controller for Fibonacci Validator with Text Rendering
// Based on Digilent OLEDCtrl, adapted for simple text display
//==============================================================================

module oled_ctrl (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  display_mode,
    input  wire [7:0]  result0,
    input  wire [7:0]  result1,
    input  wire [7:0]  result2,
    input  wire [7:0]  result3,
    output wire        oled_sclk,
    output wire        oled_sdin,
    output reg         oled_dc,
    output reg         oled_res,
    output reg         oled_vbat,
    output reg         oled_vdd
);

    // States
    localparam IDLE = 0, VDD_ON = 1, RESET_LOW = 2, RESET_HIGH = 3;
    localparam VBAT_ON = 4, INIT = 5, CLEAR = 6, WRITE_TEXT = 7;
    localparam READY = 8, SPI_WAIT = 9, DELAY_WAIT = 10;
    
    reg [3:0] state = IDLE;
    reg [3:0] after_state = IDLE;
    reg [4:0] init_idx = 0;
    reg [9:0] clear_cnt = 0;
    reg [5:0] text_idx = 0;
    reg [2:0] char_col = 0;
    reg [2:0] prev_mode = 7;
    
    // SPI interface
    reg spi_start = 0;
    reg [7:0] spi_data = 0;
    wire spi_ready;
    wire spi_cs;
    
    SpiCtrl spi (
        .clk(clk),
        .send_start(spi_start),
        .send_data(spi_data),
        .send_ready(spi_ready),
        .CS(spi_cs),
        .SDO(oled_sdin),
        .SCLK(oled_sclk)
    );
    
    // Delay controller
    reg delay_start = 0;
    reg [11:0] delay_ms = 0;
    wire delay_done;
    
    delay_ms delayer (
        .clk(clk),
        .delay_time_ms(delay_ms),
        .delay_start(delay_start),
        .delay_done(delay_done)
    );
    
    // Simple 5x8 font ROM
    function [39:0] get_char;
        input [7:0] ascii;
        case (ascii)
            8'h20: get_char = 40'h0000000000;  // Space
            8'h21: get_char = 40'h005F000000;  // !
            8'h30: get_char = 40'h3E51494541;  // 0
            8'h31: get_char = 40'h007F400000;  // 1
            8'h32: get_char = 40'h7249494946;  // 2
            8'h33: get_char = 40'h2141494936;  // 3
            8'h34: get_char = 40'h0F08087F08;  // 4
            8'h35: get_char = 40'h2745454539;  // 5
            8'h36: get_char = 40'h3E49493200;  // 6
            8'h37: get_char = 40'h0101710901;  // 7
            8'h38: get_char = 40'h3649493600;  // 8
            8'h39: get_char = 40'h2649493E00;  // 9
            8'h41: get_char = 40'h7E09097E00;  // A
            8'h43: get_char = 40'h3E41414100;  // C
            8'h44: get_char = 40'h7F41413E00;  // D
            8'h45: get_char = 40'h7F49494100;  // E
            8'h46: get_char = 40'h7F09090100;  // F
            8'h49: get_char = 40'h00417F4100;  // I
            8'h4D: get_char = 40'h7F02047F00;  // M
            8'h4E: get_char = 40'h7F04087F00;  // N
            8'h4F: get_char = 40'h3E41413E00;  // O
            8'h52: get_char = 40'h7F09193600;  // R
            8'h53: get_char = 40'h2649493200;  // S
            8'h54: get_char = 40'h01017F0101;  // T
            8'h59: get_char = 40'h0103047803;  // Y
            default: get_char = 40'h0000000000;
        endcase
    endfunction
    
    // Text buffer
    reg [7:0] text [0:15];
    reg [3:0] text_len;
    
    // Helper: binary to decimal ASCII
    function [7:0] bin2ascii;
        input [7:0] digit;
        bin2ascii = 8'h30 + digit;  // '0' + digit
    endfunction
    
    // Convert 8-bit binary to 3 decimal digits
    function [23:0] bin2dec;
        input [7:0] bin;
        reg [7:0] hundreds, tens, ones;
        begin
            hundreds = bin / 100;
            tens = (bin % 100) / 10;
            ones = bin % 10;
            bin2dec = {hundreds, tens, ones};
        end
    endfunction
    
    // Load text based on mode
    task load_text;
        input [2:0] mode;
        reg [23:0] dec0, dec1, dec2, dec3;
        case (mode)
            3'd0: begin  // IDLE - "SYSTEM READY"
                text[0]="S"; text[1]="Y"; text[2]="S"; text[3]="T";
                text[4]="E"; text[5]="M"; text[6]=" "; text[7]="R";
                text[8]="E"; text[9]="A"; text[10]="D"; text[11]="Y";
                text_len = 12;
            end
            3'd4: begin  // DONE - decimal format "3 5 8 13"
                dec0 = bin2dec(result0);
                dec1 = bin2dec(result1);
                dec2 = bin2dec(result2);
                dec3 = bin2dec(result3);
                // Format: show only non-zero leading digits
                text[0] = bin2ascii(dec0[23:16] ? dec0[23:16] : (dec0[15:8] ? 8'h20 : 8'h20));
                text[1] = bin2ascii(dec0[23:16] | dec0[15:8] ? dec0[15:8] : 8'h20);
                text[2] = bin2ascii(dec0[7:0]);
                text[3] = " ";
                text[4] = bin2ascii(dec1[23:16] ? dec1[23:16] : (dec1[15:8] ? 8'h20 : 8'h20));
                text[5] = bin2ascii(dec1[23:16] | dec1[15:8] ? dec1[15:8] : 8'h20);
                text[6] = bin2ascii(dec1[7:0]);
                text[7] = " ";
                text[8] = bin2ascii(dec2[7:0]);
                text[9] = " ";
                text[10] = bin2ascii(dec3[7:0]);
                text_len = 11;
            end
            3'd5: begin  // ERROR - "ERROR!"
                text[0]="E"; text[1]="R"; text[2]="R"; text[3]="O";
                text[4]="R"; text[5]="!";
                text_len = 6;
            end
            default: text_len = 0;
        endcase
    endtask
    
    // Init sequence
    function [7:0] get_init_cmd;
        input [4:0] idx;
        case (idx)
            0: get_init_cmd=8'hAE; 1: get_init_cmd=8'hD5; 2: get_init_cmd=8'h80;
            3: get_init_cmd=8'hA8; 4: get_init_cmd=8'h1F; 5: get_init_cmd=8'hD3;
            6: get_init_cmd=8'h00; 7: get_init_cmd=8'h40; 8: get_init_cmd=8'h8D;
            9: get_init_cmd=8'h14; 10: get_init_cmd=8'h20; 11: get_init_cmd=8'h00;
            12: get_init_cmd=8'hA1; 13: get_init_cmd=8'hC8; 14: get_init_cmd=8'hDA;
            15: get_init_cmd=8'h02; 16: get_init_cmd=8'h81; 17: get_init_cmd=8'h8F;
            18: get_init_cmd=8'hD9; 19: get_init_cmd=8'hF1; 20: get_init_cmd=8'hDB;
            21: get_init_cmd=8'h40; 22: get_init_cmd=8'hA4; 23: get_init_cmd=8'hA6;
            24: get_init_cmd=8'hAF;
            default: get_init_cmd=8'h00;
        endcase
    endfunction
    
    reg [39:0] char_bitmap;
    
    // Main FSM
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            oled_vdd <= 1;
            oled_vbat <= 1;
            oled_res <= 0;
            oled_dc <= 0;
            spi_start <= 0;
            delay_start <= 0;
            prev_mode <= 7;
        end else begin
            case (state)
                IDLE: begin
                    oled_vdd <= 0;
                    delay_ms <= 1;
                    delay_start <= 1;
                    after_state <= VDD_ON;
                    state <= DELAY_WAIT;
                end
                
                VDD_ON: begin
                    oled_vdd <= 1;
                    delay_ms <= 25;
                    delay_start <= 1;
                    after_state <= RESET_LOW;
                    state <= DELAY_WAIT;
                end
                
                RESET_LOW: begin
                    oled_res <= 0;
                    delay_ms <= 3;
                    delay_start <= 1;
                    after_state <= RESET_HIGH;
                    state <= DELAY_WAIT;
                end
                
                RESET_HIGH: begin
                    oled_res <= 1;
                    delay_ms <= 3;
                    delay_start <= 1;
                    after_state <= VBAT_ON;
                    state <= DELAY_WAIT;
                end
                
                VBAT_ON: begin
                    oled_vbat <= 0;
                    delay_ms <= 100;
                    delay_start <= 1;
                    after_state <= INIT;
                    init_idx <= 0;
                    state <= DELAY_WAIT;
                end
                
                INIT: begin
                    if (init_idx < 25) begin
                        oled_dc <= 0;
                        spi_data <= get_init_cmd(init_idx);
                        spi_start <= 1;
                        after_state <= INIT;
                        init_idx <= init_idx + 1;
                        state <= SPI_WAIT;
                    end else begin
                        clear_cnt <= 0;
                        state <= CLEAR;
                    end
                end
                
                CLEAR: begin
                    if (clear_cnt < 512) begin
                        oled_dc <= 1;
                        spi_data <= 8'h00;
                        spi_start <= 1;
                        after_state <= CLEAR;
                        clear_cnt <= clear_cnt + 1;
                        state <= SPI_WAIT;
                    end else begin
                        load_text(display_mode);
                        prev_mode <= display_mode;
                        text_idx <= 0;
                        char_col <= 0;
                        state <= WRITE_TEXT;
                    end
                end
                
                WRITE_TEXT: begin
                    if (text_idx < text_len) begin
                        char_bitmap = get_char(text[text_idx]);
                        oled_dc <= 1;
                        spi_data <= char_bitmap[39 - char_col*8 -: 8];
                        spi_start <= 1;
                        after_state <= WRITE_TEXT;
                        
                        if (char_col == 4) begin
                            char_col <= 0;
                            text_idx <= text_idx + 1;
                        end else begin
                            char_col <= char_col + 1;
                        end
                        state <= SPI_WAIT;
                    end else begin
                        state <= READY;
                    end
                end
                
                READY: begin
                    if (display_mode != prev_mode) begin
                        load_text(display_mode);
                        prev_mode <= display_mode;
                        text_idx <= 0;
                        char_col <= 0;
                        clear_cnt <= 0;
                        state <= CLEAR;
                    end
                end
                
                SPI_WAIT: begin
                    spi_start <= 0;
                    if (spi_ready) state <= after_state;
                end
                
                DELAY_WAIT: begin
                    delay_start <= 0;
                    if (delay_done) state <= after_state;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
