#!/usr/bin/env openroad

# Design: 55,508 cells, 0.57 mm² (cell area)
# Target: Sky130 @ 40 MHz


# Environment Setup
set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK "sky130A"
set LIB "sky130_fd_sc_hd"

set TECH_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set SC_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set LIB_FILE "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# STAGE 1: Read Design


read_lef $TECH_LEF
read_lef $SC_LEF
read_liberty $LIB_FILE

read_verilog picosoc_aes_sram.v

link_design picosoc

# STAGE 2: Floorplan

# Die size calculation:
# Cell area: 570,135 µm²
# Target utilization: 65%
# Core area needed: 570,135 / 0.65 = 877,131 µm²
# Core side: √877,131 = 937 µm
# With margins: ~1100 µm × 1100 µm die

initialize_floorplan \
    -die_area {0 0 1500 1500} \
    -core_area {100 100 1400 1400} \
    -site unithd

report_design_area
