`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.11.2025 23:18:29
// Design Name: 
// Module Name: Hazard_Detection
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps
module Hazard_Detection(
    input  wire        clk,
    input  wire        reset,       // active-high reset (matches your code style)
    // load-use hazard inputs
    input  wire        MemReadE,    // must be 1 when EX stage instruction is a load (propagate from decode)
    input  wire [4:0]  RD_E,        // destination reg in EX stage
    input  wire [4:0]  RS1_D,       // source regs in ID stage
    input  wire [4:0]  RS2_D,
    // branch taken from EX stage
    input  wire        BranchTakenE, // PCSrcE from Execute_Cycle
    // aes co-processor busy
    input  wire        aes_busy,
    // outputs to pipeline control (connect where PC and IF/ID registers are updated)
    output reg         PCWrite,
    output reg         IF_ID_Write,
    output reg         ID_EX_Flush
);

    wire load_use_hazard;
    assign load_use_hazard = (MemReadE & (RD_E != 5'd0) & ((RD_E == RS1_D) | (RD_E == RS2_D)));

    always @(*) begin
        // defaults
        PCWrite     = 1'b1;
        IF_ID_Write = 1'b1;
        ID_EX_Flush = 1'b0;

        // AES stall highest priority: freeze PC and IF/ID, keep ID/EX as-is
        if (aes_busy) begin
            PCWrite     = 1'b0;
            IF_ID_Write = 1'b0;
            ID_EX_Flush = 1'b0;
        end
        else if (load_use_hazard) begin
            // stall one cycle: freeze PC and IF/ID and insert bubble into EX by flushing ID/EX
            PCWrite     = 1'b0;
            IF_ID_Write = 1'b0;
            ID_EX_Flush = 1'b1;
        end
        else if (BranchTakenE) begin
            // branch taken: allow PC to change to target, but flush ID/EX (remove wrong-path instruction)
            PCWrite     = 1'b1;
            IF_ID_Write = 1'b1;
            ID_EX_Flush = 1'b1;
        end
    end

endmodule

