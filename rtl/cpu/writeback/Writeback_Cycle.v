`timescale 1ns / 1ps
// `include "Mux_4_1_32.v"

module Writeback_Cycle(

input [1:0] ResultSrcW,
input [31:0] PCPlus4W,
input [31:0] ALU_ResultW,
input [31:0] ReadDataW,

output [31:0] ResultW

);
//

//no need of clock or reset in this module...comment by hepin....
// Declaration of IOs
// Data will be wrote to the reg file in next clock cycle not in this.....
//what will happen if write and read the same location...? // data forwarding in decode cycle
//may need forwarding there too....comment by hepin
//input clock, reset;




// Declaration of Module
Mux_4_1_32 result_mux (    

                .Input0(ALU_ResultW),
                .Input1(ReadDataW),
                .Input2(PCPlus4W),
                .Input3(32'h00000000),//rest
                .Selection(ResultSrcW),

                .Output(ResultW)
                );
endmodule