import subprocess
import os
import json

def generate_diagrams(verilog_files, top_module):
    print(f"🚀 Starting AutoArchitect for Top Module: {top_module}")
    
    # 1. Yosys ke commands ki list banao
    # Output JSON ka naam module ke hisaab se rakha hai (e.g., data_monitor_netlist.json)
    json_filename = f"{top_module}_netlist.json"
    svg_filename = f"{top_module}_gate.svg"
    
    yosys_commands = f"""
    read_verilog {verilog_files}
    hierarchy -check -top {top_module}
    synth -top {top_module}
    write_json {json_filename}
    """
    
    # 2. Yosys ko background mein run karo using subprocess
    print("⚙️ Running Yosys Synthesis (Please wait)...")
    result = subprocess.run(['yosys', '-p', yosys_commands], 
                            capture_output=True, 
                            text=True)
    
    # 3. Check karo ki Yosys crash toh nahi hua
    if result.returncode != 0:
        print("❌ Yosys Failed! Check your Verilog code. Error:")
        print(result.stderr[-500:]) # Sirf last 500 chars error ke dikhenge
        return
    
    print("✅ Yosys Synthesis Successful!")
    
    # 4. Ab Yosys ne jo JSON generate kiya hai, usko check karo
    if os.path.exists(json_filename):
        print(f"📄 {json_filename} generated successfully!")
        
        # JSON file kholo aur thoda data dekho
        with open(json_filename, 'r') as f:
            netlist_data = json.load(f)
            modules = netlist_data.get('modules', {})
            print(f"🎉 Found {len(modules)} module(s) in the netlist.")
            
            for mod_name in modules:
                num_ports = len(modules[mod_name].get('ports', {}))
                num_cells = len(modules[mod_name].get('cells', {}))
                print(f"   -> Module '{mod_name}': {num_ports} Ports, {num_cells} Logic Cells (Gates/FFs)")
            
            # ==========================================
            # 5. NEW FEATURE: JSON to SVG using NetlistSVG
            # ==========================================
            print(f"\n🎨 Converting {json_filename} to Gate-Level SVG...")
            svg_result = subprocess.run(['netlistsvg', json_filename, '-o', svg_filename], 
                                        capture_output=True, 
                                        text=True)
            
            if svg_result.returncode == 0 and os.path.exists(svg_filename):
                print(f"✅ Gate-Level SVG saved as: {svg_filename}")
            else:
                print("❌ NetlistSVG failed! Make sure Node.js and netlistsvg are installed.")
                print(svg_result.stderr[-300:])
    else:
        print(f"❌ {json_filename} not found! Something went wrong.")


# Script ko run karo
if __name__ == "__main__":
    
    print("="*50)
    # 1. Sirf DEMU Core ke liye
    generate_diagrams("data_monitor.v", "data_monitor")
    
    print("\n" + "="*50)
    # 2. APB Wrapper (DEMU + APB) ke liye
    # (Agar sirf DEMU nikalna hai toh neeche wali line comment kar de)
    #generate_diagrams("data_monitor.v apb_demu_wrapper.v", "apb_demu_wrapper")
    
    print("\n🏆 AutoArchitect Batch Complete!")