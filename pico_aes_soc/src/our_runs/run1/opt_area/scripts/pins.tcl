set OUTPUT_DIR "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run1/opt_area/outputs"


read_db $OUTPUT_DIR/01_fp.odb

# -------------------------------------------------------------------------
# PIN ASSIGNMENT (Optimized for Data Flow)
# -------------------------------------------------------------------------

# WEST: System Control & Interrupts
set west_pins {
    clk
    resetn
    irq_5
    irq_6
    irq_7
}

# EAST: UART
set east_pins {
    ser_rx
    ser_tx
}

# NORTH: Flash Memory Bus
set north_pins {
    flash_csb
    flash_clk
}
for {set i 0} {$i < 4} {incr i} { 
    lappend north_pins "flash_io${i}_di"   
    lappend north_pins "flash_io${i}_oe"
    lappend north_pins "flash_io${i}_do"
}

# SOUTH: Core Memory Bus (AES + PicoSoC Data)
set south_pins {
    iomem_valid
    iomem_ready
}
for {set i 0} {$i < 4}  {incr i} { lappend south_pins "iomem_wstrb\[$i\]" }
for {set i 0} {$i < 32} {incr i} { lappend south_pins "iomem_addr\[$i\]"  }
for {set i 0} {$i < 32} {incr i} { lappend south_pins "iomem_wdata\[$i\]" }
for {set i 0} {$i < 32} {incr i} { lappend south_pins "iomem_rdata\[$i\]" }

place_pins -hor_layers met1 -ver_layers met2
write_db $OUTPUT_DIR/02_pins.odb