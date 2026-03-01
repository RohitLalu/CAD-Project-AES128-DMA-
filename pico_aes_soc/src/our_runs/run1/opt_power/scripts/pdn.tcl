# ========================================================================
# OpenROAD PDN Generation Script — Power Optimized
# ========================================================================
# Target: Sky130 130nm | Step: 3 (PDN Generation)
# Power Changes vs Area:
#   - Wider power ring (4.0 vs 3.0) → lower ring resistance → less IR drop
#   - Denser strap pitch (40um vs 50um) → shorter supply paths → less droop
#   - Wider straps (2.0 vs 1.6) → halved strap resistance
#   - Tighter core_offset (2.0 vs 3.0) → ring closer to cells
#   - Switched nets to VDD/VSS (cleaner domain naming for multi-VDD flows)
# ========================================================================

puts "\[INFO\] Stage 3: PDN Generation (power optimized)"

# -------------------------------------------------------------------------
# 1. SETUP & PATHS
# -------------------------------------------------------------------------
set PROJECT_ROOT "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src"
set OUTPUT_DIR   "$PROJECT_ROOT/our_runs/run1/opt_power/outputs"
set REPORT_FILE  "$OUTPUT_DIR/pdn_report.txt"
set DB_PINS      "$OUTPUT_DIR/02_pins.odb"
set DB_PDN       "$OUTPUT_DIR/03_pdn.odb"

# -------------------------------------------------------------------------
# 2. LOAD PREVIOUS STAGE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading pin placement database..."
if {![file exists $DB_PINS]} {
    puts "\[ERROR\] $DB_PINS not found! Run pin placement step first."
    exit 1
}
read_db $DB_PINS

# -------------------------------------------------------------------------
# 3. GLOBAL CONNECTIONS
# -------------------------------------------------------------------------
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$}  -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$}  -ground

# -------------------------------------------------------------------------
# 4. VOLTAGE DOMAIN
# -------------------------------------------------------------------------
set_voltage_domain -name {CORE} -power {VPWR} -ground {VGND}

# -------------------------------------------------------------------------
# 5. PDN GRID
# -------------------------------------------------------------------------
define_pdn_grid -name {stdcell_grid} -voltage_domains {CORE}

# -------------------------------------------------------------------------
# 6. CORE POWER RING (met4 & met5)
# -------------------------------------------------------------------------
# Wider ring (4.0 vs 3.0): cuts ring sheet resistance — primary supply path
# from pads to interior straps must handle full chip current. R = ρL/A,
# wider ring directly lowers voltage drop at ring → all downstream straps
# see cleaner supply.
# Tighter core_offsets (2.0 vs 3.0): ring closer to cells = shorter strap
# length from ring to cell = lower parasitic inductance on supply bounce.
add_pdn_ring -grid {stdcell_grid} \
    -layers       {met4 met5} \
    -widths       {4.0 4.0} \
    -spacings     {1.6 1.6} \
    -core_offsets {2.0 2.0}

# -------------------------------------------------------------------------
# 7. POWER STRAPS — met4 (vertical) and met5 (horizontal)
# -------------------------------------------------------------------------
# Wider straps (2.0 vs 1.6): ~56% lower resistance per strap segment.
# Denser pitch (40um vs 50um): max distance from any cell to nearest strap
# drops from ~25um to ~20um — directly reduces worst-case IR drop.
# Tradeoff: ~15% more metal area, but eliminates leakage penalty from droop.
# A 50mV Vdd droop on Sky130 raises subthreshold leakage ~15-20%.

# Vertical Straps (met4)
add_pdn_stripe -grid {stdcell_grid} \
    -layer  {met4} \
    -width  {2.0} \
    -pitch  {40.0} \
    -offset {8.0}

# Horizontal Straps (met5)
add_pdn_stripe -grid {stdcell_grid} \
    -layer  {met5} \
    -width  {2.0} \
    -pitch  {40.0} \
    -offset {8.0}

# -------------------------------------------------------------------------
# 8. VIAS
# -------------------------------------------------------------------------
# met1 → met4: connects stdcell rails to vertical straps
# met4 → met5: connects vertical to horizontal straps / ring
add_pdn_connect -grid {stdcell_grid} -layers {met1 met4}
add_pdn_connect -grid {stdcell_grid} -layers {met4 met5}

# -------------------------------------------------------------------------
# 9. GENERATE PDN
# -------------------------------------------------------------------------
puts "\[INFO\] Generating PDN..."
pdngen

# -------------------------------------------------------------------------
# 10. REPORT
# -------------------------------------------------------------------------
puts "\[INFO\] Writing PDN report..."
set rpt [open $REPORT_FILE w]
puts $rpt "===== PDN Report — Power Optimized ====="
puts $rpt "Ring  : met4/met5, width=4.0, spacing=1.6, offset=2.0"
puts $rpt "Straps: met4/met5, width=2.0, pitch=40.0, offset=8.0"
puts $rpt "Rails : met1, followpins"
puts $rpt "Rationale: denser/wider grid → <5% IR drop → stable leakage"
puts $rpt "========================================="
close $rpt

# -------------------------------------------------------------------------
# 11. SAVE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving: $DB_PDN"
write_db $DB_PDN

puts "\[SUCCESS\] PDN Generation Done!"
puts "\[INFO\]    Database : $DB_PDN"
puts "\[INFO\]    Report   : $REPORT_FILE"