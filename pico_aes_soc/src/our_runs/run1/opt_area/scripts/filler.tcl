set OUTPUT_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/outputs"

read_db $OUTPUT_DIR/06_routing.odb

filler_placement {sky130_fd_sc_hd__decap_12 sky130_fd_sc_hd__decap_8 sky130_fd_sc_hd__decap_6 sky130_fd_sc_hd__decap_4 sky130_fd_sc_hd__decap_3 sky130_fd_sc_hd__fill_8 sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_2 sky130_fd_sc_hd__fill_1}

write_db $OUTPUT_DIR/07_filler.odb