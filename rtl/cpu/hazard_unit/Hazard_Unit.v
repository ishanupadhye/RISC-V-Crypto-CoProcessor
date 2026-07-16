`timescale 1ns / 1ps
module Hazard_Unit(    

    // Declaration of I/Os
    input reset,
    // rest can be reduncant ??? ..comment by hepin
    input RegWriteM, // is this needed ?
    input RegWriteW,
    input [4:0] RD_M,
    input [4:0] RD_W,
    input [4:0] RS1_D,
    input [4:0] RS2_D,
    input [4:0] RS1_E,
    input [4:0] RS2_E,


    output [1:0] ForwardAE,
    output [1:0] ForwardBE,
    output ForwardAD,
    output ForwardBD

);


    
    assign ForwardAE = (reset == 1'b1) ? 2'b00 : 
                       ((RegWriteM == 1'b1) & (RD_M != 5'b00000) & (RD_M == RS1_E)) ? 2'b10 :
                       ((RegWriteW == 1'b1) & (RD_W != 5'b00000) & (RD_W == RS1_E)) ? 2'b01 : 2'b00;
                       
    assign ForwardBE = (reset == 1'b1) ? 2'b00 : 
                       ((RegWriteM == 1'b1) & (RD_M != 5'b00000) & (RD_M == RS2_E)) ? 2'b10 :
                       ((RegWriteW == 1'b1) & (RD_W != 5'b00000) & (RD_W == RS2_E)) ? 2'b01 : 2'b00;

    assign ForwardAD = (reset == 1'b1) ? 1'b0 : 
                       ((RegWriteW == 1'b1) & (RD_W != 5'b00000) & (RD_W == RS1_D)) ? 1'b1 : 1'b0;
                       
    assign ForwardBD = (reset == 1'b1) ? 1'b0 : 
                       ((RegWriteW == 1'b1) & (RD_W != 5'b00000) & (RD_W == RS2_D)) ? 1'b1 : 1'b0;

                       

endmodule