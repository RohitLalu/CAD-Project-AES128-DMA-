
create_clock -name clk -period 22.0 [get_ports {clk}]

# Clock uncertainty (jitter + skew)
set_clock_uncertainty 0.4 [get_clocks {clk}]

# Clock transition (rise/fall time)
set_clock_transition 0.5 [get_clocks {clk}]

# Inputs
set_input_delay -clock clk -max 2.0 [get_ports {reset_n}]
set_input_delay -clock clk -max 2.0 [get_ports {cs}]
set_input_delay -clock clk -max 2.0 [get_ports {we}]
set_input_delay -clock clk -max 2.0 [get_ports {address[*]}]
set_input_delay -clock clk -max 2.0 [get_ports {write_data[*]}]

# Input transition time
set_input_transition 1.0 [get_ports {reset_n}]
set_input_transition 1.0 [get_ports {cs}]
set_input_transition 1.0 [get_ports {we}]
set_input_transition 1.0 [get_ports {address[*]}]
set_input_transition 1.0 [get_ports {write_data[*]}]

#Outputs
set_output_delay -clock clk -max 2.0 [get_ports {read_data[*]}]

# Output load
set_load 0.2 [all_outputs]

# Reset is asynchronous - no timing check needed
set_false_path -from [get_ports {reset_n}]

# IRQ signals are asynchronous (synchronized internally)
set_false_path -from [get_ports {cs}]
set_false_path -from [get_ports {we}]

