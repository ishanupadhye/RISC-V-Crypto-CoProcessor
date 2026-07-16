`timescale 1ns / 1ps

module PC_Adder(

    input [31:0] PC,
    input [31:0] Amount,

    output [31:0] Incremented_PC
);

assign Incremented_PC = PC + Amount;// by default ripple carry adder

// gives the final pc
//wht about the overflow condition ?

//wire overflow = (PC[31]&Amount[31]&(~incremented_pc_intermediate))+(~PC[31] & (~Amount[31]) & incremented_pc_intermediate);
//wire [31:0] incremented_pc_intermediate;
// assign incremented_pc_intermediate = PC + Amount;
// signed overflow condition to be looked after 

//try to add pc_overflow flage or 
//go to zero
//go to end
//stay where you are (may result infinite loop)
//By hepin:
//go somewhere at nope ?
//may be zero address ca be hard codeded to thr nop instruction
//assign Incremented_PC = (overflow)?(32'd0):(incremented_pc_intermediate);

    
endmodule