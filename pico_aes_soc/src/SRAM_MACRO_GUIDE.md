# Using SRAM Macros with PicoSoC + AES
## Complete Guide to SRAM Integration

---

## Overview

Instead of synthesizing the 1KB memory (picosoc_mem) to ~8,000 flip-flops, we'll use a **compiled SRAM macro** which is:
- **50% smaller area**
- **90% less static power** (leakage)
- **2-3x faster** access time
- More realistic for production ASICs

---

## SRAM Macro Specification

**What we need:**
- **Size:** 1KB = 256 words × 32 bits = 8,192 bits
- **Configuration:** 1 read/write port
- **Access time:** < 25ns (for 40 MHz operation)

**Typical Sky130 SRAM macro name:**
```
sky130_sram_1kbyte_1rw1r_32x256_8
```

**Breakdown:**
- `sky130` - Technology
- `sram` - Macro type
- `1kbyte` - Total size
- `1rw1r` - 1 read/write port + 1 read port
- `32x256` - 32-bit words, 256 deep
- `8` - Column mux ratio

---

## Step 1: Obtain SRAM Macro

You have three options:

### **Option A: Use Pre-built Macros** (Easiest)

Check if macros exist in your PDK:

```bash
cd ~/.ciel/ciel/sky130/versions/*/sky130A/libs.ref/
ls -la sky130_sram_macros/
```

Look for:
```
sky130_sram_macros/
├── lef/     ← Physical layout description
├── lib/     ← Timing models
├── gds/     ← Final layout
├── verilog/ ← Behavioral model
└── spice/   ← Circuit model
```

If these exist, you're good to go!

### **Option B: Generate with OpenRAM** (Recommended if not present)

OpenRAM generates optimized SRAM macros:

```bash
# Install OpenRAM (if not already installed)
git clone https://github.com/VLSIDA/OpenRAM.git
cd OpenRAM

# Create SRAM config file: sram_1kb_config.py
cat > sram_1kb_config.py << 'EOF'
# 1KB SRAM for Sky130
word_size = 32          # 32-bit word
num_words = 256         # 256 words = 1KB
tech_name = "sky130"
process_corners = ["TT"]
supply_voltages = [1.8]
temperatures = [25]
route_supplies = True
check_lvsdrc = False    # Disable for faster gen
output_path = "output"
output_name = "sky130_sram_1kb_32x256"
EOF

# Generate SRAM
python3 openram.py sram_1kb_config.py
```

This creates all necessary files (LEF, LIB, GDS, Verilog).

### **Option C: Use Existing Flip-Flop Memory** (Fallback)

If SRAM macros are unavailable, you can still proceed without them. The synthesis will use flip-flops (less efficient but functional).

---

## Step 2: Modify RTL (if needed)

### **Option 1: Keep Existing RTL** (Preferred)

Your current `picosoc_aes.v` already has the memory defined. We'll just mark it as a blackbox during synthesis.

**No RTL changes needed!**

### **Option 2: Explicit SRAM Instantiation** (Alternative)

If you want to explicitly instantiate the SRAM macro in RTL:

```verilog
// In picosoc_aes.v, replace the picosoc_mem module with:

sky130_sram_1kbyte_1rw1r_32x256_8 memory (
    .clk0(clk),              // Clock
    .csb0(~mem_valid),       // Chip select (active low)
    .web0(~|mem_wstrb),      // Write enable (active low)
    .wmask0(4'b1111),        // Write mask (all bytes)
    .addr0(mem_addr[9:2]),   // Address (word-aligned)
    .din0(mem_wdata),        // Data input
    .dout0(ram_rdata)        // Data output
);
```

---

## Step 3: Modified Synthesis Flow

### **Key Change: Don't Map Memory to Flip-Flops**

```tcl
# In Yosys synthesis script:

# Normal flow
proc
flatten
opt

# Prepare memories
memory -nomap

# STOP HERE - Don't call memory_map!
# Instead, mark as blackbox:
blackbox picosoc_mem

# Continue with rest of synthesis
techmap
dfflibmap ...
abc ...
```

**What this does:**
- Keeps `picosoc_mem` as an abstract module
- Yosys doesn't synthesize it to flip-flops
- OpenROAD will see it as a "macro" to be placed

---

## Step 4: OpenROAD Integration

### **A. Read SRAM Macro Files**

```tcl
# In OpenROAD script:

# Read SRAM macro LEF (physical description)
read_lef path/to/sky130_sram_1kb_32x256.lef

# Read SRAM macro LIB (timing)
read_liberty path/to/sky130_sram_1kb_32x256_TT_1p8V_25C.lib
```

### **B. Manual Macro Placement**

SRAM macros must be placed manually (not auto-placed like standard cells):

```tcl
# After floorplan, before standard cell placement:

# Place SRAM at coordinates (x, y) in microns
place_cell -inst memory -origin "300 500" -orient N

# Orient options: N, S, E, W, FN, FS, FE, FW
# N = North (default), FN = Flipped North, etc.
```

**Placement tips:**
- Place near CPU to minimize wire delay
- Leave space around it for routing
- Common positions: center-left or bottom-center
- Check macro size first (typically ~150µm × 200µm)

### **C. PDN for SRAM**

SRAM needs power connections:

```tcl
# Add power straps over SRAM area
add_pdn_stripe -grid {grid} -layer {met4} -width {3.0} ...

# SRAM macros have internal power pins
# PDN will connect to them automatically
```

### **D. Placement Blockage**

Prevent standard cells from overlapping SRAM:

```tcl
# This is usually automatic when macro is placed
# But you can explicitly add:
create_placement_blockage -bbox {x1 y1 x2 y2}
```

---

## Step 5: Comparison

### **Flip-Flop Implementation:**
```
Area: ~200,000 µm² (flip-flops + muxes)
Power: ~5 mW static (leakage)
Speed: ~3ns access (slow)
Gates: ~8,000 flip-flops + ~2,000 muxes
```

### **SRAM Macro Implementation:**
```
Area: ~30,000 µm² (macro)
Power: ~0.5 mW static
Speed: ~1ns access (fast)
Gates: 1 macro (easier routing)
```

**Savings:**
- **6.5x smaller area**
- **10x less static power**
- **3x faster access**

---

## Troubleshooting

### **Issue: SRAM Macro Files Not Found**

```bash
# Check if macros are in PDK:
find ~/.ciel -name "*sram*" -type d

# If not found, you need to:
# 1. Generate with OpenRAM, or
# 2. Download pre-built macros, or
# 3. Use flip-flop memory (remove blackbox)
```

### **Issue: SRAM Instance Not Found in Netlist**

```tcl
# Check if blackbox worked:
grep "picosoc_mem" picosoc_aes_sram.v

# Should see module declaration but no internal logic
# If you see flip-flops, blackbox didn't work
```

### **Issue: SRAM Placement Fails**

```tcl
# Check SRAM dimensions first:
# In OpenROAD:
report_macro_stats

# Adjust placement coordinates to fit in core area
# Core area is: 50,50 to 1150,1150 (for 1200×1200 die)
```

### **Issue: Timing Violations After SRAM**

SRAM is faster than flip-flop memory, so timing should improve!

If violations exist:
```tcl
# Check SRAM access time in .lib file:
grep "min_pulse_width" *.lib

# Ensure clock period > SRAM access time
# 40 MHz (25ns) should be fine for most SRAMs
```

---

## Complete File Checklist

### **For Synthesis (Yosys):**
- ✅ `picosoc_aes_sram_synth.tcl` - Modified synthesis script
- ✅ All RTL files (aes_*.v, picorv32.v, picosoc_aes.v)
- ⚠️ SRAM Verilog model (optional, for blackbox)

### **For Physical Design (OpenROAD):**
- ✅ `openroad_aes_sram.tcl` - OpenROAD script
- ✅ `picosoc_aes.sdc` - Timing constraints
- ✅ SRAM LEF file - Physical layout
- ✅ SRAM LIB file - Timing model
- ✅ SRAM GDS file - Final layout

---

## Quick Start Commands

### **With SRAM Macros (Full Flow):**

```bash
# 1. Synthesis with SRAM blackbox
yosys -s picosoc_aes_sram_synth.tcl

# 2. Physical design with macro placement
openroad
source openroad_aes_sram.tcl
```

### **Without SRAM Macros (Fallback):**

```bash
# Use original synthesis (memory → flip-flops)
yosys -s picosoc_aes_synth.tcl

# Use original OpenROAD flow
openroad
source openroad_aes_complete.tcl
```

---

## Expected Results

### **With SRAM Macro:**
- **Die size:** 1000µm × 1000µm (smaller!)
- **Total area:** ~0.8 mm²
- **Power @ 40MHz:** ~15 mW
- **Cell count:** ~50K cells (no memory flip-flops)

### **Without SRAM (flip-flops):**
- **Die size:** 1200µm × 1200µm
- **Total area:** ~1.2 mm²
- **Power @ 40MHz:** ~25 mW
- **Cell count:** ~60K cells (includes memory)

---

## Next Steps

1. **Check if SRAM macros are available** in your PDK
2. **If yes:** Use the SRAM flow scripts
3. **If no:** Either generate with OpenRAM or use flip-flop flow
4. **After synthesis:** Verify blackbox worked (check netlist)
5. **During OpenROAD:** Manually place SRAM macro
6. **After routing:** Check timing and power reports

---

**Using SRAM macros is highly recommended for production designs!**
They offer significant benefits in area, power, and speed.
