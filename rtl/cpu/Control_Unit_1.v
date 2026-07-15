`timescale 1ns / 1ps

// ============================================================
//  CONTROL UNIT (Updated for custom AES instruction support)
// ============================================================
//
//  - All original control signals preserved
//  - Added output: isAES
//  - AES instruction detect pattern added
//
//  AES instruction encoding example:
//      opcode  = 0001011  (custom-0 space)
//      funct7  = 0000001
//      funct3  = 000
//
//  Instruction format (R-type):
//      [31:25] funct7  (0000001)
//      [24:20] rs2
//      [19:15] rs1
//      [14:12] funct3  (000)
//      [11:7]  rd
//      [6:0]   opcode  (0001011)
//
//  CHANGE the detect logic if you choose a different encoding.
// ============================================================

module Control_Unit_1(

    input  [6:0] Op,
    input  [6:0] funct7,
    input  [2:0] funct3,

    output RegWrite,
    output [1:0] ResultSrc,
    output MemWrite,
    output Jump,
    output [2:0] Branch,
    output [3:0] ALUControl,
    output ALUSrc,
    output [2:0] ImmSrc,

    // NEW OUTPUT
    output wire isAES
);

    wire [1:0] ALUOp;
    wire isAES_ENC;
    wire isAES_DEC;

    // Instantiate Main Decoder
    Main_Decoder main_dec (
        .Op(Op),
        .funct3(funct3),

        .RegWrite(RegWrite),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .isJump(Jump),
        .ALUSrc(ALUSrc),
        .ImmSrc(ImmSrc),
        .Branch(Branch),
        .ALUOp(ALUOp)
    );

    // Instantiate ALU Decoder
    ALU_Decoder alu_dec (
        .op(Op),
        .funct3(funct3),
        .funct7(funct7),
        .ALUOp(ALUOp),
        .ALUControl(ALUControl)
    );

    // ======================================================
    //  AES INSTRUCTION DETECTION (CUSTOM-0 INSTRUCTION)
    // ======================================================
    //
    //  Change these 3 fields if you pick a different encoding.
    //
    // ======================================================

assign isAES_ENC =
    (Op     == 7'b0001011) &&
    (funct7 == 7'b0000111) &&
    (funct3 == 3'b000);

assign isAES_DEC =
    (Op     == 7'b0001011) &&
    (funct7 == 7'b0001000) &&
    (funct3 == 3'b000);

assign isAES = isAES_ENC | isAES_DEC;

endmodule



// ============================================================
//  MAIN DECODER
// ============================================================

module Main_Decoder(

    input [6:0] Op,
    input [2:0] funct3,

    output RegWrite,
    output [1:0] ResultSrc,
    output MemWrite,
    output isJump,
    output ALUSrc,
    output [2:0] ImmSrc,
    output [2:0] Branch,
    output [1:0] ALUOp
);

    // Register write disabled only for: store, branch, system
    assign RegWrite = (Op == 7'b0100011 |   // STORE
                       Op == 7'b1100011 |   // BRANCH
                       Op == 7'b1110011)    // SYSTEM
                       ? 1'b0 : 1'b1;

    // WB Mux select
    assign ResultSrc =
        (Op == 7'b0000011) ? 2'b01 :     // LOAD
        (Op == 7'b1101111 | Op == 7'b1100111) ? 2'b10 :   // JAL/JALR
        2'b00;

    // Memory write enable
    assign MemWrite = (Op == 7'b0100011) ? 1'b1 : 1'b0;

    // Jumps
    assign isJump = (Op == 7'b1101111 | Op == 7'b1100111) ? 1'b1 : 1'b0;

    // ALU input mux select
    assign ALUSrc = (Op == 7'b0000011 |    // LOAD
                     Op == 7'b0100011 |    // STORE
                     Op == 7'b0010011)     // I-type ALU
                     ? 1'b1 : 1'b0;

    // Immediate type encoder
    assign ImmSrc =
        (Op == 7'b0010011 | Op == 7'b1100111 | Op == 7'b1110011) ?
            ((funct3 == 3'b011) ? 3'b101 : 3'b000) :
        (Op == 7'b0000011) ?
            ((funct3 == 3'b100 | funct3 == 3'b101) ? 3'b101 : 3'b000) :
        (Op == 7'b0100011) ? 3'b001 :        // STORE
        (Op == 7'b1100011) ?                 // BRANCH
            ((funct3 == 3'b110 | funct3 == 3'b111) ? 3'b110 : 3'b010) :
        (Op == 7'b0110111 | Op == 7'b0010111) ? 3'b011 :   // LUI/AUIPC
        3'b100;

    // ALUOp
    assign ALUOp =
        (Op == 7'b0110011) ? 2'b00 :  // R-Type
        (Op == 7'b0010011) ? 2'b01 :  // I-Type
        (Op == 7'b1100011) ? 2'b10 :  // Branch
                             2'b11;   // Default: add

    assign Branch = (Op == 7'b1100011) ? funct3 : 3'b000;

endmodule



// ============================================================
//  ALU DECODER (unchanged)
// ============================================================

module ALU_Decoder( 

    input [1:0] ALUOp,
    input [2:0] funct3,
    input [6:0] funct7,
    input [6:0] op,

    output [3:0] ALUControl
);

    assign ALUControl =
        ((ALUOp == 2'b00) & (funct3 == 3'b000) & (funct7 == 7'b0000000)) ? 4'b0000 : 
        ((ALUOp == 2'b00) & (funct3 == 3'b000) & (funct7 == 7'b0100000)) ? 4'b0001 : 
        ((ALUOp == 2'b00) & (funct3 == 3'b001)) ? 4'b0101 :
        ((ALUOp == 2'b00) & (funct3 == 3'b010)) ? 4'b1000 :
        ((ALUOp == 2'b00) & (funct3 == 3'b011)) ? 4'b1001 :
        ((ALUOp == 2'b00) & (funct3 == 3'b100)) ? 4'b0010 :
        ((ALUOp == 2'b00) & (funct3 == 3'b101) & (funct7 == 7'b0000000)) ? 4'b0110 :
        ((ALUOp == 2'b00) & (funct3 == 3'b101) & (funct7 == 7'b0100000)) ? 4'b0111 :
        ((ALUOp == 2'b00) & (funct3 == 3'b110)) ? 4'b0011 :
        ((ALUOp == 2'b00) & (funct3 == 3'b111)) ? 4'b0100 :

        ((ALUOp == 2'b01) & (funct3 == 3'b000)) ? 4'b0000 : 
        ((ALUOp == 2'b01) & (funct3 == 3'b001)) ? 4'b0101 :
        ((ALUOp == 2'b01) & (funct3 == 3'b010)) ? 4'b1000 :
        ((ALUOp == 2'b01) & (funct3 == 3'b011)) ? 4'b1001 :
        ((ALUOp == 2'b01) & (funct3 == 3'b100)) ? 4'b0010 :
        ((ALUOp == 2'b01) & (funct3 == 3'b101) & (funct7 == 7'b0000000)) ? 4'b0110 :
        ((ALUOp == 2'b01) & (funct3 == 3'b101) & (funct7 == 7'b0100000)) ? 4'b0111 :
        ((ALUOp == 2'b01) & (funct3 == 3'b110)) ? 4'b0011 :
        ((ALUOp == 2'b01) & (funct3 == 3'b111)) ? 4'b0100 :

        (ALUOp == 2'b10) ? 4'b0001 :   // SUB
        (ALUOp == 2'b11) ? 4'b0000 :   // ADD
                           4'b0000 ;

endmodule
