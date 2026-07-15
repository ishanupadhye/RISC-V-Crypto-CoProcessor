`timescale 1ns / 1ps





module PC_Module(

    input clock,
    input reset,
    input [31:0] PC_Next,

    output [31:0] PC
);

reg [31:0] PC0;
always @(posedge clock or posedge reset)//active high reset
begin
    if(reset == 1'b1) begin
        PC0 <= 32'h00000000;//32'd0;
    end

    else begin
        PC0 <= PC_Next;
    end

end
assign PC=PC0;

endmodule

/*module PC_Module(

    input clock,
    input reset,
    input [31:0] PC_Next,

    output reg [31:0] PC
);

always @(posedge clock or posedge reset)//active high reset
begin
    if(reset == 1'b1) begin
        PC <= 32'h00000000;//32'd0;
    end

    else begin
        PC <= PC_Next;
    end

end

endmodule
*/

//BY HEPIN
//SAME RESULT OF POWER AND RESOURCE
//COMMENCT BY HEPIN




