# # Define the clock period in nanoseconds (10ns = 100MHz)
# set clk_period 10
# set clk_port "clk"

# # Create the clock object
# create_clock -name $clk_port -period $clk_period [get_ports $clk_port]

# # Set input/output delays (standard rule of thumb is 20% of the clock period)
# set_input_delay [expr $clk_period * 0.2] -clock $clk_port [all_inputs]
# set_output_delay [expr $clk_period * 0.2] -clock $clk_port [all_outputs]

# # Set load and transition for more realistic results
# set_load 0.0334 [all_outputs]
# set_input_transition 0.5 [all_inputs]

