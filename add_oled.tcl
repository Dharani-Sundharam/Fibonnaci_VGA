# Add all OLED modules to Vivado project
puts "Adding OLED controller modules to project..."

# Add OLED controller and dependencies
add_files -norecurse {C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/oled_ctrl.v}
add_files -norecurse {C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/SpiCtrl.v}
add_files -norecurse {C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/delay_ms.v}

# Update compile order
update_compile_order -fileset sources_1

puts "OLED modules added successfully!"
puts "- oled_ctrl.v (Main OLED controller)"
puts "- SpiCtrl.v (Digilent SPI controller)"
puts "- delay_ms.v (Digilent delay timer)"
