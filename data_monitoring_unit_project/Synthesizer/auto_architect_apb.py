import subprocess
import os

# File names
verilog_files = "data_monitor.v apb_demu_wrapper.v"
top_module = "apb_demu_wrapper"

print(f"🚀 AutoArchitect started for: {top_module}")

# ==========================================
# 1. RTL View (Pre-Synthesis Block Diagram)
# ==========================================
print("\n[1/2] Generating RTL View...")
yosys_rtl_cmd = f"""
read_verilog {verilog_files}
hierarchy -check -top {top_module}
select {top_module}
show -format png -prefix {top_module}_rtl
"""

# Run Yosys for RTL
subprocess.run(['yosys', '-p', yosys_rtl_cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print(f"✅ RTL View saved as: {top_module}_rtl.png")


# ==========================================
# 2. Gate Level View (Post-Synthesis JSON + NetlistSVG)
# ==========================================
print("\n[2/2] Generating Gate-Level JSON for NetlistSVG...")
yosys_gate_cmd = f"""
read_verilog {verilog_files}
synth -top {top_module}
write_json {top_module}_gate.json
"""

# Run Yosys for Gate-Level
subprocess.run(['yosys', '-p', yosys_gate_cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print(f"✅ JSON generated: {top_module}_gate.json")

# Convert JSON to SVG using NetlistSVG
print("\n🎨 Converting JSON to clean Gate-Level SVG...")
subprocess.run(['netlistsvg', f'{top_module}_gate.json', '-o', f'{top_module}_gate.svg'])
print(f"🎉 Gate-Level SVG saved as: {top_module}_gate.svg")

print("\n🏆 AutoArchitect Mission Complete!")