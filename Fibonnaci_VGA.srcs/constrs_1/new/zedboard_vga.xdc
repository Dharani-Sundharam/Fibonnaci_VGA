## Clock Signal (100MHz)
set_property -dict { PACKAGE_PIN Y9 IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## Switches (SW0-SW7)
set_property -dict { PACKAGE_PIN F22 IOSTANDARD LVCMOS25 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN G22 IOSTANDARD LVCMOS25 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN H22 IOSTANDARD LVCMOS25 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN F21 IOSTANDARD LVCMOS25 } [get_ports { sw[3] }];
set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS25 } [get_ports { sw[4] }];
set_property -dict { PACKAGE_PIN H18 IOSTANDARD LVCMOS25 } [get_ports { sw[5] }];
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS25 } [get_ports { sw[6] }];
set_property -dict { PACKAGE_PIN M15 IOSTANDARD LVCMOS25 } [get_ports { sw[7] }];

## Buttons
set_property -dict { PACKAGE_PIN P16 IOSTANDARD LVCMOS25 } [get_ports { btnc }];
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS25 } [get_ports { btnr }];

## LEDs (LD0-LD7)
set_property -dict { PACKAGE_PIN T22 IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN T21 IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN U22 IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN U21 IOSTANDARD LVCMOS33 } [get_ports { led[3] }];
set_property -dict { PACKAGE_PIN V22 IOSTANDARD LVCMOS33 } [get_ports { led[4] }];
set_property -dict { PACKAGE_PIN W22 IOSTANDARD LVCMOS33 } [get_ports { led[5] }];
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports { led[6] }];
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports { led[7] }];

## VGA Connector
# Red (4-bit)
set_property -dict { PACKAGE_PIN V20 IOSTANDARD LVCMOS33 } [get_ports { vga_r[0] }];
set_property -dict { PACKAGE_PIN U20 IOSTANDARD LVCMOS33 } [get_ports { vga_r[1] }];
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports { vga_r[2] }];
set_property -dict { PACKAGE_PIN V18 IOSTANDARD LVCMOS33 } [get_ports { vga_r[3] }];

# Green (4-bit)
set_property -dict { PACKAGE_PIN AB22 IOSTANDARD LVCMOS33 } [get_ports { vga_g[0] }];
set_property -dict { PACKAGE_PIN AA22 IOSTANDARD LVCMOS33 } [get_ports { vga_g[1] }];
set_property -dict { PACKAGE_PIN AB21 IOSTANDARD LVCMOS33 } [get_ports { vga_g[2] }];
set_property -dict { PACKAGE_PIN AA21 IOSTANDARD LVCMOS33 } [get_ports { vga_g[3] }];

# Blue (4-bit)
set_property -dict { PACKAGE_PIN Y21 IOSTANDARD LVCMOS33 } [get_ports { vga_b[0] }];
set_property -dict { PACKAGE_PIN Y20 IOSTANDARD LVCMOS33 } [get_ports { vga_b[1] }];
set_property -dict { PACKAGE_PIN AB20 IOSTANDARD LVCMOS33 } [get_ports { vga_b[2] }];
set_property -dict { PACKAGE_PIN AB19 IOSTANDARD LVCMOS33 } [get_ports { vga_b[3] }];

# Sync signals
set_property -dict { PACKAGE_PIN AA19 IOSTANDARD LVCMOS33 } [get_ports { hsync }];
set_property -dict { PACKAGE_PIN Y19 IOSTANDARD LVCMOS33 } [get_ports { vsync }];
