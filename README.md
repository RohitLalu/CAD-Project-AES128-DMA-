# CAD Project: AES128-DMA Integration

Integrating AES128 encryption block with PicoRV32 core and DMA block to accelerate the encryption process.

## Project Overview

This project implements a hardware-accelerated AES128 encryption system by integrating:
- **AES128 Encryption Block**: Custom hardware implementation for AES128 encryption
- **PicoRV32 Core**: A lightweight RISC-V processor for system control
- **DMA Block**: Direct Memory Access controller to optimize data transfer and acceleration

The goal is to create a high-performance cryptographic system suitable for embedded and edge computing applications.

## Technology Stack

| Language | Percentage |
|----------|-----------|
| VHDL | 45.1% |
| Verilog | 41.6% |
| SystemVerilog | 9.0% |
| Python | 2.3% |
| Tcl | 0.5% |
| C | 0.4% |
| Other | 1.1% |

## Key Components

### Hardware Design
- **VHDL & Verilog**: Core hardware implementation for encryption and DMA modules
- **SystemVerilog**: Advanced testbenches and verification

### Control & Testing
- **Python**: Build scripts and simulation utilities
- **Tcl**: Design automation and tool configuration
- **C**: Low-level firmware/driver code

## Features

- Lightweight RISC-V processor (PicoRV32) for flexible instruction execution
- Hardware-accelerated AES128 encryption engine
- DMA controller for efficient memory operations
- Optimized data throughput and reduced CPU overhead

## Directory Structure

```
CAD-Project-AES128-DMA-/
├── hardware/          # RTL design files (VHDL, Verilog, SystemVerilog)
├── testbenches/       # Verification and simulation files
├── scripts/           # Python and Tcl automation scripts
├── firmware/          # C code for PicoRV32
└── docs/             # Documentation and design specifications
```

## Getting Started

### Prerequisites
- Hardware design tools (Vivado, ModelSim, or equivalent)
- Python 3.x
- RISC-V toolchain (for firmware development)

### Build & Simulation

Instructions for building and simulating the design will be provided in detailed documentation.

## License

[Add License Information]

## Author

RohitLalu

## References

- [PicoRV32 Documentation](https://github.com/cliffordwolf/picorv32)
- AES Encryption Standard (FIPS 197)

---

*For detailed technical information and design specifications, please refer to the project documentation.*
