# #!/usr/bin/env openroad
# # STAGE 10: Reports & Outputs

# # Timing reports

# # --- First, load your design ---
# # 1. Load Technology LEF (CRITICAL for DEF parsing)
# read_lef /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef

# # 2. Load Standard Cell / Macro LEF
# read_lef /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef

# read_def picosoc_aes_final.def

# read_liberty /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# puts "Generating timing reports..."
# report_checks -path_delay max -format full_clock > timing_report.txt
# report_tns > tns_fast__report.txt  
# report_wns > wns_fast__report.txt
# # check_antennas -verbose > antenna_report.txt

# # Power report
# puts "Generating power report..."
# report_power > power_fast__report.txt

# # Final statistics
# report_design_area > area_report.txt
# puts " Physical Design Complete!"


#!/usr/bin/env openroad
# STAGE 10: Reports & Outputs

# --- First, load your design ---

# 1. Load Technology LEF
read_lef /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef

# 2. Load Standard Cell / Macro LEF
read_lef /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef

# 3. Read DEF
read_def picosoc_aes_final.def

# 4. Read Liberty
read_liberty /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 5. Read Constraints (CRITICAL FIX: Update this path to your SDC file!)
read_sdc trial_picosoc.sdc

# --- Generate Reports ---

puts "Generating timing reports..."
report_checks -path_delay max -format full_clock > timing_report.txt
report_tns > tns_fast__report.txt  
report_wns > wns_fast__report.txt

puts "Running antenna checks..."
# Correct OpenROAD syntax for antenna checking
check_antennas -report_file antenna_report.txt -report_violating_nets

puts "Generating power report..."
report_power > power_fast__report.txt

puts "Generating area report..."
report_design_area > area_report.txt

puts "✅ Physical Design Complete!"