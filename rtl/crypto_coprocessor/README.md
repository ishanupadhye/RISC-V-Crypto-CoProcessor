# Crypto Co-Processor

The cryptographic subsystem extends the RISC-V processor with a tightly coupled lightweight AES co-processor for hardware-accelerated encryption. The processor communicates with the accelerator using a dedicated control interface based on `aes_start`, `aes_busy`, and completion signals, allowing cryptographic operations to execute while maintaining correct pipeline synchronization.

---

# Encryption Flow

The lightweight cryptographic co-processor features a modified 6-round AES architecture with an XOR-based lightweight diffusion layer to reduce hardware complexity and latency. Integrated as a tightly-coupled custom instruction accelerator for the RV32I RISC-V processor.
The figure below illustrates the encryption flow implemented by the lightweight AES cryptographic engine.

<p align="center">
    <img src="../../../doc/images/crypto_flow.png" width="650">
</p>

The encryption process begins when the processor issues a custom cryptographic instruction. The AES co-processor accepts the plaintext and encryption key, performs the encryption internally, and returns the generated ciphertext to the processor upon completion.

---

# Simulation

The following simulation waveform verifies the communication between the processor and the cryptographic accelerator.

<p align="center">
    <img src="../../../doc/images/crypto_waves.png" width="950">
</p>

The waveform demonstrates the complete processor–accelerator handshake:

- The processor initiates encryption by asserting **`aes_start`**.
- The accelerator acknowledges the request by asserting **`aes_busy`**.
- The AES engine performs the encryption while the processor pipeline remains synchronized.
- After encryption completes, **`aes_busy`** is de-asserted.
- The generated ciphertext is returned to the processor for subsequent execution.

The successful assertion and de-assertion of the handshake signals verify the correct functional behavior of the cryptographic co-processor and its integration with the pipelined RISC-V processor.
