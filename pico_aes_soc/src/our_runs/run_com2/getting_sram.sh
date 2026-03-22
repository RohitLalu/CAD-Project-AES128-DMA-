#!/usr/bin/env bash


PDK_ROOT="/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
MACRO="sky130_sram_1kbyte_1rw1r_32x256_8"
SRC="$PDK_ROOT/sky130A/libs.ref/sky130_sram_macros"
RUNDIR="/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com"

echo "[copy_sram] Source : $SRC"
echo "[copy_sram] Dest   : $RUNDIR"
echo ""

# ── Copy each format ──────────────────────────────────────────────────────────
for fmt in lef lib verilog gds spice; do
    # verilog dir uses .v extension
    if [ "$fmt" = "verilog" ]; then
        src_file="$SRC/verilog/${MACRO}.v"
        dst_file="$RUNDIR/${MACRO}.v"
    else
        src_file="$SRC/${fmt}/${MACRO}.${fmt}"
        dst_file="$RUNDIR/${MACRO}.${fmt}"
    fi

    if [ -f "$src_file" ]; then
        cp "$src_file" "$dst_file"
        echo "  [OK]  $(basename $dst_file)"
    else
        # Try alternate extensions
        alt=$(ls $SRC/${fmt}/${MACRO}.* 2>/dev/null | head -1)
        if [ -n "$alt" ]; then
            cp "$alt" "$RUNDIR/"
            echo "  [OK]  $(basename $alt)  (alternate extension)"
        else
            echo "  [!!]  MISSING: $src_file"
        fi
    fi
done

# ── Also grab TT corner lib specifically (needed for STA) ─────────────────────
echo ""
echo "[copy_sram] Checking for corner libs..."
for lib_file in "$SRC/lib/${MACRO}"*.lib; do
    [ -f "$lib_file" ] || continue
    cp "$lib_file" "$RUNDIR/"
    echo "  [OK]  $(basename $lib_file)"
done

echo ""
echo "[copy_sram] Files now in $RUNDIR:"
ls -lh "$RUNDIR/${MACRO}"* 2>/dev/null