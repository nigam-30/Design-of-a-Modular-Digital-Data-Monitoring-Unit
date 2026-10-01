# Design of a Modular Digital Data Monitoring Unit (DEMU)

<p align="center">
  <img src="https://img.shields.io/badge/HDL-Verilog-blue?style=for-the-badge" alt="Verilog">
  <img src="https://img.shields.io/badge/Interface-AMBA%20APB4-orange?style=for-the-badge" alt="APB4">
  <img src="https://img.shields.io/badge/FPGA-Vivado-red?style=for-the-badge" alt="Vivado">
  <img src="https://img.shields.io/badge/Data%20Width-8--Bit-green?style=for-the-badge" alt="8 Bit">
  <img src="https://img.shields.io/badge/Design-SoC--Ready-purple?style=for-the-badge" alt="SoC Ready">
</p>

<h2 align="center">Digital Event Monitoring Unit (DEMU)</h2>

<p align="center">
  <b>From a Standalone Hardware Watchdog to a Memory-Mapped SoC-Ready IP Core</b>
</p>

---

## 📌 Overview

The **Digital Event Monitoring Unit (DEMU)** is a modular RTL-based hardware monitoring IP designed to continuously monitor 8-bit sensor data and detect threshold violations in real time.

The project was developed in two phases:

- **Phase 1:** Standalone 8-bit Digital Event Monitoring Unit
- **Phase 2:** Integration of the DEMU core with an **AMBA APB4 slave interface**, converting the standalone design into a processor-configurable, memory-mapped IP block.

The design combines:

- Configurable threshold monitoring
- Signed and unsigned comparison modes
- Sticky alarm behavior
- Fault-value capture
- Three-state FSM control
- Software acknowledgement
- APB4 processor interface
- Memory-mapped configuration and status registers
- RTL and synthesized hardware analysis

The resulting architecture can be integrated into larger FPGA or SoC-based systems for hardware-level event and fault monitoring.

---

# 🏗️ Project Evolution

```text
                    PHASE 1
        Standalone Digital Event Monitor
                     │
                     ▼
           ┌─────────────────────┐
           │      DEMU CORE      │
           │                     │
Sensor ───►│ Threshold Monitor   │
           │ Signed/Unsigned     │
           │ Comparison          │
           │ FSM Controller      │
           │ Sticky Alarm        │
           │ Fault Capture       │
           └──────────┬──────────┘
                      │
                      ▼
                    PHASE 2
             APB4 SoC Integration
                      │
             ┌────────▼────────┐
             │   APB4 WRAPPER  │
             │                 │
CPU ────────►│ Address Decoder │
             │ Register Logic  │
             │ Read/Write Logic│
             │ Software ACK    │
             └────────┬────────┘
                      │
                      ▼
              ┌───────────────┐
              │   DEMU CORE   │
              └───────────────┘
```

---

# 🎯 Problem Statement

Software-based monitoring can miss short-duration sensor events because the processor may be occupied with other tasks or may poll the sensor too slowly.

Traditional alarm systems also provide limited diagnostic information. Simply indicating that an abnormal condition occurred does not necessarily preserve the actual sensor value responsible for the event.

The DEMU addresses these limitations through dedicated hardware monitoring.

### Key problems addressed

1. **Transient Event Loss**
   - Hardware continuously monitors sensor data.
   - Short-duration threshold violations can be detected without depending solely on software polling.

2. **Insufficient Diagnostic Information**
   - The actual sensor value responsible for the event is stored in a fault capture register.

3. **Static Data Monitoring**
   - The monitoring logic supports both signed and unsigned data comparison modes.

4. **Lack of Processor Interface**
   - Phase 2 introduces an APB4 interface for CPU-controlled configuration and status monitoring.

---

# ⚙️ Phase 1 — Standalone DEMU Core

The Phase 1 design implements the fundamental monitoring engine.

## Core Features

- 8-bit sensor input
- 8-bit programmable threshold
- Signed comparison mode
- Unsigned comparison mode
- Monitor enable control
- Sticky alarm behavior
- Fault capture register
- Software acknowledgement
- Three-state FSM
- Asynchronous active-low reset
- Synthesizable Verilog RTL

---

# 🧠 DEMU FSM

The monitoring logic is controlled using a three-state Moore FSM:

```text
                 Sensor > Threshold
                       │
                       ▼
                 ┌───────────┐
                 │   ALARM   │
                 └─────┬─────┘
                       │
                 Software ACK
                       │
                       ▼
                 ┌───────────┐
                 │ COOLDOWN  │
                 └─────┬─────┘
                       │
                 Sensor < Threshold
                       │
                       ▼
                 ┌───────────┐
                 │   IDLE    │
                 └───────────┘
```

### FSM States

| State | Description |
|---|---|
| `IDLE` | Normal monitoring state |
| `ALARM` | Threshold violation detected; alarm and fault value are active |
| `COOLDOWN` | Waits for the sensor value to return below the threshold before returning to IDLE |

---

# 🔢 Signed & Unsigned Monitoring

The DEMU supports two data interpretation modes.

### Unsigned Mode

```text
Sensor Data > Threshold
        │
        └──► Alarm
```

Example:

```text
Threshold = 80
Sensor    = 90

90 > 80  →  ALARM
```

### Signed Mode

The same 8-bit data can be interpreted as a signed two's-complement value.

This allows the IP to be used for applications where positive and negative sensor values are meaningful.

---

# 🔒 Sticky Alarm & Fault Capture

When a threshold violation occurs:

```text
Sensor Data
     │
     ▼
Threshold Comparator
     │
     ▼
   ALARM
     │
     ├──────────────► Alarm Output = 1
     │
     └──────────────► Fault Capture = Trigger Value
```

The captured fault information remains available until the alarm is acknowledged and the cooldown condition is satisfied.

### Example

```text
Threshold = 80

Sensor:
50 → 50 → 90 → 90 → 50

Alarm:
0  → 0 → 1 → 1 → 1

Fault Capture:
       └──── 90 ────┘
```

---

# 🚌 Phase 2 — APB4 Integration

Phase 2 transforms the standalone DEMU into a **processor-configurable SoC-ready IP**.

A processor can access the DEMU through a standard **AMBA APB4 memory-mapped interface**.

### APB4 Signals

| Signal | Description |
|---|---|
| `pclk` | APB clock |
| `presetn` | Active-low reset |
| `psel` | Peripheral select |
| `penable` | APB enable |
| `pwrite` | Read/write direction |
| `paddr[31:0]` | Address |
| `pwdata[31:0]` | Write data |
| `prdata[31:0]` | Read data |
| `pready` | Transfer ready |
| `pslverr` | APB error indication |

---

# 🗺️ APB4 Memory Map

| Offset | Register | Access | Description |
|---:|---|:---:|---|
| `0x00` | `THRESHOLD` | R/W | 8-bit threshold value |
| `0x04` | `MODE CTRL` | R/W | Bit[0] = Monitor Enable, Bit[1] = Data Mode |
| `0x08` | `SW ACK` | W | Write `1` to acknowledge/clear the sticky alarm |
| `0x0C` | `SENSOR IN` | R | Current sensor value |
| `0x10` | `ALARM STAT` | R | Bit[0] = Alarm, Bits[8:1] = Fault Capture |

### MODE CTRL

```text
Bit [0] → Monitor Enable
Bit [1] → Data Mode

Data Mode:
0 → Unsigned
1 → Signed
```

### ALARM STAT

```text
Bit [0]    → Alarm Status
Bits [8:1] → Captured Fault Value
```

---

# 🔄 APB Transaction Flow

```text
        CPU
         │
         │ APB WRITE
         ▼
   ┌───────────────┐
   │ APB4 Wrapper  │
   └───────┬───────┘
           │
           ├── 0x00 → Threshold
           ├── 0x04 → Enable / Mode
           └── 0x08 → Software ACK
           
Sensor ───────────────────────► DEMU Core
                                  │
                                  ▼
                             Alarm Detection
                                  │
                                  ▼
                           Fault Capture Register
                                  │
                                  ▼
        CPU ◄──── APB READ ───── 0x10 ALARM STAT
```

---

# 🧪 Verification

The project contains two dedicated Verilog testbenches.

## Phase 1 Verification

`tb_data_monitor.v`

The Phase 1 testbench verifies the DEMU using eight application scenarios:

| # | Application | Monitoring Mode |
|---:|---|---|
| 1 | Industrial Motor Overheat | Unsigned |
| 2 | Automotive / EV Battery Overcharge | Unsigned |
| 3 | Consumer Smart Thermostat | Unsigned |
| 4 | Robotics Collision / Current Surge | Unsigned |
| 5 | Medical Fever Detection | Signed |
| 6 | Environmental Flood Warning | Unsigned |
| 7 | Audio Clipping Detection | Signed |
| 8 | Security / Intruder Detection | Unsigned |

Each scenario:

1. Configures the threshold.
2. Enables monitoring.
3. Provides normal sensor data.
4. Generates a threshold violation.
5. Checks the captured fault value.
6. Sends a software acknowledgement.
7. Returns the sensor to a safe condition.

---

## Phase 2 Verification

`tb_apb_wrapper.v`

The APB testbench models processor interaction with the DEMU.

### Verification sequence

```text
1. Reset system
      ↓
2. Write threshold = 80
      ↓
3. Enable monitor
      ↓
4. Sensor = 50
      ↓
5. Sensor spike = 90
      ↓
6. Read ALARM STAT
      ↓
7. Verify alarm + fault capture
      ↓
8. Write Software ACK
      ↓
9. Sensor returns to safe value
```

The testbench implements reusable:

```verilog
apb_write(...)
apb_read(...)
```

tasks to model APB transactions.

---

# 📊 Example APB Verification

```text
Threshold:
0x50 = 80

Sensor Spike:
90

Alarm Status:
Alarm = 1
Fault Capture = 90
```

---

# 🖥️ RTL & Synthesis Analysis

The project includes RTL and synthesized schematics for both phases.

### Phase 1

- RTL schematic
- Synthesized schematic

### Phase 2

- APB wrapper RTL schematic
- APB-integrated synthesized schematic

These diagrams show the transition from behavioral RTL to FPGA-oriented synthesized hardware structures such as:

- Registers
- LUTs
- Carry logic
- Multiplexers
- FSM implementation
- Input/output buffers
- Clocking resources

---

# 📁 Project Files

```text
Digital_Data_Monitor_Phase_1_and_2/
│
├── data_monitor.v
├── apb_demu_wrapper.v
│
├── tb_data_monitor.v
├── tb_apb_wrapper.v
│
├── constraint.xdc
├── timing.xdc
│
├── rtlschematic.pdf
├── synthesizedschematic.pdf
├── apbrtlschematic.pdf
├── apbsynthesizedschematic.pdf
│
├── Data Monitoring Unit Phase 1 Report.pdf
└── Data Monitoring Unit Phase 2 Report.pdf
```

---

# 📄 Design Files

### RTL

| File | Purpose |
|---|---|
| `data_monitor.v` | Main standalone DEMU monitoring core |
| `apb_demu_wrapper.v` | APB4 wrapper around the DEMU core |

### Testbenches

| File | Purpose |
|---|---|
| `tb_data_monitor.v` | Phase 1 functional verification |
| `tb_apb_wrapper.v` | Phase 2 APB4 verification |

### Constraints

| File | Purpose |
|---|---|
| `constraint.xdc` | Clock constraint for the standalone DEMU |
| `timing.xdc` | APB clock constraint |

---

# 📐 Hardware Documentation

## Phase 1 RTL Schematic

[View RTL Schematic](./rtlschematic.pdf)

## Phase 1 Synthesized Schematic

[View Synthesized Schematic](./synthesizedschematic.pdf)

## Phase 2 APB RTL Schematic

[View APB RTL Schematic](./apbrtlschematic.pdf)

## Phase 2 APB Synthesized Schematic

[View APB Synthesized Schematic](./apbsynthesizedschematic.pdf)

---

# 📑 Project Reports

### Phase 1 Report

[Read the Phase 1 Report](./Data%20Monitoring%20Unit%20Phase%201%20Report.pdf)

### Phase 2 Report

[Read the Phase 2 Report](./Data%20Monitoring%20Unit%20Phase%202%20Report.pdf)

---

# ⏱️ Timing & Specifications

| Parameter | Specification |
|---|---|
| Sensor Data Width | 8-bit |
| Threshold Width | 8-bit |
| APB Address Width | 32-bit |
| APB Data Width | 32-bit |
| FSM States | 3 |
| FSM | IDLE → ALARM → COOLDOWN |
| Reset | Asynchronous Active-Low |
| Phase 1 Interface | Direct hardware inputs |
| Phase 2 Interface | AMBA APB4 |
| Clock Constraint | 10 ns period |
| Target Clock | 100 MHz clock constraint |
| Reported FPGA Operating Reference | 50 MHz average maximum processing speed |

> **Note:** The supplied XDC files specify a **10 ns clock period**, corresponding to a 100 MHz timing constraint. The project report separately describes 50 MHz as an average FPGA maximum processing-speed reference.

---

# 🌍 Application Areas

The modular DEMU architecture can be adapted to:

- Industrial motor monitoring
- Automotive / EV battery monitoring
- Medical monitoring
- Environmental flood detection
- Robotics
- Consumer electronics
- Audio clipping detection
- Security monitoring

---

# 🌱 SDG Relevance

| Application | SDG |
|---|---|
| Industrial Motor Protection | SDG 9 — Industry, Innovation and Infrastructure |
| Automotive Battery Management | SDG 7 — Affordable and Clean Energy |
| Medical Monitoring | SDG 3 — Good Health and Well-being |
| Flood Warning | SDG 11 — Sustainable Cities and Communities |
| Agriculture / Irrigation | SDG 6 — Clean Water and Sanitation |
| Robotics | SDG 9 — Industry, Innovation and Infrastructure |
| Smart Thermostat | SDG 12 — Responsible Consumption and Production |
| Security Monitoring | SDG 11 — Sustainable Cities and Communities |

---

# 🛠️ Tools & Technologies

- **Verilog HDL**
- **RTL Design**
- **Finite State Machines**
- **AMBA APB4**
- **Xilinx Vivado**
- **Spartan-7 FPGA Target**
- **XDC Timing Constraints**
- **RTL Schematic Analysis**
- **Post-Synthesis Hardware Analysis**
- **Digital Hardware Verification**

---

# 🚀 How to Run in Vivado

The project was developed and simulated using **Xilinx Vivado** with the following target FPGA device for both Phase 1 and Phase 2:

```text
xc7s25csga225-1
```

> **Important:** The project can be fully verified through Vivado simulation without a physical FPGA board. The selected device is used as the synthesis/implementation target.

---

## 🖥️ Phase 1 — Standalone DEMU

### Step 1 — Create Vivado Project

Open **Xilinx Vivado** and select:

```text
Create Project
```

Choose a project name such as:

```text
DEMU_Phase_1
```

Select:

```text
RTL Project
```

---

### Step 2 — Select Target Device

In **Default Part**, search for:

```text
xc7s25csga225-1
```

Select:

```text
Family  : Spartan-7
Device  : XC7S25
Package : CSGA225
Speed   : -1
```

Finish project creation.

---

### Step 3 — Add Phase 1 RTL

Go to:

```text
Project Manager
→ Add Sources
→ Add or Create Design Sources
```

Add:

```text
data_monitor.v
```

This is the main standalone DEMU core.

---

### Step 4 — Add Phase 1 Testbench

Go to:

```text
Add Sources
→ Add or Create Simulation Sources
```

Add:

```text
tb_data_monitor.v
```

Set:

```text
tb_data_monitor
```

as the simulation top.

The hierarchy should be:

```text
tb_data_monitor
       │
       ▼
data_monitor
```

---

### Step 5 — Add Phase 1 Constraint

Add the supplied:

```text
constraint.xdc
```

under:

```text
Constraints
```

---

### Step 6 — Run Phase 1 Simulation

From the Vivado Flow Navigator:

```text
Simulation
→ Run Simulation
→ Run Behavioral Simulation
```

The testbench will execute the monitoring scenarios and generate the simulation waveform.

Important signals to observe include:

```text
Clock
Reset
Sensor Data
Threshold
Monitor Enable
Data Mode
Alarm
Fault Capture
FSM State
```

The expected functional sequence is:

```text
Normal Sensor Value
        ↓
Threshold Violation
        ↓
ALARM = 1
        ↓
Fault Value Captured
        ↓
Software ACK
        ↓
Cooldown
        ↓
Normal Operation
```

---

### Step 7 — Phase 1 Synthesis

After successful simulation:

```text
Run Synthesis
```

Then select:

```text
Open Synthesized Design
```

You can inspect:

- Utilization
- Timing
- LUTs
- Flip-Flops
- FSM implementation
- Synthesized schematic

For RTL-level schematic:

```text
Open Elaborated Design
→ Schematic
```

For synthesized hardware:

```text
Open Synthesized Design
→ Schematic
```

---

# 🚌 Phase 2 — APB4 Integrated DEMU

Phase 2 integrates the Phase 1 monitoring core with an APB4 slave wrapper.

---

## Step 1 — Create Phase 2 Vivado Project

Create a new RTL project:

```text
DEMU_Phase_2
```

---

## Step 2 — Select Target Device

Use the same FPGA target:

```text
xc7s25csga225-1
```

---

## Step 3 — Add Phase 2 Design Sources

Add both:

```text
data_monitor.v
apb_demu_wrapper.v
```

The architecture is:

```text
              APB4
               │
               ▼
      ┌──────────────────┐
      │ apb_demu_wrapper │
      │                  │
      │ Address Decoder  │
      │ Register Logic   │
      │ APB Read/Write   │
      └────────┬─────────┘
               │
               ▼
      ┌──────────────────┐
      │   data_monitor   │
      │                  │
      │ Threshold        │
      │ Comparator       │
      │ FSM              │
      │ Alarm            │
      │ Fault Capture   │
      └──────────────────┘
```

---

## Step 4 — Add Phase 2 Testbench

Under:

```text
Simulation Sources
```

add:

```text
tb_apb_wrapper.v
```

Set:

```text
tb_apb_wrapper
```

as the simulation top.

Hierarchy:

```text
tb_apb_wrapper
       │
       ▼
apb_demu_wrapper
       │
       ▼
data_monitor
```

---

## Step 5 — Add Phase 2 Timing Constraint

Add:

```text
timing.xdc
```

under:

```text
Constraints
```

The supplied constraint uses:

```text
10 ns clock period
```

which corresponds to:

```text
100 MHz
```

---

## Step 6 — Run Phase 2 Simulation

Run:

```text
Simulation
→ Run Simulation
→ Run Behavioral Simulation
```

The testbench performs APB transactions using:

```verilog
apb_write(...)
apb_read(...)
```

The main verification sequence is:

```text
             Reset
               ↓
       Write Threshold = 80
               ↓
        Enable Monitor
               ↓
         Sensor = 50
               ↓
         Sensor = 90
               ↓
          ALARM = 1
               ↓
      Fault Capture = 90
               ↓
          APB READ
               ↓
       Alarm Status
               ↓
        Software ACK
               ↓
       Safe Sensor Value
```

---

# 🔍 Phase 2 Waveform Signals

In the waveform viewer, inspect the APB signals:

```text
pclk
presetn
psel
penable
pwrite
paddr
pwdata
prdata
pready
pslverr
```

and DEMU signals:

```text
sensor_data
threshold
monitor_enable
data_mode
alarm
fault_capture
state
```

The expected relationship is:

```text
APB WRITE
    ↓
Register Update
    ↓
DEMU Configuration
    ↓
Sensor Event
    ↓
Alarm
    ↓
Fault Capture
    ↓
APB READ
    ↓
Processor receives Status
```

---

# 🔬 Phase 2 Synthesis & Schematic

After successful behavioral simulation:

```text
Run Synthesis
```

Then:

```text
Open Synthesized Design
```

For RTL architecture:

```text
Open Elaborated Design
→ Schematic
```

For synthesized hardware:

```text
Open Synthesized Design
→ Schematic
```

The corresponding schematic documentation included in the project is:

```text
apbrtlschematic.pdf
apbsynthesizedschematic.pdf
```

---

# 💻 Quick Vivado Flow

For someone reproducing the project, the complete workflow is:

```text
                 ┌────────────────────┐
                 │   Open Vivado      │
                 └─────────┬──────────┘
                           ↓
                 ┌────────────────────┐
                 │ Create RTL Project │
                 └─────────┬──────────┘
                           ↓
                 ┌────────────────────┐
                 │ xc7s25csga225-1    │
                 └─────────┬──────────┘
                           ↓
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
          PHASE 1                   PHASE 2
              │                         │
       data_monitor.v          data_monitor.v
       tb_data_monitor.v       apb_demu_wrapper.v
       constraint.xdc           tb_apb_wrapper.v
              │                  timing.xdc
              │                         │
              ▼                         ▼
       Behavioral Sim.          Behavioral Sim.
              │                         │
              ▼                         ▼
          Synthesis                 Synthesis
              │                         │
              ▼                         ▼
       RTL/Synth Schematic       RTL/Synth Schematic
```

---

# ⚠️ Simulation vs Physical FPGA Board

A physical FPGA board is **not required** for the simulation workflow.

The target device:

```text
xc7s25csga225-1
```

is used by Vivado for:

```text
RTL Synthesis
       ↓
Technology Mapping
       ↓
Implementation
       ↓
Timing Analysis
       ↓
Resource Estimation
```

A physical board is only required if you want to go beyond simulation and actually program hardware:

```text
Generate Bitstream
        ↓
Program FPGA
        ↓
Run on Physical Hardware
```

For the current project, the primary verification flow is:

```text
Behavioral Simulation
        ↓
RTL Analysis
        ↓
Synthesis
        ↓
Timing Analysis
        ↓
Schematic Analysis
```

---

# 🔬 Design Highlights

### Hardware-Level Event Detection

The DEMU continuously evaluates sensor data in hardware rather than relying exclusively on processor polling.

### Configurable Threshold

The threshold can be configured according to the monitored application.

### Dual Data Interpretation

Supports:

```text
Unsigned Mode
Signed Mode
```

### Fault Snapshot

The sensor value that caused the threshold violation is preserved.

### Sticky Alarm

The alarm condition remains available for software/hardware acknowledgement.

### APB4 Integration

Phase 2 provides a standardized processor-facing interface suitable for SoC integration.

### Modular Architecture

The core can be reused independently of the APB wrapper.

---

# 📈 Phase 1 → Phase 2 Comparison

| Feature | Phase 1 | Phase 2 |
|---|:---:|:---:|
| 8-bit Sensor Monitoring | ✅ | ✅ |
| Configurable Threshold | ✅ | ✅ |
| Signed Mode | ✅ | ✅ |
| Unsigned Mode | ✅ | ✅ |
| Sticky Alarm | ✅ | ✅ |
| Fault Capture | ✅ | ✅ |
| 3-State FSM | ✅ | ✅ |
| Software Acknowledgement | Direct Input | APB Register |
| CPU Configuration | ❌ | ✅ |
| Memory-Mapped Registers | ❌ | ✅ |
| APB4 Interface | ❌ | ✅ |
| SoC Integration | Limited | ✅ |
| APB Verification | ❌ | ✅ |

---

# 🔮 Future Work

Potential future extensions include:

- Moving Average Filter for noisy sensor environments
- AXI4-Lite interface for higher-bandwidth SoC integration
- Additional sensor channels
- More configurable monitoring modes
- Hardware filtering and signal conditioning
- Extended fault logging
- FPGA board-level demonstration
- Further automation of RTL-to-gate visualization

---

# 👨‍💻 Project Contribution

## Phase 1 — Group Project

The standalone DEMU core was developed collaboratively by:

- **Dhruv Bhanushalli**
- **Nigam Mehta**
- **Vrushal Vaity**

The Phase 1 work included the standalone monitoring architecture, FSM-based control, fault capture, signed/unsigned monitoring and verification.

## Phase 2 — Individual Extension

Phase 2 was developed by:

**Nigam Mehta**

Major contributions included:

- APB4 wrapper architecture
- APB memory-map design
- Processor-facing configuration interface
- APB read/write transactions
- APB verification testbench
- SoC-oriented integration of the DEMU core
- RTL and synthesized design analysis

---

# 📚 References

1. S. Brown and Z. Vranesic, *Fundamentals of Digital Logic with Verilog Design*, 2nd ed.
2. M. D. Ciletti, *Advanced Digital Design with the Verilog HDL*, 2nd ed.
3. ARM Limited, *AMBA 3 APB Protocol Specification*.
4. C. Wolf, *Yosys Open SYnthesis Suite*.
5. United Nations, *Transforming our World: The 2030 Agenda for Sustainable Development*.

---

# ⭐ Project Summary

The **Design of a Modular Digital Data Monitoring Unit** demonstrates the evolution of a hardware monitoring block from a standalone RTL IP into a processor-accessible SoC component.

**Phase 1** establishes the core monitoring engine with:

```text
8-bit Monitoring
      +
Threshold Comparison
      +
Signed / Unsigned Mode
      +
FSM Control
      +
Sticky Alarm
      +
Fault Capture
```

**Phase 2** adds:

```text
APB4 Interface
      +
Memory-Mapped Registers
      +
CPU Configuration
      +
Software Acknowledgement
      +
Processor Status Readback
```

Together, the two phases demonstrate practical concepts in **RTL design, FSM-based control, digital verification, FPGA synthesis, bus-interface design, and SoC-oriented IP development**.

<p align="center">
  <b>DEMU — Hardware Monitoring from RTL to SoC-Ready IP</b>
</p>
