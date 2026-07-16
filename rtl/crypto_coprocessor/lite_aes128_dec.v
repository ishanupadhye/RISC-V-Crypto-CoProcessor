`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.03.2026 02:42:01
// Design Name: 
// Module Name: lite_aes128_dec
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lite_aes128_dec #(
  parameter ROUNDS = 6
)(
  input  wire clk,
  input  wire rst_n,
  input  wire start,             // single-cycle start pulse (from CPU)
  input  wire [127:0] key_in,    // load master key
  input  wire key_load,          // sample key when high
  input  wire [127:0] ciphertext,
  output reg  [127:0] plaintext,
  output reg  ready
);

  // --- AES Forward S-box (Needed for Key Expansion)
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

  // --- AES Inverse S-box (For Decryption Rounds)
  reg [7:0] inv_sbox [0:255];
  initial begin
    inv_sbox[8'h00]=8'h52; inv_sbox[8'h01]=8'h09; inv_sbox[8'h02]=8'h6a; inv_sbox[8'h03]=8'hd5;
    inv_sbox[8'h04]=8'h30; inv_sbox[8'h05]=8'h36; inv_sbox[8'h06]=8'ha5; inv_sbox[8'h07]=8'h38;
    inv_sbox[8'h08]=8'hbf; inv_sbox[8'h09]=8'h40; inv_sbox[8'h0a]=8'ha3; inv_sbox[8'h0b]=8'h9e;
    inv_sbox[8'h0c]=8'h81; inv_sbox[8'h0d]=8'hf3; inv_sbox[8'h0e]=8'hd7; inv_sbox[8'h0f]=8'hfb;
    inv_sbox[8'h10]=8'h7c; inv_sbox[8'h11]=8'he3; inv_sbox[8'h12]=8'h39; inv_sbox[8'h13]=8'h82;
    inv_sbox[8'h14]=8'h9b; inv_sbox[8'h15]=8'h2f; inv_sbox[8'h16]=8'hff; inv_sbox[8'h17]=8'h87;
    inv_sbox[8'h18]=8'h34; inv_sbox[8'h19]=8'h8e; inv_sbox[8'h1a]=8'h43; inv_sbox[8'h1b]=8'h44;
    inv_sbox[8'h1c]=8'hc4; inv_sbox[8'h1d]=8'hde; inv_sbox[8'h1e]=8'he9; inv_sbox[8'h1f]=8'hcb;
    inv_sbox[8'h20]=8'h54; inv_sbox[8'h21]=8'h7b; inv_sbox[8'h22]=8'h94; inv_sbox[8'h23]=8'h32;
    inv_sbox[8'h24]=8'ha6; inv_sbox[8'h25]=8'hc2; inv_sbox[8'h26]=8'h23; inv_sbox[8'h27]=8'h3d;
    inv_sbox[8'h28]=8'hee; inv_sbox[8'h29]=8'h4c; inv_sbox[8'h2a]=8'h95; inv_sbox[8'h2b]=8'h0b;
    inv_sbox[8'h2c]=8'h42; inv_sbox[8'h2d]=8'hfa; inv_sbox[8'h2e]=8'hc3; inv_sbox[8'h2f]=8'h4e;
    inv_sbox[8'h30]=8'h08; inv_sbox[8'h31]=8'h2e; inv_sbox[8'h32]=8'ha1; inv_sbox[8'h33]=8'h66;
    inv_sbox[8'h34]=8'h28; inv_sbox[8'h35]=8'hd9; inv_sbox[8'h36]=8'h24; inv_sbox[8'h37]=8'hb2;
    inv_sbox[8'h38]=8'h76; inv_sbox[8'h39]=8'h5b; inv_sbox[8'h3a]=8'ha2; inv_sbox[8'h3b]=8'h49;
    inv_sbox[8'h3c]=8'h6d; inv_sbox[8'h3d]=8'h8b; inv_sbox[8'h3e]=8'hd1; inv_sbox[8'h3f]=8'h25;
    inv_sbox[8'h40]=8'h72; inv_sbox[8'h41]=8'hf8; inv_sbox[8'h42]=8'hf6; inv_sbox[8'h43]=8'h64;
    inv_sbox[8'h44]=8'h86; inv_sbox[8'h45]=8'h68; inv_sbox[8'h46]=8'h98; inv_sbox[8'h47]=8'h16;
    inv_sbox[8'h48]=8'hd4; inv_sbox[8'h49]=8'ha4; inv_sbox[8'h4a]=8'h5c; inv_sbox[8'h4b]=8'hcc;
    inv_sbox[8'h4c]=8'h5d; inv_sbox[8'h4d]=8'h65; inv_sbox[8'h4e]=8'hb6; inv_sbox[8'h4f]=8'h92;
    inv_sbox[8'h50]=8'h6c; inv_sbox[8'h51]=8'h70; inv_sbox[8'h52]=8'h48; inv_sbox[8'h53]=8'h50;
    inv_sbox[8'h54]=8'hfd; inv_sbox[8'h55]=8'hed; inv_sbox[8'h56]=8'hb9; inv_sbox[8'h57]=8'hda;
    inv_sbox[8'h58]=8'h5e; inv_sbox[8'h59]=8'h15; inv_sbox[8'h5a]=8'h46; inv_sbox[8'h5b]=8'h57;
    inv_sbox[8'h5c]=8'ha7; inv_sbox[8'h5d]=8'h8d; inv_sbox[8'h5e]=8'h9d; inv_sbox[8'h5f]=8'h84;
    inv_sbox[8'h60]=8'h90; inv_sbox[8'h61]=8'hd8; inv_sbox[8'h62]=8'hab; inv_sbox[8'h63]=8'h00;
    inv_sbox[8'h64]=8'h8c; inv_sbox[8'h65]=8'hbc; inv_sbox[8'h66]=8'hd3; inv_sbox[8'h67]=8'h0a;
    inv_sbox[8'h68]=8'hf7; inv_sbox[8'h69]=8'he4; inv_sbox[8'h6a]=8'h58; inv_sbox[8'h6b]=8'h05;
    inv_sbox[8'h6c]=8'hb8; inv_sbox[8'h6d]=8'hb3; inv_sbox[8'h6e]=8'h45; inv_sbox[8'h6f]=8'h06;
    inv_sbox[8'h70]=8'hd0; inv_sbox[8'h71]=8'h2c; inv_sbox[8'h72]=8'h1e; inv_sbox[8'h73]=8'h8f;
    inv_sbox[8'h74]=8'hca; inv_sbox[8'h75]=8'h3f; inv_sbox[8'h76]=8'h0f; inv_sbox[8'h77]=8'h02;
    inv_sbox[8'h78]=8'hc1; inv_sbox[8'h79]=8'haf; inv_sbox[8'h7a]=8'hbd; inv_sbox[8'h7b]=8'h03;
    inv_sbox[8'h7c]=8'h01; inv_sbox[8'h7d]=8'h13; inv_sbox[8'h7e]=8'h8a; inv_sbox[8'h7f]=8'h6b;
    inv_sbox[8'h80]=8'h3a; inv_sbox[8'h81]=8'h91; inv_sbox[8'h82]=8'h11; inv_sbox[8'h83]=8'h41;
    inv_sbox[8'h84]=8'h4f; inv_sbox[8'h85]=8'h67; inv_sbox[8'h86]=8'hdc; inv_sbox[8'h87]=8'hea;
    inv_sbox[8'h88]=8'h97; inv_sbox[8'h89]=8'hf2; inv_sbox[8'h8a]=8'hcf; inv_sbox[8'h8b]=8'hce;
    inv_sbox[8'h8c]=8'hf0; inv_sbox[8'h8d]=8'hb4; inv_sbox[8'h8e]=8'he6; inv_sbox[8'h8f]=8'h73;
    inv_sbox[8'h90]=8'h96; inv_sbox[8'h91]=8'hac; inv_sbox[8'h92]=8'h74; inv_sbox[8'h93]=8'h22;
    inv_sbox[8'h94]=8'he7; inv_sbox[8'h95]=8'had; inv_sbox[8'h96]=8'h35; inv_sbox[8'h97]=8'h85;
    inv_sbox[8'h98]=8'he2; inv_sbox[8'h99]=8'hf9; inv_sbox[8'h9a]=8'h37; inv_sbox[8'h9b]=8'he8;
    inv_sbox[8'h9c]=8'h1c; inv_sbox[8'h9d]=8'h75; inv_sbox[8'h9e]=8'hdf; inv_sbox[8'h9f]=8'h6e;
    inv_sbox[8'ha0]=8'h47; inv_sbox[8'ha1]=8'hf1; inv_sbox[8'ha2]=8'h1a; inv_sbox[8'ha3]=8'h71;
    inv_sbox[8'ha4]=8'h1d; inv_sbox[8'ha5]=8'h29; inv_sbox[8'ha6]=8'hc5; inv_sbox[8'ha7]=8'h89;
    inv_sbox[8'ha8]=8'h6f; inv_sbox[8'ha9]=8'hb7; inv_sbox[8'haa]=8'h62; inv_sbox[8'hab]=8'h0e;
    inv_sbox[8'hac]=8'haa; inv_sbox[8'had]=8'h18; inv_sbox[8'hae]=8'hbe; inv_sbox[8'haf]=8'h1b;
    inv_sbox[8'hb0]=8'hfc; inv_sbox[8'hb1]=8'h56; inv_sbox[8'hb2]=8'h3e; inv_sbox[8'hb3]=8'h4b;
    inv_sbox[8'hb4]=8'hc6; inv_sbox[8'hb5]=8'hd2; inv_sbox[8'hb6]=8'h79; inv_sbox[8'hb7]=8'h20;
    inv_sbox[8'hb8]=8'h9a; inv_sbox[8'hb9]=8'hdb; inv_sbox[8'hba]=8'hc0; inv_sbox[8'hbb]=8'hfe;
    inv_sbox[8'hbc]=8'h78; inv_sbox[8'hbd]=8'hcd; inv_sbox[8'hbe]=8'h5a; inv_sbox[8'hbf]=8'hf4;
    inv_sbox[8'hc0]=8'h1f; inv_sbox[8'hc1]=8'hdd; inv_sbox[8'hc2]=8'ha8; inv_sbox[8'hc3]=8'h33;
    inv_sbox[8'hc4]=8'h88; inv_sbox[8'hc5]=8'h07; inv_sbox[8'hc6]=8'hc7; inv_sbox[8'hc7]=8'h31;
    inv_sbox[8'hc8]=8'hb1; inv_sbox[8'hc9]=8'h12; inv_sbox[8'hca]=8'h10; inv_sbox[8'hcb]=8'h59;
    inv_sbox[8'hcc]=8'h27; inv_sbox[8'hcd]=8'h80; inv_sbox[8'hce]=8'hec; inv_sbox[8'hcf]=8'h5f;
    inv_sbox[8'hd0]=8'h60; inv_sbox[8'hd1]=8'h51; inv_sbox[8'hd2]=8'h7f; inv_sbox[8'hd3]=8'ha9;
    inv_sbox[8'hd4]=8'h19; inv_sbox[8'hd5]=8'hb5; inv_sbox[8'hd6]=8'h4a; inv_sbox[8'hd7]=8'h0d;
    inv_sbox[8'hd8]=8'h2d; inv_sbox[8'hd9]=8'he5; inv_sbox[8'hda]=8'h7a; inv_sbox[8'hdb]=8'h9f;
    inv_sbox[8'hdc]=8'h93; inv_sbox[8'hdd]=8'hc9; inv_sbox[8'hde]=8'h9c; inv_sbox[8'hdf]=8'hef;
    inv_sbox[8'he0]=8'ha0; inv_sbox[8'he1]=8'he0; inv_sbox[8'he2]=8'h3b; inv_sbox[8'he3]=8'h4d;
    inv_sbox[8'he4]=8'hae; inv_sbox[8'he5]=8'h2a; inv_sbox[8'he6]=8'hf5; inv_sbox[8'he7]=8'hb0;
    inv_sbox[8'he8]=8'hc8; inv_sbox[8'he9]=8'heb; inv_sbox[8'hea]=8'hbb; inv_sbox[8'heb]=8'h3c;
    inv_sbox[8'hec]=8'h83; inv_sbox[8'hed]=8'h53; inv_sbox[8'hee]=8'h99; inv_sbox[8'hef]=8'h61;
    inv_sbox[8'hf0]=8'h17; inv_sbox[8'hf1]=8'h2b; inv_sbox[8'hf2]=8'h04; inv_sbox[8'hf3]=8'h7e;
    inv_sbox[8'hf4]=8'hba; inv_sbox[8'hf5]=8'h77; inv_sbox[8'hf6]=8'hd6; inv_sbox[8'hf7]=8'h26;
    inv_sbox[8'hf8]=8'he1; inv_sbox[8'hf9]=8'h69; inv_sbox[8'hfa]=8'h14; inv_sbox[8'hfb]=8'h63;
    inv_sbox[8'hfc]=8'h55; inv_sbox[8'hfd]=8'h21; inv_sbox[8'hfe]=8'h0c; inv_sbox[8'hff]=8'h7d;
  end

  // --- Rcon Table
  reg [7:0] rcon_table [0:10];
  initial begin
    rcon_table[0] = 8'h01; rcon_table[1] = 8'h02; rcon_table[2] = 8'h04; rcon_table[3] = 8'h08;
    rcon_table[4] = 8'h10; rcon_table[5] = 8'h20; rcon_table[6] = 8'h40; rcon_table[7] = 8'h80;
    rcon_table[8] = 8'h1B; rcon_table[9] = 8'h36; rcon_table[10] = 8'h6C;
  end

  // --- Helpers
  function [7:0] sb;
    input [7:0] b; sb = sbox[b]; 
  endfunction

  function [7:0] inv_sb;
    input [7:0] b; inv_sb = inv_sbox[b]; 
  endfunction

  // --- Forward Next Round Key logic (used to precompute keys backwards)
  function [127:0] next_roundkey;
    input [127:0] cur;
    input [3:0] round_idx;
    reg [31:0] temp;
    reg [31:0] w0, w1, w2, w3;
    reg [7:0] t0, t1, t2, t3;
    begin
      w0 = cur[127:96];
      w1 = cur[95:64];
      w2 = cur[63:32];
      w3 = cur[31:0];
      t0 = sb(w0[23:16]);
      t1 = sb(w0[15:8]);
      t2 = sb(w0[7:0]);
      t3 = sb(w0[31:24]);
      temp = {t0, t1, t2, t3};
      temp[31:24] = temp[31:24] ^ rcon_table[round_idx % 11];
      w0 = w0 ^ temp;
      w1 = w1 ^ w0;
      w2 = w2 ^ w1;
      w3 = w3 ^ w2;
      next_roundkey = {w0, w1, w2, w3};
    end
  endfunction

  // --- FSM and Datapath
  reg [127:0] state;
  reg [127:0] roundkey;
  reg [127:0] key_mem [0:15];     // store expanded keys (supports up to 15 rounds)
  reg [3:0]   exp_ctr;
  reg [3:0]   dec_ctr;            // counts backwards
  reg [1:0]   fsm; 

  localparam IDLE       = 2'b00;
  localparam KEY_EXPAND = 2'b01;  // New state to precompute keys
  localparam ROUND      = 2'b10;
  localparam DONE       = 2'b11;

  // Temporaries inside module scope
  reg [7:0] t1_bytes [0:15];
  reg [7:0] inv_mix_bytes [0:15];
  reg [7:0] inv_shift_bytes [0:15];
  reg [7:0] inv_sub_bytes [0:15];
  reg [127:0] t4;
  integer i;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= 128'b0;
      roundkey <= 128'b0;
      exp_ctr <= 0;
      dec_ctr <= 0;
      fsm <= IDLE;
      ready <= 1'b1;
      plaintext <= 128'b0;
    end else begin
      case (fsm)
        IDLE: begin
          ready <= 1'b1;
          if (key_load) begin
            roundkey <= key_in;
            exp_ctr <= 0;
            fsm <= KEY_EXPAND;
            ready <= 1'b0;
          end else if (start) begin
            state <= ciphertext;
            dec_ctr <= ROUNDS - 1;
            fsm <= ROUND;
            ready <= 1'b0;
          end
        end

        KEY_EXPAND: begin
          // Build up the array of round keys exactly matching encryption
          key_mem[exp_ctr] <= roundkey;
          roundkey <= next_roundkey(roundkey, exp_ctr);
          exp_ctr <= exp_ctr + 1;
          
          if (exp_ctr == ROUNDS - 1) begin
            fsm <= IDLE;
            ready <= 1'b1;
          end
        end

        ROUND: begin
          // 1. AddRoundKey (at the start of inverse round)
          for (i=0; i<16; i=i+1) begin
            t1_bytes[i] = state[(120 - 8*i) +: 8] ^ key_mem[dec_ctr][(120 - 8*i) +: 8];
          end

          // 2. InvMixBytes (GF(2) polynomial inverse wiring)
          for (i=0; i<16; i=i+1) begin
            inv_mix_bytes[i] = t1_bytes[i] ^ t1_bytes[(i+2)%16] ^ t1_bytes[(i+4)%16] ^ 
                               t1_bytes[(i+5)%16] ^ t1_bytes[(i+8)%16] ^ t1_bytes[(i+12)%16] ^ 
                               t1_bytes[(i+13)%16] ^ t1_bytes[(i+14)%16] ^ t1_bytes[(i+15)%16];
          end

          // 3. InvShiftRows (reverse the wire assignments)
          inv_shift_bytes[0]  = inv_mix_bytes[0];
          inv_shift_bytes[4]  = inv_mix_bytes[4];
          inv_shift_bytes[8]  = inv_mix_bytes[8];
          inv_shift_bytes[12] = inv_mix_bytes[12];

          inv_shift_bytes[5]  = inv_mix_bytes[1];
          inv_shift_bytes[9]  = inv_mix_bytes[5];
          inv_shift_bytes[13] = inv_mix_bytes[9];
          inv_shift_bytes[1]  = inv_mix_bytes[13];

          inv_shift_bytes[10] = inv_mix_bytes[2];
          inv_shift_bytes[14] = inv_mix_bytes[6];
          inv_shift_bytes[2]  = inv_mix_bytes[10];
          inv_shift_bytes[6]  = inv_mix_bytes[14];

          inv_shift_bytes[15] = inv_mix_bytes[3];
          inv_shift_bytes[3]  = inv_mix_bytes[7];
          inv_shift_bytes[7]  = inv_mix_bytes[11];
          inv_shift_bytes[11] = inv_mix_bytes[15];

          // 4. InvSubBytes
          t4 = 128'b0;
          for (i=0; i<16; i=i+1) begin
            inv_sub_bytes[i] = inv_sb(inv_shift_bytes[i]);
            t4[(120 - 8*i) +: 8] = inv_sub_bytes[i];
          end

          if (dec_ctr == 0) begin
            // Reached the end of the round iterations.
            // The very first operation in the encryptor was: state <= plaintext ^ K_0
            // We must undo that pre-round XOR combinationally here to get the plaintext.
            plaintext <= t4 ^ key_mem[0];
            fsm <= DONE;
            ready <= 1'b1;
          end else begin
            state <= t4;
            dec_ctr <= dec_ctr - 1;
            fsm <= ROUND;
          end
        end

        DONE: begin
          ready <= 1'b1;
          if (key_load) begin
            roundkey <= key_in;
            exp_ctr <= 0;
            fsm <= KEY_EXPAND;
            ready <= 1'b0;
          end else if (start) begin
            state <= ciphertext;
            dec_ctr <= ROUNDS - 1;
            fsm <= ROUND;
            ready <= 1'b0;
          end
        end

      endcase
    end
  end

endmodule

