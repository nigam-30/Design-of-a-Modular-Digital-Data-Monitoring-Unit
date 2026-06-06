📖 Project Journey & Architecture
This project was built in two progressive phases to demonstrate core VLSI design principles, from RTL logic to SoC integration.

🛠️ Phase 1: The Core - Data Monitoring Unit (DEMU)
The foundation of the project. A standalone Verilog module that monitors an 8-bit sensor data line against a configurable threshold.

Dual Comparison Modes: Supports both Unsigned and Signed ($signed) data comparison via a data_mode pin.
Custom Bitwise Logic: Comparison logic built entirely using bitwise operators (&, |, ~) without relying on direct < or > operators, ensuring strict control over the generated hardware.
FSM-Driven Control: 3-state Finite State Machine (IDLE ➔ ALARM ➔ COOLDOWN).
Sticky Alarm & Fault Capture: Latches the alarm state until the processor acknowledges it, and captures the exact sensor value that triggered the fault.

🧠 Phase 2: SoC Integration - APB4 Wrapper
Real-world IPs don't exist in isolation; they talk to a CPU. In this phase, the DEMU core was wrapped inside an AMBA APB4 slave interface, making it a memory-mapped peripheral.

APB4 Protocol Implementation: Fully compliant with Setup and Access phases (psel, penable, pwrite, pready).
Memory-Mapped Registers: The CPU configures the DEMU and reads its status entirely by reading/writing to specific memory addresses.
Auto-Clearing Acknowledge: Software acknowledgment (sw_ack) auto-clears after one clock cycle to prevent latching errors.

🗺️ APB4 Register Map (Phase 2)
Address Offset	Register Name	R/W	Description

0x00	THRESHOLD_REG	R/W	Sets the threshold value (8-bit)

0x04	MODE_CTRL_REG	R/W	[0]: monitor_enable, [1]: data_mode

0x08	SW_ACK_REG	W	Write 1 to acknowledge and clear alarm

0x0C	SENSOR_IN_REG	R	Live sensor data read (Hardware input)

0x10	ALARM_STAT_REG	R	[0]: alarm_output, [8:1]: fault_capture

🤖 Bonus: AutoArchitect (Mini EDA Tool)
Instead of manually running Yosys commands, a Python automation script was developed using the subprocess module.

Automatically invokes Yosys for synthesis.
Generates Post-Synthesis JSON netlist.
Uses NetlistSVG to render clean Gate-Level SVG diagrams instantly.
Script: synth/auto_architect.py

🚀 How to Run
1. Simulation (Icarus Verilog)
Phase 1 (DEMU Core):

bash

iverilog -o sim_demu.vvp rtl/data_monitor.v tb/tb_data_monitor.v
vvp sim_demu.vvp
Phase 2 (APB Wrapper):

bash

iverilog -o sim_apb.vvp rtl/data_monitor.v rtl/apb_demu_wrapper.v tb/tb_apb_wrapper.v
vvp sim_apb.vvp

2. Synthesis & Visualization (AutoArchitect)
Navigate to the synth folder and run the python script:

bash

cd synth
python3 auto_architect.py

SVG diagrams and JSON netlists will be generated 

🧠 Tech Stack
HDL: Verilog
Simulation: Icarus Verilog
Synthesis: Yosys
Protocols: AMBA APB4
Automation: Python (Subprocess, JSON)
