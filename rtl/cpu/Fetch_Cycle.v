`timescale 1ns / 1ps

module Fetch_Cycle(
    input  wire        clock,
    input  wire        reset,
    input  wire        PCWrite,
    input  wire        IF_ID_Write,
    input  wire        PCSrcE,
    input  wire [31:0] PCTargetE,

    output wire [31:0] InstrD,
    output wire [31:0] PCD,
    output wire [31:0] PCPlus4D
);

    wire [31:0] PCF;
    wire [31:0] PCNext;
    wire [31:0] PCPlus4F;
    wire [31:0] inst_fetched;

    assign PCPlus4F = PCF + 32'h00000004;

    Mux_2_1_32 PC_MUX(
        .Input0(PCPlus4F),
        .Input1(PCTargetE),
        .Selection(PCSrcE),
        .Output(PCNext)
    );

    PC_Module program_counter(
        .clock(clock),
        .reset(reset),
        .PC_Next(PCWrite ? PCNext : PCF),
        .PC(PCF)
    );

    // UPDATED IMEM instantiation
    Instruction_Memory INST_MEMORY(
        .clock(clock),          // Added clock
        .address(PCF[7:0]),
        .data(inst_fetched)
    );

    reg [31:0] InstrD_r;
    reg [31:0] PCD_r;
    reg [31:0] PCPlus4D_r;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            InstrD_r    <= 32'h00000013;  // NOP
            PCD_r       <= 32'h00000000;
            PCPlus4D_r  <= 32'h00000000;
        end
        else begin
            if (IF_ID_Write) begin
                InstrD_r    <= inst_fetched;
                PCD_r       <= PCF;
                PCPlus4D_r  <= PCPlus4F;
            end
        end
    end

    assign InstrD    = InstrD_r;
    assign PCD       = PCD_r;
    assign PCPlus4D  = PCPlus4D_r;

endmodule
