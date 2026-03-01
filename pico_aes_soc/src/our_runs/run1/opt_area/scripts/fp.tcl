set PDK_ROOT "$env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd"
set OUTPUT_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/outputs"

read_lef $PDK_ROOT/techlef/sky130_fd_sc_hd__nom.tlef
read_lef $PDK_ROOT/lef/sky130_fd_sc_hd.lef
read_liberty $PDK_ROOT/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog $OUTPUT_DIR/netlist.v
link_design picosoc_aes

initialize_floorplan -die_area {0 0 1400 1400} -core_area {30 30 1370 1370} -site unithd
make_tracks
tapcell -distance 14 -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1 -endcap_master sky130_fd_sc_hd__decap_4

write_db $OUTPUT_DIR/01_fp.odb