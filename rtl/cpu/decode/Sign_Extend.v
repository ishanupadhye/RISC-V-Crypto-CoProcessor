`timescale 1ns / 1ps
module Sign_Extend(

    input [31:7] Input, // whole pc is provided as input
    input [2:0] ImmSrc,//select the source of immediate // 8X1 mux select line//we requires only 5

    output [31:0] Output
);
    

    assign Output =  (ImmSrc == 3'b000) ? {{20{Input[31]}},Input[31:20]} : //I-type
                     (ImmSrc == 3'b001) ? {{20{Input[31]}},Input[31:25],Input[11:7]} : //S-type
                     (ImmSrc == 3'b010) ? {{19{Input[31]}},Input[31],Input[7],Input[30:25],Input[11:8], 1'b0} : //B-type (13 bit effectively)
                     (ImmSrc == 3'b011) ? {Input[31:12], 12'h000} : //U-type
                     (ImmSrc == 3'b100) ? {{11{Input[31]}},Input[31],Input[19:12],Input[20], Input[30:21], 1'b0}:  // J-type (21 effectively)
		     (ImmSrc == 3'b101) ? {{20{1'b0}},Input[31:20]} : //I-type
		     (ImmSrc == 3'b110) ? {{19{1'b0}},Input[31],Input[7],Input[30:25],Input[11:8], 1'b0} :32'h00000000;//B-type (13 bit effectively)	\
// here else (111) will give ops as zeros
                                                                               




endmodule