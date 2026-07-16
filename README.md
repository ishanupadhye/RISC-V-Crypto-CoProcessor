# RISC-V Crypto Co-Processor

A custom **32-bit 5-stage pipelined RISC-V processor** integrated with a **lightweight cryptographic co-processor**, developed entirely in **Verilog HDL**.

This project demonstrates the complete RTL design of a pipelined RISC-V processor along with a custom cryptographic accelerator intended for secure embedded and edge computing applications.

---

## Overview

The processor follows the classic five-stage RISC-V pipeline:

- Instruction Fetch (IF)
- Instruction Decode (ID)
- Execute (EX)
- Memory Access (MEM)
- Write Back (WB)

The processor is integrated with a lightweight cryptographic co-processor to accelerate cryptographic operations while maintaining compatibility with the processor datapath.

---

## Features

- 32-bit RISC-V Processor
- Five-stage pipelined architecture
- Modular RTL design
- Hazard handling logic
- Lightweight cryptographic co-processor
- Written entirely in Verilog HDL
- Hierarchical project organization for easy understanding

---

# Directory Structure

```text
rtl/
├── cpu/
│   ├── fetch/
│   ├── decode/
│   ├── execute/
│   ├── memory/
│   ├── writeback/
│   ├── hazard_unit/
│   └── cpu_top/
│
└── crypto/
```

---

# CPU Pipeline

## Fetch Stage

Responsible for:

- Program Counter (PC)
- PC increment logic
- Instruction Memory
- Instruction Fetch

---

## Decode Stage

Responsible for:

- Register File
- Control Unit
- Immediate Generation
- Instruction Decode

---

## Execute Stage

Responsible for:

- ALU Operations
- Branch Evaluation
- Operand Selection
- Arithmetic and Logical Instructions

---

## Memory Stage

Responsible for:

- Data Memory Access
- Load Operations
- Store Operations

---

## Write Back Stage

Responsible for:

- Register Write Back
- Result Selection

---

## Hazard Unit

Implements hazard detection and pipeline control to ensure correct execution of dependent instructions.

---

# Crypto Co-Processor

The repository also contains a lightweight cryptographic co-processor designed for integration with the RISC-V pipeline.

The crypto subsystem is modular and can be extended with additional cryptographic algorithms.

---

# Repository Organization

Each pipeline stage is documented independently to improve readability and simplify RTL exploration.

Future updates will include:

- Architecture diagrams
- Datapath illustrations
- Control path diagrams
- RTL hierarchy
- Simulation waveforms
- Verification methodology

---

# Development Tools

- Verilog HDL
- Xilinx Vivado
- ModelSim / Compatible Simulator

---

# Author

**Ishan Upadhye**

M.Tech VLSI Design

---

## License

This project is released for educational and research purposes.
