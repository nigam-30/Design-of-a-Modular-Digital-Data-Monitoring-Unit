Developed an 8-bit modular RTL-based Digital Event Monitoring Unit for real-time sensor monitoring with support for both signed and unsigned user-defined thresholds. Implemented a 3-state Moore Finite State Machine (IDLE, ALARM, COOLDOWN) to manage control logic, achieving operation up to 50 MHz with a 1-cycle alarm latency. Designed advanced diagnostic features including a Sticky Alarm latch and a Fault Capture Register to prevent transitory event loss and retain fault-triggering data. Verified functionality through extensive Cadence simulations and evaluated applications across industrial automation and healthcare domains aligned with UN Sustainable Development Goals.
[RTL Architecture – Modular Digital Event Monitoring Unit](https://drive.google.com/file/d/1bg3-cig8jHdExzSdsEnqjQ5-MuOId5EV/view?usp=sharing)

[RTL schematic view of the modular Digital Event Monitoring Unit designed in Verilog](https://drive.google.com/file/d/1diK_dYo5Jqkw7fBFGjLXGGve9prxE2Km/view?usp=sharing)

Digital Event Monitoring Unit
Cadence NC-Launch Simulation & Waveform Analysis Guide

This repository contains the RTL design and testbench files for simulating a Digital Event Monitoring Unit using Cadence NC tools (NC-Launch, Xcelium, SimVision).

📂 Files Included

dut.v – RTL Design (Design Under Test)

test.v – Verilog Testbench

🛠 Prerequisites

Linux environment

Cadence tools installed:

NC-Launch

Xcelium

SimVision

Cadence environment properly sourced

Shell set to csh

▶️ Simulation Steps (NC-Launch Flow)
1. Open Terminal and switch to C Shell
csh

2. Source Cadence Environment

(Use the setup file provided by your institute/company)

source /path/to/cadence/setup.csh

3. Navigate to Project Directory
cd <project_directory>

4. Launch NC-Launch
nclaunch &

🧭 Running the Simulation in NC-Launch

In NC-Launch, create a new simulation session

Add the following source files:

dut.v

test.v

Select Xcelium as the simulator

Set test.v as the top module

Enable waveform dumping

Click Run

The design will compile and the simulation will start.

📊 Waveform Analysis (SimVision)

After simulation starts:

SimVision opens automatically

Open the Waveform Window

Add relevant signals:

clk

reset

sensor_data

threshold_value

alarm_output

fault_capture

FSM state signals

Run the simulation and zoom into areas of interest

🧪 Expected Results

Alarm triggers within 1 clock cycle after threshold violation

Sticky alarm remains asserted even after sensor returns to safe value

Fault Capture Register stores the exact sensor value at failure

Correct FSM transitions:
IDLE → ALARM → COOLDOWN

📝 Notes

Modify test.v to validate additional scenarios

Add signals to the waveform before running for full visibility

Recommended zoom range: 100 ns – 1 µs
