yosys -import

set HOME $env(HOME)
set PROJECT_ROOT "$HOME/CAD-Project-AES128-DMA-/pico_aes_soc/src"
set SKY130_ROOT  "$HOME/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set LIB_FILE     "$SKY130_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
set OUTPUT_DIR   "$PROJECT_ROOT/our_runs/run1/opt_area/outputs"
set REPORT_FILE  "$OUTPUT_DIR/synthesis_report.txt"
set env(TMPDIR) "$PROJECT_ROOT/our_runs/run1/opt_area/tmp"


# 3. READ RTL FILES
puts "\[INFO\] Reading RTL files..."

read_verilog -sv "$PROJECT_ROOT/aes_sbox.v"
read_verilog -sv "$PROJECT_ROOT/aes_inv_sbox.v"
read_verilog -sv "$PROJECT_ROOT/aes_key_mem.v"
read_verilog -sv "$PROJECT_ROOT/aes_encipher_block.v"
read_verilog -sv "$PROJECT_ROOT/aes_decipher_block.v"
read_verilog -sv "$PROJECT_ROOT/aes_core.v"
read_verilog -sv "$PROJECT_ROOT/aes.v"
read_verilog -sv "$PROJECT_ROOT/simpleuart.v"
read_verilog -sv "$PROJECT_ROOT/spimemio.v"
read_verilog -sv "$PROJECT_ROOT/picosoc_aes.v"
read_verilog -sv "$PROJECT_ROOT/picorv32.v"

synth -top picosoc_aes
dfflibmap -liberty $LIB_FILE
abc -liberty $LIB_FILE 
clean

write_verilog -noattr "$OUTPUT_DIR/netlist.v"

tee -o $REPORT_FILE stat -liberty $LIB_FILE