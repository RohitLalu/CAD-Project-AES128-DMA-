
puts "=========================================="
puts "Generating Power Delivery Network (PDN)"
puts "=========================================="

puts "\n--- Setting power/ground nets ---"

add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground

set_voltage_domain -power VPWR -ground VGND

puts "Power net: VPWR"
puts "Ground net: VGND"

puts "\n--- Defining PDN grid ---"

define_pdn_grid -name {grid} -voltage_domains {CORE}

add_pdn_stripe \
    -grid {grid} \
    -layer {met1} \
    -width {0.48} \
    -pitch {2.72} \
    -offset {0} \
    -followpins

puts "  met1 rails: width=0.48µm, pitch=2.72µm (follows standard cell rows)"

add_pdn_stripe \
    -grid {grid} \
    -layer {met4} \
    -width {1.6} \
    -pitch {50.0} \
    -offset {25.0}

puts "  met4 straps: width=1.6µm, pitch=50µm (vertical)"

add_pdn_stripe \
    -grid {grid} \
    -layer {met5} \
    -width {1.6} \
    -pitch {50.0} \
    -offset {25.0}

puts "  met5 straps: width=1.6µm, pitch=50µm (horizontal)"

puts "\n--- Adding power ring ---"

add_pdn_ring \
    -grid {grid} \
    -layers {met4 met5} \
    -widths {5.0 5.0} \
    -spacings {2.0 2.0} \
    -core_offsets {15.0 15.0}

puts "  Power ring: met4/met5, width=5µm, core offset=5µm"

puts "\n--- Defining via connections ---"

add_pdn_connect \
    -grid {grid} \
    -layers {met1 met4}

add_pdn_connect \
    -grid {grid} \
    -layers {met4 met5}

puts "  Connections: met1↔met4, met4↔met5"

puts "\n--- Generating PDN geometry ---"

pdngen

puts "\n=========================================="
puts "PDN Generation Complete!"
puts "=========================================="
puts "\nTo verify PDN:"
puts "  - Use GUI: gui::show"
puts "  - Check layers: View → Layers → enable met1, met4, met5"
puts "  - Red/blue grid should be visible"
puts "=========================================="