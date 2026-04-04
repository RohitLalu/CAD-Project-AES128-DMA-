
create_clock -name clk -period 25.0 [get_ports clk]

# =============================================================================
# 2. Clock uncertainty (jitter + skew budget)
# =============================================================================
set_clock_uncertainty 0.5 [get_clocks clk]

# =============================================================================
# 3. Input delays — all inputs relative to clk
#    Use 2 ns input delay (10% of period) as a conservative estimate.
# =============================================================================
set_input_delay -max 2.0 -clock clk [get_ports resetn]
set_input_delay -max 2.0 -clock clk [get_ports iomem_ready]
set_input_delay -max 2.0 -clock clk [get_ports {iomem_rdata[*]}]
set_input_delay -max 2.0 -clock clk [get_ports irq_5]
set_input_delay -max 2.0 -clock clk [get_ports irq_6]
set_input_delay -max 2.0 -clock clk [get_ports irq_7]
set_input_delay -max 2.0 -clock clk [get_ports ser_rx]
set_input_delay -max 2.0 -clock clk [get_ports flash_io0_di]
set_input_delay -max 2.0 -clock clk [get_ports flash_io1_di]
set_input_delay -max 2.0 -clock clk [get_ports flash_io2_di]
set_input_delay -max 2.0 -clock clk [get_ports flash_io3_di]

# =============================================================================
# 4. Output delays — all outputs relative to clk
# =============================================================================
set_output_delay -max 2.0 -clock clk [get_ports iomem_valid]
set_output_delay -max 2.0 -clock clk [get_ports {iomem_wstrb[*]}]
set_output_delay -max 2.0 -clock clk [get_ports {iomem_addr[*]}]
set_output_delay -max 2.0 -clock clk [get_ports {iomem_wdata[*]}]
set_output_delay -max 2.0 -clock clk [get_ports ser_tx]
set_output_delay -max 2.0 -clock clk [get_ports flash_csb]
set_output_delay -max 2.0 -clock clk [get_ports flash_clk]
set_output_delay -max 2.0 -clock clk [get_ports flash_io0_oe]
set_output_delay -max 2.0 -clock clk [get_ports flash_io1_oe]
set_output_delay -max 2.0 -clock clk [get_ports flash_io2_oe]
set_output_delay -max 2.0 -clock clk [get_ports flash_io3_oe]
set_output_delay -max 2.0 -clock clk [get_ports flash_io0_do]
set_output_delay -max 2.0 -clock clk [get_ports flash_io1_do]
set_output_delay -max 2.0 -clock clk [get_ports flash_io2_do]
set_output_delay -max 2.0 -clock clk [get_ports flash_io3_do]

# =============================================================================
# 5. False paths
#    resetn is an asynchronous reset — no timing arc needed from it.
# =============================================================================
set_false_path -from [get_ports resetn]

# =============================================================================
# 6. Max fanout / transition (optional but recommended for sky130 HD)
# =============================================================================
set_max_fanout  20 [current_design]
set_max_transition 1.5 [current_design]

# =============================================================================
# 7. Load / drive strength on I/Os
# =============================================================================
set_load 0.05 [all_outputs]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 \
                 -pin X [all_inputs]
