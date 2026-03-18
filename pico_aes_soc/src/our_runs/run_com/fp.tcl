# #!/usr/bin/env openroad

# set_thread_count 7

# set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
# set RUNDIR   "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com"

# set TECH_LEF "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
# set SC_LEF   "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
# set LIB_FILE "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
# set SRAM_LEF "$RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8.lef"
# set SRAM_LIB "$RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
# set AES_LEF  "$RUNDIR/aes_abstract.lef"
# set AES_LIB  "$RUNDIR/aes_macro.lib"

# puts "================================================================"
# puts "  PicoSoC + AES + SRAM  —  Floorplan + Pins + PDN"
# puts "================================================================"

# # =============================================================================
# # 1. Read LEFs
# # =============================================================================
# puts "\n--- 1. Reading LEFs ---"
# read_lef $TECH_LEF
# read_lef $SC_LEF
# read_lef $SRAM_LEF
# read_lef $AES_LEF
# puts "✓ LEFs loaded"

# # 2. Read Liberty and netlist

# puts "\n--- 2. Reading Liberty ---"
# read_liberty $LIB_FILE
# read_liberty $SRAM_LIB
# read_liberty $AES_LIB
# puts "✓ Liberty loaded"

# puts "\n--- 3. Reading netlist ---"
# read_verilog $RUNDIR/picosoc_syn.v
# link_design picosoc
# puts "✓ Design linked"

# # 4. SDC

# puts "\n--- 4. Reading SDC ---"
# read_sdc $RUNDIR/picosoc_aes.sdc
# puts "✓ SDC loaded"

# # 5. Floorplan initialisation

# puts "\n--- 5. Floorplan ---"
# initialize_floorplan \
#     -die_area  {0 0 1600 1600} \
#     -core_area {50 50 1550 1550} \
#     -site unithd

# report_design_area
# puts "✓ Floorplan: 1600×1600 µm die, 1500×1500 µm core"

# puts "\n--- 6. Macro placement ---"
# set_macro_extension 10

# place_macro \
#     -macro_name {memory.sram_macro} \
#     -location   {85 585} \
#     -orient     R0
# puts "✓ SRAM placed"

# place_macro \
#     -macro_name aes_inst \
#     -location   {635 635} \
#     -orient     R0
# puts "✓ AES  placed"


# # 7. Placement blockages around macros
# #    Prevents std cells from encroaching on macro keep-out zones.
# #    Each region = macro footprint expanded by 10 µm halo.

# set block [ord::get_db_block]
 
# # SRAM halo blockage
# set sram_blk [odb::dbBlockage_create $block \
#     [ord::microns_to_dbu 75]     \
#     [ord::microns_to_dbu 575]    \
#     [ord::microns_to_dbu 574.78] \
#     [ord::microns_to_dbu 992.5]]
 
# # AES halo blockage
# set aes_blk [odb::dbBlockage_create $block \
#     [ord::microns_to_dbu 625]    \
#     [ord::microns_to_dbu 625]    \
#     [ord::microns_to_dbu 1529]   \
#     [ord::microns_to_dbu 1463.84]]

# # 8. Tap cells  ← before make_tracks and place_pins

# puts "\n--- 8. Tap cells ---"
# tapcell \
#     -tapcell_master  sky130_fd_sc_hd__tapvpwrvgnd_1 \
#     -endcap_master   sky130_fd_sc_hd__decap_3 \
#     -distance        14 \
#     -halo_width_x          15 \
#     -halo_width_y          15
# puts "✓ Tap cells inserted"

# # 9. Routing tracks  ← before place_pins

# puts "\n--- 9. Routing tracks ---"
# make_tracks
# puts "✓ Tracks created"

# # Pin assignments (from pins_and_pdn.tcl):
# #   West  : clk, resetn, irq_5/6/7
# #   East  : iomem_valid/ready, ser_rx/tx
# #   North : iomem_rdata[*], flash inputs
# #   South : iomem_wstrb/addr/wdata[*], flash outputs

# puts "\n--- 10. Pin placement ---"
# set west_pins  {clk resetn irq_5 irq_6 irq_7}
# set east_pins  {iomem_valid iomem_ready ser_rx ser_tx}

# set north_pins {}
# for {set i 0} {$i < 32} {incr i} { lappend north_pins "iomem_rdata\[$i\]" }
# lappend north_pins flash_csb flash_clk \
#     flash_io0_di flash_io1_di flash_io2_di flash_io3_di

# set south_pins {}
# for {set i 0} {$i < 4}  {incr i} { lappend south_pins "iomem_wstrb\[$i\]" }
# for {set i 0} {$i < 32} {incr i} { lappend south_pins "iomem_addr\[$i\]"  }
# for {set i 0} {$i < 32} {incr i} { lappend south_pins "iomem_wdata\[$i\]" }
# lappend south_pins \
#     flash_io0_oe flash_io1_oe flash_io2_oe flash_io3_oe \
#     flash_io0_do flash_io1_do flash_io2_do flash_io3_do

# set_io_pin_constraint -pin_names $west_pins  -region left:100-1500
# set_io_pin_constraint -pin_names $east_pins  -region right:100-1500
# set_io_pin_constraint -pin_names $north_pins -region top:100-1500
# set_io_pin_constraint -pin_names $south_pins -region bottom:100-1500

# place_pins -hor_layers met3 -ver_layers met2
# puts "✓ Pins placed (123 total)"

# write_db $RUNDIR/3_pins.odb
# puts "✓ Checkpoint: 3_pins.odb"

# puts "\n--- 11. Power delivery network ---"
 
# add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
# add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$}  -power
# add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^HI$}   -power
# add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground
# add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$}  -ground
# add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^LO$}   -ground
 
# # SRAM macro: vccd1/vssd1
# add_global_connection -net {VPWR} \
#     -inst_pattern {memory\.sram_macro} -pin_pattern {^vccd1$} -power
# add_global_connection -net {VGND} \
#     -inst_pattern {memory\.sram_macro} -pin_pattern {^vssd1$} -ground
 
# set_voltage_domain -power VPWR -ground VGND
 
# define_pdn_grid \
#     -name            {core_grid} \
#     -voltage_domains {CORE}
 
# # met1 followpins — horizontal VDD/VSS rails inside every std-cell row
# add_pdn_stripe -grid {core_grid} -layer {met1} \
#     -width {0.48} -pitch {2.72} -offset {0} -followpins
 
# # met4 vertical stripes
# # offset=2.0 → first stripe at core_x+2 ≈ 52µm, catching tap/endcap cells
# # at x≈50.83µm that were unconnected with offset=13.57
# add_pdn_stripe -grid {core_grid} -layer {met4} \
#     -width {1.6} -pitch {40.0} -offset {2.0}
 
# # met5 horizontal stripes
# add_pdn_stripe -grid {core_grid} -layer {met5} \
#     -width {1.6} -pitch {40.0} -offset {2.0}
 
# # Power ring — placed INSIDE the core (+5µm from core boundary)
# # Previously core_offsets placed the ring OUTSIDE the snapped core, so
# # the vertical ring segment couldn't connect to internal met1 followpins.
# # With positive offsets the ring sits at core_edge+5 to core_edge+10 µm,
# # inside the first row of cells.
# add_pdn_ring -grid {core_grid} \
#     -layers         {met4 met5} \
#     -widths         {5.0 5.0}   \
#     -spacings       {2.0 2.0}   \
#     -core_offsets   {5.0 5.0}   \
#     -starts_with    POWER
 
# # Connections: met1 followpins → met4 stripes → met5 stripes
# # met1↔met4 catches all std cells and tap cells via the vertical met4 stripes
# add_pdn_connect -grid {core_grid} -layers {met1 met4}
# add_pdn_connect -grid {core_grid} -layers {met4 met5}
 
# pdngen
# puts "✓ PDN complete"
 
# write_db $RUNDIR/4_pdn.odb
# puts "✓ Checkpoint: 4_pdn.odb"

# puts "\nFloorplan + Pins + PDN complete."

#!/usr/bin/env openroad

set_thread_count 7

set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set RUNDIR   "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com"

set TECH_LEF "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set SC_LEF   "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set LIB_FILE "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
set SRAM_LEF "$RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8.lef"
set SRAM_LIB "$RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
set AES_LEF  "$RUNDIR/aes_abstract.lef"
set AES_LIB  "$RUNDIR/aes_macro.lib"

puts "================================================================"
puts "  PicoSoC + AES + SRAM  —  Floorplan + Pins + PDN"
puts "================================================================"

# =============================================================================
# 1. Read LEFs
# =============================================================================
puts "\n--- 1. Reading LEFs ---"
read_lef $TECH_LEF
read_lef $SC_LEF
read_lef $SRAM_LEF
read_lef $AES_LEF
puts "✓ LEFs loaded"

# 2. Read Liberty and netlist

puts "\n--- 2. Reading Liberty ---"
read_liberty $LIB_FILE
read_liberty $SRAM_LIB
read_liberty $AES_LIB
puts "✓ Liberty loaded"

puts "\n--- 3. Reading netlist ---"
read_verilog $RUNDIR/picosoc_syn.v
link_design picosoc
puts "✓ Design linked"

# 4. SDC

puts "\n--- 4. Reading SDC ---"
read_sdc $RUNDIR/picosoc_aes.sdc
puts "✓ SDC loaded"

# 5. Floorplan initialisation

puts "\n--- 5. Floorplan ---"
initialize_floorplan \
    -die_area  {0 0 1900 1100} \
    -core_area {50 50 1850 1050} \
    -site unithd

report_design_area
puts "✓ Floorplan: 1900×1000 µm die, 1800×1000 µm core"

puts "\n--- 6. Macro placement ---"
set_macro_extension 10

place_macro \
    -macro_name {memory.sram_macro} \
    -location   {85 120} \
    -orient     R0
puts "✓ SRAM placed "

place_macro \
    -macro_name aes_inst \
    -location   {850 120} \
    -orient     R0
puts "✓ AES  placed )"


# 7. Placement blockages — ODB API (no create_placement_blockage in this build)
# Regions = macro footprint + 10µm halo
# SRAM: (60,62)→(539.78,459.5)  + 10µm = (50,52)→(549.78,469.5)
# AES:  (560,62)→(1444,880.84)  + 10µm = (550,52)→(1454,890.84)
# set block [ord::get_db_block]

# set sram_blk [odb::dbBlockage_create $block \
#     [ord::microns_to_dbu 50]     \
#     [ord::microns_to_dbu 52]     \
#     [ord::microns_to_dbu 549.78] \
#     [ord::microns_to_dbu 469.5]]

# set aes_blk [odb::dbBlockage_create $block \
#     [ord::microns_to_dbu 550]    \
#     [ord::microns_to_dbu 52]     \
#     [ord::microns_to_dbu 1454]   \
#     [ord::microns_to_dbu 890.84]]

# 8. Tap cells  ← before make_tracks and place_pins

puts "\n--- 8. Tap cells ---"
tapcell \
    -tapcell_master  sky130_fd_sc_hd__tapvpwrvgnd_1 \
    -endcap_master   sky130_fd_sc_hd__decap_3 \
    -distance        14 \
    -halo_width_x          15 \
    -halo_width_y          15
puts "✓ Tap cells inserted"

# 9. Routing tracks  ← before place_pins

puts "\n--- 9. Routing tracks ---"
make_tracks
puts "✓ Tracks created"

puts "\n--- 10. Pin placement ---"
set west_pins  {irq_5 irq_6 irq_7}
set east_pins  {iomem_valid iomem_ready ser_rx ser_tx}

set north_pins {}
for {set i 0} {$i < 32} {incr i} { lappend north_pins "iomem_rdata\[$i\]" }
lappend north_pins flash_csb flash_clk \
    flash_io0_di flash_io1_di flash_io2_di flash_io3_di

set south_pins {}
for {set i 0} {$i < 4}  {incr i} { lappend south_pins "iomem_wstrb\[$i\]" }
for {set i 0} {$i < 32} {incr i} { lappend south_pins "iomem_addr\[$i\]"  }
for {set i 0} {$i < 32} {incr i} { lappend south_pins "iomem_wdata\[$i\]" }
lappend south_pins \
    flash_io0_oe flash_io1_oe flash_io2_oe flash_io3_oe \
    flash_io0_do flash_io1_do flash_io2_do flash_io3_do \
    clk resetn

set_io_pin_constraint -pin_names $west_pins  -region left:50-1050
set_io_pin_constraint -pin_names $east_pins  -region right:50-1050
set_io_pin_constraint -pin_names $north_pins -region top:50-1750
set_io_pin_constraint -pin_names $south_pins -region bottom:50-1750

place_pins -hor_layers met3 -ver_layers met2
puts "✓ Pins placed (123 total)"

# write_db $RUNDIR/3_pins.odb
puts "✓ Checkpoint: 3_pins.odb"

puts "\n--- 11. Power delivery network ---"
 
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$}  -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^HI$}   -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$}  -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^LO$}   -ground
 
# SRAM macro: vccd1/vssd1
add_global_connection -net {VPWR} \
    -inst_pattern {memory\.sram_macro} -pin_pattern {^vccd1$} -power
add_global_connection -net {VGND} \
    -inst_pattern {memory\.sram_macro} -pin_pattern {^vssd1$} -ground
 
set_voltage_domain -power VPWR -ground VGND
 
define_pdn_grid \
    -name            {core_grid} \
    -voltage_domains {CORE}
 
# met1 followpins — horizontal VDD/VSS rails inside every std-cell row
add_pdn_stripe -grid {core_grid} -layer {met1} \
    -width {0.48} -pitch {2.72} -offset {0} -followpins
 
# met4 vertical stripes
# offset=2.0 → first stripe at core_x+2 ≈ 52µm, catching tap/endcap cells
# at x≈50.83µm that were unconnected with offset=13.57
add_pdn_stripe -grid {core_grid} -layer {met4} \
    -width {1.6} -pitch {40.0} -offset {2.0}
 
# met5 horizontal stripes
add_pdn_stripe -grid {core_grid} -layer {met5} \
    -width {1.6} -pitch {40.0} -offset {2.0}

add_pdn_ring -grid {core_grid} \
    -layers         {met4 met5} \
    -widths         {5.0 5.0}   \
    -spacings       {2.0 2.0}   \
    -core_offsets   {5.0 5.0}   \
    -starts_with    POWER
 
add_pdn_connect -grid {core_grid} -layers {met1 met4}
add_pdn_connect -grid {core_grid} -layers {met4 met5}
 
pdngen
puts "✓ PDN complete"
 
write_db $RUNDIR/4_pdn.odb
puts "✓ Checkpoint: 4_pdn.odb"

puts "\nFloorplan + Pins + PDN complete."