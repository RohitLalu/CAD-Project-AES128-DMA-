# #!/usr/bin/env openroad

# read_db picosoc_after_routing.odb


filler_placement sky130_fd_sc_hd__fill_* 
# above statement worked
write_db picosoc_final.odb
write_def picosoc_aes_final.def
gds write "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds" picosoc_aes_final.gds
puts "🎉 DONE! Check picosoc_aes_final.gds"