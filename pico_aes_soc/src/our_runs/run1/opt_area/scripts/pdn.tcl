set OUTPUT_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/outputs"

read_db $OUTPUT_DIR/02_pins.odb

add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$|^VPB$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$|^VNB$} -ground
set_voltage_domain -name {CORE} -power {VPWR} -ground {VGND}

define_pdn_grid -name {stdcell_grid} -voltage_domains {CORE}
add_pdn_stripe -grid {stdcell_grid} -layer {met1} -width {0.48} -pitch {2.72} -offset {0} -followpins
add_pdn_ring -grid {stdcell_grid} -layers {met4 met5} -widths {3.0 3.0} -spacings {1.6 1.6} -core_offsets {3.0 3.0}
add_pdn_stripe -grid {stdcell_grid} -layer {met4} -width {1.6} -pitch {50.0} -offset {10.0}
add_pdn_stripe -grid {stdcell_grid} -layer {met5} -width {1.6} -pitch {50.0} -offset {10.0}

add_pdn_connect -grid {stdcell_grid} -layers {met1 met4}
add_pdn_connect -grid {stdcell_grid} -layers {met4 met5}
pdngen

write_db $OUTPUT_DIR/03_pdn.odb