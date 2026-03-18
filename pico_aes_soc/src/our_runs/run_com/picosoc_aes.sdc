
# create_clock -name clk -period 30 [get_ports {clk}]

# # Clock uncertainty (jitter + skew)
# set_clock_uncertainty 0.5 [get_clocks {clk}]

# # Clock transition (rise/fall time)
# set_clock_transition 0.5 [get_clocks {clk}]

# # Set input delay for all input ports except clock
# # OpenROAD doesn't support remove_from_collection, so we list ports explicitly

# # Control inputs
# set_input_delay -clock clk -max 3.5 [get_ports {resetn}]
# set_input_delay -clock clk -max 3.5 [get_ports {iomem_ready}]
# set_input_delay -clock clk -max 3.5 [get_ports {ser_rx}]
# set_input_delay -clock clk -max 3.5 [get_ports {irq_5}]
# set_input_delay -clock clk -max 3.5 [get_ports {irq_6}]
# set_input_delay -clock clk -max 3.5 [get_ports {irq_7}]

# # Data inputs
# set_input_delay -clock clk -max 3.5 [get_ports {iomem_rdata[*]}]

# # Flash inputs
# set_input_delay -clock clk -max 3.5 [get_ports {flash_io0_di}]
# set_input_delay -clock clk -max 3.5 [get_ports {flash_io1_di}]
# set_input_delay -clock clk -max 3.5 [get_ports {flash_io2_di}]
# set_input_delay -clock clk -max 3.5 [get_ports {flash_io3_di}]

# # Input transition time
# set_input_transition 1.0 [get_ports {resetn}]
# set_input_transition 1.0 [get_ports {iomem_ready}]
# set_input_transition 1.0 [get_ports {iomem_rdata[*]}]
# set_input_transition 1.0 [get_ports {ser_rx}]
# set_input_transition 1.0 [get_ports {irq_*}]
# set_input_transition 1.0 [get_ports {flash_io*_di}]

# # ========================================================================
# # Output Constraints
# # ========================================================================

# # Output delay for all outputs
# set_output_delay -clock clk -max 3.5 [get_ports {iomem_valid}]
# set_output_delay -clock clk -max 3.5 [get_ports {iomem_wstrb[*]}]
# set_output_delay -clock clk -max 3.5 [get_ports {iomem_addr[*]}]
# set_output_delay -clock clk -max 3.5 [get_ports {iomem_wdata[*]}]
# set_output_delay -clock clk -max 3.5 [get_ports {ser_tx}]
# set_output_delay -clock clk -max 3.5 [get_ports {flash_csb}]
# set_output_delay -clock clk -max 3.5 [get_ports {flash_clk}]
# set_output_delay -clock clk -max 3.5 [get_ports {flash_io*_oe}]
# set_output_delay -clock clk -max 3.5 [get_ports {flash_io*_do}]

# # Output load (driving 4 standard loads)
# set_load 0.4 [all_outputs]

# # ========================================================================
# # False Paths
# # ========================================================================

# # Reset is asynchronous - no timing check needed
# set_false_path -from [get_ports {resetn}]

# # IRQ signals are asynchronous (synchronized internally)
# set_false_path -from [get_ports {irq_5}]
# set_false_path -from [get_ports {irq_6}]
# set_false_path -from [get_ports {irq_7}]

# =============================================================================
# aes_sdc.sdc  —  Timing constraints for PicoSoC + AES128 + SRAM
#
# Top-level module: picosoc
#
# Key points:
#   • reset_n / cs / we / address / write_data / read_data are AES *internal*
#     ports, not picosoc top-level ports — they cannot be referenced here.
#   • The picosoc top-level reset port is "resetn" (no underscore).
#   • AES and SRAM timing is covered by their .lib files (aes_macro.lib and
#     sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib). The SDC only
#     needs to constrain the top-level I/O and the clock.
#
# Top-level ports of module picosoc:
#   Inputs : clk, resetn, iomem_ready, iomem_rdata[31:0],
#            irq_5, irq_6, irq_7, ser_rx,
#            flash_io0_di, flash_io1_di, flash_io2_di, flash_io3_di
#   Outputs: iomem_valid, iomem_wstrb[3:0], iomem_addr[31:0],
#            iomem_wdata[31:0], ser_tx,
#            flash_csb, flash_clk,
#            flash_io{0,1,2,3}_oe, flash_io{0,1,2,3}_do
# =============================================================================

# =============================================================================
# 1. Clock — 50 MHz (20 ns period) on clk
#    Adjust period to match your target frequency.
#    PicoRV32 with sky130 HD typically closes at 50-80 MHz.
# =============================================================================
create_clock -name clk -period 30.0 [get_ports clk]

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
set_max_fanout  10 [current_design]
set_max_transition 1.5 [current_design]

# =============================================================================
# 7. Load / drive strength on I/Os
# =============================================================================
set_load 0.05 [all_outputs]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 \
                 -pin X [all_inputs]
