#!/usr/bin/env bash

PDK_ROOT="/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
RUNDIR="/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com"
SRAM_GDS="$RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8.gds"
AES_GDS="$RUNDIR/aes_m.gds"
SC_GDS="$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds"

magic -T "$PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech" -noconsole -dnull << 'MAGICEOF'
gds read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
gds read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/sky130_sram_1kbyte_1rw1r_32x256_8.gds
gds read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/aes_m.gds
load aes
load sky130_sram_1kbyte_1rw1r_32x256_8
lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
lef read /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
lef read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/sky130_sram_1kbyte_1rw1r_32x256_8.lef
lef read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/aes_abstract.lef
def read /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/picosoc_aes_combined.def
load picosoc
gds write /Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/picosoc_aes_combined.gds
quit -noprompt
MAGICEOF

echo "Done. Check picosoc_aes_combined.gds"