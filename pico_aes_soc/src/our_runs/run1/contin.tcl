# # You're already past placement, so continue from CTS:

# puts "\n--- Clock tree synthesis ---"
# create_clock -name clk -period 25.0 [get_ports {clk}]
# set_clock_uncertainty 2.5 [get_clocks {clk}]
# clock_tree_synthesis \
#     -buf_list {sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_2}

puts "\n--- Global routing ---"
global_route  -allow_congestion

puts "\n--- Detailed routing ---"
detailed_route \
    -output_drc route_drc.rpt \
    -droute_end_iter 10 \
    -bottom_routing_layer met1 \
    -top_routing_layer met5

puts "\n--- Filler cells ---"
filler_placement -cells {
    sky130_fd_sc_hd__fill_8
    sky130_fd_sc_hd__fill_4
    sky130_fd_sc_hd__fill_2
    sky130_fd_sc_hd__fill_1
}

puts "\n--- Outputs ---"
write_def picosoc_aes_final.def
write_gds -lib_files /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds picosoc_aes_final.gds
