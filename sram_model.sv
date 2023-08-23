module sram_model #(
    parameter DATA_W = 0,
    parameter ADDR_W = 0,
    parameter SINGLE_ERROR_INJ = 0,
    parameter DOUBLE_ERROR_INJ = 0
)(
    input  logic clk,
    input  logic ce,//片选信号
    input  logic way_en, 
    input  logic we,//0:R 1:W
    input  logic[ADDR_W-1:0] addr,
    input  logic[DATA_W-1:0] w_data,
    output logic[DATA_W-1:0] r_data
);
    localparam DEPTH = 1 << ADDR_W;

    logic [DATA_W-1:0] mem [DEPTH-1:0];

    //cache initial
    initial begin
        for(int i=0;i<DEPTH; i++) begin
            mem[i] = {DATA_W{1'b0}};
        end
    end
    
    //write
    always @(posedge clk) begin
        if(ce && way_en && we) begin
            if(SINGLE_ERROR_INJ)
                mem[addr] <= {w_data[DATA_W-1:1], ~w_data[0]};
            else if(DOUBLE_ERROR_INJ)
                mem[addr] <= {w_data[DATA_W-1:2], ~w_data[1:0]};
            else
                mem[addr] <= w_data;
        end
    end
    //read
    always @(posedge clk) begin
        if(ce && way_en && !we)
            r_data <= mem[addr];
    end  
endmodule