transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+picorv32_axi  -L xil_defaultlib -L xilinx_vip -L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.picorv32_axi xil_defaultlib.glbl

do {picorv32_axi.udo}

run 1000ns

endsim

quit -force
