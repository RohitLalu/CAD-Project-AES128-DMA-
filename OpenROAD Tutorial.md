# OpenROAD Physical Design Learning Guide
## From Netlist to GDSII - Step by Step

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [OpenROAD Flow Overview](#openroad-flow-overview)
3. [Stage 1: Setup and Design Import](#stage-1-setup-and-design-import)
4. [Stage 2: Floorplanning](#stage-2-floorplanning)
5. [Stage 3: Placement](#stage-3-placement)
6. [Stage 4: Clock Tree Synthesis](#stage-4-clock-tree-synthesis)
7. [Stage 5: Routing](#stage-5-routing)
8. [Stage 6: Finishing](#stage-6-finishing)
9. [Command Reference](#command-reference)

---

## Prerequisites

**Files you need:**
- ✅ `picosoc_synth.v` - Gate-level netlist from Yosys (5.1 MB)
- ✅ `picosoc.sdc` - Timing constraints (40 MHz clock)
- ✅ Sky130 PDK files (LEF, LIB, GDS)

**Check your environment:**
```bash
which openroad
openroad -version
ls picosoc_synth.v picosoc.sdc
```

---

## OpenROAD Flow Overview

```
┌─────────────────┐
│  Synthesized    │ ← We are here (from Yosys)
│    Netlist      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Floorplanning  │ Define die size, place I/O
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Placement     │ Position 39,690 cells
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Clock Tree     │ Build clock distribution
│   Synthesis     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Routing      │ Connect all nets
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Finishing     │ Filler cells, optimization
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     GDSII       │ Final layout for fabrication
└─────────────────┘
```

---

## Stage 1: Setup and Design Import

### What We're Doing
- Loading technology files (LEF, Liberty)
- Reading the synthesized netlist
- Linking the design

### Step-by-Step Commands

**Launch OpenROAD:**
```bash
cd ~/CAD-Project-AES128-DMA-/pico_aes_soc/src
openroad
```

You'll see the OpenROAD prompt:
```
openroad>
```

**Set up paths (one-time setup):**
```tcl
set PDK_ROOT "$env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK "sky130A"
set LIB "sky130_fd_sc_hd"
```

**Read technology LEF (metal layers, design rules):**
```tcl
read_lef ${PDK_ROOT}/${PDK}/libs.ref/${LIB}/techlef/${LIB}__nom.tlef
```

**What this does:**
- Loads metal layer definitions (met1, met2, met3, met4, met5)
- Via definitions (via1, via2, via3, via4)
- Design rules (spacing, width, etc.)

**Read standard cell LEF (physical cell layouts):**
```tcl
read_lef ${PDK_ROOT}/${PDK}/libs.ref/${LIB}/lef/${LIB}.lef
```

**What this does:**
- Loads physical dimensions of each Sky130 cell
- Pin locations
- Obstruction layers
- Cell boundaries

**Read Liberty file (timing information):**
```tcl
read_liberty ${PDK_ROOT}/${PDK}/libs.ref/${LIB}/lib/${LIB}__tt_025C_1v80.lib
```

**What this does:**
- Cell delays
- Setup/hold times
- Power consumption
- Drive strengths

**Read your synthesized netlist:**
```tcl
read_verilog picosoc_synth.v
```

**Link the design:**
```tcl
link_design picosoc
```

**What this does:**
- Connects all module instances
- Resolves all cell references
- Verifies netlist integrity

**Check what was loaded:**
```tcl
# Count design objects
puts "Cells: [llength [get_cells *]]"
puts "Nets: [llength [get_nets *]]"
puts "Pins: [llength [get_pins *]]"

# Report design statistics
report_design_area
```

---

## Stage 2: Floorplanning

### What We're Doing
- Define die size (800µm x 800µm)
- Define core area (where cells go)
- Place I/O pins
- Plan power grid

### Understanding Die vs Core

```
┌─────────────────────────────────┐ ← Die boundary (800µm x 800µm)
│  I/O Pad Ring                   │
│  ┌─────────────────────────┐    │
│  │  Core Area (760µm x 760)│    │ ← Core area (cells placed here)
│  │                         │    │
│  │   [Standard Cells]      │    │
│  │                         │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

### Calculating Die Size

From synthesis: **432,526 µm² of cells**

**Formula:**
```
Core Area = Cell Area / Utilization
Die Area = Core Area + I/O margin
```

**Example (70% utilization):**
```
Core Area = 432,526 / 0.70 = 618,000 µm²
Core Side = √618,000 = 786 µm
Die Size = 786 + margins = 800 µm
```

### Commands

**Initialize floorplan:**
```tcl
initialize_floorplan \
    -die_area {0 0 800 800} \
    -core_area {20 20 780 780} \
    -site unithd
```

**What each parameter means:**
- `-die_area {x1 y1 x2 y2}`: Die corners in microns
- `-core_area {x1 y1 x2 y2}`: Core corners in microns
- `-site unithd`: Standard cell site name (from LEF)

**Check the floorplan:**
```tcl
# Report areas
report_design_area

# Check utilization
puts "Core utilization: [expr {double([get_db current_design .stats.cell_area]) / [get_db current_design .core_area] * 100}]%"
```

**Place I/O pins automatically:**
```tcl
auto_place_pins -layer met3
```

**Or place pins manually (example):**
```tcl
# Place clock on left side
place_pin -pin_name clk -layer met3 -location {0 400} -force_to_die_boundary

# Place reset on left side
place_pin -pin_name resetn -layer met3 -location {0 420} -force_to_die_boundary

# ... (repeat for all 27 pins)
```

**View the floorplan (if you have GUI):**
```tcl
gui::show
```

---

## Stage 3: Placement

### What We're Doing
- Place all 39,690 cells in the core area
- Optimize for timing, wirelength, and congestion
- Two phases: Global → Detailed

### Global Placement

**What is Global Placement?**
- Coarse placement
- Cells may overlap
- Optimizes wirelength and timing
- Fast (few minutes)

**Run global placement:**
```tcl
global_placement -density 0.65
```

**What `-density 0.65` means:**
- Use 65% of available core area
- Leave 35% for routing
- Higher density = smaller die, harder to route
- Lower density = easier routing, larger die

**Check placement:**
```tcl
# Check if placement was successful
check_placement

# Report placement utilization
report_design_area
```

### Detailed Placement

**What is Detailed Placement?**
- Legalizes global placement
- No overlaps
- Cells on grid
- Fast (seconds)

**Run detailed placement:**
```tcl
detailed_placement
```

**Optimize placement (optional):**
```tcl
# Improve timing
improve_placement -max_displacement 50
```

**Report placement quality:**
```tcl
# Check timing after placement
report_worst_slack
report_tns
report_wns

# Check congestion
report_design_area
```

---

## Stage 4: Clock Tree Synthesis (CTS)

### What We're Doing
- Build clock distribution network
- Balance clock arrival times (minimize skew)
- Use clock buffers to drive large fanout

### Understanding Clock Trees

```
        CLK (input pin)
             │
        ┌────┴────┐
        │  Root   │
        │  Buffer │
        └────┬────┘
             │
      ┌──────┴──────┐
      │             │
   Buffer        Buffer
      │             │
   ┌──┴──┐       ┌──┴──┐
   │     │       │     │
  FF1   FF2    FF3   FF4  ... (10,732 flip-flops)
```

**Goal:** All flip-flops receive clock at nearly same time

### Commands

**Read timing constraints:**
```tcl
read_sdc picosoc.sdc
```

**Configure CTS:**
```tcl
# Set clock buffer cells
set_cts_buf_cell sky130_fd_sc_hd__clkbuf_8
set_cts_buf_cell sky130_fd_sc_hd__clkbuf_4
set_cts_buf_cell sky130_fd_sc_hd__clkbuf_2

# Set target skew (in picoseconds)
set_cts_target_skew 200
```

**Run CTS:**
```tcl
clock_tree_synthesis
```

**Check clock tree:**
```tcl
# Report clock skew
report_clock_skew

# Report clock tree stats
report_cts
```

---

## Stage 5: Routing

### What We're Doing
- Connect all nets using metal layers
- Two phases: Global → Detailed
- Fix DRC violations

### Metal Layer Stack (Sky130)

```
┌─────────┐
│  met5   │ ← Top metal (thick, for power)
├─────────┤
│  met4   │
├─────────┤
│  met3   │ ← Middle layers (signal routing)
├─────────┤
│  met2   │
├─────────┤
│  met1   │ ← Bottom metal (local routing, power rails)
├─────────┤
│  Cell   │
│ Layouts │
└─────────┘
```

### Global Routing

**What is Global Routing?**
- High-level routing plan
- Divides die into routing grid
- Assigns nets to routing regions
- Doesn't create actual wires yet

**Run global routing:**
```tcl
global_route \
    -guide_file route.guide \
    -layers met1:met5
```

**Check routing:**
```tcl
# Report routing congestion
report_congestion

# Estimate routing wirelength
report_route_status
```

### Detailed Routing

**What is Detailed Routing?**
- Creates actual wire geometries
- Assigns specific tracks
- Fixes DRC violations
- Uses routing grid from global routing

**Run detailed routing:**
```tcl
detailed_route \
    -guide route.guide \
    -output_drc route.drc \
    -output_maze route.maze
```

**This may take several minutes!**

**Check for DRC violations:**
```tcl
# Report DRC violations
run_drc

# If violations exist, try to fix
detailed_route -via_in_pin_bottom_layer met1 -via_in_pin_top_layer met5
```

---

## Stage 6: Finishing

### What We're Doing
- Insert filler cells (fill gaps)
- Final optimization
- Generate GDSII

### Filler Cells

**Why?**
- Fill empty spaces between cells
- Provide continuous N-well and P-well
- Meet DRC requirements

**Insert fillers:**
```tcl
# Filler cell names (sorted by size)
set fillers {
    sky130_fd_sc_hd__fill_8
    sky130_fd_sc_hd__fill_4
    sky130_fd_sc_hd__fill_2
    sky130_fd_sc_hd__fill_1
}

# Insert filler cells
filler_placement -cells $fillers
```

### Final Optimization

**Timing optimization:**
```tcl
# Re-check timing
read_sdc picosoc.sdc
report_checks

# If timing violations exist
improve_placement -max_displacement 10
```

**Power optimization:**
```tcl
# Report power
report_power

# Optimize
# (power optimization typically done with multi-Vt cells)
```

### Generate Output Files

**Write DEF (Design Exchange Format):**
```tcl
write_def picosoc_final.def
```

**Write GDSII (for fabrication):**
```tcl
# Merge with standard cell GDS
set GDS_FILES "${PDK_ROOT}/${PDK}/libs.ref/${LIB}/gds/${LIB}.gds"

write_gds \
    -design picosoc \
    -lib_files $GDS_FILES \
    picosoc.gds
```

**Write reports:**
```tcl
# Timing report
report_checks -path_delay max > timing_report.txt

# Area report
report_design_area > area_report.txt

# Power report
report_power > power_report.txt
```

---

## Command Reference

### Essential Commands

| Command | Purpose |
|---------|---------|
| `read_lef` | Load LEF files (technology, cells) |
| `read_liberty` | Load timing library |
| `read_verilog` | Load gate-level netlist |
| `link_design` | Connect all modules |
| `initialize_floorplan` | Create die/core areas |
| `auto_place_pins` | Place I/O pins |
| `global_placement` | Coarse cell placement |
| `detailed_placement` | Legalize placement |
| `clock_tree_synthesis` | Build clock tree |
| `global_route` | High-level routing |
| `detailed_route` | Detailed routing |
| `filler_placement` | Insert filler cells |
| `write_def` | Save DEF file |
| `write_gds` | Generate GDSII |

### Reporting Commands

| Command | What It Shows |
|---------|--------------|
| `report_design_area` | Core area, cell area, utilization |
| `report_checks` | Timing violations |
| `report_worst_slack` | Worst timing slack |
| `report_tns` | Total negative slack |
| `report_wns` | Worst negative slack |
| `report_clock_skew` | Clock tree skew |
| `report_power` | Power consumption |
| `report_congestion` | Routing congestion |
| `check_placement` | Placement legality |
| `run_drc` | Design rule violations |

---

## Files Created

After completing the flow, you'll have:

```
picosoc.gds          ← Final GDSII layout
picosoc_final.def    ← DEF file
route.guide          ← Routing guide
timing_report.txt    ← Timing analysis
area_report.txt      ← Area breakdown
power_report.txt     ← Power analysis
```

---

## Next Steps

After OpenROAD, you need:

1. **Design Rule Check (DRC)** - Verify no manufacturing violations
2. **Layout vs Schematic (LVS)** - Verify layout matches netlist  
3. **Static Timing Analysis (STA)** - Final timing verification
4. **Parasitic Extraction** - Extract R/C for accurate timing
5. **Sign-off** - Final checks before tape-out

**Tools:**
- DRC: Magic, Calibre
- LVS: Netgen, Calibre
- STA: OpenSTA, PrimeTime
- Extraction: Magic, StarRC

---

## Ready to Start?

Copy the configuration files to your working directory:
```bash
cp picosoc.sdc ~/CAD-Project-AES128-DMA-/pico_aes_soc/src/
cp openroad_interactive.tcl ~/CAD-Project-AES128-DMA-/pico_aes_soc/src/
```

Then launch OpenROAD and work through the stages!

```bash
cd ~/CAD-Project-AES128-DMA-/pico_aes_soc/src
openroad
```

**At the OpenROAD prompt, you can either:**
1. Run commands one-by-one (recommended for learning)
2. Source the interactive script: `source openroad_interactive.tcl`

Good luck with your physical design! 🚀
