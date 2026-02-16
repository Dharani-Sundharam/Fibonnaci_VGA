# VGA Integration - Quick Reference

## 📋 Checklist

### Step 1: Add New Files to Vivado
```tcl
# Run in TCL Console:
add_files -norecurse {
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/clk_divider.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/vga_sync.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/digit_renderer.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/top_vga.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/fibonacci_vga_top.v
}

add_files -fileset constrs_1 C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/constrs_1/new/zedboard_vga.xdc
```

### Step 2: Set Top Module
```tcl
set_property top fibonacci_vga_top [current_fileset]
update_compile_order -fileset sources_1
```

### Step 3: Run Simulation
```tcl
# Set testbench as top
set_property top tb_vga_system [get_filesets sim_1]
# Run simulation
launch_simulation
run all
```

### Step 4: Synthesize
- Flow Navigator → Run Synthesis
- Expected time: 3-5 minutes
- Expected LUTs: ~1500-1800

### Step 5: Program FPGA
- Generate Bitstream
- Program Device
- Connect VGA cable
- Test!

## 🎯 What VGA Will Show

| State | Display | Color |
|-------|---------|-------|
| IDLE (breathing LED) | "RDY" | Green on Black |
| DONE (valid sequence) | Last result (e.g., "144") | Green on Black |
| ERROR (invalid) | "ERR" | Green on Black |

## 📂 File Summary

**New Files (5)**:
- ✅ clk_divider.v
- ✅ vga_sync.v
- ✅ digit_renderer.v
- ✅ top_vga.v
- ✅ fibonacci_vga_top.v
- ✅ zedboard_vga.xdc

**Modified (1)**:
- ✅ fibo_top.v (added VGA outputs)

**Testbench (1)**:
- ✅ tb_vga_system.v

## ⚙️ No Files to Remove

All existing files stay - VGA adds to the project without conflicts!

## 🔧 Troubleshooting

### Synthesis Errors
- Check all 5 .v files are added
- Verify top module is `fibonacci_vga_top`
- Ensure constraints file is added

### No VGA Output
- Check VGA cable connection
- Verify monitor supports 640×480 @ 60Hz
- Check pin assignments match ZedBoard

### Simulation Issues
- Set `tb_vga_system` as simulation top
- Run for at least 5ms to see frames
- Check waveforms for hsync/vsync

## 📊 Expected Results

**Simulation**: Should complete in ~10ms, rendering multiple VGA frames

**Synthesis**: 
- LUTs: ~1500-1800 / 53,200 (3%)
- Timing: 100 MHz easily met
- No critical warnings

**Hardware**:
- VGA displays immediately on power-up
- Shows "RDY" when idle
- Updates when you enter Fibonacci sequences
