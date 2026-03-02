# 1. Setup Paths
set OUTPUT_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/outputs"
set SCRIPTS_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/scripts"
set REPORT_FILE "final_signoff_report.txt"

# 2. Load the Routed Design and Constraints
read_liberty $env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_db $OUTPUT_DIR/06_routing.odb 
read_sdc $SCRIPTS_DIR/picosoc.sdc

# 3. Generate Reports
report_checks -path_delay max -format full_clock > $REPORT_FILE
report_tns >> $REPORT_FILE
report_wns >> $REPORT_FILE
report_power >> $REPORT_FILE
report_design_area >> $REPORT_FILE

# 4. Write Final Files
write_def picosoc_aes_final.def