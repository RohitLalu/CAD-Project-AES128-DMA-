#!/usr/bin/env openroad

# STAGE 7: Routing

# ── Global Routing ──────────────────────────────────────────────────────────
# set_routing_layers uses "min-max" layer name format per GRT docs
# li1-met5 = full stack for signal (all 6 layers)
# met3-met5 = upper metals only for clock (lower R/C)

set_routing_layers -signal li1-met5 \
                   -clock  met3-met5

global_route \
    -congestion_iterations 30 \
    -congestion_report_file grt_congestion.rpt \
    -verbose

# ── Detailed Routing ─────────────────────────────────────────────────────────
detailed_route \
    -bottom_routing_layer li1 \
    -top_routing_layer met5 \
    -output_drc route_drc.rpt \
    -output_maze route_maze.log \
    -verbose 1

# ── Post-route checks ────────────────────────────────────────────────────────
set_propagated_clock [all_clocks]
report_checks -path_delay max -fields {slew cap input nets fanout} \
              -format full_clock_expanded > timing_post_route.rpt
report_checks -path_delay min -fields {slew cap input nets fanout} \
              -format full_clock_expanded >> timing_post_route.rpt
report_wns
report_tns
report_power

puts "\n✓ Routing complete. Check route_drc.rpt for violations."
puts "  Timing summary written to timing_post_route.rpt"