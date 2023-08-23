module oh2bin #(
  parameter OH_WIDTH = -1
)(
  input  logic[OH_WIDTH-1:0]          oh_i,
  output logic[$clog2(OH_WIDTH)-1:0]  bin_o
);

  logic[OH_WIDTH-1:0] matrix [$clog2(OH_WIDTH)-1:0];

  //  ont-hot to binary
  //assign bin = {3{oh[0]}} & 3'd0 |
  //             {3{oh[1]}} & 3'd1 |
  //             {3{oh[2]}} & 3'd2 |
  //             {3{oh[3]}} & 3'd3 |
  //             {3{oh[4]}} & 3'd4 |
  //             {3{oh[5]}} & 3'd5 |
  //             {3{oh[6]}} & 3'd6 |
  //             {3{oh[7]}} & 3'd7 ;
  generate
    for(genvar i=0; i<$clog2(OH_WIDTH); i++) begin: g_matrix_i
      for(genvar j=0; j<OH_WIDTH; j++) begin: g_matrix_j
        if((j & (1 << i)) != 0) //  select j whose ith bit is 1
          assign matrix[i][j] = oh_i[j];
        else
          assign matrix[i][j] = 1'b0;
      end
      assign bin_o[i] = |matrix[i];
    end
  endgenerate

endmodule
