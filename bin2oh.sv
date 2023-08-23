module bin2oh #(
  parameter OH_WIDTH  = 8
  )(
  input  logic[$clog2(OH_WIDTH)-1:0] bin_i,
  output logic[OH_WIDTH-1:0]         oh_o
  );

  //  binary to one-hot
  generate
    for(genvar i=0; i<OH_WIDTH; i++) begin: g_oh
      assign oh_o[i] = (bin_i == i);
    end
  endgenerate

endmodule
