`timescale 1ns/1ps

module aes_cp(
    input  wire        clk,
    input  wire        rst,

    // From EX stage
    input  wire        isAES_E,
    input  wire [4:0]  rd_E,
    input  wire [31:0] rs1_val,
    input  wire [31:0] rs2_val,

    // Status
    output wire        aes_busy,
    output wire        aes_done,

    // Writeback
    output reg         aes_wen,
    output reg  [4:0]  aes_waddr,
    output reg  [31:0] aes_wdata,

    // Debug
    output wire [127:0] aes_result_full
);

    //--------------------------------------------------
    // 32 → 128 packing
    //--------------------------------------------------
    wire [127:0] data_block = {96'd0, rs1_val};
    wire [127:0] key_block  = {96'd0, rs2_val};

    //--------------------------------------------------
    // Start pulse detection
    //--------------------------------------------------
    reg isAES_prev;
    wire aes_start = isAES_E & ~isAES_prev;

    always @(posedge clk or posedge rst) begin
        if (rst)
            isAES_prev <= 0;
        else
            isAES_prev <= isAES_E;
    end

    //--------------------------------------------------
    // Phase FSM
    //--------------------------------------------------
    reg [2:0] phase;

   localparam IDLE     = 3'd0,
           ENC_KEY  = 3'd1,
           ENC_RUN  = 3'd2,
           DEC_KEY  = 3'd3,
           DEC_RUN  = 3'd4,
           DONE     = 3'd5;

    reg [127:0] enc_store;

    //--------------------------------------------------
    // Encrypt Core
    //--------------------------------------------------
    wire [127:0] enc_cipher;
    wire enc_ready;

    lite_aes128 enc_core (
        .clk(clk),
        .rst_n(~rst),
        .start(phase == ENC_RUN),
        .key_in(key_block),
        .key_load(phase == ENC_KEY),
        .plaintext(data_block),
        .ciphertext(enc_cipher),
        .ready(enc_ready)
    );

    //--------------------------------------------------
    // Decrypt Core
    //--------------------------------------------------
    wire [127:0] dec_plain;
    wire dec_ready;

    lite_aes128_dec dec_core (
        .clk(clk),
        .rst_n(~rst),

        // IMPORTANT: Never assert together
        .start(phase == DEC_RUN),
        .key_in(key_block),
        .key_load(phase == DEC_KEY),

        .ciphertext(enc_store),
        .plaintext(dec_plain),
        .ready(dec_ready)
    );

    //--------------------------------------------------
    // Phase Control
    //--------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase <= IDLE;
            enc_store <= 0;
        end else begin
            case (phase)

                IDLE:
                    if (aes_start)
                        phase <= ENC_RUN;

                ENC_RUN:
                    if (enc_ready) begin
                        enc_store <= enc_cipher;
                        phase <= DEC_KEY;
                    end

                // 1 cycle key expansion trigger
                DEC_KEY:
                    phase <= DEC_RUN;

                DEC_RUN:
                    if (dec_ready)
                        phase <= DONE;

                DONE:
                    phase <= IDLE;

            endcase
        end
    end

    //--------------------------------------------------
    // Final Result = decrypted plaintext
    //--------------------------------------------------
    assign aes_result_full = dec_plain;

    //--------------------------------------------------
    // Busy / Done
    //--------------------------------------------------
    assign aes_busy = (phase != IDLE) && (phase != DONE);
    assign aes_done = (phase == DONE);

    //--------------------------------------------------
    // 128 → 4×32 writeback
    //--------------------------------------------------
    reg [1:0] write_phase;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            aes_wen <= 0;
            write_phase <= 0;
        end else begin

            if (phase == DONE)
                write_phase <= 0;

            if (phase == DONE) begin
                aes_wen <= 1;

                case (write_phase)

                    2'd0: begin
                        aes_waddr <= rd_E;
                        aes_wdata <= dec_plain[31:0];
                        write_phase <= 2'd1;
                    end

                    2'd1: begin
                        aes_waddr <= rd_E + 5'd1;
                        aes_wdata <= dec_plain[63:32];
                        write_phase <= 2'd2;
                    end

                    2'd2: begin
                        aes_waddr <= rd_E + 5'd2;
                        aes_wdata <= dec_plain[95:64];
                        write_phase <= 2'd3;
                    end

                    2'd3: begin
                        aes_waddr <= rd_E + 5'd3;
                        aes_wdata <= dec_plain[127:96];
                        write_phase <= 2'd0;
                        aes_wen <= 0;
                    end
                endcase
            end else begin
                aes_wen <= 0;
            end
        end
    end

endmodule