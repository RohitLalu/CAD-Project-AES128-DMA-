# ========================================================================
# SDC Timing Constraints for PicoSoC
# Target Frequency: 40 MHz (25 ns period)
# ========================================================================

# ========================================================================
# Clock Definition
# ========================================================================
# Create main clock: 40 MHz (25 ns period)
create_clock -name clk -period 25.0 [get_ports {clk}]

# Clock uncertainty (jitter + skew) - conservative estimate
# Typically 5-10% of period for on-chip clock
set_clock_uncertainty 2.5 [get_clocks {clk}]

# Clock transition (rise/fall time)
set_clock_transition 0.5 [get_clocks {clk}]

# ========================================================================
# Input Constraints
# ========================================================================
# All inputs except clock
set all_inputs [all_inputs]
set clk_port [get_ports {clk}]
set input_ports [remove_from_collection $all_inputs $clk_port]

# Input delay: Assume external device provides data with some delay
# Conservative: 40% of clock period (10 ns)
set input_delay 10.0
set_input_delay -clock clk -max $input_delay $input_ports
set_input_delay -clock clk -min [expr $input_delay * 0.5] $input_ports

# Input transition time (external driver rise/fall time)
set_input_transition 1.0 $input_ports

# ========================================================================
# Output Constraints  
# ========================================================================
# Output delay: Assume external device needs data with some setup time
# Conservative: 40% of clock period (10 ns)
set output_delay 10.0
set_output_delay -clock clk -max $output_delay [all_outputs]
set_output_delay -clock clk -min [expr $output_delay * 0.5] [all_outputs]

# Output load: Assume driving standard capacitive load
# Typical fanout = 4 (0.1 pF per gate input in Sky130)
set_load 0.4 [all_outputs]

# ========================================================================
# Environmental Conditions
# ========================================================================
# Operating conditions already defined in liberty file (tt_025C_1v80)
# Voltage: 1.8V nominal
# Temperature: 25°C

# ========================================================================
# Special Constraints
# ========================================================================

# Reset is asynchronous - no timing check needed
set_false_path -from [get_ports {resetn}]

# If you have any multi-cycle paths (not typical for PicoSoC)
# Example: set_multicycle_path -setup 2 -from [get_pins ...] -to [get_pins ...]

# ========================================================================
# Design-Specific Constraints
# ========================================================================

# SPI Flash interface - if you're using external SPI flash, these signals
# might need special constraints. For now, using default I/O constraints.

# UART signals (ser_tx, ser_rx) - these are typically much slower than
# the system clock, but we'll keep the default constraints

# IRQ signals - asynchronous inputs, but synchronized internally
# No special constraints needed as they go through synchronizers

# ========================================================================
# Timing Exceptions (if needed)
# ========================================================================

# Example: If you have any false paths (paths that don't need timing check)
# set_false_path -from [get_pins some_reg/Q] -to [get_pins other_reg/D]

# Example: If you have any timing paths that can take multiple cycles
# set_multicycle_path -setup 2 -from [get_pins ...] -to [get_pins ...]

# ========================================================================
# Notes
# ========================================================================
# - Clock period: 25 ns (40 MHz)
# - Setup margin: ~5 ns after accounting for input/output delays
# - This should be achievable with Sky130 for this design
# - Critical paths will likely be in the CPU datapath (ALU, shifters)
# - Memory paths should be fine with single-cycle access
