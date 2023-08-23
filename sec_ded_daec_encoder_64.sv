module sec_ded_daec_encoder_64(
  input  logic[63:0]  data_i,
  output logic[7:0]   ecc_o
);

  //  row0: 0 3 5 7 8 9 11 13 14 17 19 22 25 30 32 33 37 40 41 44 48 49 51 56 57 58
  //  row1: 0 2 3 4 7 8 14 16 18 21 24 29 31 32 36 39 40 43 47 48 50 55 56 57 63
  //  row2: 1 2 4 6 8 10 11 12 14 16 17 20 23 28 30 31 35 38 39 42 46 47 49 54 55 56 62 63
  //  row3: 0 1 2 3 5 6 9 11 12 15 16 19 22 24 27 29 30 34 37 38 41 45 46 48 53 54 61 62 63
  //  row4: 0 3 5 6 10 11 12 13 15 16 18 21 23 26 28 29 33 36 37 40 44 45 52 53 55 60 61 62
  //  row5: 0 1 2 4 5 8 9 10 11 12 13 15 16 17 20 22 25 27 28 32 35 36 43 44 47 51 52 54 59 60 61
  //  row6: 1 2 4 6 7 9 10 12 13 14 15 19 21 24 26 27 34 35 39 42 43 46 50 51 53 58 59 60
  //  row7: 1 3 4 5 6 8 9 10 13 14 15 18 20 23 25 26 31 33 34 38 41 42 45 49 50 52 57 58 59

  //  row0: 0 3 5 7 8 9 11 13 14 17 19 22 25 30 32 33 37 40 41 44 48 49 51 56 57 58
  assign ecc_o[0] = data_i[0]^data_i[3]^data_i[5]^data_i[7]^data_i[8]^data_i[9]^data_i[11]^data_i[13]^data_i[14]^data_i[17]^data_i[19]^data_i[22]^data_i[25]^data_i[30]^data_i[32]^data_i[33]^data_i[37]^data_i[40]^data_i[41]^data_i[44]^data_i[48]^data_i[49]^data_i[51]^data_i[56]^data_i[57]^data_i[58];
  //  row1: 0 2 3 4 7 8 14 16 18 21 24 29 31 32 36 39 40 43 47 48 50 55 56 57 63
  assign ecc_o[1] = data_i[0]^data_i[2]^data_i[3]^data_i[4]^data_i[7]^data_i[8]^data_i[14]^data_i[16]^data_i[18]^data_i[21]^data_i[24]^data_i[29]^data_i[31]^data_i[32]^data_i[36]^data_i[39]^data_i[40]^data_i[43]^data_i[47]^data_i[48]^data_i[50]^data_i[55]^data_i[56]^data_i[57]^data_i[63];
  //  row2: 1 2 4 6 8 10 11 12 14 16 17 20 23 28 30 31 35 38 39 42 46 47 49 54 55 56 62 63
  assign ecc_o[2] = data_i[1]^data_i[2]^data_i[4]^data_i[6]^data_i[8]^data_i[10]^data_i[11]^data_i[12]^data_i[14]^data_i[16]^data_i[17]^data_i[20]^data_i[23]^data_i[28]^data_i[30]^data_i[31]^data_i[35]^data_i[38]^data_i[39]^data_i[42]^data_i[46]^data_i[47]^data_i[49]^data_i[54]^data_i[55]^data_i[56]^data_i[62]^data_i[63];
  //  row3: 0 1 2 3 5 6 9 11 12 15 16 19 22 24 27 29 30 34 37 38 41 45 46 48 53 54 61 62 63
  assign ecc_o[3] = data_i[0]^data_i[1]^data_i[2]^data_i[3]^data_i[5]^data_i[6]^data_i[9]^data_i[11]^data_i[12]^data_i[15]^data_i[16]^data_i[19]^data_i[22]^data_i[24]^data_i[27]^data_i[29]^data_i[30]^data_i[34]^data_i[37]^data_i[38]^data_i[41]^data_i[45]^data_i[46]^data_i[48]^data_i[53]^data_i[54]^data_i[61]^data_i[62]^data_i[63];
  //  row4: 0 3 5 6 10 11 12 13 15 16 18 21 23 26 28 29 33 36 37 40 44 45 52 53 55 60 61 62
  assign ecc_o[4] = data_i[0]^data_i[3]^data_i[5]^data_i[6]^data_i[10]^data_i[11]^data_i[12]^data_i[13]^data_i[15]^data_i[16]^data_i[18]^data_i[21]^data_i[23]^data_i[26]^data_i[28]^data_i[29]^data_i[33]^data_i[36]^data_i[37]^data_i[40]^data_i[44]^data_i[45]^data_i[52]^data_i[53]^data_i[55]^data_i[60]^data_i[61]^data_i[62];
  //  row5: 0 1 2 4 5 8 9 10 11 12 13 15 16 17 20 22 25 27 28 32 35 36 43 44 47 51 52 54 59 60 61
  assign ecc_o[5] = data_i[0]^data_i[1]^data_i[2]^data_i[4]^data_i[5]^data_i[8]^data_i[9]^data_i[10]^data_i[11]^data_i[12]^data_i[13]^data_i[15]^data_i[16]^data_i[17]^data_i[20]^data_i[22]^data_i[25]^data_i[27]^data_i[28]^data_i[32]^data_i[35]^data_i[36]^data_i[43]^data_i[44]^data_i[47]^data_i[51]^data_i[52]^data_i[54]^data_i[59]^data_i[60]^data_i[61];
  //  row6: 1 2 4 6 7 9 10 12 13 14 15 19 21 24 26 27 34 35 39 42 43 46 50 51 53 58 59 60
  assign ecc_o[6] = data_i[1]^data_i[2]^data_i[4]^data_i[6]^data_i[7]^data_i[9]^data_i[10]^data_i[12]^data_i[13]^data_i[14]^data_i[15]^data_i[19]^data_i[21]^data_i[24]^data_i[26]^data_i[27]^data_i[34]^data_i[35]^data_i[39]^data_i[42]^data_i[43]^data_i[46]^data_i[50]^data_i[51]^data_i[53]^data_i[58]^data_i[59]^data_i[60];
  //  row7: 1 3 4 5 6 8 9 10 13 14 15 18 20 23 25 26 31 33 34 38 41 42 45 49 50 52 57 58 59
  assign ecc_o[7] = data_i[1]^data_i[3]^data_i[4]^data_i[5]^data_i[6]^data_i[8]^data_i[9]^data_i[10]^data_i[13]^data_i[14]^data_i[15]^data_i[18]^data_i[20]^data_i[23]^data_i[25]^data_i[26]^data_i[31]^data_i[33]^data_i[34]^data_i[38]^data_i[41]^data_i[42]^data_i[45]^data_i[49]^data_i[50]^data_i[52]^data_i[57]^data_i[58]^data_i[59];

endmodule
