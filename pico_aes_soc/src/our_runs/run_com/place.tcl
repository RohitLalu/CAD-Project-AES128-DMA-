#!/usr/bin/env openroad

# --- Macro Paths ---
set SRAM_LEF "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/sky130_sram_1kbyte_1rw1r_32x256_8.lef"
set SRAM_LIB "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
set AES_LEF  "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/aes_macro_1.lef"
set AES_LIB  "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/aes_macro.lib" 

set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK "sky130A"
set LIB "sky130_fd_sc_hd"

set TECH_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set SC_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set LIB_FILE "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

puts "PicoSoC + AES macro + SRAM macro Flow"

puts "\n--- Reading design ---"

puts "\n--- Reading design ---"
read_lef $TECH_LEF
read_lef $SC_LEF
read_lef $SRAM_LEF
read_lef $AES_LEF

read_liberty $LIB_FILE
read_liberty $SRAM_LIB
read_liberty $AES_LIB

read_verilog picosoc_syn.v
link_design picosoc
puts "✓ Design loaded with Macros"

read_lef $TECH_LEF
read_lef $SC_LEF
read_liberty $LIB_FILE
read_verilog picosoc_aes_sram.v
link_design picosoc
puts "✓ Design loaded"

puts "\n--- Setting timing constraints ---"
read_sdc picosoc_aes.sdc

read_db 4_pdn.odb

puts "\n--- Placement (timing-driven) ---"

insert_tiecells sky130_fd_sc_hd__conb_1/HI
# -prefix "TIEHI"
insert_tiecells sky130_fd_sc_hd__conb_1/LO
# -prefix "TIELO"
set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2

global_placement -density 0.4 -timing_driven
set_placement_padding -global -left 2 -right 2
detailed_placement
check_placement -verbose -report_file_name placement_report_before_cts.rpt
write_db 5_placement.odb