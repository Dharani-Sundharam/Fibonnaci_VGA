# Quick syntax check script
open_project "Fibonnaci.xpr"
update_compile_order -fileset sources_1
check_syntax
puts "Syntax check complete"
close_project
