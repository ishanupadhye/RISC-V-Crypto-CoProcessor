`timescale 1ns / 1ps
// `include "Mux_2_1_32.v"

module Mux_4_1_32(

    input [31:0] Input0,
    input [31:0] Input1,
    input [31:0] Input2,
    input [31:0] Input3,
    input [1:0] Selection,

    output [31:0] Output
);

    //assign Output = (Selection == 2'b00) ? Input0 : 
                    //(Selection == 2'b01) ? Input1 : 
                   // (Selection == 2'b10) ? Input2 : Input3;

//isnt it selective approch
//try to implement using 2:1 module

wire[31:0] out_l10,out_l11;
Mux_2_1_32 mx0(.Input0(Input0),.Input1(Input1),.Selection(Selection[0]),.Output(out_l10));
Mux_2_1_32 mx1(.Input0(Input2),.Input1(Input3),.Selection(Selection[0]),.Output(out_l11));
Mux_2_1_32 mx2(.Input0(out_l10),.Input1(out_l11),.Selection(Selection[1]),.Output(Output));

// look at lookup tables for both
//...comment by hepin

//resource utilization is same for everyone 
//power consumption is little bit lesser in second approach


endmodule