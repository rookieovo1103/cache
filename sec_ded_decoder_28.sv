module sec_ded_decoder_28(
  input  logic[27:0]  data_i,
  input  logic[6:0]   ecc_i,
  output logic[27:0]  corrected_data_o,
  output logic        single_error_o,
  output logic        double_error_o
);

  logic[5:0]  syndrome;
  logic       parity_bit;
  logic[33:0] error_mask;
  logic[33:0] data_i_plus_parity;
  logic[33:0] dout_plus_parity;

  //  Syndrome
  assign syndrome[0] = ecc_i[0]^data_i[0]^data_i[1]^data_i[3]^data_i[4]^data_i[6]^data_i[8]^data_i[10]^data_i[11]^data_i[13]^data_i[15]^data_i[17]^data_i[19]^data_i[21]^data_i[23]^data_i[25]^data_i[26];
  assign syndrome[1] = ecc_i[1]^data_i[0]^data_i[2]^data_i[3]^data_i[5]^data_i[6]^data_i[9]^data_i[10]^data_i[12]^data_i[13]^data_i[16]^data_i[17]^data_i[20]^data_i[21]^data_i[24]^data_i[25]^data_i[27];
  assign syndrome[2] = ecc_i[2]^data_i[1]^data_i[2]^data_i[3]^data_i[7]^data_i[8]^data_i[9]^data_i[10]^data_i[14]^data_i[15]^data_i[16]^data_i[17]^data_i[22]^data_i[23]^data_i[24]^data_i[25];
  assign syndrome[3] = ecc_i[3]^data_i[4]^data_i[5]^data_i[6]^data_i[7]^data_i[8]^data_i[9]^data_i[10]^data_i[18]^data_i[19]^data_i[20]^data_i[21]^data_i[22]^data_i[23]^data_i[24]^data_i[25];
  assign syndrome[4] = ecc_i[4]^data_i[11]^data_i[12]^data_i[13]^data_i[14]^data_i[15]^data_i[16]^data_i[17]^data_i[18]^data_i[19]^data_i[20]^data_i[21]^data_i[22]^data_i[23]^data_i[24]^data_i[25];
  assign syndrome[5] = ecc_i[5]^data_i[26]^data_i[27];

  assign parity_bit = (^data_i) ^ (^ecc_i);

  assign single_error_o = parity_bit;
  assign double_error_o = ~parity_bit & (syndrome != 0);  // all errors in the sed_ded case will be recorded as DE

  // Generate the mask for error correctiong
  generate
    for(genvar i=1; i<35; i++) begin: g_error_mask
      assign error_mask[i-1] = (syndrome == i);
    end
  endgenerate

  // Generate the corrected data
  assign data_i_plus_parity = {data_i[27:26], ecc_i[5], data_i[25:11], ecc_i[4], data_i[10:4], ecc_i[3], data_i[3:1], ecc_i[2], data_i[0], ecc_i[1:0]};

  assign dout_plus_parity = single_error_o ? (error_mask ^ data_i_plus_parity) : data_i_plus_parity;
  assign corrected_data_o = {dout_plus_parity[33:32], dout_plus_parity[30:16], dout_plus_parity[14:8], dout_plus_parity[6:4], dout_plus_parity[2]};
  //assign ecc_out[6:0]           = {(dout_plus_parity[38] ^ (syndrome[6:0] == 7'b1000000)), dout_plus_parity[31], dout_plus_parity[15], dout_plus_parity[7], dout_plus_parity[3], dout_plus_parity[1:0]};

  //  | Parity | Syndrome |  Error Type  |
  //  ------------------------------------
  //  |    0   |    0     |   No Error   |
  //  |    1   |    0     | Parity Error |
  //  |    1   |   !=0    | Single Error |
  //  |    0   |   !=0    | Double Error |
  //assign single_error_o = parity  && (syndrome != {(ECC_WIDTH-1){1'b0}});
  //assign double_error_o = !parity && (syndrome == {(ECC_WIDTH-1){1'b0}});

endmodule
