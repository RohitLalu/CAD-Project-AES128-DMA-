set OUTPUT_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/outputs"
set SCRIPTS_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/scripts"

read_db $OUTPUT_DIR/03_pdn.odb
read_liberty $env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_sdc $SCRIPTS_DIR/picosoc.sdc

set_dont_use *probe*
set_dont_use *lpflow*

set_thread_count 14
set_wire_rc -layer met3

# -------------------------------------------------------------------------
# AES PLACEMENT REGION (Hierarchical Cell Matching)
# -------------------------------------------------------------------------
puts "\[INFO\] Creating physical region for AES core..."

set block [ord::get_db_block]
set region [odb::dbRegion_create $block "aes_bound"]

# Draw a 400x350um box in the South-West corner (Coordinates in DBU)
odb::dbBox_create $region 50000 50000 450000 400000 

# Search through every physical leaf cell and add AES logic to the box
set inst_count 0
foreach inst [$block getInsts] {
    set inst_name [$inst getName]
    # Match any standard cell whose name starts with "aes_inst"
    if {[string match "aes_inst*" $inst_name]} {
        $region addInst $inst
        incr inst_count
    }
}

if {$inst_count > 0} {
    puts "\[INFO\] Successfully locked $inst_count AES logic cells into aes_bound"
} else {
    puts "\[WARNING\] Could not find any cells matching 'aes_inst*'."
}
# -------------------------------------------------------------------------

global_placement -density 0.50

estimate_parasitics -placement
repair_design -max_wire_length 200 -max_utilization 60

detailed_placement -max_displacement 50
optimize_mirroring

write_db $OUTPUT_DIR/04_placement.odb