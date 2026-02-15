# ZedBoard Fibonacci Validator & Generator

FPGA-based Fibonacci sequence validator and generator implemented on the Xilinx ZedBoard (Zynq-7000).

## Overview

This project implements a hardware-based Fibonacci sequence validator that:
- Accepts three 8-bit numbers via slide switches
- Validates if they form a valid Fibonacci sequence (num1 + num2 = num3)
- Generates the next 4 Fibonacci values if valid
- Transmits results via UART (9600 baud)
- Displays progress and results on LEDs

## Hardware Requirements

- **Board**: Xilinx ZedBoard (XC7Z020-CLG484)
- **Clock**: 100 MHz system clock
- **Inputs**: 
  - SW[6:0] — 7 slide switches for binary input (0-127)
  - BTNC — Enter button
  - BTNR — Reset button
- **Outputs**:
  - LD0-6 — Progress indicators and result display
  - LD7 — PWM breathing LED (IDLE indicator)
  - Pmod JA Pin 1 (Y11) — UART TX output

## Features

✅ **Moore FSM** — Clean state machine design  
✅ **Button Debouncing** — 10 ms hardware debounce  
✅ **PWM Breathing LED** — Smooth fade effect in IDLE  
✅ **UART Output** — Transmits results at 9600 baud  
✅ **Error Detection** — Validates Fibonacci sequence  
✅ **LED Display** — Shows progress and final result  

## Project Structure

```
Fibonnaci.srcs/
├── sources_1/new/
│   ├── fibo_top.v              # Top-level module
│   ├── fibonacci_fsm.v         # Moore FSM controller
│   ├── fibonacci_datapath.v    # Registers, adders, validator
│   ├── debounce.v              # Button debouncer
│   ├── pwm_breathing.v         # PWM breathing LED
│   └── uart_tx.v               # UART transmitter (9600 8N1)
├── sim_1/new/
│   └── tb_top_fibonacci.v      # Testbench with UART monitor
└── constrs_1/new/
    └── constraints.xdc         # ZedBoard pin constraints
```

## Module Descriptions

| Module | Description |
|--------|-------------|
| **fibo_top** | Top-level wrapper, connects all modules |
| **fibonacci_fsm** | Moore FSM (IDLE → READ → VALIDATE → GENERATE → DONE/ERROR) |
| **fibonacci_datapath** | Arithmetic logic, registers, validation |
| **debounce** | Parameterizable button debouncer (10 ms @ 100 MHz) |
| **pwm_breathing** | PWM generator for breathing LED effect |
| **uart_tx** | Simple UART transmitter, 8-N-1, 9600 baud |
| **tb_top_fibonacci** | Self-checking testbench with UART decoder |

## Usage

### Simulation

1. Open project in Vivado
2. Run Behavioral Simulation
3. In Tcl console: `restart; run all`
4. UART output appears in console (e.g., `03 05 08 0D`)

### Hardware

1. **Synthesize** → **Implement** → **Generate Bitstream**
2. Program ZedBoard via JTAG
3. **Enter sequence**:
   - Set switches to first number
   - Press BTNC
   - Repeat for 2nd and 3rd numbers
4. **View results**:
   - LEDs show generated values
   - Connect FTDI cable to Pmod JA Pin 1 for UART output

### Example Test Cases

| num1 | num2 | num3 | Result | Output |
|------|------|------|--------|--------|
| 1 | 1 | 2 | ✅ Valid | `03 05 08 0D` (3, 5, 8, 13) |
| 2 | 3 | 5 | ✅ Valid | `08 0D 15 22` (8, 13, 21, 34) |
| 1 | 1 | 5 | ❌ Invalid | `ERR` (LEDs blink) |

## UART Format

**Valid sequence**: `[R0] [R1] [R2] [R3]\r\n` (hex, space-separated)  
**Invalid sequence**: `ERR\r\n`

**Settings**: 9600 baud, 8 data bits, no parity, 1 stop bit (8N1)

## Timing Results

- **WNS (Setup)**: +4.888 ns ✅
- **WHS (Hold)**: +0.169 ns ✅
- **WPWS**: +4.500 ns ✅
- **Clock**: 100 MHz (10 ns period)
- **All timing constraints met** ✅

## Resource Utilization

| Resource | Used | Available | % |
|----------|------|-----------|---|
| LUTs | ~200 | 53,200 | <1% |
| Flip-Flops | ~150 | 106,400 | <1% |
| DSPs | 0 | 220 | 0% |
| BRAM | 0 | 140 | 0% |

## Tools

- **Vivado**: 2024.x (or compatible version)
- **Target Device**: XC7Z020-CLG484-1 (ZedBoard)
- **Language**: Verilog-2001

## Author

Dharani Sundharam

## License

This project is open source and available for educational purposes.
