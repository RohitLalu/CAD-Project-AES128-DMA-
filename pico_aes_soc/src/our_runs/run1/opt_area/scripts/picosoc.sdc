create_clock -name clk -period 25.0 [get_ports {clk}]
set_clock_uncertainty 1.0 [get_clocks {clk}]
set_clock_transition 0.5 [get_clocks {clk}]

set input_ports [get_ports -filter {name != "clk"} [all_inputs]]
set_input_delay -clock clk -max 10.0 $input_ports
set_input_delay -clock clk -min 5.0 $input_ports
set_input_transition 1.0 $input_ports

set_output_delay -clock clk -max 10.0 [all_outputs]
set_output_delay -clock clk -min 5.0 [all_outputs]
set_load 0.4 [all_outputs]

set_false_path -from [get_ports {resetn}]