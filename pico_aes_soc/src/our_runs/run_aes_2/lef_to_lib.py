#!/usr/bin/env python3
"""
Generate simplified Liberty (.lib) from LEF file
Extracts physical info from LEF and creates basic timing model
"""

import re
import sys

def parse_lef_size(lef_file):
    """Extract die size from LEF file"""
    with open(lef_file, 'r') as f:
        content = f.read()
    
    # Find SIZE line
    size_match = re.search(r'SIZE\s+([\d.]+)\s+BY\s+([\d.]+)', content)
    if size_match:
        width = float(size_match.group(1))
        height = float(size_match.group(2))
        return width, height
    
    return None, None

def parse_lef_pins(lef_file):
    """Extract pin names from LEF file"""
    pins = []
    with open(lef_file, 'r') as f:
        for line in f:
            # Look for PIN declarations
            pin_match = re.search(r'^\s*PIN\s+(\w+)', line)
            if pin_match:
                pins.append(pin_match.group(1))
    
    return pins

def generate_liberty(macro_name, width, height, pins, output_file):
    """Generate simplified Liberty file"""
    
    area = width * height
    
    lib_content = f'''/* Auto-generated Liberty file for {macro_name} */
/* Generated from LEF file - SIMPLIFIED MODEL */

library ({macro_name}_lib) {{
    comment : "Generated from LEF - simplified timing";
    delay_model : table_lookup;
    time_unit : "1ns";
    voltage_unit : "1V";
    current_unit : "1mA";
    capacitive_load_unit (1, pf);
    
    default_operating_conditions : tt_025C_1v80;
    
    operating_conditions (tt_025C_1v80) {{
        process : 1.0;
        temperature : 25;
        voltage : 1.80;
    }}
    
    cell ({macro_name}) {{
        area : {area:.2f};
        cell_leakage_power : 5000.0;  /* Estimate */
        
        /* Clock pin (assumed) */
        pin (clk) {{
            direction : input;
            clock : true;
            capacitance : 0.05;
        }}
        
        /* Other pins (generic) */
'''
    
    for pin in pins:
        if pin.lower() in ['clk', 'clock']:
            continue  # Already added
        
        # Guess direction based on common naming
        if any(x in pin.lower() for x in ['out', 'result', 'dout', 'rdata', 'ready', 'valid']):
            direction = 'output'
        else:
            direction = 'input'
        
        lib_content += f'''        pin ({pin}) {{
            direction : {direction};
            capacitance : 0.001;
        }}
        
'''
    
    lib_content += '''    }
}
'''
    
    with open(output_file, 'w') as f:
        f.write(lib_content)
    
    print(f"✓ Generated {output_file}")
    print(f"  Macro: {macro_name}")
    print(f"  Size: {width} × {height} µm")
    print(f"  Area: {area:.2f} µm²")
    print(f"  Pins: {len(pins)}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 lef_to_lib.py <input.lef> [output.lib]")
        print("")
        print("Example:")
        print("  python3 lef_to_lib.py aes_macro.lef aes_macro.lib")
        sys.exit(1)
    
    lef_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else lef_file.replace('.lef', '.lib')
    
    print(f"Parsing LEF: {lef_file}")
    
    width, height = parse_lef_size(lef_file)
    if width is None:
        print("ERROR: Could not find SIZE in LEF file")
        sys.exit(1)
    
    pins = parse_lef_pins(lef_file)
    
    macro_name = lef_file.replace('.lef', '').replace('_macro', '')
    
    generate_liberty(macro_name, width, height, pins, output_file)
    
    print("")
    print("⚠️  WARNING: This is a SIMPLIFIED timing model")
    print("   Suitable for integration but not accurate timing analysis")
    print("")
    print("For better timing model, use:")
    print("  1. write_timing_model in OpenROAD (Method 1)")
    print("  2. Full SPICE characterization")