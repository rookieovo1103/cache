import cache_pkg::*;
module tag_array(
    input  logic                   clk,
    input  logic                   rd_req_valid_i,
    input  logic [CACHE_IDX_W-1:0] rd_req_idx_i,
    input  logic [CACHE_WAY_N-1:0] rd_req_way_i,
    input  logic                   wr_req_valid_i,
    input  logic [CACHE_IDX_W-1:0] wr_req_idx_i,
    input  logic [CACHE_WAY_N-1:0] wr_req_way_i,
    input  logic [CACHE_TAG_W-1:0] wr_req_tag_i,
    output logic [CACHE_TAG_W-1:0] tag_rd_o [CACHE_WAY_N-1:0],
    output logic [TAG_ECC_W-1:0]   tag_ecc_rd_o [CACHE_WAY_N-1:0]
);

    logic ce;
    logic [CACHE_WAY_N-1:0] we;
    logic [CACHE_IDX_W-1:0] idx;
    logic [CACHE_WAY_N-1:0] way_en;
    logic [TAG_ECC_W-1:0]   tag_encoder_ecc;

    generate
        for(genvar i=0; i<CACHE_WAY_N; i++) begin: g_tag_way
            sram_model  #(
                .DATA_W (CACHE_TAG_W),
                .ADDR_W (CACHE_IDX_W),
                .SINGLE_ERROR_INJ(1),
                .DOUBLE_ERROR_INJ(0)
            ) u_tag_ram(
                .clk(clk),
                .ce(ce),
                .way_en(way_en[i]),
                .we(we[i]),
                .addr(idx),
                .w_data(wr_req_tag_i),
                .r_data(tag_rd_o[i])
            );
            sram_model  #(
                .DATA_W (TAG_ECC_W),
                .ADDR_W (CACHE_IDX_W),
                .SINGLE_ERROR_INJ(0),
                .DOUBLE_ERROR_INJ(0)
            ) u_tag_ecc_ram(
                .clk(clk),
                .ce(ce),
                .way_en(way_en[i]),
                .we(we[i]),
                .addr(idx),
                .w_data(tag_encoder_ecc),
                .r_data(tag_ecc_rd_o[i])
            );
            
        end
    endgenerate
    sec_ded_encoder_28 tag_ecc_encoder(
                                        .data_i(wr_req_tag_i),
                                        .ecc_o(tag_encoder_ecc) 
                                      );

    //generate 
    //    for(genvar i=0; i<CACHE_WAY_N; i++) begin:g_tag_ecc
    //        sec_ded_encoder_28 tag_ecc_encoder(
    //                                           .data_i(wr_req_tag_i[i]),
    //                                           .ecc_o(tag_encoder_ecc[i]) 
    //                                          );
    //    end
    //endgenerate

    assign ce = rd_req_valid_i || wr_req_valid_i;
    assign we = {CACHE_WAY_N{wr_req_valid_i}} & wr_req_way_i;
    //assign idx = rd_req_valid_i ? rd_req_idx_i : wr_req_idx_i; has the same minning as below
    assign idx = {CACHE_IDX_W{rd_req_valid_i}} & rd_req_idx_i |
                 {CACHE_IDX_W{wr_req_valid_i}} & wr_req_idx_i ;
    assign way_en = {CACHE_WAY_N{rd_req_valid_i}} & rd_req_way_i |
                    {CACHE_WAY_N{wr_req_valid_i}} & wr_req_way_i ;


endmodule