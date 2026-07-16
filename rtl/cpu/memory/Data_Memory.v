`timescale 1ns / 1ps

module Data_Memory (

    input  wire        clock,
    input  wire        WE,
    input  wire [31:0] A,          // Byte address
    input  wire [31:0] WD,
    output reg  [31:0] RD
);

    parameter MEMORY_SIZE = 1024;  // 4KB

    (* ram_style = "block" *)
    reg [31:0] Memory [0:MEMORY_SIZE-1];

    // Word-aligned addressing
    wire [9:0] A_word = A[11:2];

    initial begin
        $readmemh("dmem_init1.mem", Memory);
    end

    always @(posedge clock) begin
        if (WE)
            Memory[A_word] <= WD;

        RD <= Memory[A_word];   // synchronous read
    end

endmodule
