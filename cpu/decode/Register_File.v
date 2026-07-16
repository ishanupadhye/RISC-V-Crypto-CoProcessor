`timescale 1ns / 1ps

module Register_File(
    input  wire        clock,
    input  wire        reset,

    // CPU register read ports
    input  wire [4:0]  A1,
    input  wire [4:0]  A2,

    // CPU write-back port
    input  wire [4:0]  A3,
    input  wire [31:0] WD3,
    input  wire        WE3,

    // AES write port (from aes_cp wrapper)
    input  wire        aes_wen,
    input  wire [4:0]  aes_waddr,
    input  wire [31:0] aes_wdata,

    // CPU read outputs
    output wire [31:0] RD1,
    output wire [31:0] RD2,

    // Expose registers x24..x31 for AES core input
    output wire [31:0] gpr24,
    output wire [31:0] gpr25,
    output wire [31:0] gpr26,
    output wire [31:0] gpr27,
    output wire [31:0] gpr28,
    output wire [31:0] gpr29,
    output wire [31:0] gpr30,
    output wire [31:0] gpr31
);

    // -----------------------------------
    // REGISTER FILE: 32 × 32-bit registers
    // -----------------------------------
    reg [31:0] rf [0:31];
    integer i;

    // Asynchronous reads
    assign RD1 = rf[A1];
    assign RD2 = rf[A2];

    // expose GPRs for AES wrapper
    assign gpr24 = rf[24];
    assign gpr25 = rf[25];
    assign gpr26 = rf[26];
    assign gpr27 = rf[27];
    assign gpr28 = rf[28];
    assign gpr29 = rf[29];
    assign gpr30 = rf[30];
    assign gpr31 = rf[31];

    // -----------------------------------
    // Write logic
    //  AES write FIRST  (priority)
    //  CPU write SECOND
    // -----------------------------------
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                rf[i] <= 32'h00000000;   // reset all GPRs

        end else begin

            // 1) AES write (highest priority)
            if (aes_wen == 1'b1 && aes_waddr != 5'd0) begin
                rf[aes_waddr] <= aes_wdata;
            end

            // 2) CPU writeback (only if AES NOT writing this cycle)
            else if (WE3 && A3 != 5'd0) begin
                rf[A3] <= WD3;
            end

        end
    end

endmodule
