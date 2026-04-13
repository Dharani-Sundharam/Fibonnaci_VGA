<div align="center">
  <img src="docs/assets/banner_placeholder.gif" alt="Fibonacci System Banner" width="600" />
</div>

<h1 align="center">ZedBoard Fibonacci Validation Engine & VGA Visualizer</h1>

<div align="center">
  
  ![License](https://img.shields.io/github/license/Dharani-Sundharam/Fibonnaci_VGA?style=for-the-badge)
  ![Last Commit](https://img.shields.io/github/last-commit/Dharani-Sundharam/Fibonnaci_VGA?style=for-the-badge)
  ![Timing Constraints](https://img.shields.io/badge/Timing-Met-success?style=for-the-badge)
  ![Platform](https://img.shields.io/badge/Hardware-ZedBoard-orange?style=for-the-badge)

  > An enterprise-grade, FPGA-based hardware accelerator for validating, generating, and visually rendering Fibonacci sequences on the Xilinx ZedBoard (Zynq-7000) over VGA.
  
</div>

<br />

## Table of Contents

- [About The Project](#about-the-project)
- [Key Features](#key-features)
- [Built With](#built-with)
- [System Architecture](#system-architecture)
- [Sneak Peek](#sneak-peek)
- [Getting Started](#getting-started)
- [Testing & Validation](#testing--validation)
- [Contributing](#contributing)
- [License](#license)

## About The Project

This repository contains the RTL source, hardware constraints, and robust verification environments for an FPGA-based Fibonacci sequence validator equipped with **VGA Rendering capabilities**. Engineered specifically for the robust Xilinx ZedBoard architecture, this system guarantees precise sequence validation through deterministic Moore State Machine execution.

The engine ingests three sequential 8-bit inputs via dedicated hardware slide switches, rigorously validates them against the natural mathematical Fibonacci progression ($n_1 + n_2 = n_3$), dynamically computes the next subsequent values, and renders real-time graphical outputs straight to a VGA monitor.

## Key Features

- **Live VGA Output** — Dedicated VGA synchronization controllers explicitly developed for real-time digit rendering on connected monitors.
- **Robust Moore FSM** — A highly deterministic state machine architecture governing all datapath switching logically and seamlessly.
- **Hardware Debouncing** — Integrated 10 ms hardware-level debouncing filters for clean execution cycles during mechanical switch interactions.
- **Visual Feedback System** — Real-time peripheral progression monitoring, utilizing an optimized PWM breathing LED algorithm.
- **Rigorous Error Detection** — Built-in hardware fallback for instant invalid mathematical sequence catching and halting.

## Built With

Our technology stack leverages core RTL tooling for synthesis and hardware implementation:

* [![Verilog][Verilog.js]][Verilog-url]
* [![Vivado][Vivado.js]][Vivado-url]
* [![Xilinx][Xilinx.js]][Xilinx-url]

## Sneak Peek

<img align="right" width="380" src="docs/assets/demo_placeholder.gif" alt="Hardware Demo GIF">

### Interactive Hardware Dashboard & Display

When synthesized and loaded onto the ZedBoard via JTAG, the user interfaces directly with the onboard peripheral switches:

1. **Input Entry:** Configure base 8-bit sequences sequentially utilizing the `SW[6:0]` digital switches.
2. **Execution Control:** Engage the computation engine using the debounced `BTNC` hardware pushbutton.
3. **Data Telemetry & Display:** Validation results immediately map to VGA memory for crisp visual representation across your connected display, supplemented by onboard LED progress indications.

> The visualization to the right demonstrates a potential visual feedback loop, capturing the soft PWM breathing LED pattern alongside the generated sequence outputs on VGA.

<br clear="both"/>

## Getting Started

To compile, synthesize, and run this logic accelerator on your local hardware platform, follow these deployment steps:

<details>
<summary><b>View Required Prerequisites</b></summary>
<br>

To successfully synthesize this project, you will need:
- **Xilinx Vivado Design Suite** (2024.x or a highly compatible version)
- **ZedBoard Target Device** (Model XC7Z020-CLG484-1)
- Micro-USB data cables (for UART Telemetry/JTAG Bitstream loading)
- VGA Display configuration (cable + 1080p/720p monitor)

</details>

<details>
<summary><b>View Installation & Build Guide</b></summary>
<br>

1. **Clone the Environment**
   ```sh
   git clone https://github.com/Dharani-Sundharam/Fibonnaci_VGA.git
   ```
2. **Initialize Workspace**
   - Launch Vivado.
   - Open the primary system `.xpr` project file (`Fibonnaci_VGA.xpr`).
3. **Compile Hardware Maps**
   - Run standard **Synthesis** processes.
   - Run **Implementation**.
   - Output via **Generate Bitstream** to compile the underlying binary payload.
4. **Deploy Payload**
   - Link the ZedBoard using the JTAG interface and connect the VGA cable.
   - Launch Vivado Hardware Manager and **Program Device** passing your generated `.bit` target.

</details>

## Testing & Validation

A comprehensive array of simulation testbenches (`tb_fibo_vga_system`, `tb_top_fibonacci`, etc.) validate the RTL environment thoroughly before jumping to synthesis. To boot the self-checking monitor through Vivado Tcl:

```tcl
restart; run all
```

**Common Edge Case Testing Outcomes:**

| Primary Input | Result Validation | Behavioral Output |
| :--- | :---: | :--- |
| Valid Range ($3, 5, 8$) | Sequence Match Verified | Calculates $13, 21, 34$, triggers VGA Draw System |
| Invalid Range ($1, 2, 8$) | Verification Fail Context | Pipeline freezes, fires visual Error LED routine |

## Contributing

Contributions make the open-source community an amazing place to learn, inspire, and build. Your optimizations or UI rendering fixes are **greatly appreciated**.

1. Fork the Repository
2. Initialize your Feature Branch (`git checkout -b feature/OptimizationDesign`)
3. Commit your Architectural Changes (`git commit -m 'Implement pipelined VGA Memory Cache'`)
4. Push to the Branch (`git push origin feature/OptimizationDesign`)
5. Open a Pull Request

## License

Distributed under the MIT License. Reference the root layout for exhaustive distribution regulations.

---

<!-- Markdown Image Definition Links -->
[Verilog.js]: https://img.shields.io/badge/Verilog-153F71?style=for-the-badge
[Verilog-url]: https://en.wikipedia.org/wiki/Verilog
[Vivado.js]: https://img.shields.io/badge/Vivado-E30022?style=for-the-badge&logo=xilinx&logoColor=white
[Vivado-url]: https://www.xilinx.com/products/design-tools/vivado.html
[Xilinx.js]: https://img.shields.io/badge/Xilinx_ZedBoard-000000?style=for-the-badge&logo=Xilinx&logoColor=white
[Xilinx-url]: https://digilent.com/reference/programmable-logic/zedboard/start
