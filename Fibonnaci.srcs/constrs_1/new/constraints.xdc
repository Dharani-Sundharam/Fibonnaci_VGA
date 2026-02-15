## ============================================================================
## ZedBoard (Zynq-7000 XC7Z020-CLG484-1) Constraints File
## Project: Fibonacci Sequence Validator & Generator
##
## Pin assignments sourced from the ZedBoard Hardware User's Guide.
## IO standards: Switches/Buttons on 2.5V banks = LVCMOS25
##               LEDs/Pmod on 3.3V banks = LVCMOS33
## ============================================================================

## ----------------------------------------------------------------------------
## Clock — 100 MHz Oscillator
## ----------------------------------------------------------------------------
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]

## ----------------------------------------------------------------------------
## Slide Switches (Active-high, directly readable)
## Bank: LVCMOS25
## ----------------------------------------------------------------------------
set_property PACKAGE_PIN F22 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {sw[0]}]

set_property PACKAGE_PIN G22 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {sw[1]}]

set_property PACKAGE_PIN H22 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {sw[2]}]

set_property PACKAGE_PIN F21 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {sw[3]}]

set_property PACKAGE_PIN H19 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {sw[4]}]

set_property PACKAGE_PIN H18 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {sw[5]}]

set_property PACKAGE_PIN H17 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {sw[6]}]

set_property PACKAGE_PIN M15 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {sw[7]}]

## ----------------------------------------------------------------------------
## Push Buttons (Active-high with internal pull-down on ZedBoard)
## Bank: LVCMOS25
## ----------------------------------------------------------------------------
## BTNC — Center button (used as "Enter")
set_property PACKAGE_PIN P16 [get_ports btnc]
set_property IOSTANDARD LVCMOS25 [get_ports btnc]

## BTNR — Right button (used as "Reset")
set_property PACKAGE_PIN R18 [get_ports btnr]
set_property IOSTANDARD LVCMOS25 [get_ports btnr]

## ----------------------------------------------------------------------------
## User LEDs (Active-high)
## Bank: LVCMOS33
## ----------------------------------------------------------------------------
set_property PACKAGE_PIN T22 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN T21 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN U22 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN U21 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

set_property PACKAGE_PIN V22 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

set_property PACKAGE_PIN W22 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

set_property PACKAGE_PIN U19 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

set_property PACKAGE_PIN U14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

## ----------------------------------------------------------------------------
## UART TX — Pmod JA1 (since onboard UART is PS-only)
## Used for latency counter debug output
## Bank: LVCMOS33
## ----------------------------------------------------------------------------
set_property PACKAGE_PIN Y11 [get_ports uart_txd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_txd]

## ----------------------------------------------------------------------------
## OLED Display — UG-2832HSWEG04 (SSD1306, 128x32 pixels)
## 4-wire SPI interface + power control
## Bank: LVCMOS33
## ----------------------------------------------------------------------------
set_property PACKAGE_PIN AB12 [get_ports oled_dc]
set_property IOSTANDARD LVCMOS33 [get_ports oled_dc]

set_property PACKAGE_PIN AA12 [get_ports oled_res]
set_property IOSTANDARD LVCMOS33 [get_ports oled_res]

set_property PACKAGE_PIN U10 [get_ports oled_sclk]
set_property IOSTANDARD LVCMOS33 [get_ports oled_sclk]

set_property PACKAGE_PIN U9 [get_ports oled_sdin]
set_property IOSTANDARD LVCMOS33 [get_ports oled_sdin]

set_property PACKAGE_PIN U11 [get_ports oled_vbat]
set_property IOSTANDARD LVCMOS33 [get_ports oled_vbat]

set_property PACKAGE_PIN U12 [get_ports oled_vdd]
set_property IOSTANDARD LVCMOS33 [get_ports oled_vdd]

## ============================================================================
## End of constraints
## ============================================================================
