# ========================================================================
# SDC Timing Constraints for PicoSoC (OpenROAD Compatible)
# Target Frequency: 40 MHz (25 ns period)
# ========================================================================

# ========================================================================
# 1. Clock Definition
# ========================================================================
# Create main clock: 40 MHz (25 ns period)
create_clock -name clk -period 25.0 [get_ports {clk}]

# Clock uncertainty (jitter + skew)
set_clock_uncertainty 2.5 [get_clocks {clk}]

# Clock transition (rise/fall time)
set_clock_transition 0.5 [get_clocks {clk}]

# ========================================================================
# 2. Input Constraints
# ========================================================================
# CRITICAL FIX: Use 'get_ports' with a filter to exclude the clock.
# 'remove_from_collection' is not supported in all OpenROAD versions.

set input_ports [get_ports -filter {name != "clk"} [all_inputs]]

# Input delay: 10ns (40% of period)
set input_delay 10.0
set_input_delay -clock clk -max $input_delay $input_ports
set_input_delay -clock clk -min [expr $input_delay * 0.5] $input_ports

# Input transition
set_input_transition 1.0 $input_ports

# ========================================================================
# 3. Output Constraints
# ========================================================================
# Output delay: 10ns (40% of period)
set output_delay 10.0
set_output_delay -clock clk -max $output_delay [all_outputs]
set_output_delay -clock clk -min [expr $output_delay * 0.5] [all_outputs]

# Output load: 0.4pF (Standard load)
set_load 0.4 [all_outputs]

# ========================================================================
# 4. Special Constraints
# ========================================================================

# Reset is asynchronous - no timing check needed
# Note: 'get_ports' is safer than 'get_pins' for top-level ports
set_false_path -from [get_ports {resetn}]

# ========================================================================
# 5. Environment
# ========================================================================
# (Optional, but good practice)
set_operating_conditions -analysis_type single