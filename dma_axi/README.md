# README – DMA Controller Project with AXI4-Lite Interface

## Project Overview
This repository contains a **SystemVerilog implementation** of a DMA controller with an AXI4-Lite interface.  
The design allows the DMA core to read data from a source memory address and write it to a destination address over a memory-mapped AXI4-Lite bus.

The project includes:

- DMA core module (dma_core.sv)  
- AXI-Lite slave module (axi_lite_slave.sv)  
- AXI-Lite memory module (axi_lite_mem.sv)  
- Top-level integration module (dma_top.sv)  
- Simulation testbenches:
  - tb_dma_system.sv – DMA core with memory  
  - tb_dma_top.sv – Top-level system (DMA + AXI-Lite slave + memory)  
- Optional documentation (docs/) containing waveforms and analysis  

This setup is ideal for studying AXI handshakes, DMA memory transfers, and system-level integration.

## Folder Structure

**src/**  
- dma_core.sv – DMA controller logic  
- axi_lite_slave.sv – AXI-Lite slave for programming DMA registers  
- axi_lite_mem.sv – Memory block with AXI4-Lite interface  
- dma_top.sv – Top-level integration module  

**testbench/**  
- tb_dma_system.sv – Simulates DMA core with memory  
- tb_dma_top.sv – Simulates complete top-level system  

**docs/**  
- waveform_analysis.docx – Waveform captures and simulation analysis  

## How It Works

1. **Initialization:** Memory is preloaded with data at source addresses. Transfer parameters (source address, destination address, length) are set via the AXI-Lite slave in the testbench.

   Example initialization in the testbench:

   - Preload source memory:  
     - u_mem.mem[4] = 32'hDDDD_DDDA  
     - u_mem.mem[5] = 32'hDDDD_DDDB  
     - u_mem.mem[6] = 32'hDDDD_DDDC  
     - u_mem.mem[7] = 32'hDDDD_DDDD  

   - Program DMA transfer via AXI-Lite slave:  
     - axi_write(32'h00, 32'h4)  // src_addr = 4  
     - axi_write(32'h04, 32'ha)  // dst_addr = 10  
     - axi_write(32'h08, 32'h4)  // len = 4 words  
     - axi_write(32'h0C, 32'h1)  // ctrl_start = 1  

2. **DMA Operation:** The DMA core performs sequential read and write operations over the AXI4-Lite interface. Handshakes (AWVALID/AWREADY, WVALID/WREADY, BVALID/BREADY, ARVALID/ARREADY, RVALID/RREADY) ensure proper timing.

3. **Completion:** The status_done signal indicates that the DMA transfer has finished.

## Requirements

- Vivado (tested with version 2023.1)  
- SystemVerilog support  

## How to Run Simulations

1. Open Vivado.  
2. Create a new project and add src/ and the desired testbench from testbench/.  
3. Run either tb_dma_system.sv or tb_dma_top.sv in simulation mode.  
4. Observe memory contents, registers, and DMA transfers in the waveform viewer.  
5. Modify memory or DMA parameters in the testbench to test different scenarios.  

## Notes

- The project is primarily for **simulation**; no XDC file is provided.  
- dma_top.sv integrates the DMA core, AXI-Lite slave, and memory for full-system simulation.  
- Waveform captures and detailed simulation analysis are available in the docs/ folder.  

## Future Work

- Support for **burst transfers** over AXI.  
- **Multiple outstanding transactions** for higher throughput.  
- **Interrupt support** for asynchronous DMA completion notification.  
- **FPGA deployment** with proper constraints and timing validation.  

## Author

**Daniel Ichkovski**
