# RISC-V Crypto Co-Processor

A custom **32-bit 5-stage pipelined RISC-V processor** integrated with a **lightweight cryptographic co-processor**, developed entirely in **Verilog HDL**.

This repository presents the complete RTL implementation of a pipelined RISC-V processor tightly coupled with a lightweight AES-based cryptographic accelerator. The design targets secure embedded and edge computing applications by accelerating cryptographic operations while preserving the standard processor pipeline.

---

# System Architecture

The figure below illustrates the complete processor architecture, showing the integration of the five-stage RISC-V pipeline with the custom cryptographic co-processor.

<p align="center">
  <img src="docs/images/cipher.png" width="950">
</p>

---

# Features

- 32-bit RISC-V Processor
- Five-stage pipelined architecture
- Lightweight AES Cryptographic Co-Processor
- Tight processor-accelerator integration
- Hazard Detection Unit
- Data Forwarding Unit
- Modular RTL implementation
- Verilog HDL based design
- Hierarchical project organization

---

# Processor Pipeline

The processor follows the classic five-stage RISC-V pipeline.

| Stage | Description |
|-------|-------------|
| **Instruction Fetch (IF)** | Fetches instructions and updates the Program Counter |
| **Instruction Decode (ID)** | Decodes instructions, reads register operands and generates control signals |
| **Execute (EX)** | Performs ALU operations, branch evaluation and cryptographic instruction execution |
| **Memory (MEM)** | Executes load/store operations through Data Memory |
| **Write Back (WB)** | Writes computation results back into the Register File |

Complete documentation for every stage is available inside the corresponding directory under:

```text
rtl/cpu/
```

---

# Supported Directory Structure

```text
rtl/
├── cpu/
│   ├── cpu_top/
│   ├── fetch/
│   ├── decode/
│   ├── execute/
│   ├── memory/
│   ├── writeback/
│   └── hazard_unit/
│
└── crypto/
```

Each directory contains its own documentation describing the RTL implementation, internal architecture and constituent modules.

---

# Crypto Co-Processor

The processor integrates a lightweight cryptographic co-processor through a tightly coupled interface rather than using memory-mapped communication.

The accelerator supports:

- Lightweight AES Encryption
- Custom Crypto Instruction Interface
- Busy/Done Handshake Protocol
- Pipeline Stall Logic
- Native Processor Integration

The internal RTL architecture of the crypto accelerator is documented under:

```text
rtl/crypto/
```

---

# Functional Verification

The following waveform demonstrates the interaction between the processor and the cryptographic accelerator.

The processor issues an encryption request through **aes_start**, the accelerator enters the **aes_busy** state while computation is performed, and finally returns the encrypted ciphertext after completion.

<p align="center">
  <img src="docs/images/handshake.png" width="950">
</p>

---

# Project Organization

The repository has been organized hierarchically for easier navigation.

```text
RISC-V-Crypto-CoProcessor/
│
├── docs/
│   └── images/
│
├── rtl/
│   ├── cpu/
│   │   ├── fetch/
│   │   ├── decode/
│   │   ├── execute/
│   │   ├── memory/
│   │   ├── writeback/
│   │   ├── hazard_unit/
│   │   └── cpu_top/
│   │
│   └── crypto/
│
└── memory/
```

Every CPU stage has its own dedicated README containing:

- RTL Block Diagram
- Internal RTL Schematic
- Module Description
- Inputs and Outputs
- Design Notes

---

# Development Tools

- Verilog HDL
- Xilinx Vivado
- Quartus II

---

# Author

**Ishan Upadhye**

M.Tech – VLSI Design

---

# License

This project is released for educational and research purposes.
