# VGA Integration - Vivado Setup Guide

## Files to Add to Vivado Project

### New VGA Source Files (Add these)
```tcl
# In Vivado TCL Console, run:
add_files -norecurse {
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/clk_divider.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/vga_sync.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/digit_renderer.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/top_vga.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/fibonacci_vga_top.v
}

# Add VGA constraints
add_files -fileset constrs_1 -norecurse {
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/constrs_1/new/zedboard_vga.xdc
}

# Update compile order
update_compile_order -fileset sources_1
```

### Modified Existing Files (Already updated)
- ✅ `fibo_top.v` - Added VGA output ports

### Top Module Change
**IMPORTANT**: Set **`fibonacci_vga_top`** as the top module

```tcl
# Option 1: Via TCL
set_property top fibonacci_vga_top [current_fileset]

# Option 2: Via GUI
# Right-click fibonacci_vga_top.v → Set as Top
```

## Complete File List

### All Source Files Needed:
```
Fibonacci Core (Existing):
├── fibo_top.v            (Modified - added VGA outputs)
├── fibonacci_fsm.v
├── fibonacci_datapath.v
├── uart_tx.v
├── oled_ctrl.v
├── SpiCtrl.v
├── delay_ms.v
├── pwm_breathing.v
└── debounce.v

VGA System (New):
├── clk_divider.v         ⭐ NEW
├── vga_sync.v            ⭐ NEW
├── digit_renderer.v      ⭐ NEW
├── top_vga.v             ⭐ NEW
└── fibonacci_vga_top.v   ⭐ NEW (Top Module)

Total: 14 source files
```

### Constraint Files:
```
├── constraints.xdc       (Existing - switches, LEDs, UART, OLED)
└── zedboard_vga.xdc      ⭐ NEW (VGA pins)
```

## Synthesis Settings

**No changes needed** - default settings work fine

Expected resource usage:
- LUTs: ~1500-1800 (< 4% of XC7Z020)
- FFs: ~600-800
- Clock: 100 MHz (easily met)

## Pin Conflict Check

**VGA pins do NOT conflict** with existing design:
- Switches, LEDs, buttons: Different pins
- UART (Y11): Different from VGA pins
- OLED (U9-U12, AB12, AA12): Different from VGA pins

✅ **Safe to add VGA** without removing anything!

## Testing Workflow

1. **Add files** (see TCL commands above)
2. **Set top module** to `fibonacci_vga_top`
3. **Run simulation** (see tb_vga_system.v)
4. **Run synthesis** - should complete in ~3-5 min
5. **Generate bitstream**
6. **Program FPGA** + connect VGA monitor

## Quick Start Commands

```tcl
# Complete setup in one go:
add_files -norecurse {
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/clk_divider.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/vga_sync.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/digit_renderer.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/top_vga.v
    C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/sources_1/new/fibonacci_vga_top.v
}

add_files -fileset constrs_1 C:/Users/Dharani Sundharam/Fibonnaci/Fibonnaci.srcs/constrs_1/new/zedboard_vga.xdc

set_property top fibonacci_vga_top [current_fileset]
update_compile_order -fileset sources_1

# Now ready to synthesize!
```
