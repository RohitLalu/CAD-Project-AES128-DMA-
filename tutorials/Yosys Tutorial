# Yosys Synthesis Learning Guide
## From RTL to Sky130 Standard Cells

---

## Table of Contents
1. [Overview](#overview)
2. [What We Accomplished](#what-we-accomplished)
3. [Detailed Command Reference](#detailed-command-reference)
4. [Key Concepts Learned](#key-concepts-learned)
5. [Design Metrics](#design-metrics)
6. [Next Steps](#next-steps)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This document summarizes the complete Yosys synthesis flow used to convert the PicoRV32-based System-on-Chip (PicoSoC) from RTL Verilog to Sky130 standard cell gates.

**Design**: PicoSoC (RISC-V RV32I processor with UART, SPI, and memory)  
**Technology**: SkyWater SKY130 130nm (sky130_fd_sc_hd library)  
**Tool**: Yosys 0.46  
**Result**: 39,690 standard cells, 432,526 µm² area

---

## What We Accomplished

### Stage 1: RTL Reading and Elaboration
✅ Read 4 Verilog files in correct order (dependencies matter!)  
✅ Set `picosoc` as top module  
✅ Verified hierarchy (14 modules → 8 used modules)  
✅ Removed unused modules

### Stage 2: Behavioral to Structural Conversion
✅ Converted 37 behavioral processes to hardware primitives  
✅ Flattened hierarchy for optimization  
✅ Initial optimization (constant propagation, dead code removal)

### Stage 3: Memory Synthesis
✅ Converted 2 memories (9,216 bits) to flip-flops:
   - Register file: 1,024 bits (32 × 32-bit registers)
   - Data memory: 8,192 bits (256 × 32-bit words)
✅ Result: ~9,000 additional flip-flops + addressing logic

### Stage 4: Technology-Independent Mapping
✅ Mapped to generic gates ($_AND_, $_OR_, $_MUX_, etc.)  
✅ Generated 34,342 generic cells

### Stage 5: Sky130 Technology Mapping
✅ Mapped 10,732 flip-flops to `sky130_fd_sc_hd__dfxtp_1`  
✅ Mapped combinational logic using ABC  
✅ Final: 39,690 Sky130 standard cells

### Stage 6: Output Generation
✅ Gate-level Verilog netlist (5.1 MB)  
✅ Statistics report with area information  
✅ Ready for OpenROAD

---

## Detailed Command Reference

### 1. Reading RTL
```tcl
read_verilog -sv <filename>
```
- **Purpose**: Parse Verilog/SystemVerilog and convert to RTLIL
- **Flag `-sv`**: Enable SystemVerilog features
- **Order matters**: Read files respecting dependencies

### 2. Hierarchy Management
```tcl
hierarchy -check -top <module_name>
```
- **`-check`**: Verify all module references are resolved
- **`-top`**: Set top-level module (everything else becomes sub-module)
- **Effect**: Removes unused modules, resolves parameters

### 3. Process Conversion
```tcl
proc
```
- **Purpose**: Convert behavioral `always` blocks to hardware
- **Converts**:
  - `always @(posedge clk)` → D flip-flops
  - `always @(*)` → combinational logic
  - `case` statements → multiplexers
- **Output**: Structural hardware primitives

### 4. Flattening
```tcl
flatten
```
- **Purpose**: Remove module boundaries (except top)
- **Why**: Allows cross-module optimization
- **Trade-off**: Loses hierarchy visibility but gains optimization opportunities

### 5. Optimization
```tcl
opt              # General optimization
opt -full        # Full optimization with multiple passes
opt -fast        # Quick optimization
opt_clean -purge # Remove unused wires/cells aggressively
```
- **What it does**:
  - Constant propagation
  - Dead code elimination
  - Logic minimization
  - Redundant mux removal

### 6. Memory Synthesis
```tcl
memory -nomap    # Prepare memories
memory_map       # Convert to flip-flops/logic
```
- **Purpose**: Convert abstract memories to gates
- **Options**:
  - Synthesize as flip-flops (what we did)
  - Map to SRAM macros (more efficient but requires setup)

### 7. Technology Mapping - Generic
```tcl
techmap
```
- **Purpose**: Map to generic gate primitives
- **Output**: $_AND_, $_OR_, $_NOT_, $_MUX_, $_DFF_P_, etc.
- **Why**: Intermediate step before technology-specific mapping

### 8. Technology Mapping - Sky130 Flip-Flops
```tcl
dfflibmap -liberty <liberty_file>
```
- **Purpose**: Map generic flip-flops to Sky130 DFFs
- **Input**: Liberty (.lib) file with timing/area info
- **Maps**: $_DFF_P_ → sky130_fd_sc_hd__dfxtp_1, etc.

### 9. Technology Mapping - Combinational Logic (ABC)
```tcl
abc -liberty <liberty_file>
```
- **Purpose**: Map combinational logic to Sky130 gates
- **Tool**: UC Berkeley ABC (And-Inverter Graph optimizer)
- **Optimizes for**: Area, delay, power
- **Output**: Real gates (NAND, NOR, AND, OR, AOI, OAI, MUX, etc.)

### 10. Statistics
```tcl
stat                           # Basic statistics
stat -liberty <liberty_file>   # With area/timing info
```
- **Shows**: Cell counts, wire counts, area, percentage breakdown

### 11. Output Generation
```tcl
write_verilog -noattr -noexpr -nohex -nodec <filename>
```
- **Purpose**: Generate gate-level netlist
- **Flags**:
  - `-noattr`: Remove attributes
  - `-noexpr`: No complex expressions
  - `-nohex/-nodec`: Simpler number formats

```tcl
write_json <filename>
```
- **Purpose**: Generate JSON for OpenROAD/Nextpnr

---

## Key Concepts Learned

### 1. Synthesis Flow Stages
**RTL → Behavioral → Generic → Technology-Specific → Netlist**

Each stage transforms the design representation:
- RTL: Human-readable HDL
- Behavioral: Processes and high-level operations
- Generic: Technology-independent gates
- Technology-Specific: Actual library cells
- Netlist: Final gate-level description

### 2. Why Order Matters
Some Verilog files use macros or parameters from others:
```verilog
// picosoc.v defines PICORV32_REGS before including picorv32.v
`define PICORV32_REGS picosoc_regs
```

### 3. Memory Synthesis Options

**Option 1: Synthesize to Flip-Flops** (what we did)
- Pros: Simple, portable, no special macros needed
- Cons: Large area, high power, slower
- Best for: Small memories, learning, FPGAs

**Option 2: SRAM Macros**
- Pros: Much smaller area, lower power, faster
- Cons: Requires SRAM compiler, fixed sizes
- Best for: Production ASICs, large memories

### 4. ABC Optimization
ABC (And-Inverter Graph) performs:
- Technology-independent optimization (AIG rewriting)
- Technology mapping (gate selection)
- Area/delay trade-offs

Result: Complex gates like AOI (AND-OR-INVERT) and OAI (OR-AND-INVERT) which are more efficient than separate gates.

### 5. Liberty Files (.lib)
Contain cell information:
- Pin names and functions
- Timing arcs (delays)
- Power consumption
- Area
- Capacitance/resistance

Used by tools for:
- Technology mapping (which cells to use)
- Timing analysis (static timing analysis)
- Power estimation

### 6. Design Hierarchy
```
picosoc (top)
├── picorv32 (CPU core)
│   ├── picorv32_pcpi_mul (multiplier)
│   ├── picorv32_pcpi_div (divider)
│   └── picosoc_regs (register file)
├── picosoc_mem (data memory)
├── simpleuart (UART)
└── spimemio (SPI flash interface)
```

After flattening: All logic merged into single `picosoc` module.

---

## Design Metrics

### Final Statistics

| Metric | Value |
|--------|-------|
| **Total Cells** | 39,690 |
| **Flip-Flops** | 10,732 (27%) |
| **Multiplexers** | 8,054 (20%) |
| **NAND Gates** | 3,544 (9%) |
| **AOI Gates** | 3,584 (9%) |
| **Other Logic** | 13,776 (35%) |
| **Total Area** | 432,526 µm² (0.433 mm²) |
| **Sequential Area** | 214,846 µm² (49.67%) |
| **Combinational Area** | 217,680 µm² (50.33%) |

### Key Observations

1. **Balanced Design**: Nearly 50/50 split between sequential and combinational logic
2. **Heavy MUX Usage**: 20% of cells are muxes (memory addressing + control logic)
3. **Complex Gates**: ABC chose efficient AOI/OAI gates where possible
4. **Reasonable Size**: 0.433 mm² is manageable for 130nm

### Performance Estimates

With Sky130 @ 1.8V, 25°C (typical corner):
- **Estimated Fmax**: ~50-100 MHz (will know after STA)
- **Power**: Will depend on activity factor and clock frequency
- **Die Area**: Add ~2x for routing, power grid → ~1 mm² total

---

## Next Steps: OpenROAD Flow

Now that synthesis is complete, the next phases are:

### 1. Floorplanning
- Define die size and aspect ratio
- Place I/O pins
- Create power grid plan
- Define placement blockages

### 2. Placement
- **Global Placement**: Coarse cell positions
- **Detailed Placement**: Legal, non-overlapping positions
- **Optimization**: Timing-driven placement

### 3. Clock Tree Synthesis (CTS)
- Build clock distribution network
- Balance clock skew
- Minimize clock latency

### 4. Routing
- **Global Routing**: High-level routing plan
- **Detailed Routing**: Actual metal layers
- **Optimization**: Fix DRC violations

### 5. Static Timing Analysis (STA)
- Verify timing constraints met
- Check setup/hold times
- Identify critical paths

### 6. Physical Verification
- Design Rule Check (DRC)
- Layout vs Schematic (LVS)
- Antenna check
- Density checks

### 7. GDSII Generation
- Final layout for fabrication
- Merge with standard cell library
- Add filler cells

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Module not found"
```
ERROR: Module `\xyz' not found!
```
**Solution**: Check file read order. Some modules depend on others.

#### Issue: "Cannot map DFF type"
```
Warning: unmapped dff cell: $_DFF_...
```
**Solution**: Liberty file may not have matching flip-flop type. Try different lib or add more `-liberty` files.

#### Issue: ABC takes too long
```
abc -liberty ... (hangs)
```
**Solution**: Large designs may need `-D` flag to limit depth or use `-fast` mode.

#### Issue: Memory explosion
```
ERROR: Out of memory
```
**Solution**: 
- Flatten in stages
- Use `-noabc` and map manually
- Increase system RAM

#### Issue: Liberty file parse errors
```
ERROR: Syntax error in liberty file
```
**Solution**: 
- Check liberty file format
- Some expressions aren't supported by Yosys
- Use simpler liberty file or different PDK version

---

## Command Cheat Sheet

### Quick Synthesis Flow
```tcl
# Read
read_verilog -sv file1.v file2.v ...
hierarchy -check -top TOPMODULE

# Synthesize
proc
flatten
opt
memory -nomap
memory_map
opt -full
techmap
opt -fast

# Map to technology
dfflibmap -liberty path/to/lib.lib
abc -liberty path/to/lib.lib
clean
opt_clean -purge

# Output
write_verilog netlist.v
stat -liberty path/to/lib.lib
```

### Useful Debug Commands
```tcl
ls                    # List modules
stat                  # Show statistics
check                 # Check for issues
show                  # Visualize design (graphviz)
select -list          # Show selected objects
help <command>        # Get help on command
```

---

## References

### Documentation
- **Yosys Manual**: http://yosyshq.net/yosys/documentation.html
- **Sky130 PDK**: https://skywater-pdk.readthedocs.io/
- **ABC Tool**: https://people.eecs.berkeley.edu/~alanmi/abc/

### Key Papers
- "Yosys Open SYnthesis Suite" - Claire Xenia Wolf
- "ABC: An Academic Industrial-Strength Verification Tool" - Berkeley

### Related Tools
- **OpenROAD**: Place and route
- **Magic**: Layout viewer/editor
- **Netgen**: LVS tool
- **ngspice**: SPICE simulator

---

## Conclusion

You've successfully completed RTL-to-gates synthesis! Key achievements:

✅ Understood the complete synthesis flow  
✅ Learned each Yosys command and its purpose  
✅ Mapped a real design (RISC-V CPU) to Sky130  
✅ Generated production-ready netlists  
✅ Ready to proceed to physical design  

The netlist you generated (`picosoc_synth.v`) is now ready for the next phase: **floorplanning and place-and-route with OpenROAD**.

**Next lesson**: OpenROAD for physical implementation!
