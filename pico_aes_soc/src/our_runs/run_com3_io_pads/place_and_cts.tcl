# #!/usr/bin/env openroad
set_thread_count 7

# # --- Macro Paths ---
# set SRAM_LEF "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/sky130_sram_1kbyte_1rw1r_32x256_8.lef"
# set SRAM_LIB "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
# set AES_LEF  "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/aes_abstract.lef"
# set AES_LIB  "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/aes_macro.lib" 

# set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
# set PDK "sky130A"
# set LIB "sky130_fd_sc_hd"

# set TECH_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
# set SC_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
# set LIB_FILE "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# puts "PicoSoC + AES macro + SRAM macro Flow"

# puts "\n--- Reading design ---"

# puts "\n--- Reading design ---"
# read_lef $TECH_LEF
# read_lef $SC_LEF
# read_lef $SRAM_LEF
# read_lef $AES_LEF

# read_liberty $LIB_FILE
# read_liberty $SRAM_LIB
# read_liberty $AES_LIB

# read_verilog picosoc_syn.v
# link_design picosoc
# puts "✓ Design loaded with Macros"

# read_lef $TECH_LEF
# read_lef $SC_LEF
# read_liberty $LIB_FILE
# read_verilog picosoc_aes_sram.v
# link_design picosoc
# puts "✓ Design loaded"

# puts "\n--- Setting timing constraints ---"
# read_sdc picosoc_aes.sdc

#read_db 4_pdn.odb

puts "\n--- Placement (routing-driven) ---"

insert_tiecells sky130_fd_sc_hd__conb_1/HI
# -prefix "TIEHI"
insert_tiecells sky130_fd_sc_hd__conb_1/LO
# -prefix "TIELO"
set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2

global_placement -density 0.35 -routability_driven
set_placement_padding -global -left 0 -right 0
detailed_placement
check_placement -verbose -report_file_name placement_report_before_cts.rpt
#write_db 5_placement.odb

puts "\n--- Clock tree synthesis ---"
set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2
# Keep CTS buffers away from macro halo zones
set_placement_padding -masters {sky130_fd_sc_hd__clkbuf_*} -left 4 -right 4
clock_tree_synthesis \
    -buf_list {sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_2} \
    -root_buf sky130_fd_sc_hd__clkbuf_8

set_propagated_clock [all_clocks]

estimate_parasitics -placement
repair_clock_nets -max_wire_length 3500

set_placement_padding -masters {sky130_fd_sc_hd__clkbuf_*} -left 2 -right 2
detailed_placement
puts "✓ CTS complete"
#write_db 6_cts.odb


puts "FIXING TIMING & ANTENNA VIOLATIONS"
puts "\n--- Estimating parasitics ---"
estimate_parasitics -placement

puts "\n--- Repairing design rules (slew/cap) ---"
repair_design -max_wire_length 3500

estimate_parasitics -placement
puts "\n--- Repairing SETUP timing (WNS/TNS) ---"
repair_timing -setup -setup_margin 0.1 -max_passes 15

puts "\n--- Repairing HOLD timing ---"
#set_opt_config -disable_buffer_pruning
estimate_parasitics -placement
repair_timing -hold -hold_margin 0.1 -max_buffer_percent 30

#Legalize all new cells
set_placement_padding -global -left 1 -right 1
detailed_placement

puts "\n--- Optimization complete ---"
puts "Checking timing..."
estimate_parasitics -placement
report_worst_slack -max
report_tns
#write_db 6_timing_optimized.odb
