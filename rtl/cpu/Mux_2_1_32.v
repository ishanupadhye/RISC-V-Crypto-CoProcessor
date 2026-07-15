`timescale 1ns / 1ps

module Mux_2_1_32(

    input [31:0] Input0,
    input [31:0] Input1,
    input Selection,

    output [31:0] Output
    );

assign Output = ~(Selection) ? Input0 : Input1;


//assign Output = (Selection) ? Input1: Input0;
//check look up for both....commency by hepin
//same for both updated by hepin...


endmodule