create_clock -name clk -period 35.0 [get_ports {clk}]
set_clock_uncertainty 2.5 [get_clocks {clk}]