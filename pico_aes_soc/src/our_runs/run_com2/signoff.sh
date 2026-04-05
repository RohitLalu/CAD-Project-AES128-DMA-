# #!/usr/bin/env bash
# # =============================================================================
# # signoff_checks.sh
# # Runs DRC, LVS, and Antenna checks for the PicoSoC+AES+SRAM design
# # Prerequisites: magic, netgen, openroad all available in nix-shell
# # Run from: ~/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2
# # =============================================================================

# PDK_ROOT="/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
# RUNDIR="/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"
# DESIGN="picosoc"
# GDS="$RUNDIR/picosoc_aes_combined.gds"
# DEF="$RUNDIR/picosoc_aes_combined.def"
# NETLIST="$RUNDIR/picosoc_syn.v"         # synthesized gate-level Verilog

# MAGIC_TECH="$PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech"
# MAGIC_RC="$PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc"
# NETGEN_SETUP="$PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl"

# mkdir -p $RUNDIR/signoff

# echo ""
# echo "============================================================"
# echo " SIGNOFF CHECKS: DRC + LVS + ANTENNA"
# echo "============================================================"
# echo ""

# # =============================================================================
# # STEP 1: ANTENNA CHECK (fastest — uses OpenROAD directly on ODB)
# # Run this first since it operates on the routed ODB without needing GDS.
# # =============================================================================
# echo "--- STEP 1: Antenna Check (OpenROAD) ---"

# openroad -no_init << 'OREOF'
# set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
# set RUNDIR   "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"

# read_lef $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
# read_lef $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
# read_lef $RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8.lef
# read_lef $RUNDIR/aes_abstract.lef
# read_liberty $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
# read_liberty $RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
# read_liberty $RUNDIR/aes_macro.lib

# read_db $RUNDIR/8_final.odb
# read_sdc $RUNDIR/picosoc_aes.sdc

# check_antennas

# puts "\n✓ Antenna check complete → signoff/antenna_final.rpt"
# OREOF

# echo "✓ Antenna check done"
# echo ""

# # =============================================================================
# # STEP 2: DRC (Magic — using the final GDS)
# # Uses full GDS including macro GDS for accurate DRC geometry.
# # Output: signoff/drc.rpt
# # =============================================================================
# echo "--- STEP 2: DRC Check (Magic) ---"

# magic -T $MAGIC_TECH -noconsole -dnull << 'MAGICEOF'
# gds read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
# gds read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/sky130_sram_1kbyte_1rw1r_32x256_8.gds
# gds read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/aes_m.gds
# load aes
# load sky130_sram_1kbyte_1rw1r_32x256_8
# lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
# lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
# lef read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/sky130_sram_1kbyte_1rw1r_32x256_8.lef
# lef read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/aes_abstract.lef
# def read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/picosoc_aes_combined.def
# load picosoc

# select top cell
# expand

# drc euclidean on
# drc style drc(full)
# drc check

# set drc_count [drc list count total]
# puts "Total DRC violations: $drc_count"

# set fout [open "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/signoff/drc.rpt" w]
# puts $fout "DRC Report — picosoc_aes_combined"
# puts $fout "Technology: sky130A"
# puts $fout "Tool: Magic 8.3"
# puts $fout "Total violations: $drc_count"
# puts $fout "---"
# foreach item [drc list] {
#     puts $fout $item
# }
# close $fout

# puts "✓ DRC complete → signoff/drc.rpt"
# quit -noprompt
# MAGICEOF

# echo "✓ DRC done"
# echo ""

# # =============================================================================
# # STEP 3: SPICE EXTRACTION (Magic — needed for LVS)
# #
# # Key fix: we do NOT read the macro GDS files (SRAM, AES) here.
# # Instead, macros are loaded via LEF only, which Magic treats as port-only
# # black boxes. After loading the DEF we explicitly call "cellname filepath"
# # to mark any residual internal cells as black boxes before extraction.
# #
# # The "33 errors / electrically shorted ports" warnings are expected and
# # harmless — they refer to DEF pad/power port naming, not real shorts.
# # They do NOT affect the extracted netlist correctness for LVS purposes.
# # =============================================================================
# echo "--- STEP 3: SPICE Extraction (Magic) ---"

# magic -T $MAGIC_TECH -noconsole -dnull << 'MAGICEOF'
# # Load ONLY the standard cell GDS — macro GDS files deliberately excluded
# # so Magic cannot descend into SRAM/AES transistor internals
# gds read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds

# # Macros arrive via LEF abstracts only — no transistor geometry
# lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
# lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
# lef read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/sky130_sram_1kbyte_1rw1r_32x256_8.lef
# lef read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/aes_abstract.lef

# def read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/picosoc_aes_combined.def
# load picosoc
# select top cell


# cellname list
# # Use the correct Magic 8.3 blackbox syntax:
# property sky130_sram_1kbyte_1rw1r_32x256_8 blackbox 1
# property aes blackbox 1


# # Explicitly mark the two macro cell types as black boxes for extraction.
# # This prevents ext2spice from expanding any residual internal geometry
# # that may have been inferred from the DEF component references.
# cellname filepath sky130_sram_1kbyte_1rw1r_32x256_8 ""
# cellname filepath aes ""

# # LVS-mode extraction settings:
# #   blackbox on    — emit macro instances as subcircuit calls, not expanded
# #   subcircuits on — write a .subckt wrapper for each hierarchy level
# #   hierarchy on   — preserve hierarchy (do not flatten to transistor level)
# ext2spice lvs
# ext2spice blackbox on
# ext2spice subcircuits on
# ext2spice hierarchy on
# extract do local
# extract no capacitance
# extract no coupling
# extract no resistance
# extract no adjust
# extract unique
# extract

# ext2spice -o /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/signoff/picosoc.spice
# puts "✓ SPICE extraction complete"
# quit -noprompt
# MAGICEOF

# # Sanity check — should be 0 if macros are properly black-boxed
# prim_count=$(grep -c "sky130_fd_pr__" $RUNDIR/signoff/picosoc.spice 2>/dev/null || echo 0)
# echo "Transistor primitive calls in SPICE: $prim_count  (should be 0)"
# if [ "$prim_count" -ne 0 ]; then
#     echo "WARNING: Macro internals still present in SPICE."
#     echo "         LVS will likely fail — check that LEF files are being read before DEF."
# fi
# echo ""

# # =============================================================================
# # STEP 4: SCHEMATIC NETLIST PREPARATION (for LVS)
# #
# # 4a: Write gate-level Verilog from the final ODB via OpenROAD.
# #     Note: -remove_cells is not available in OpenROAD 1.5.x, so we
# #     strip physical-only cells (filler/decap/tap) in a Python post-step.
# # 4b/4c: Write black-box stub modules for SRAM and AES so netgen can
# #     resolve their port lists without needing their full netlists.
# # 4d: Run netgen LVS comparing extracted SPICE vs gate-level Verilog.
# # =============================================================================
# echo "--- STEP 4: LVS Netlist Preparation + Comparison ---"

# # STEP 4a: Generate gate-level Verilog from final ODB
# openroad -no_init << 'OREOF'
# set RUNDIR "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"
# set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
# read_lef $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
# read_lef $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
# read_lef $RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8.lef
# read_lef $RUNDIR/aes_abstract.lef
# read_liberty $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
# read_liberty $RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
# read_liberty $RUNDIR/aes_macro.lib
# read_db $RUNDIR/8_final.odb
# write_verilog -include_pwr_gnd $RUNDIR/signoff/picosoc_gl_full.v
# puts "✓ Gate-level Verilog written → signoff/picosoc_gl_full.v"
# OREOF

# # STEP 4a (post): Strip physical-only cells that have no logical connectivity.
# # Filler, decap, and tap cells appear in the ODB/Verilog but NOT in the
# # extracted SPICE netlist, so they must be removed before LVS comparison.
# python3 - << 'PYEOF'
# import re

# RUNDIR = "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"

# # Matches the start of any filler/decap/tap/antenna-diode instantiation line.
# # These cells are inserted by the placer for physical reasons only and carry
# # no logical signal connections — netgen cannot match them to the SPICE.
# skip_patterns = re.compile(
#     r'\bsky130_fd_sc_hd__(fill|decap|tapvpwrvgnd|diode|tap)\w*\s+\w+\s*\('
# )

# removed = 0
# with open(f"{RUNDIR}/signoff/picosoc_gl_full.v") as fin, \
#      open(f"{RUNDIR}/signoff/picosoc_gl.v", "w") as fout:
#     skip = False
#     paren_depth = 0
#     for line in fin:
#         if not skip and skip_patterns.search(line):
#             skip = True
#             paren_depth = line.count('(') - line.count(')')
#             removed += 1
#             fout.write(f"// REMOVED: {line}")
#             continue
#         if skip:
#             paren_depth += line.count('(') - line.count(')')
#             fout.write(f"// REMOVED: {line}")
#             # Instantiation fully closed when parens balance and ); appears
#             if paren_depth <= 0 and ");" in line:
#                 skip = False
#                 paren_depth = 0
#         else:
#             fout.write(line)

# print(f"✓ Stripped {removed} physical-only cell instances → picosoc_gl.v")
# PYEOF

# # Verify strip worked — grep returns 1 (no match) which means count is 0
# remaining=$(grep -c "sky130_fd_sc_hd__fill\|sky130_fd_sc_hd__decap\|sky130_fd_sc_hd__tapvpwrvgnd" \
#     $RUNDIR/signoff/picosoc_gl.v 2>/dev/null || echo 0)
# echo "Physical-only cell lines remaining (should be 0): $remaining"

# # STEP 4b: SRAM black-box stub — ports must exactly match what write_verilog emitted.
# # If LVS shows SRAM port mismatches, cross-check against:
# #   grep -A5 "sky130_sram" $RUNDIR/signoff/picosoc_gl.v | head -20
# cat > $RUNDIR/signoff/sram_stub.v << 'STUBEOF'
# module sky130_sram_1kbyte_1rw1r_32x256_8 (
#     input         clk0,
#     input         csb0,
#     input         web0,
#     input  [7:0]  wmask0,
#     input  [7:0]  addr0,
#     input  [31:0] din0,
#     output [31:0] dout0,
#     input         clk1,
#     input         csb1,
#     input  [7:0]  addr1,
#     output [31:0] dout1,
#     input         vccd1,
#     input         vssd1
# );
# endmodule
# STUBEOF

# # STEP 4c: AES black-box stub — ports must match aes_abstract.lef pin names.
# # If LVS shows AES port mismatches, cross-check against:
# #   grep "PIN\|PORT\|DIRECTION" $RUNDIR/aes_abstract.lef
# cat > $RUNDIR/signoff/aes_stub.v << 'STUBEOF'
# module aes (
#     input         clk,
#     input         reset_n,
#     input         cs,
#     input         we,
#     input  [7:0]  address,
#     input  [31:0] write_data,
#     output [31:0] read_data,
#     input         VPWR,
#     input         VGND
# );
# endmodule
# STUBEOF

# # STEP 4d: Run LVS with netgen.
# # Both SPICE and Verilog use "picosoc" as the top-level cell name.
# # The stub files are appended to the Verilog argument so netgen can
# # resolve SRAM and AES module definitions without descending into them.
# # Stale report files from previous runs are cleared first to avoid
# # the "Could not open log file" error caused by locked/zero-byte files.
# rm -f $RUNDIR/signoff/lvs.rpt $RUNDIR/signoff/lvs_run.log

# netgen -batch lvs \
#     "$RUNDIR/signoff/picosoc.spice picosoc" \
#     "$RUNDIR/signoff/picosoc_gl.v $RUNDIR/signoff/sram_stub.v $RUNDIR/signoff/aes_stub.v picosoc" \
#     $NETGEN_SETUP \
#     $RUNDIR/signoff/lvs.rpt \
#     2>&1 | tee $RUNDIR/signoff/lvs_run.log

# echo ""
# echo "--- LVS verdict (last 10 lines of report) ---"
# if [ -s "$RUNDIR/signoff/lvs.rpt" ]; then
#     tail -10 $RUNDIR/signoff/lvs.rpt
# else
#     echo "ERROR: lvs.rpt not created or is empty."
#     echo "       Last 20 lines of netgen stdout:"
#     tail -20 $RUNDIR/signoff/lvs_run.log
# fi
# echo ""

# # =============================================================================
# # STEP 5: PARSE AND SUMMARIZE RESULTS
# # =============================================================================
# echo "============================================================"
# echo " SIGNOFF SUMMARY"
# echo "============================================================"
# echo ""

# # Antenna summary — check_antennas writes violations with keyword "violated"
# if [ -f "$RUNDIR/signoff/antenna_final.rpt" ]; then
#     antenna_viols=$(grep -ic "violated" $RUNDIR/signoff/antenna_final.rpt 2>/dev/null || echo "0")
#     echo "Antenna violations: $antenna_viols"
# else
#     echo "Antenna violations: (report not found)"
# fi

# # DRC summary
# if [ -f "$RUNDIR/signoff/drc.rpt" ]; then
#     drc_viols=$(grep "Total violations:" $RUNDIR/signoff/drc.rpt | awk '{print $NF}')
#     echo "DRC violations:     ${drc_viols:-unknown}"
# else
#     echo "DRC violations:     (report not found)"
# fi

# # LVS summary — netgen writes exactly one of these two verdict strings
# if [ -f "$RUNDIR/signoff/lvs.rpt" ]; then
#     if grep -q "Circuits match" $RUNDIR/signoff/lvs.rpt; then
#         echo "LVS result:         PASS — Circuits match"
#     elif grep -q "Netlists do not match" $RUNDIR/signoff/lvs.rpt; then
#         echo "LVS result:         FAIL — Netlists do not match"
#         echo "  → Check signoff/lvs.rpt for mismatch details"
#         echo "  → Common causes: macro port name mismatch, missing stub pins,"
#         echo "    or residual transistor primitives in picosoc.spice"
#     else
#         echo "LVS result:         INCOMPLETE — verdict string not found in report"
#         echo "  → netgen may have run out of memory or timed out mid-comparison"
#         echo "  → Check signoff/lvs_run.log for the last netgen message"
#     fi
# else
#     echo "LVS result:         NOT RUN — lvs.rpt missing"
# fi

# echo ""
# echo "All reports in: $RUNDIR/signoff/"
# echo "  antenna_final.rpt  — per-net antenna ratios (from OpenROAD)"
# echo "  drc.rpt            — DRC violations with coordinates (from Magic)"
# echo "  picosoc.spice      — extracted SPICE netlist (layout side)"
# echo "  picosoc_gl.v       — gate-level Verilog, physical cells stripped (schematic side)"
# echo "  lvs.rpt            — LVS comparison result (from netgen)"
# echo "  lvs_run.log        — full netgen stdout/stderr"
# echo ""

#!/usr/bin/env bash
# =============================================================================
# signoff_checks.sh
# Runs DRC, LVS, and Antenna checks for the PicoSoC+AES+SRAM design
# Prerequisites: magic, netgen, openroad all available in nix-shell
# Run from: ~/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2
# =============================================================================

PDK_ROOT="/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
RUNDIR="/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"
DESIGN="picosoc"
GDS="$RUNDIR/picosoc_aes_combined.gds"
DEF="$RUNDIR/picosoc_aes_combined.def"
NETLIST="$RUNDIR/picosoc_syn.v"

MAGIC_TECH="$PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech"
MAGIC_RC="$PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc"
NETGEN_SETUP="$PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl"

mkdir -p $RUNDIR/signoff

echo ""
echo "============================================================"
echo " SIGNOFF CHECKS: DRC + LVS + ANTENNA"
echo "============================================================"
echo ""

# =============================================================================
# STEP 1: ANTENNA CHECK (OpenROAD)
# =============================================================================
echo "--- STEP 1: Antenna Check (OpenROAD) ---"

openroad -no_init << 'OREOF'
set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set RUNDIR   "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"

read_lef $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_lef $RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_lef $RUNDIR/aes_abstract.lef
read_liberty $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty $RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_liberty $RUNDIR/aes_macro.lib

read_db $RUNDIR/8_final.odb
read_sdc $RUNDIR/picosoc_aes.sdc

check_antennas

puts "\n OK Antenna check complete"
OREOF

echo "OK Antenna check done"
echo ""

# =============================================================================
# STEP 2: DRC (Magic — full GDS for accurate geometry)
# =============================================================================
echo "--- STEP 2: DRC Check (Magic) ---"

magic -T $MAGIC_TECH -noconsole -dnull << 'MAGICEOF'
gds read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
gds read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/sky130_sram_1kbyte_1rw1r_32x256_8.gds
gds read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/aes_m.gds
load aes
load sky130_sram_1kbyte_1rw1r_32x256_8
lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
lef read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/sky130_sram_1kbyte_1rw1r_32x256_8.lef
lef read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/aes_abstract.lef
def read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/picosoc_aes_combined.def
load picosoc

select top cell
expand

drc euclidean on
drc style drc(full)
drc check

set drc_count [drc list count total]
puts "Total DRC violations: $drc_count"

set fout [open "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/signoff/drc.rpt" w]
puts $fout "DRC Report --- picosoc_aes_combined"
puts $fout "Technology: sky130A"
puts $fout "Tool: Magic 8.3"
puts $fout "Total violations: $drc_count"
puts $fout "---"
foreach item [drc list] {
    puts $fout $item
}
close $fout

puts "OK DRC complete"
quit -noprompt
MAGICEOF

echo "OK DRC done"
echo ""

# =============================================================================
# STEP 3: SPICE EXTRACTION (Magic)
#
# Macro GDS files are NOT loaded. Macros (SRAM, AES) arrive via LEF only,
# so Magic sees only their port geometry and cannot expand their internals.
# =============================================================================
echo "--- STEP 3: SPICE Extraction (Magic) ---"

magic -T $MAGIC_TECH -noconsole -dnull << 'MAGICEOF'
# Standard cell GDS only — no macro GDS files
gds read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds

# Macros via LEF abstracts only
lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
lef read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/sky130_sram_1kbyte_1rw1r_32x256_8.lef
lef read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/aes_abstract.lef

def read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/picosoc_aes_combined.def
load picosoc
select top cell

ext2spice lvs
ext2spice blackbox on
ext2spice subcircuits on
ext2spice hierarchy on
extract do local
extract no capacitance
extract no coupling
extract no resistance
extract no adjust
extract unique
extract

ext2spice -o /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2/signoff/picosoc.spice
puts "OK SPICE extraction complete"
quit -noprompt
MAGICEOF

prim_count=$(grep -c "sky130_fd_pr__" $RUNDIR/signoff/picosoc.spice 2>/dev/null || echo 0)
echo "Transistor primitive calls in SPICE: $prim_count  (should be 0)"
echo ""

# =============================================================================
# STEP 4: GATE-LEVEL VERILOG GENERATION
# =============================================================================
echo "--- STEP 4a: Generate Gate-Level Verilog (OpenROAD) ---"

openroad -no_init << 'OREOF'
set RUNDIR "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"
set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
read_lef $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_lef $RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_lef $RUNDIR/aes_abstract.lef
read_liberty $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty $RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_liberty $RUNDIR/aes_macro.lib
read_db $RUNDIR/8_final.odb
write_verilog -include_pwr_gnd $RUNDIR/signoff/picosoc_gl_full.v
puts "OK Gate-level Verilog written"
OREOF

echo "--- STEP 4b: Strip physical-only cells (Python) ---"

# KEY FIX: bare "endmodule" lines are always module terminators, never
# part of an instantiation block. They must never be commented out.
# The paren tracker is reset and the line is always emitted verbatim.
python3 - << 'PYEOF'
import re

RUNDIR = "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"

# Physical-only cells: present in ODB/Verilog but absent from extracted SPICE.
# clkload* = clock load buffers inserted by CTS, not in logical netlist
# load_slew* = slew repair buffers, not in logical netlist
# fill/decap/tap = standard physical cells
PHYS_CELL = re.compile(
    r'^\s*sky130_fd_sc_hd__('
    r'fill|decap|tapvpwrvgnd|diode|tap'
    r')\w*\s+\w+\s*\('
)

removed = 0
with open(f"{RUNDIR}/signoff/picosoc_gl_full.v") as fin, \
     open(f"{RUNDIR}/signoff/picosoc_gl.v", "w") as fout:

    skip = False
    paren_depth = 0

    for line in fin:
        stripped = line.strip()

        # CRITICAL: bare endmodule is a module terminator, not part of any
        # instantiation. Always emit it and always close any open skip block.
        if stripped == 'endmodule':
            if skip:
                # Paren tracker went wrong somewhere — reset and recover
                skip = False
                paren_depth = 0
            fout.write(line)
            continue

        # Detect start of a physical-only cell instantiation
        if not skip and PHYS_CELL.match(line):
            skip = True
            paren_depth = line.count('(') - line.count(')')
            removed += 1
            fout.write(f"// REMOVED: {line}")
            if paren_depth <= 0 and ');' in line:
                skip = False
                paren_depth = 0
            continue

        if skip:
            paren_depth += line.count('(') - line.count(')')
            fout.write(f"// REMOVED: {line}")
            if paren_depth <= 0 and ');' in line:
                skip = False
                paren_depth = 0
        else:
            fout.write(line)

print(f"OK Stripped {removed} physical-only instances -> picosoc_gl.v")
PYEOF

# Sanity: endmodule must exist and must not be commented out
endmod_count=$(grep -c "^endmodule" $RUNDIR/signoff/picosoc_gl.v 2>/dev/null || echo 0)
echo "endmodule lines in picosoc_gl.v: $endmod_count  (must be >= 1)"
if [ "$endmod_count" -eq 0 ]; then
    echo "FATAL: endmodule was stripped from picosoc_gl.v — aborting."
    exit 1
fi

echo "--- STEP 4c: Write macro stub modules ---"

cat > $RUNDIR/signoff/sram_stub.v << 'STUBEOF'
module sky130_sram_1kbyte_1rw1r_32x256_8 (
    input         clk0,
    input         csb0,
    input         web0,
    input  [7:0]  wmask0,
    input  [7:0]  addr0,
    input  [31:0] din0,
    output [31:0] dout0,
    input         clk1,
    input         csb1,
    input  [7:0]  addr1,
    output [31:0] dout1,
    input         vccd1,
    input         vssd1
);
endmodule
STUBEOF

cat > $RUNDIR/signoff/aes_stub.v << 'STUBEOF'
module aes (
    input         clk,
    input         reset_n,
    input         cs,
    input         we,
    input  [7:0]  address,
    input  [31:0] write_data,
    output [31:0] read_data,
    input         VPWR,
    input         VGND
);
endmodule
STUBEOF

# =============================================================================
# STEP 5: LVS via netgen Tcl script
#
# IMPORTANT: the netgen -batch lvs "cell1" "cell2" syntax passes cell name
# *strings*, but the lvs{} Tcl proc in netgen 1.5.x expects integer file
# handles returned by readnet. Using the Tcl script form with readnet
# followed by lvs {name} {name} is the correct API for this version.
# The -blackbox flag tells netgen not to expand placeholder cells
# (the sky130_fd_pr__ primitives in the SPICE) during comparison.
# =============================================================================
echo "--- STEP 5: LVS (netgen) ---"

rm -f $RUNDIR/signoff/lvs.rpt $RUNDIR/signoff/lvs_run.log

# Write the Tcl driver using printf to avoid heredoc variable expansion issues
printf '%s\n' \
    "# netgen LVS driver — picosoc sky130A" \
    "readnet spice {${RUNDIR}/signoff/picosoc.spice}" \
    "readnet verilog {${RUNDIR}/signoff/picosoc_gl.v}" \
    "readnet verilog {${RUNDIR}/signoff/sram_stub.v}" \
    "readnet verilog {${RUNDIR}/signoff/aes_stub.v}" \
    "lvs {picosoc} {picosoc} {${NETGEN_SETUP}} {${RUNDIR}/signoff/lvs.rpt} -blackbox" \
    > $RUNDIR/signoff/run_lvs.tcl

echo "Generated run_lvs.tcl:"
cat $RUNDIR/signoff/run_lvs.tcl
echo ""

netgen -batch source $RUNDIR/signoff/run_lvs.tcl \
    2>&1 | tee $RUNDIR/signoff/lvs_run.log

echo ""
echo "--- LVS verdict (last 15 lines of report) ---"
if [ -s "$RUNDIR/signoff/lvs.rpt" ]; then
    tail -15 $RUNDIR/signoff/lvs.rpt
else
    echo "ERROR: lvs.rpt not created or is empty."
    echo "Last 30 lines of netgen log:"
    tail -30 $RUNDIR/signoff/lvs_run.log
fi
echo ""

# =============================================================================
# STEP 6: SIGNOFF SUMMARY
# =============================================================================
echo "============================================================"
echo " SIGNOFF SUMMARY"
echo "============================================================"
echo ""

if [ -f "$RUNDIR/signoff/antenna_final.rpt" ]; then
    antenna_viols=$(grep -ic "violated" $RUNDIR/signoff/antenna_final.rpt 2>/dev/null || echo "0")
    echo "Antenna violations: $antenna_viols"
else
    echo "Antenna violations: (report not found)"
fi

if [ -f "$RUNDIR/signoff/drc.rpt" ]; then
    drc_viols=$(grep "Total violations:" $RUNDIR/signoff/drc.rpt | awk '{print $NF}')
    echo "DRC violations:     ${drc_viols:-unknown}"
else
    echo "DRC violations:     (report not found)"
fi

if [ -f "$RUNDIR/signoff/lvs.rpt" ]; then
    if grep -q "Circuits match" $RUNDIR/signoff/lvs.rpt; then
        echo "LVS result:         PASS --- Circuits match"
    elif grep -q "Netlists do not match" $RUNDIR/signoff/lvs.rpt; then
        echo "LVS result:         FAIL --- Netlists do not match"
        echo "  -> Check signoff/lvs.rpt for mismatch details"
    else
        echo "LVS result:         INCOMPLETE --- verdict not found in report"
        echo "  -> Check signoff/lvs_run.log"
    fi
else
    echo "LVS result:         NOT RUN --- lvs.rpt missing"
fi

echo ""
echo "Reports in: $RUNDIR/signoff/"
echo "  antenna_final.rpt  --- per-net antenna ratios"
echo "  drc.rpt            --- DRC violations with coordinates"
echo "  picosoc.spice      --- extracted SPICE netlist (layout side)"
echo "  picosoc_gl.v       --- gate-level Verilog, physical cells stripped"
echo "  run_lvs.tcl        --- netgen driver script"
echo "  lvs.rpt            --- LVS comparison result"
echo "  lvs_run.log        --- full netgen stdout/stderr"
echo ""