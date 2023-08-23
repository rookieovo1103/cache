module oh_logic_mux #(
  parameter NUM   = 0,
  parameter WIDTH = 0
)(
  input  logic[NUM-1:0]    oh_sel_i,
  input  logic[WIDTH-1:0]  data_i [NUM-1:0],
  output logic[WIDTH-1:0]  data_o
);

  logic[NUM-1:0] matrix [WIDTH-1:0];

  generate
    for(genvar i=0; i<WIDTH; i++) begin: g_matrix_i
      for(genvar j=0; j<NUM; j++) begin: g_matrix_j
        assign matrix[i][j] = data_i[j][i];
      end
      assign data_o[i] = |(oh_sel_i & matrix[i]);
    end
  endgenerate

endmodule
