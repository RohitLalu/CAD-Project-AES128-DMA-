#!/usr/bin/env openroad

# STAGE 4: Power Delivery Network

add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground

add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^HI$}
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^LO$}

set_voltage_domain -power VPWR -ground VGND

define_pdn_grid -name {grid} -voltage_domains {CORE}

# Standard cell power rails
add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {2.72} -offset {0} -followpins

# Power straps
add_pdn_stripe -grid {grid} -layer {met4} -width {1.6} -pitch {50.0} -offset {13.570}
add_pdn_stripe -grid {grid} -layer {met5} -width {1.6} -pitch {50.0} -offset {13.600}

# Power ring
add_pdn_ring -grid {grid} -layers {met4 met5} -widths {5.0 5.0} -spacings {2.0 2.0} -core_offsets {5.0 5.0}

# Connections
add_pdn_connect -grid {grid} -layers {met1 met4}
add_pdn_connect -grid {grid} -layers {met4 met5}

pdngen

