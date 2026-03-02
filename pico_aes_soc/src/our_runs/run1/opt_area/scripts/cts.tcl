set OUTPUT_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/outputs"
set SCRIPTS_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/scripts"

read_db $OUTPUT_DIR/04_placement.odb
read_liberty $env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_sdc $SCRIPTS_DIR/picosoc.sdc

set_dont_use *probe*
set_dont_use *lpflow*

set_thread_count 14
set_wire_rc -layer met3
clock_tree_synthesis -buf_list {sky130_fd_sc_hd__clkbuf_1 sky130_fd_sc_hd__clkbuf_2 sky130_fd_sc_hd__clkbuf_4} -clk_nets "clk"

set_propagated_clock [all_clocks]
estimate_parasitics -placement
repair_timing -hold -max_buffer_percent 20

detailed_placement -max_displacement 50

write_db $OUTPUT_DIR/05_cts.odb
