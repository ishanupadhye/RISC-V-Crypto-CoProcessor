`timescale 1ns/1ps
module lite_aes128 #(
  parameter ROUNDS = 6
)(
  input  wire clk,
  input  wire rst_n,
  input  wire start,                // single-cycle start pulse (from CPU)
  input  wire [127:0] key_in,       // load master key
  input  wire key_load,             // sample key when high
  input  wire [127:0] plaintext,
  output reg  [127:0] ciphertext,
  output reg  ready
);

  // --- AES S-box (full 256 entries)
  reg [7:0] sbox [0:255];
  initial begin
    sbox[8'h00]=8'h63; sbox[8'h01]=8'h7c; sbox[8'h02]=8'h77; sbox[8'h03]=8'h7b;
    sbox[8'h04]=8'hf2; sbox[8'h05]=8'h6b; sbox[8'h06]=8'h6f; sbox[8'h07]=8'hc5;
    sbox[8'h08]=8'h30; sbox[8'h09]=8'h01; sbox[8'h0a]=8'h67; sbox[8'h0b]=8'h2b;
    sbox[8'h0c]=8'hfe; sbox[8'h0d]=8'hd7; sbox[8'h0e]=8'hab; sbox[8'h0f]=8'h76;
    sbox[8'h10]=8'hca; sbox[8'h11]=8'h82; sbox[8'h12]=8'hc9; sbox[8'h13]=8'h7d;
    sbox[8'h14]=8'hfa; sbox[8'h15]=8'h59; sbox[8'h16]=8'h47; sbox[8'h17]=8'hf0;
    sbox[8'h18]=8'had; sbox[8'h19]=8'hd4; sbox[8'h1a]=8'ha2; sbox[8'h1b]=8'haf;
    sbox[8'h1c]=8'h9c; sbox[8'h1d]=8'ha4; sbox[8'h1e]=8'h72; sbox[8'h1f]=8'hc0;
    sbox[8'h20]=8'hb7; sbox[8'h21]=8'hfd; sbox[8'h22]=8'h93; sbox[8'h23]=8'h26;
    sbox[8'h24]=8'h36; sbox[8'h25]=8'h3f; sbox[8'h26]=8'hf7; sbox[8'h27]=8'hcc;
    sbox[8'h28]=8'h34; sbox[8'h29]=8'ha5; sbox[8'h2a]=8'he5; sbox[8'h2b]=8'hf1;
    sbox[8'h2c]=8'h71; sbox[8'h2d]=8'hd8; sbox[8'h2e]=8'h31; sbox[8'h2f]=8'h15;
    sbox[8'h30]=8'h04; sbox[8'h31]=8'hc7; sbox[8'h32]=8'h23; sbox[8'h33]=8'hc3;
    sbox[8'h34]=8'h18; sbox[8'h35]=8'h96; sbox[8'h36]=8'h05; sbox[8'h37]=8'h9a;
    sbox[8'h38]=8'h07; sbox[8'h39]=8'h12; sbox[8'h3a]=8'h80; sbox[8'h3b]=8'he2;
    sbox[8'h3c]=8'heb; sbox[8'h3d]=8'h27; sbox[8'h3e]=8'hb2; sbox[8'h3f]=8'h75;
    sbox[8'h40]=8'h09; sbox[8'h41]=8'h83; sbox[8'h42]=8'h2c; sbox[8'h43]=8'h1a;
    sbox[8'h44]=8'h1b; sbox[8'h45]=8'h6e; sbox[8'h46]=8'h5a; sbox[8'h47]=8'ha0;
    sbox[8'h48]=8'h52; sbox[8'h49]=8'h3b; sbox[8'h4a]=8'hd6; sbox[8'h4b]=8'hb3;
    sbox[8'h4c]=8'h29; sbox[8'h4d]=8'he3; sbox[8'h4e]=8'h2f; sbox[8'h4f]=8'h84;
    sbox[8'h50]=8'h53; sbox[8'h51]=8'hd1; sbox[8'h52]=8'h00; sbox[8'h53]=8'hed;
    sbox[8'h54]=8'h20; sbox[8'h55]=8'hfc; sbox[8'h56]=8'hb1; sbox[8'h57]=8'h5b;
    sbox[8'h58]=8'h6a; sbox[8'h59]=8'hcb; sbox[8'h5a]=8'hbe; sbox[8'h5b]=8'h39;
    sbox[8'h5c]=8'h4a; sbox[8'h5d]=8'h4c; sbox[8'h5e]=8'h58; sbox[8'h5f]=8'hcf;
    sbox[8'h60]=8'hd0; sbox[8'h61]=8'hef; sbox[8'h62]=8'haa; sbox[8'h63]=8'hfb;
    sbox[8'h64]=8'h43; sbox[8'h65]=8'h4d; sbox[8'h66]=8'h33; sbox[8'h67]=8'h85;
    sbox[8'h68]=8'h45; sbox[8'h69]=8'hf9; sbox[8'h6a]=8'h02; sbox[8'h6b]=8'h7f;
    sbox[8'h6c]=8'h50; sbox[8'h6d]=8'h3c; sbox[8'h6e]=8'h9f; sbox[8'h6f]=8'ha8;
    sbox[8'h70]=8'h51; sbox[8'h71]=8'ha3; sbox[8'h72]=8'h40; sbox[8'h73]=8'h8f;
    sbox[8'h74]=8'h92; sbox[8'h75]=8'h9d; sbox[8'h76]=8'h38; sbox[8'h77]=8'hf5;
    sbox[8'h78]=8'hbc; sbox[8'h79]=8'hb6; sbox[8'h7a]=8'hda; sbox[8'h7b]=8'h21;
    sbox[8'h7c]=8'h10; sbox[8'h7d]=8'hff; sbox[8'h7e]=8'hf3; sbox[8'h7f]=8'hd2;
    sbox[8'h80]=8'hcd; sbox[8'h81]=8'h0c; sbox[8'h82]=8'h13; sbox[8'h83]=8'hec;
    sbox[8'h84]=8'h5f; sbox[8'h85]=8'h97; sbox[8'h86]=8'h44; sbox[8'h87]=8'h17;
    sbox[8'h88]=8'hc4; sbox[8'h89]=8'ha7; sbox[8'h8a]=8'h7e; sbox[8'h8b]=8'h3d;
    sbox[8'h8c]=8'h64; sbox[8'h8d]=8'h5d; sbox[8'h8e]=8'h19; sbox[8'h8f]=8'h73;
    sbox[8'h90]=8'h60; sbox[8'h91]=8'h81; sbox[8'h92]=8'h4f; sbox[8'h93]=8'hdc;
    sbox[8'h94]=8'h22; sbox[8'h95]=8'h2a; sbox[8'h96]=8'h90; sbox[8'h97]=8'h88;
    sbox[8'h98]=8'h46; sbox[8'h99]=8'hee; sbox[8'h9a]=8'hb8; sbox[8'h9b]=8'h14;
    sbox[8'h9c]=8'hde; sbox[8'h9d]=8'h5e; sbox[8'h9e]=8'h0b; sbox[8'h9f]=8'hdb;
    sbox[8'ha0]=8'he0; sbox[8'ha1]=8'h32; sbox[8'ha2]=8'h3a; sbox[8'ha3]=8'h0a;
    sbox[8'ha4]=8'h49; sbox[8'ha5]=8'h06; sbox[8'ha6]=8'h24; sbox[8'ha7]=8'h5c;
    sbox[8'ha8]=8'hc2; sbox[8'ha9]=8'hd3; sbox[8'haa]=8'hac; sbox[8'hab]=8'h62;
    sbox[8'hac]=8'h91; sbox[8'had]=8'h95; sbox[8'hae]=8'he4; sbox[8'haf]=8'h79;
    sbox[8'hb0]=8'he7; sbox[8'hb1]=8'hc8; sbox[8'hb2]=8'h37; sbox[8'hb3]=8'h6d;
    sbox[8'hb4]=8'h8d; sbox[8'hb5]=8'hd5; sbox[8'hb6]=8'h4e; sbox[8'hb7]=8'ha9;
    sbox[8'hb8]=8'h6c; sbox[8'hb9]=8'h56; sbox[8'hba]=8'hf4; sbox[8'hbb]=8'hea;
    sbox[8'hbc]=8'h65; sbox[8'hbd]=8'h7a; sbox[8'hbe]=8'hae; sbox[8'hbf]=8'h08;
    sbox[8'hc0]=8'hba; sbox[8'hc1]=8'h78; sbox[8'hc2]=8'h25; sbox[8'hc3]=8'h2e;
    sbox[8'hc4]=8'h1c; sbox[8'hc5]=8'ha6; sbox[8'hc6]=8'hb4; sbox[8'hc7]=8'hc6;
    sbox[8'hc8]=8'he8; sbox[8'hc9]=8'hdd; sbox[8'hca]=8'h74; sbox[8'hcb]=8'h1f;
    sbox[8'hcc]=8'h4b; sbox[8'hcd]=8'hbd; sbox[8'hce]=8'h8b; sbox[8'hcf]=8'h8a;
    sbox[8'hd0]=8'h70; sbox[8'hd1]=8'h3e; sbox[8'hd2]=8'hb5; sbox[8'hd3]=8'h66;
    sbox[8'hd4]=8'h48; sbox[8'hd5]=8'h03; sbox[8'hd6]=8'hf6; sbox[8'hd7]=8'h0e;
    sbox[8'hd8]=8'h61; sbox[8'hd9]=8'h35; sbox[8'hda]=8'h57; sbox[8'hdb]=8'hb9;
    sbox[8'hdc]=8'h86; sbox[8'hdd]=8'hc1; sbox[8'hde]=8'h1d; sbox[8'hdf]=8'h9e;
    sbox[8'he0]=8'he1; sbox[8'he1]=8'hf8; sbox[8'he2]=8'h98; sbox[8'he3]=8'h11;
    sbox[8'he4]=8'h69; sbox[8'he5]=8'hd9; sbox[8'he6]=8'h8e; sbox[8'he7]=8'h94;
    sbox[8'he8]=8'h9b; sbox[8'he9]=8'h1e; sbox[8'hea]=8'h87; sbox[8'heb]=8'he9;
    sbox[8'hec]=8'hce; sbox[8'hed]=8'h55; sbox[8'hee]=8'h28; sbox[8'hef]=8'hdf;
    sbox[8'hf0]=8'h8c; sbox[8'hf1]=8'ha1; sbox[8'hf2]=8'h89; sbox[8'hf3]=8'h0d;
    sbox[8'hf4]=8'hbf; sbox[8'hf5]=8'he6; sbox[8'hf6]=8'h42; sbox[8'hf7]=8'h68;
    sbox[8'hf8]=8'h41; sbox[8'hf9]=8'h99; sbox[8'hfa]=8'h2d; sbox[8'hfb]=8'h0f;
    sbox[8'hfc]=8'hb0; sbox[8'hfd]=8'h54; sbox[8'hfe]=8'hbb; sbox[8'hff]=8'h16;
  end

  // rcon table (for simple key schedule)
  reg [7:0] rcon_table [0:10];
  initial begin
    rcon_table[0] = 8'h01; rcon_table[1] = 8'h02; rcon_table[2] = 8'h04; rcon_table[3] = 8'h08;
    rcon_table[4] = 8'h10; rcon_table[5] = 8'h20; rcon_table[6] = 8'h40; rcon_table[7] = 8'h80;
    rcon_table[8] = 8'h1B; rcon_table[9] = 8'h36; rcon_table[10] = 8'h6C;
  end

  // --- helpers and storage (module-scope)
  function [7:0] sb;
    input [7:0] b; sb = sbox[b]; endfunction

  reg [127:0] state;
  reg [127:0] roundkey;
  reg [3:0] round_ctr; // up to 15
  reg [1:0] fsm; // states
  localparam IDLE = 2'b00, KEY_LOADED = 2'b01, ROUND = 2'b10, DONE = 2'b11;

  // temporary byte arrays and temp states (module scope)
  reg [7:0] tmp_bytes [0:15];     // for SubBytes output
  reg [7:0] shift_bytes [0:15];   // after shiftrows
  reg [7:0] mix_bytes [0:15];     // after lite_mix
  reg [127:0] tmpst;              // intermediate 128-bit state
  integer i;

  // --- next_roundkey function (accept round index)
  function [127:0] next_roundkey;
    input [127:0] cur;
    input [3:0]  round_idx;
    reg [31:0] temp;
    reg [31:0] w0, w1, w2, w3;
    reg [7:0] t0, t1, t2, t3;
    begin
      w0 = cur[127:96];
      w1 = cur[95:64];
      w2 = cur[63:32];
      w3 = cur[31:0];
      // rotate bytes of w0 and apply sbox per byte
      t0 = sb(w0[23:16]); // note: rotate bytes: [23:16],[15:8],[7:0],[31:24]
      t1 = sb(w0[15:8]);
      t2 = sb(w0[7:0]);
      t3 = sb(w0[31:24]);
      // assemble temp word
      temp = {t0, t1, t2, t3};
      // XOR rcon to high byte
      temp[31:24] = temp[31:24] ^ rcon_table[round_idx % 11];
      // compute next words
      w0 = w0 ^ temp;
      w1 = w1 ^ w0;
      w2 = w2 ^ w1;
      w3 = w3 ^ w2;
      next_roundkey = {w0, w1, w2, w3};
    end
  endfunction

  // --- lite_mix: new_b[i] = b[i] ^ b[(i+1)%16] ^ b[(i+4)%16]
  // implemented inline in always block using mix_bytes array.

  // --- FSM & datapath
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= 128'b0;
      roundkey <= 128'b0;
      round_ctr <= 0;
      fsm <= IDLE;
      ready <= 1'b1;
      ciphertext <= 128'b0;
      // clear temps
      for (i=0; i<16; i=i+1) begin
        tmp_bytes[i] = 8'b0;
        shift_bytes[i] = 8'b0;
        mix_bytes[i] = 8'b0;
      end
    end else begin
      case (fsm)
        IDLE: begin
          ready <= 1'b1;
          if (key_load) begin
            roundkey <= key_in;
            fsm <= KEY_LOADED;
            ready <= 1'b0;
          end else if (start) begin
            // start encryption using current roundkey
            state <= plaintext ^ roundkey;
            round_ctr <= 0;
            fsm <= ROUND;
            ready <= 1'b0;
          end
        end

        KEY_LOADED: begin
          // just go back to idle and indicate ready
          ready <= 1'b1;
          fsm <= IDLE;
        end

        ROUND: begin
          // --- SubBytes
          for (i=0; i<16; i=i+1) begin
            tmp_bytes[i] = sb(state[(120 - 8*i) +: 8]);
          end

          // --- ShiftRows (AES mapping)
          // bytes indices in column-major: [0,4,8,12]=row0, [1,5,9,13]=row1, etc.
          shift_bytes[0]  = tmp_bytes[0];
          shift_bytes[4]  = tmp_bytes[4];
          shift_bytes[8]  = tmp_bytes[8];
          shift_bytes[12] = tmp_bytes[12];

          shift_bytes[1]  = tmp_bytes[5];
          shift_bytes[5]  = tmp_bytes[9];
          shift_bytes[9]  = tmp_bytes[13];
          shift_bytes[13] = tmp_bytes[1];

          shift_bytes[2]  = tmp_bytes[10];
          shift_bytes[6]  = tmp_bytes[14];
          shift_bytes[10] = tmp_bytes[2];
          shift_bytes[14] = tmp_bytes[6];

          shift_bytes[3]  = tmp_bytes[15];
          shift_bytes[7]  = tmp_bytes[3];
          shift_bytes[11] = tmp_bytes[7];
          shift_bytes[15] = tmp_bytes[11];

          // --- Lite diffusion (mix): new_b[i] = b[i] ^ b[(i+1)%16] ^ b[(i+4)%16]
          for (i=0; i<16; i=i+1) begin
            mix_bytes[i] = shift_bytes[i] ^ shift_bytes[(i+1) % 16] ^ shift_bytes[(i+4) % 16];
          end

          // reassemble tmpst from mix_bytes (big-endian byte packing like earlier)
          tmpst = 128'b0;
          for (i=0; i<16; i=i+1) begin
            tmpst[(120 - 8*i) +: 8] = mix_bytes[i];
          end

          // AddRoundKey
          tmpst = tmpst ^ roundkey;

          // update state and roundkey (non-blocking style)
          state <= tmpst;
          roundkey <= next_roundkey(roundkey, round_ctr);
          round_ctr <= round_ctr + 1;

          if (round_ctr + 1 >= ROUNDS) begin
            ciphertext <= tmpst;
            fsm <= DONE;
            ready <= 1'b1;
          end else begin
            fsm <= ROUND; // continue rounds
          end
        end

        DONE: begin
          // hold ciphertext until next start or key_load
          ready <= 1'b1;
          if (key_load) begin
            roundkey <= key_in;
            fsm <= KEY_LOADED;
            ready <= 1'b0;
          end else if (start) begin
            state <= plaintext ^ roundkey;
            round_ctr <= 0;
            fsm <= ROUND;
            ready <= 1'b0;
          end
        end

      endcase
    end
  end

endmodule
