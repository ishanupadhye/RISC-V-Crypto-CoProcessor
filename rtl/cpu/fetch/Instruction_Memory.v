`timescale 1ns / 1ps

module Instruction_Memory(

    input  wire        clock,          // Added clock
    input  wire [7:0]  address,        // PC[7:0]
    output reg  [31:0] data            // instruction out
);

    // 256 x 32-bit memory
    (* ram_style = "block" *)
    reg [31:0] mem [0:255];

    // Load instructions from file
    initial begin
        $readmemh("imem_init.mem", mem);
    end

    // Synchronous read (BRAM style)
    always @(posedge clock) begin
        data <= mem[address[7:2]];
    end

endmodule
