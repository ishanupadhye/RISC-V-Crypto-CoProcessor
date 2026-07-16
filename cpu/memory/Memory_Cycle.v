`timescale 1ns / 1ps
// `include "Data_Memory.v"

module Memory_Cycle(

    input clock,
    input reset,
    input RegWriteM,//pass
    input MemWriteM,
    input [1:0] ResultSrcM, //pass
    input [4:0] RD_M, //pass
    input [31:0] PCPlus4M,//pass
    input [31:0] WriteDataM,//pass
    input [31:0] ALU_ResultM, //pass or use (in case of load store )

    output RegWriteW,//pass
    output [1:0] ResultSrcW,//pass
    output [4:0] RD_W,//pass
    output [31:0] PCPlus4W,
    output [31:0] ALU_ResultW,//pass
    output [31:0] ReadDataW
);
    
    

    // Declaration of Interim Wires
    wire [31:0] ReadDataM; // asynchronous read data

    // Declaration of Interim Registers
    reg RegWriteM_r; //pass
    reg [1:0] ResultSrcM_r; //pass
    reg [4:0] RD_M_r; //pass
    reg [31:0] PCPlus4M_r; //pass
    reg [31:0] ALU_ResultM_r; //pass
    reg [31:0] ReadDataM_r;

    // Declaration of Module Initiation
    //(*dont_touch = "true"*)
    Data_Memory dm1 (
    .clock(clock),
    //.reset(reset),
    .WE(MemWriteM),
    .A(ALU_ResultM),
    .WD(WriteDataM),
    .RD(ReadDataM)
);



    // Memory Stage Register Logic
    always @(posedge clock or posedge reset) begin
        if (reset == 1'b1) begin
            RegWriteM_r <= 1'b0; 
            ResultSrcM_r <= 2'b00;
            RD_M_r <= 5'h00; // and reg0 is hardcoded
            PCPlus4M_r <= 32'h00000000; 
            ALU_ResultM_r <= 32'h00000000; 
            ReadDataM_r <= 32'h00000000;
        end

        else begin
            RegWriteM_r <= RegWriteM; 
            ResultSrcM_r <= ResultSrcM;
            RD_M_r <= RD_M;
            PCPlus4M_r <= PCPlus4M; 
            ALU_ResultM_r <= ALU_ResultM; 
            ReadDataM_r <= ReadDataM;
        end

    end 

    // Declaration of output assignments
    assign RegWriteW = RegWriteM_r;
    assign ResultSrcW = ResultSrcM_r;
    assign RD_W = RD_M_r;
    assign PCPlus4W = PCPlus4M_r;
    assign ALU_ResultW = ALU_ResultM_r;
    assign ReadDataW = ReadDataM_r;

endmodule