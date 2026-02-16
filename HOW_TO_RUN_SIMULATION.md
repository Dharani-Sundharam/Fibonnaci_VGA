# Running VGA Simulation - Step by Step

## Understanding the Files

### Simulation Files (Both Needed!)
You have **2 testbenches** - this is normal:

1. **tb_top_fibonacci.v** (Original)
   - Tests: Fibonacci core only (no VGA)
   - Tests: FSM, datapath, UART, OLED
   - Use when: Testing basic Fibonacci functionality

2. **tb_vga_system.v** (NEW)
   - Tests: Complete system with VGA
   - Tests: VGA timing, display states, frame rendering
   - Use when: Testing VGA integration

### Constraint Files (Both Needed!)
You have **2 constraint files** - Vivado merges them automatically:

1. **constraints.xdc** (Original)
   - Pins: Clock, switches, LEDs, buttons
   - Pins: UART, OLED
   - Total: ~40 pins

2. **zedboard_vga.xdc** (NEW)
   - Pins: VGA only (RGB + H/V sync)
   - Total: 14 pins

**During synthesis**: Vivado combines both files automatically - no conflicts!

---

## How to Run VGA Simulation

### Method 1: GUI (Easiest)

#### Step 1: Set Active Testbench
1. In **Sources** panel, expand **Simulation Sources**
2. Right-click **tb_vga_system.v**
3. Select **"Set as Top"**

#### Step 2: Run Simulation
1. Flow Navigator → **"Run Simulation"** → **"Run Behavioral Simulation"**
2. Wait for Vivado to compile (30 seconds)
3. Simulation window opens

#### Step 3: Run the Test
In TCL Console at bottom:
```tcl
run all
```

#### Step 4: View Waveforms
- Left panel: Signal hierarchy
- Main window: Waveforms
- Look for:
  - `vga_hsync`, `vga_vsync` - Should pulse periodically
  - `vga_g[3:0]` - Should be non-zero when text displayed
  - `led[7:0]` - Shows Fibonacci results

---

### Method 2: TCL Commands (Faster)

```tcl
# Set active testbench
set_property top tb_vga_system [get_filesets sim_1]
update_compile_order -fileset sim_1

# Launch simulation
launch_simulation

# Run test
run all
```

---

## What You Should See

### Console Output
```
==================================================
VGA Display System Testbench
Testing: Fibonacci + VGA Integration
==================================================

[100 ns] Reset released
--- TEST 1: VGA Timing Verification ---
[1100000 ns] Expected: VGA showing 'RDY' (IDLE state)
...
✅ VGA timing appears correct (at least 1 frame rendered)
```

### Waveforms
- **vga_hsync**: Pulses every ~31.8 µs (800 pixels @ 25 MHz)
- **vga_vsync**: Pulses every ~16.7 ms (525 lines @ 60 Hz)
- **vga_g**: Green values (0x0 or 0xF) - shows green text
- **vga_r, vga_b**: Always 0x0 (no red/blue)

---

## Switching Between Testbenches

### To Test Original Fibonacci (Without VGA)
```tcl
set_property top tb_top_fibonacci [get_filesets sim_1]
launch_simulation
run all
```

### To Test VGA System
```tcl
set_property top tb_vga_system [get_filesets sim_1]
launch_simulation
run all
```

---

## Common Issues

### Issue 1: "Simulation already running"
**Fix**: 
```tcl
close_sim -force
launch_simulation
```

### Issue 2: "Module not found"
**Fix**: Check all VGA files are added to project
```tcl
update_compile_order -fileset sources_1
```

### Issue 3: Slow simulation
**Normal**: VGA simulation takes ~10ms of sim time
- Rendering multiple 640×480 frames is computationally intensive
- Be patient - should complete in 1-2 minutes real time

---

## Quick Verification Checklist

After running `tb_vga_system`:

✅ Simulation completes without errors  
✅ Console shows "VGA timing appears correct"  
✅ Frame count > 0  
✅ H-sync pulse count > 500  
✅ V-sync pulse count > 5  
✅ Green output (vga_g) shows activity during text display  

If all pass → **VGA system is working!** Ready for synthesis.

---

## Files Summary

| File | Purpose | Keep? |
|------|---------|-------|
| tb_top_fibonacci.v | Test Fib core | ✅ Yes |
| tb_vga_system.v | Test VGA system | ✅ Yes |
| constraints.xdc | Original pins | ✅ Yes |
| zedboard_vga.xdc | VGA pins | ✅ Yes |

**All 4 files are needed** - no duplicates to remove!
