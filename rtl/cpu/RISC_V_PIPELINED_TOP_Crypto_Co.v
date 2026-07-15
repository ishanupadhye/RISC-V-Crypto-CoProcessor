`timescale 1ns / 1ps

module RISC_V_PIPELINED_TOP_Crypto_Co(
    input  clock,
    input  reset,
    output [31:0] output1
);

    // ----------------------------
    // FETCH → DECODE
    // ----------------------------
    wire [31:0] InstrD, PCD, PCPlus4D;
    wire aes_mode_E;

    // ----------------------------
    // DECODE → EXECUTE
    // ----------------------------
    wire RegWriteE, ALUSrcE, MemWriteE, JumpE;
    wire [2:0] BranchE;
    wire [1:0] ResultSrcE;
    wire [3:0] ALUControlE;
    wire [31:0] RD1_E, RD2_E, Imm_Ext_E;
    wire [4:0] RS1_E, RS2_E, RD_E;
    wire [31:0] PCE, PCPlus4E;
    wire isAES_E;   // AES flag pipelined into EX

    // ----------------------------
    // EXECUTE → MEM
    // ----------------------------
    wire PCSrcE;
    wire RegWriteM, MemWriteM;
    wire [1:0] ResultSrcM;
    wire [4:0] RD_M;
    wire [31:0] PCPlus4M, WriteDataM, ALU_ResultM, PCTargetE;

    // ----------------------------
    // MEM → WB
    // ----------------------------
    wire RegWriteW;
    wire [1:0] ResultSrcW;
    wire [4:0] RDW;
    wire [31:0] PCPlus4W, ReadDataW, ALU_ResultW, ResultW;

    // ----------------------------
    // Forwarding / Hazard
    // ----------------------------
    wire [1:0] ForwardAE, ForwardBE;
    wire ForwardAD, ForwardBD;
    wire [4:0] RS1_D, RS2_D;
    wire PCWrite, IF_ID_Write, ID_EX_Flush;
    wire MemReadE = (ResultSrcE == 2'b01);

    // ----------------------------
    // AES COPROCESSOR
    // ----------------------------
    wire aes_busy;
    wire aes_done;
    wire aes_start;
    wire aes_wen;
    wire [4:0]  aes_waddr;
    wire [31:0] aes_wdata;

    // ============================================================
    // STAGE 1: FETCH
    // ============================================================
    Fetch_Cycle Fetch (
        .clock(clock),
        .reset(reset),
        .PCSrcE(PCSrcE),
        .PCTargetE(PCTargetE),
        .InstrD(InstrD),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D),
        .PCWrite(PCWrite),
        .IF_ID_Write(IF_ID_Write)
    );

    // ============================================================
    // STAGE 2: DECODE
    // (Contains internal Register File - AES writes wired into it)
    // ============================================================
    Decode_Cycle Decode (
        .clock(clock),
        .reset(reset),
        .data(InstrD),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D),
        .RegWriteW(RegWriteW),
        .RDW(RDW),
        .ResultW(ResultW),
        .ForwardA_D(ForwardAD),
        .ForwardB_D(ForwardBD),

        .RegWriteE(RegWriteE),
        .ALUSrcE(ALUSrcE),
        .MemWriteE(MemWriteE),
        .JumpE(JumpE),
        .BranchE(BranchE),
        .ResultSrcE(ResultSrcE),
        .ALUControlE(ALUControlE),
        .RD1_E(RD1_E),
        .RD2_E(RD2_E),
        .Imm_Ext_E(Imm_Ext_E),
        .RS1_E(RS1_E),
        .RS2_E(RS2_E),
        .RD_E(RD_E),
        .PCE(PCE),
        .PCPlus4E(PCPlus4E),

        // AES flag into pipeline
        .isAES_E(isAES_E),

        // hazard unit operands
        .RS1_D(RS1_D),
        .RS2_D(RS2_D),

        // Flush support
        .ID_EX_Flush(ID_EX_Flush),
        .aes_mode_E(aes_mode_E)

        // NEW - AES WRITE PORT ROUTED INTO REGISTER FILE INSIDE DECODE
        
        
    );

    // ============================================================
    // STAGE 3: EXECUTE
    // ============================================================
    Execute_Cycle Execute (
        .clock(clock),
        .reset(reset),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .JumpE(JumpE),
        .BranchE(BranchE),
        .ALUControlE(ALUControlE),
        .ALUSrcE(ALUSrcE),
        .RD_E(RD_E),
        .PCPlus4E(PCPlus4E),

        .RD1_E(RD1_E),
        .RD2_E(RD2_E),
        .Imm_Ext_E(Imm_Ext_E),
        .PCE(PCE),
        .ForwardA_E(ForwardAE),
        .ForwardB_E(ForwardBE),
        .ResultW(ResultW),

        .PCSrcE(PCSrcE),
        .RegWriteM(RegWriteM),
        .MemWriteM(MemWriteM),
        .ResultSrcM(ResultSrcM),
        .RD_M(RD_M),
        .PCPlus4M(PCPlus4M),
        .WriteDataM(WriteDataM),
        .ALU_ResultM(ALU_ResultM),
        .PCTargetE(PCTargetE),

        // AES start pulse
        .isAES_E(isAES_E),
        .aes_start(aes_start)
        //.aes_mode_E(aes_mode_E)
    );

    // ============================================================
    // MEMORY + WRITEBACK (unchanged)
    // ============================================================
    Memory_Cycle Memory (
        .clock(clock),
        .reset(reset),
        .RegWriteM(RegWriteM),
        .MemWriteM(MemWriteM),
        .ResultSrcM(ResultSrcM),
        .RD_M(RD_M),
        .PCPlus4M(PCPlus4M),
        .WriteDataM(WriteDataM),
        .ALU_ResultM(ALU_ResultM),
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW),
        .RD_W(RDW),
        .PCPlus4W(PCPlus4W),
        .ALU_ResultW(ALU_ResultW),
        .ReadDataW(ReadDataW)
    );

    Writeback_Cycle WriteBack (
        .ResultSrcW(ResultSrcW),
        .PCPlus4W(PCPlus4W),
        .ALU_ResultW(ALU_ResultW),
        .ReadDataW(ReadDataW),
        .ResultW(ResultW)
    );

    Hazard_Unit Forwarding_block (
        .reset(reset),
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .RD_M(RD_M),
        .RD_W(RDW),
        .RS1_D(RS1_D),
        .RS2_D(RS2_D),
        .RS1_E(RS1_E),
        .RS2_E(RS2_E),

        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
        .ForwardAD(ForwardAD),
        .ForwardBD(ForwardBD)
    );

    // ============================================================
    // Hazard Detection - AES stalls added
    // ============================================================
    Hazard_Detection hazard_detect (
        .clk(clock),
        .reset(reset),
        .MemReadE(MemReadE),
        .RD_E(RD_E),
        .RS1_D(RS1_D),
        .RS2_D(RS2_D),
        .BranchTakenE(PCSrcE),
        .aes_busy(aes_busy),
        .PCWrite(PCWrite),
        .IF_ID_Write(IF_ID_Write),
        .ID_EX_Flush(ID_EX_Flush)
    );

    // ============================================================
    // FINAL AES COPROCESSOR - working with your rs1/rs2 version
    // ============================================================
    aes_cp aes_cp (
        .clk(clock),
        .rst(reset),

        .isAES_E(isAES_E),
        .rd_E(RD_E),
        .rs1_val(RD1_E),
        .rs2_val(RD2_E),

        .aes_busy(aes_busy),
        .aes_done(aes_done),

        .aes_wen(aes_wen),
        .aes_waddr(aes_waddr),
        .aes_wdata(aes_wdata)
        //.aes_mode(aes_mode_E)
    );

    assign output1 = ResultW;

endmodule
