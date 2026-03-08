# ---------------------------------------------------------------------
# 1. GENERATE PIN LISTS MANUALLY FROM PICOSOC.V
# ---------------------------------------------------------------------

# IO Memory Interface (External)
set iomem_pins {iomem_valid iomem_ready}
for {set i 0} {$i < 4} {incr i} { lappend iomem_pins "iomem_wstrb\[$i\]" }
for {set i 0} {$i < 32} {incr i} { 
    lappend iomem_pins "iomem_addr\[$i\]" 
    lappend iomem_pins "iomem_wdata\[$i\]"
    lappend iomem_pins "iomem_rdata\[$i\]"
}

# Flash SPI Interface 
set flash_pins {flash_csb flash_clk}
for {set i 0} {$i < 4} {incr i} {
    lappend flash_pins "flash_io${i}_oe"
    lappend flash_pins "flash_io${i}_do"
    lappend flash_pins "flash_io${i}_di"
}

# Interrupts and UART [cite: 6, 12]
set misc_pins {irq_5 irq_6 irq_7 ser_tx ser_rx}

# Control Pins
set control_pins {clk resetn}

# ---------------------------------------------------------------------
# 2. APPLY CONSTRAINTS (Organized by Function)
# ---------------------------------------------------------------------

# Left (West) -> Power, Clock, Reset, and Interrupts
set_io_pin_constraint -direction left -pin_names [concat $control_pins $misc_pins]

# Top (North) -> Flash SPI Interface (Typically high-speed/specific layout)
set_io_pin_constraint -direction top -pin_names $flash_pins

# Right (East) & Bottom (South) -> High-density I/O Memory Bus
# Split the large iomem bus to avoid congestion on one side
set_io_pin_constraint -direction right -pin_names $iomem_pins

# ---------------------------------------------------------------------
# 3. PLACE PINS
# ---------------------------------------------------------------------
make_tracks 
# Run placement using Metal 3 (Horizontal) and Metal 2 (Vertical)
place_pins -hor_layers met5 -ver_layers met4

puts "PicoSoC I/O pins placed based on picosoc.v definitions!"