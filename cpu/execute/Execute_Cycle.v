`timescale 1ns / 1ps
// `include "ALU.v"
// `include "Mux_2_1_32.v"
// `include "Mux_4_1_32.v"
// `include "PC_Adder.v"
// `include "Branch_Module.v"

module Execute_Cycle(

    input clock,
    input reset,
    input RegWriteE,//pass
    input [1:0] ResultSrcE,//pass
    input MemWriteE,//pass
    input JumpE,
    input [2:0] BranchE,
    input [3:0] ALUControlE,
    input ALUSrcE,
    input [4:0] RD_E,//pass
    input [31:0] PCPlus4E,//pass

   // data
    input [31:0] RD1_E,
    input [31:0] RD2_E,
    input [31:0] Imm_Ext_E,
    input [31:0] PCE,// use in ex stage for pc + immediate
    input [1:0] ForwardA_E,
    input [1:0] ForwardB_E,
    input [31:0] ResultW, // for forwarding

    // NEW: pipelined AES flag coming into EX stage
    input isAES_E,            // asserted when decode detected AES_START (pipelined)

    // outputs
    output PCSrcE,// because conditional branch result will be know in this stage (selection line)
    output RegWriteM,//pass
    output MemWriteM,//pass
    output [1:0] ResultSrcM,//pass
    output [4:0] RD_M,//pass
    output [31:0] PCPlus4M,//pass for jal
    output [31:0] WriteDataM,//to be write in data memory,for store type of instruction //pass
    output [31:0] ALU_ResultM, //error
    output [31:0] PCTargetE, //for conditional pc+immediate value

    // NEW: start pulse for AES coprocessor (one-cycle pulse)
    output aes_start
);



    wire [31:0] Src_A;
    wire [31:0] Src_B_interim;
    wire [31:0] Src_B;
    wire [31:0] ResultE;
    wire ZeroE;
    wire Overflow;
    wire Carry;
    wire Negative;
    wire isBranch; //final result take or not


    reg RegWriteE_r;
    reg MemWriteE_r;
    reg [1:0] ResultSrcE_r;
    reg [4:0] RD_E_r;
    reg [31:0] RD2_E_r; // this is for what purpose ?...comment by hepin // data to be store in data memory ?
    reg [31:0] PCPlus4E_r;
    reg [31:0] ResultE_r;

    // AES start register (one-cycle pulse)
    reg aes_start_reg;


    Mux_4_1_32 srca_mux (
                        .Input0(RD1_E),
                        .Input1(ResultW),//1stage
                        .Input2(ALU_ResultM),//2stage //eror //output
                        .Input3(32'h00000000),//rest case // never to be happend
                        .Selection(ForwardA_E),

                        .Output(Src_A)
                        );

    Mux_4_1_32 srcb_mux (
                        .Input0(RD2_E),
                        .Input1(ResultW),
                        .Input2(ALU_ResultM),
                        .Input3(32'h00000000),
                        .Selection(ForwardB_E),

                        .Output(Src_B_interim)
                        );


    Mux_2_1_32 alu_src_mux (
            .Input0(Src_B_interim),
            .Input1(Imm_Ext_E),
            .Selection(ALUSrcE),

            .Output(Src_B)
            );
/*

    Branch_Module is_Branch(
            .A(Src_A), 
            .B(Src_B), // this can be immediate ? // signed //
         // check and upadte the code accordingly...comment by hepin
             //why unsigned are not passed
            .A_Unsigned(Src_A), 
            .B_Unsigned(Src_B), 
            .BranchE(BranchE), 

            .isBranch(isBranch) 

            );

*/
 Branch_Module is_Branch(  

 .BranchE(BranchE),
 .Zero(ZeroE),
 .Negative(Negative),
 .Carry(Carry),

 .isBranch(isBranch)  //final result taken or not in ex stage

);


    
    ALU alu (
            .A(Src_A),
            .B(Src_B),
            .Result(ResultE),
            .ALUControl(ALUControlE),

            .OverFlow(Overflow),
            .Carry(Carry),
            .Zero(ZeroE),
            .Negative(Negative) 
            );

    
    PC_Adder branch_adder (
            .PC(PCE),
            .Amount(Imm_Ext_E),

            .Incremented_PC(PCTargetE)

            );

  
    always @(posedge clock or posedge reset) begin
        if(reset == 1'b1) begin
            RegWriteE_r <= 1'b0; 
            MemWriteE_r <= 1'b0; 
            ResultSrcE_r <= 2'b00;
            RD_E_r <= 5'h00;
            PCPlus4E_r <= 32'h00000000; 
            RD2_E_r <= 32'h00000000; 
            ResultE_r <= 32'h00000000;

            // AES start reset
            aes_start_reg <= 1'b0;
        end
        else begin
            RegWriteE_r <= RegWriteE; 
            MemWriteE_r <= MemWriteE; 
            ResultSrcE_r <= ResultSrcE;
            RD_E_r <= RD_E;
            PCPlus4E_r <= PCPlus4E; 
            RD2_E_r <= Src_B_interim; 
            ResultE_r <= ResultE;

            // sample pipelined AES flag to produce a one-cycle start pulse
            // if isAES_E is high this cycle, aes_start_reg becomes 1 for ONE cycle
            aes_start_reg <= isAES_E;
        end
    end

    // Output Assignments
    assign PCSrcE = JumpE | ( isBranch == 1'b1);
    assign RegWriteM = RegWriteE_r;
    assign MemWriteM = MemWriteE_r;
    assign ResultSrcM = ResultSrcE_r;
    assign RD_M = RD_E_r;
    assign PCPlus4M = PCPlus4E_r;
    assign WriteDataM = RD2_E_r;
    assign ALU_ResultM = ResultE_r;

    // AES start output
    assign aes_start = aes_start_reg;

endmodule
