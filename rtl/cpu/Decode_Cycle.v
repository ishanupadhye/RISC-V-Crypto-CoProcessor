`timescale 1ns / 1ps
// `include "Control_Unit_1.v"
// `include "Register_File.v"
// `include "Sign_Extend.v"
// `include "Mux_2_1_32.v"


module Decode_Cycle(

    input clock,
    input reset,
    input [31:0] data,
    input [31:0] PCD,
    input [31:0] PCPlus4D,
    input RegWriteW,
    input [4:0] RDW, //Register destination from w stage
    input [31:0] ResultW,   //W-RESULT FROM W STAGE TO REG FILE
    input ForwardA_D, // forwarding select from hazard unit (WB->D)
    input ForwardB_D, // forwarding select from hazard unit (WB->D)
    input  wire ID_EX_Flush,  // flush signal to insert bubble into EX stage

    // pipelined outputs to EX stage
    output RegWriteE,
    output ALUSrcE,
    output MemWriteE,
    output JumpE,
    output [2:0] BranchE,
    output [1:0] ResultSrcE,
    output [3:0] ALUControlE,
    output [31:0] RD1_E, //readed data from register file (forwarded)
    output [31:0] RD2_E, //readed data from register file (forwarded)
    output [31:0] Imm_Ext_E,

    // For Hazard detection & forwarding
    output [4:0] RS1_E,
    output [4:0] RS1_D,
    output [4:0] RS2_E,
    output [4:0] RS2_D,
    output [4:0] RD_E,

    // pipeline PCs
    output [31:0] PCE,
    output [31:0] PCPlus4E,

    // NEW: pipelined load indicator and AES flag
    output wire MemReadE,      // pipelined load indicator to EX
    output wire isAES_E,        // pipelined AES_START indicator to EX
    output wire aes_mode_E

    //output [4:0] RS1_D,//what is this ?
    //output [4:0] RS2_D//what is this ?
);


    // ----------------------------
    // Local wires & regs
    // ----------------------------
    wire RegWriteD;
    wire [31:0] InstrD;
    wire ALUSrcD;
    wire MemWriteD;
    wire JumpD;
    wire [2:0] BranchD;
    wire [1:0] ResultSrcD;
    wire [2:0] ImmSrcD;
    wire [3:0] ALUControlD;
    wire [31:0] RD1_D;
    wire [31:0] RD2_D;
    wire [31:0] Imm_Ext_D;
    // trace the below two and update its trace...comment by hepin
    wire [31:0] RD1_D_mux;
    wire [31:0] RD2_D_mux;

    // --- new signals for hazard detection / AES pipeline
    wire MemReadD;        // combinational detection in decode (ResultSrcD == load)
    reg  MemReadD_r;      // pipelined to EX
    reg  isAES_D_r;       // pipelined AES flag
    wire isAES;           // coming from control unit (added port in Control_Unit_1)

    // ----------------------------
    // Pipeline registers (D-stage registers that feed E-stage)
    // ----------------------------
    reg RegWriteD_r;
    reg ALUSrcD_r;
    reg MemWriteD_r;
    reg JumpD_r;
    reg [2:0] BranchD_r;
    reg [1:0] ResultSrcD_r;
    reg [3:0] ALUControlD_r;
    reg [31:0] RD1_D_r;
    reg [31:0] RD2_D_r;
    reg [31:0] Imm_Ext_D_r;
    reg [4:0] RS1_D_r;
    reg [4:0] RS2_D_r;
    reg [4:0] RD_D_r;
    reg [31:0] PCD_r;
    reg [31:0] PCPlus4D_r;
    reg aes_mode_D_r;   // 0 = encrypt, 1 = decrypt
     assign InstrD = data;
     //assign RS1_D = InstrD[19:15]; //to wire
     //assign RS2_D = InstrD[24:20]; //to wire


    // ----------------------------
    // Control unit
    // ----------------------------
    Control_Unit_1 control (
                            
                            .Op(InstrD[6:0]),

                            .RegWrite(RegWriteD),
                            .ImmSrc(ImmSrcD),
                            .ALUSrc(ALUSrcD),
                            .MemWrite(MemWriteD),
                            .ResultSrc(ResultSrcD),
                            .Jump(JumpD),
                            .Branch(BranchD),
                            .funct3(InstrD[14:12]),
                            .funct7(InstrD[31:25]),
                            .ALUControl(ALUControlD),
                            .isAES(isAES)    // new output from control unit
                            );



    // ----------------------------
    // Register file
    // ----------------------------
    Register_File rf (
                        .clock(clock),
                        .reset(reset),
                        .WE3(RegWriteW),
                        .WD3(ResultW),
                        .A1(InstrD[19:15]),
                        .A2(InstrD[24:20]),
                        .A3(RDW),

                        .RD1(RD1_D),
                        .RD2(RD2_D)

                        );



// WB -> D forwarding muxes
    Mux_2_1_32 execute_src_1 (
            .Input0(RD1_D),
            .Input1(ResultW),
            .Selection(ForwardA_D),
            .Output(RD1_D_mux)
            );

    Mux_2_1_32 execute_src_2 (
            .Input0(RD2_D),
            .Input1(ResultW),
            .Selection(ForwardB_D),
            .Output(RD2_D_mux)
            );



    // Sign-extend immediate
    Sign_Extend extension (
                        .Input(InstrD[31:7]),
                        .ImmSrc(ImmSrcD),

                        .Output(Imm_Ext_D)

                        );

    // detect load in decode stage (combinational)
    assign MemReadD = (ResultSrcD == 2'b01);


    // ----------------------------
    // Pipeline register update (D -> E) with flush support
    // ----------------------------
    always @(posedge clock or posedge reset) begin
        if (reset == 1'b1) begin
            RegWriteD_r <= 1'b0;
            ALUSrcD_r <= 1'b0;
            MemWriteD_r <= 1'b0;
            ResultSrcD_r <= 2'b00;
            BranchD_r <= 3'b0;
            JumpD_r <= 1'b0;
            ALUControlD_r <= 4'b0000;
            RD1_D_r <= 32'h00000000; 
            RD2_D_r <= 32'h00000000; 
            Imm_Ext_D_r <= 32'h00000000;
            RD_D_r <= 5'h00;
            PCD_r <= 32'h00000000; 
            PCPlus4D_r <= 32'h00000000;
            RS1_D_r <= 5'h00;
            RS2_D_r <= 5'h00;
            // new
            MemReadD_r <= 1'b0;
            isAES_D_r  <= 1'b0;
            aes_mode_D_r <= 1'b0;
            
        end

        else begin
            if (ID_EX_Flush) begin
                // insert bubble in EX stage
                RegWriteD_r    <= 1'b0;
                ALUSrcD_r      <= 1'b0;
                MemWriteD_r    <= 1'b0;
                ResultSrcD_r   <= 2'b00;
                BranchD_r      <= 3'b000;
                JumpD_r        <= 1'b0;
                ALUControlD_r  <= 4'b0000;

                RD1_D_r        <= 32'h00000000;
                RD2_D_r        <= 32'h00000000;
                Imm_Ext_D_r    <= 32'h00000000;
                RD_D_r         <= 5'h00;

                // pipeline the cleared hazard signals
                MemReadD_r     <= 1'b0;
                isAES_D_r      <= 1'b0;
                aes_mode_D_r   <= 1'b0;

                // keep PC values (or zero as preferred)
                PCD_r          <= PCD;
                PCPlus4D_r     <= PCPlus4D;

                RS1_D_r        <= 5'h00;
                RS2_D_r        <= 5'h00;
            end
            else begin
                // normal capture
                RegWriteD_r    <= RegWriteD;
                ALUSrcD_r      <= ALUSrcD;
                MemWriteD_r    <= MemWriteD;
                ResultSrcD_r   <= ResultSrcD;
                BranchD_r      <= BranchD;
                JumpD_r        <= JumpD;
                ALUControlD_r  <= ALUControlD;

                RD1_D_r        <= RD1_D_mux; // upddated forwarded
                RD2_D_r        <= RD2_D_mux; // updated forwarded
                Imm_Ext_D_r    <= Imm_Ext_D;
                RD_D_r         <= InstrD[11:7];
                PCD_r          <= PCD; 
                PCPlus4D_r     <= PCPlus4D;

                // Passed to next state for forwarding
                RS1_D_r        <= InstrD[19:15];
                RS2_D_r        <= InstrD[24:20];

                // NEW pipeline signals
                MemReadD_r     <= MemReadD;
                isAES_D_r      <= isAES;
                aes_mode_D_r   <= InstrD[30];
                
            end
        end
    end



    // ----------------------------
    // Assign pipelined outputs (D->E)
    // ----------------------------
    assign RegWriteE = RegWriteD_r;
    assign ALUSrcE = ALUSrcD_r;
    assign MemWriteE = MemWriteD_r;
    assign ResultSrcE = ResultSrcD_r;
    assign JumpE = JumpD_r;
    assign BranchE = BranchD_r;
    assign ALUControlE = ALUControlD_r;
    assign RD1_E = RD1_D_r;
    assign RD2_E = RD2_D_r;
    assign Imm_Ext_E = Imm_Ext_D_r;
    assign RD_E = RD_D_r;
    assign PCE = PCD_r;
    assign PCPlus4E = PCPlus4D_r;
    assign RS1_E = RS1_D_r;
    assign RS2_E = RS2_D_r;
    assign RS1_D = InstrD[19:15];
    assign RS2_D = InstrD[24:20];

    // assign the new pipelined hazard outputs
    assign MemReadE = MemReadD_r;
    assign isAES_E  = isAES_D_r;
    assign aes_mode_E = aes_mode_D_r;


endmodule
