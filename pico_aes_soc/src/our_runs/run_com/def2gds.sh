# magic -T /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.tech/magic/sky130A.tech -noconsole -dnull << 'EOF'
# lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
# lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
# def read picosoc_aes_combined.def
# load picosoc
# gds read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
# gds write picosoc_aes_combined.gds
# quit -noprompt
# EOF
# echo "✅ picosoc GDSII created!"


PDK_ROOT="/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
RUNDIR="/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com"

SRAM_GDS="$RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8.gds"

AES_GDS="$RUNDIR/aes_m.gds"


missing=0
for f in "$SRAM_GDS" "$AES_GDS"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: GDS file not found: $f"
        missing=1
    fi
done
if [ "$missing" -eq 1 ]; then
    echo ""
    echo "Find your macro GDS files with:"
    echo "  find ~/CAD-Project-AES128-DMA- -name '*.gds' 2>/dev/null"
    echo "  find $RUNDIR -name '*.gds' 2>/dev/null"
    echo "Then update the SRAM_GDS and AES_GDS variables in this script."
    exit 1
fi

echo "Using SRAM GDS: $SRAM_GDS"
echo "Using AES  GDS: $AES_GDS"
echo "Starting Magic..."

magic -T "$PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech" -noconsole -dnull << EOF


lef read $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
lef read $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
lef read $RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8.lef
lef read $RUNDIR/aes_abstract.lef

gds read $SRAM_GDS
gds read $AES_GDS

def read $RUNDIR/picosoc_aes_combined.def

load picosoc

gds read $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds

gds write $RUNDIR/picosoc_aes_combined.gds

quit -noprompt
EOF

if [ $? -eq 0 ]; then
    echo "✅ picosoc_aes_combined.gds created successfully"
    echo ""
    echo "Verify in KLayout:"
    echo "  klayout picosoc_aes_combined.gds"
    echo ""
    echo "Check that aes and sram cells appear in the cell hierarchy:"
    echo "  klayout picosoc_aes_combined.gds -e -rx -rd input=picosoc_aes_combined.gds \\"
    echo "    -rm 'puts [join [lsort [db::each_cell]] \\n]'"
else
    echo "❌ Magic exited with errors — check output above"
fi