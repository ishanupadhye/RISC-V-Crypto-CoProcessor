`timescale 1ns / 1ps

module ALU(

    input [31:0]A,
    input [31:0]B,
    input [3:0]ALUControl,

    output [31:0]Result,
    output Carry,
    output OverFlow, //look at the concept of overflow for signed numbers
    output Zero,
    output Negative

);

    //wire Cout;
    wire [31:0]Sum;


    //just calculated the result of sub and add
    //why this step is done ssepeartely ?
    assign {Carry,Sum} = (ALUControl[0] == 1'b0) ? A + B :
                                          (A + (~B) + 32'h00000001) ;
   // cout will not be effectie here since sum is 32 bit and turncated
   // need the updation in the code .... comment by hepin

    assign Result = (ALUControl == 4'b0000) ? Sum :
                           (ALUControl == 4'b0001) ? Sum :
                           (ALUControl == 4'b0010) ? A ^ B :
                           (ALUControl == 4'b0011) ? A | B :
                           (ALUControl == 4'b0100) ? A & B :
                           (ALUControl == 4'b0101) ? A << B[4:0] : // is barrael shifter is used ?
                           (ALUControl == 4'b0110) ? A >> B[4:0] :
                         //  (ALUControl == 4'b0111) ? {A[31],(A >> B[4:0])} :
                           (ALUControl == 4'b0111) ? (A >>> B[4:0]) : //check this is working or not
                           (ALUControl == 4'b1000) ? {{32{1'b0}},(Sum[31])} :
                           (ALUControl == 4'b1001) ? (A < B ? 1 : 0) :  //whill this be the unsigned comparision ?
                           {33{1'b0}};
                           
                      
    assign OverFlow = ((ALUControl == 4'b0000 | ALUControl == 4'b0001) & 
                      (B[31] & A[31] & ~Sum[31]) | ( ~B[31] & ~A[31] & Sum[31]));

    //assign Carry = Cout;
    
   // assign Zero = &(~Result);
      assign Zero = ~&(Result);
    
    assign Negative = Result[31];

endmodule