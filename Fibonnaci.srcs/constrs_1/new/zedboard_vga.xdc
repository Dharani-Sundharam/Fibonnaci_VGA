## VGA Display Pins - ZedBoard
## 12-bit color (4R, 4G, 4B) + H/V Sync

## VGA Red [3:0]
set_property PACKAGE_PIN V20 [get_ports {vga_r[0]}]
set_property PACKAGE_PIN U20 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN V19 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN V18 [get_ports {vga_r[3]}]

## VGA Green [3:0]
set_property PACKAGE_PIN AB22 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN AA22 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN AB21 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN AA21 [get_ports {vga_g[3]}]

## VGA Blue [3:0]
set_property PACKAGE_PIN Y21 [get_ports {vga_b[0]}]
set_property PACKAGE_PIN Y20 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN AB20 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN AB19 [get_ports {vga_b[3]}]

## VGA Sync Signals
set_property PACKAGE_PIN AA19 [get_ports vga_hsync]
set_property PACKAGE_PIN Y19  [get_ports vga_vsync]

## I/O Standard - All VGA pins use LVCMOS33 (3.3V)
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vsync]

## Slew Rate - FAST for video signals
set_property SLEW FAST [get_ports {vga_r[*]}]
set_property SLEW FAST [get_ports {vga_g[*]}]
set_property SLEW FAST [get_ports {vga_b[*]}]
set_property SLEW FAST [get_ports vga_hsync]
set_property SLEW FAST [get_ports vga_vsync]
