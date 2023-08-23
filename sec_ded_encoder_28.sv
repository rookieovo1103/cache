module sec_ded_encoder_28(
  input  logic[27:0] data_i,
  output logic[6:0]  ecc_o
);

  assign ecc_o[0] = data_i[0]^data_i[1]^data_i[3]^data_i[4]^data_i[6]^data_i[8]^data_i[10]^data_i[11]^data_i[13]^data_i[15]^data_i[17]^data_i[19]^data_i[21]^data_i[23]^data_i[25]^data_i[26];
  assign ecc_o[1] = data_i[0]^data_i[2]^data_i[3]^data_i[5]^data_i[6]^data_i[9]^data_i[10]^data_i[12]^data_i[13]^data_i[16]^data_i[17]^data_i[20]^data_i[21]^data_i[24]^data_i[25]^data_i[27];
  assign ecc_o[2] = data_i[1]^data_i[2]^data_i[3]^data_i[7]^data_i[8]^data_i[9]^data_i[10]^data_i[14]^data_i[15]^data_i[16]^data_i[17]^data_i[22]^data_i[23]^data_i[24]^data_i[25];
  assign ecc_o[3] = data_i[4]^data_i[5]^data_i[6]^data_i[7]^data_i[8]^data_i[9]^data_i[10]^data_i[18]^data_i[19]^data_i[20]^data_i[21]^data_i[22]^data_i[23]^data_i[24]^data_i[25];
  assign ecc_o[4] = data_i[11]^data_i[12]^data_i[13]^data_i[14]^data_i[15]^data_i[16]^data_i[17]^data_i[18]^data_i[19]^data_i[20]^data_i[21]^data_i[22]^data_i[23]^data_i[24]^data_i[25];
  assign ecc_o[5] = data_i[26]^data_i[27];
  assign ecc_o[6] = (^data_i) ^ (^ecc_o[5:0]);
endmodule
