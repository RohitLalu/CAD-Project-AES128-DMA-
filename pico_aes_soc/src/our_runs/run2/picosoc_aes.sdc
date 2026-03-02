
# Target: 40 MHz (25 ns period)

create_clock -name clk -period 25.0 [get_ports {clk}]

# Clock uncertainty (jitter + skew)
set_clock_uncertainty 2.5 [get_clocks {clk}]

# Clock transition (rise/fall time)
set_clock_transition 0.5 [get_clocks {clk}]

# Set input delay for all input ports except clock
# OpenROAD doesn't support remove_from_collection, so we list ports explicitly

# Control inputs
set_input_delay -clock clk -max 10.0 [get_ports {resetn}]
set_input_delay -clock clk -max 10.0 [get_ports {iomem_ready}]
set_input_delay -clock clk -max 10.0 [get_ports {ser_rx}]
set_input_delay -clock clk -max 10.0 [get_ports {irq_5}]
set_input_delay -clock clk -max 10.0 [get_ports {irq_6}]
set_input_delay -clock clk -max 10.0 [get_ports {irq_7}]

# Data inputs
set_input_delay -clock clk -max 10.0 [get_ports {iomem_rdata[*]}]

# Flash inputs
set_input_delay -clock clk -max 10.0 [get_ports {flash_io0_di}]
set_input_delay -clock clk -max 10.0 [get_ports {flash_io1_di}]
set_input_delay -clock clk -max 10.0 [get_ports {flash_io2_di}]
set_input_delay -clock clk -max 10.0 [get_ports {flash_io3_di}]

# Input transition time
set_input_transition 1.0 [get_ports {resetn}]
set_input_transition 1.0 [get_ports {iomem_ready}]
set_input_transition 1.0 [get_ports {iomem_rdata[*]}]
set_input_transition 1.0 [get_ports {ser_rx}]
set_input_transition 1.0 [get_ports {irq_*}]
set_input_transition 1.0 [get_ports {flash_io*_di}]

# ========================================================================
# Output Constraints
# ========================================================================

# Output delay for all outputs
set_output_delay -clock clk -max 10.0 [get_ports {iomem_valid}]
set_output_delay -clock clk -max 10.0 [get_ports {iomem_wstrb[*]}]
set_output_delay -clock clk -max 10.0 [get_ports {iomem_addr[*]}]
set_output_delay -clock clk -max 10.0 [get_ports {iomem_wdata[*]}]
set_output_delay -clock clk -max 10.0 [get_ports {ser_tx}]
set_output_delay -clock clk -max 10.0 [get_ports {flash_csb}]
set_output_delay -clock clk -max 10.0 [get_ports {flash_clk}]
set_output_delay -clock clk -max 10.0 [get_ports {flash_io*_oe}]
set_output_delay -clock clk -max 10.0 [get_ports {flash_io*_do}]

# Output load (driving 4 standard loads)
set_load 0.4 [all_outputs]

# ========================================================================
# False Paths
# ========================================================================

# Reset is asynchronous - no timing check needed
set_false_path -from [get_ports {resetn}]

# IRQ signals are asynchronous (synchronized internally)
set_false_path -from [get_ports {irq_5}]
set_false_path -from [get_ports {irq_6}]
set_false_path -from [get_ports {irq_7}]

# ========================================================================
# Notes
# ========================================================================
# - Clock period: 25 ns (40 MHz)
# - Input/output delays: 10 ns (40% of period)
# - Should leave ~5 ns margin for internal logic
# - This is conservative and should be achievable
