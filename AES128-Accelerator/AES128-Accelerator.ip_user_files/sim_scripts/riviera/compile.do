transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xilinx_vip
vlib riviera/xil_defaultlib

vmap xilinx_vip riviera/xilinx_vip
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xilinx_vip  -incr -l smartconnect_v1_0 -l axi_vip_v1_1_22 "+incdir+C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/include" -l xilinx_vip -l xil_defaultlib \
"C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/hdl/axi_vip_if.sv" \
"C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/hdl/clk_vip_if.sv" \
"C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../../../../../AMDDesignTools/2025.2/Vivado/data/rsb/busdef" "+incdir+../../../AES128-Accelerator.gen/sources_1/bd/picosoc_aes128/ipshared/f0b6/hdl/verilog" "+incdir+../../../AES128-Accelerator.gen/sources_1/bd/picosoc_aes128/ipshared/00fe/hdl/verilog" "+incdir+../../../AES128-Accelerator.gen/sources_1/bd/picosoc_aes128/ipshared/ec67/hdl" "+incdir+../../../AES128-Accelerator.gen/sources_1/bd/picosoc_aes128/ipshared/a415" "+incdir+C:/AMDDesignTools/2025.2/Vivado/data/xilinx_vip/include" -l xilinx_vip -l xil_defaultlib \
"../../../../CAD-Project-AES128-DMA-/picorv32/picorv32.v" \

vlog -work xil_defaultlib \
"glbl.v"

