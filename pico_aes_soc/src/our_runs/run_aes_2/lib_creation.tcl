set_thread_count 7

set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
read_lef  ${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef  ${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty ${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_db aes_8_final.odb

set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2

read_sdc aes_sdc.sdc

set_output_delay -clock clk -max 2.0 [all_outputs]

estimate_parasitics -global_routing

write_timing_model aes_macro.lib

