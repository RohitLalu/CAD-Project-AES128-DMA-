set OUTPUT_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/outputs"
set SCRIPTS_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/scripts"

read_db $OUTPUT_DIR/05_cts.odb
read_liberty $env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_sdc $SCRIPTS_DIR/picosoc.sdc

set_thread_count 8
set_wire_rc -layer met3

repair_tie_fanout -separation 1 sky130_fd_sc_hd__conb_1/HI
repair_tie_fanout -separation 1 sky130_fd_sc_hd__conb_1/LO
set block [ord::get_db_block]

set block [ord::get_db_block]
foreach net [$block getNets] {
    set net_name [$net getName]
    # Skip our actual global power/ground rails
    if {$net_name != "VGND" && $net_name != "VPWR"} {
        set sig_type [$net getSigType]
        # If any internal logic net is marked as power/ground, force it to SIGNAL
        if {$sig_type == "POWER" || $sig_type == "GROUND"} {
            $net setSigType SIGNAL
        }
    }
}

global_route -congestion_iterations 30
estimate_parasitics -global_routing

detailed_route -bottom_routing_layer met1 -top_routing_layer met5
write_db $OUTPUT_DIR/06_routing.odb