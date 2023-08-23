//  Fixed Priority Arbiter
module prior_arb #(                            //这个是在有多个invalid的情况下使用，可以挑选出来
  parameter REQ_NUM = 0                        //我们具体需要使用哪一个way去替换
)(
  input  logic[REQ_NUM-1:0] req,
  output logic[REQ_NUM-1:0] grant,
  output logic              grant_valid
);

  logic[REQ_NUM-1:0] prior_req;

  always_comb begin
    prior_req[0] = req[0];
    grant[0] = req[0];
    for(int i=1; i<REQ_NUM; i++) begin
      //  current request is valid and no higher priority request
      grant[i] = req[i] & ~prior_req[i-1];
      //  current request or higher priority request
      prior_req[i] = req[i] | prior_req[i-1];
    end
  end

  assign grant_valid = |req;

endmodule
