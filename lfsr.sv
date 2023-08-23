//  Linear Feedback Shift Register
//  generate pseudo random number
module lfsr #(                               //不会为全0，可以位宽定大一点，假如是4路的，在valid的情况下需要挑选出来  
  parameter LFSR_WIDTH = 0                  //替换哪一way，可以使用这个，4路原本可以定义为[1:0]，但是由于不会全为0
  
)(                                           //所以可以定义为[3:0]，取其中的高2位
  input  logic                 clk,
  input  logic                 rst_n,
  output logic[LFSR_WIDTH-1:0] lfsr_data
);
      
  logic xor_bit;

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      lfsr_data <= {{(LFSR_WIDTH-1){1'b0}}, 1'b1};
      //lfsr_data <= {LFSR_WIDTH{1'b0}};
    else
      lfsr_data <= {lfsr_data[LFSR_WIDTH-2:0], xor_bit}; //  shift left
  end

  generate
    case(LFSR_WIDTH)
      3: begin
        assign xor_bit = lfsr_data[2] ^ lfsr_data[1];
      end
      4: begin
        assign xor_bit = lfsr_data[3] ^ lfsr_data[2];
      end
      8: begin
        assign xor_bit = lfsr_data[7] ^ lfsr_data[5] ^ lfsr_data[4] ^ lfsr_data[3];
      end
      16: begin
        assign xor_bit = lfsr_data[15] ^ lfsr_data[14] ^ lfsr_data[12] ^ lfsr_data[3];
        //assign xor_bit = lfsr_data[15] ^~ lfsr_data[14] ^~ lfsr_data[12] ^~ lfsr_data[3];
      end
    endcase
  endgenerate

endmodule
