`timescale 1ns / 1ps

module Branch_Module(  

  input [2:0] BranchE,
  input Zero,
  input Negative,
  input Carry,

  output isBranch //final result taken or not in ex stage

);


    assign isBranch = (BranchE == 3'b000) ? Zero :     //not taken
                      (BranchE == 3'b001) ? ~Zero :
                      (BranchE == 3'b100) ? Negative :
                      (BranchE == 3'b101) ? ~Negative :
                      (BranchE == 3'b110) ? ~Carry:
                      (BranchE == 3'b111) ? Carry:  1'b0; // else not taken
								  

endmodule